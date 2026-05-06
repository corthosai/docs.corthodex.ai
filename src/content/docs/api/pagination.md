---
title: "Pagination"
description: "limit / offset mechanics for the two list endpoints, default page sizes, and how to walk large result sets."
visibility: external
audience: integrators
order: 4
---

# Pagination

Both list endpoints — `/datasets` and `/datasets/{namespace}/{collection}`
— support `limit` / `offset` paging. Each response body carries a
`pagination` block reporting the current page plus a `total` and a
`hasMore` flag.

## Parameters

| Parameter | Endpoint | Default | Min | Max | Notes |
|---|---|---|---|---|---|
| `limit`  | `/datasets` | 50 | 1 | 1000 | Cap is conservative; higher values are paged on the server side regardless |
| `offset` | `/datasets` | 0 | 0 | — | Skip the first N |
| `limit`  | `/datasets/{ns}/{col}` | 1000 | 1 | 10000 | Records are smaller per row; higher cap |
| `offset` | `/datasets/{ns}/{col}` | 0 | 0 | — | Skip the first N records |

`limit=0` returns `400 BadRequest` (use `limit=1` for "just one
record"). Negative values likewise.

## Response shape

```json
{
  "success": true,
  "data": { "datasets": [ ... ] },
  "pagination": {
    "limit": 50,
    "offset": 0,
    "total": 1247,
    "hasMore": true
  },
  "metadata": { "requestId": "req-..." }
}
```

- `total` is the count after any filters (`tag`, `namespace`,
  `collection` for `/datasets`) — it's the size of the result set
  you'd get walking through to the end with the same filter
- `hasMore` is `true` iff `offset + limit < total`

## Walking pages

```bash
LIMIT=200 OFFSET=0 BASE=https://api-test.corthodex.ai
while true; do
  body=$(curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
    "$BASE/datasets?limit=$LIMIT&offset=$OFFSET")
  echo "$body" | jq '.data.datasets[]'      # do work with this page
  more=$(echo "$body" | jq -r '.pagination.hasMore')
  [ "$more" = "true" ] || break
  OFFSET=$((OFFSET + LIMIT))
done
```

For `/datasets/{namespace}/{collection}`, swap the URL and consider
the higher `limit` cap (10000) — fewer round trips for large
collections.

## Choosing a page size

- **Discovery / browse**: 50–100. Default is fine.
- **Sync / batch**: 500–1000 for `/datasets`, 1000–5000 for
  `/datasets/{ns}/{col}`. Larger pages amortize per-request overhead.
- **Single record**: pass `limit=1` and a precise filter. There's no
  "get one by id" endpoint today — see the
  [issue tracker](https://github.com/corthosai/api.corthodex.ai/issues)
  for the planned `/datasets/{ns}/{col}/{id}` shape.

## Stable ordering

The response order is server-determined and stable across pages
within a single result set (no need to sort defensively). It is
**not** guaranteed to match across versions of the underlying
dataset — if a dataset is regenerated mid-walk, the page boundaries
may shift. For consistent walks of large datasets, complete the walk
in a single session or filter to a stable subset.

## Common pagination errors

- **Skipping records**: forgetting to advance `offset` by `limit`.
  Always `OFFSET = OFFSET + LIMIT`, not `+ 1`.
- **Infinite loops**: not breaking on `hasMore=false`. The example
  above guards against this.
- **Off-by-one with `total`**: `total` is the count, not the index.
  The last record is at `offset = total - 1`.

## Future: cursor-based pagination

The current `limit`/`offset` model has known weaknesses for very
large result sets (response time degrades as `offset` grows).
Cursor-based paging is on the roadmap; partners doing batch syncs of
the largest collections may hit `504 Gateway Timeout` at high offsets
in the meantime. Fall back to filter-narrowing (page within smaller
slices) if you encounter this.
