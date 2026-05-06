---
title: "Listing datasets"
description: "Discover available datasets via /datasets — pagination, filtering by tag / namespace / collection."
visibility: external
audience: integrators
order: 5
---

# Listing datasets

`GET /datasets` is the discovery endpoint. It returns the list of
datasets the API publishes, optionally filtered by `tag`, `namespace`,
or `collection`. Use it to find the namespace + collection pair you
need before fetching records (see [records.md](./records.md)).

## Endpoint

```http
GET /datasets HTTP/2
Host: api-test.corthodex.ai
X-API-Key: <your-key>
```

## Parameters

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `limit`      | integer | 50 | 1–1000. See [pagination.md](./pagination.md) |
| `offset`     | integer | 0  | See [pagination.md](./pagination.md) |
| `tag`        | string  | — | Filter to datasets carrying this tag. Pattern `^[a-zA-Z0-9-_]+$` |
| `namespace`  | string  | — | Filter to a specific namespace (e.g., `education`, `employment`) |
| `collection` | string  | — | Filter to a specific collection name within whatever namespace |

All filters are exact match. There's no wildcard, no full-text
search. Combine them as needed:

```bash
# All education datasets, page 1
curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
  "https://api-test.corthodex.ai/datasets?namespace=education&limit=50" | jq

# Just the colleges/overview dataset
curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
  "https://api-test.corthodex.ai/datasets?namespace=education&collection=colleges-overview" | jq
```

## Response

```json
{
  "success": true,
  "data": {
    "datasets": [
      {
        "namespace": "education",
        "collection": "colleges-overview",
        "title": "College Overview",
        "description": "Institutional data for U.S. colleges and universities",
        "tags": ["colleges", "education", "ipeds"],
        "recordCount": 6234,
        "lastUpdated": "2026-04-30T18:00:00Z"
      },
      ...
    ]
  },
  "pagination": { "limit": 50, "offset": 0, "total": 18, "hasMore": false },
  "metadata": { "requestId": "req-..." }
}
```

| Field | Notes |
|---|---|
| `namespace` | The dataset's namespace; first segment of the records URL |
| `collection` | The dataset's collection name; second segment |
| `title` | Human-readable label (UI / docs) |
| `description` | One-line purpose |
| `tags` | Free-form labels for grouping; usable as the `tag` filter |
| `recordCount` | Approximate row count at last publication |
| `lastUpdated` | When the published copy was generated |

## Authorization

The list returns only datasets your API key is authorized to read.
A key with no dataset scope returns `{"data":{"datasets":[]},
"pagination":{"total":0,...}}` (200 OK with an empty list, **not**
401). If you expected datasets and see an empty list, your scope is
empty — coordinate with your liaison.

## Common patterns

### Discover everything you can read

```bash
curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
  "https://api-test.corthodex.ai/datasets?limit=1000" | jq '.data.datasets[] | {namespace, collection}'
```

### Find datasets by topic via tags

```bash
curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
  "https://api-test.corthodex.ai/datasets?tag=ipeds" | jq '.data.datasets[].collection'
```

### Verify a dataset exists before fetching records

```bash
NS=education COL=colleges-overview
curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
  "https://api-test.corthodex.ai/datasets?namespace=$NS&collection=$COL" \
  | jq -e '.data.datasets | length > 0' \
  && echo "exists"
```

## What this endpoint does NOT cover

- The **records** of a dataset — see [records.md](./records.md)
- The **field schema and freshness** of a dataset — see
  [metadata.md](./metadata.md)
- Searching record content (e.g., "find colleges named Harvard") —
  this endpoint lists *datasets*, not records. Record search /
  filtering at the row level isn't currently exposed in the spec.
