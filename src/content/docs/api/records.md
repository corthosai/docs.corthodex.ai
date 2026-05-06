---
title: "Fetching records"
description: "Retrieve dataset records via /datasets/{namespace}/{collection} with pagination and field selection."
visibility: external
audience: integrators
order: 6
---

# Fetching records

`GET /datasets/{namespace}/{collection}` returns the rows of a
dataset. Use this once you've discovered the namespace + collection
pair via [`/datasets`](./datasets.md).

## Endpoint

```http
GET /datasets/{namespace}/{collection} HTTP/2
Host: api-test.corthodex.ai
X-API-Key: <your-key>
```

Path parameters:

| Parameter | Pattern | Notes |
|---|---|---|
| `namespace`  | `^[a-zA-Z0-9-_]+$` | From `/datasets` response |
| `collection` | `^[a-zA-Z0-9-_]+$` | From `/datasets` response |

## Query parameters

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `limit`  | integer | 1000 | 1–10000. See [pagination.md](./pagination.md) |
| `offset` | integer | 0    | See [pagination.md](./pagination.md) |
| `fields` | string  | —    | Comma-separated field names to include. Pattern `^[a-zA-Z0-9_]+(,[a-zA-Z0-9_]+)*$`. Reduces payload size. |

## Example

```bash
curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
  "https://api-test.corthodex.ai/datasets/education/colleges-overview?limit=2&fields=name,state,city" \
  | jq
```

```json
{
  "success": true,
  "data": {
    "records": [
      { "name": "Harvard University", "state": "MA", "city": "Cambridge" },
      { "name": "Yale University",    "state": "CT", "city": "New Haven" }
    ]
  },
  "pagination": { "limit": 2, "offset": 0, "total": 6234, "hasMore": true },
  "metadata": { "requestId": "req-..." }
}
```

## Field selection

`fields` is a denylist-by-omission: any field not in the list is
dropped from each record. Field names that don't exist in the
dataset's schema return `400 BadRequest` with `details.field`
naming the offender:

```json
{
  "success": false,
  "error": {
    "code": "BadRequest",
    "message": "Unknown field 'unicornness' in fields parameter",
    "details": { "field": "unicornness" }
  }
}
```

To see the available field names, call the
[metadata endpoint](./metadata.md):

```bash
curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
  "https://api-test.corthodex.ai/datasets/education/colleges-overview/metadata" \
  | jq '.data.fields | keys'
```

## Pagination at scale

The default `limit=1000` is suitable for batch reads. The hard cap
is `10000`; very large collections may have `total` in the millions
— see [pagination.md § cursor-based pagination](./pagination.md) for
the limits of `offset` at high values.

## Authorization

If your key isn't authorized for this namespace + collection, you'll
get `403 Forbidden` (see [errors.md § 403](./errors.md)). The check
happens before the dataset lookup, so you'll get 403 even if the
dataset doesn't exist for this caller.

If the namespace + collection genuinely doesn't exist, you'll get
`404 NotFound`.

## Response shape

The `data.records` array contains rows in the dataset's natural
schema. Field types and meaning are documented in the metadata
endpoint — see [metadata.md](./metadata.md). The order of records
is server-determined but stable across pages in a single result
set (see [pagination.md § stable ordering](./pagination.md)).

## What this endpoint does NOT cover

- **Filtering records by field value** — not currently exposed in the
  spec. The `tag`, `namespace`, and `collection` query params live on
  `/datasets`, not here. Row-level filtering (`?status=accredited`,
  `?cip_code=11.0101`) is implementation-side and not part of the
  published contract today.
- **Single-record lookup by ID** — not currently exposed. Use
  `limit=1` with the lowest-offset matching record, or fetch the page
  containing the record you want.
- **Record-level metadata** — see the
  [metadata endpoint](./metadata.md) for collection-level field
  descriptions.
