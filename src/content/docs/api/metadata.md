---
title: "Dataset metadata"
description: "Inspect a dataset's field schema, freshness, and lineage via /datasets/{namespace}/{collection}/metadata."
visibility: external
audience: integrators
order: 7
---

# Dataset metadata

`GET /datasets/{namespace}/{collection}/metadata` returns the
descriptive metadata for a dataset: field schemas (names, types,
constraints), freshness (when the data was last generated), and
lineage (where it came from upstream).

Use it to discover what's in a dataset before pulling records, or to
verify the data is fresh enough for your use case.

## Endpoint

```http
GET /datasets/{namespace}/{collection}/metadata HTTP/2
Host: api-test.corthodex.ai
X-API-Key: <your-key>
```

Path parameters: same as [records.md § endpoint](./records.md).

This endpoint takes no query parameters today.

## Example

```bash
curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
  "https://api-test.corthodex.ai/datasets/education/colleges-overview/metadata" | jq
```

```json
{
  "success": true,
  "data": {
    "namespace": "education",
    "collection": "colleges-overview",
    "title": "College Overview",
    "description": "Institutional data for U.S. colleges and universities",
    "recordCount": 6234,
    "fields": {
      "unitid":   { "type": "integer", "required": true,  "description": "IPEDS unit identifier" },
      "name":     { "type": "string",  "required": true,  "description": "Institution name" },
      "state":    { "type": "string",  "required": false, "enum": ["AL", "AK", "AZ", ...] },
      "founded":  { "type": "integer", "required": false, "min": 1636 }
    },
    "freshness": {
      "generatedAt":        "2026-04-30T18:00:00Z",
      "sourceLastModified": "2026-04-29T22:14:00Z",
      "ageHours": 31,
      "status": "fresh"
    },
    "lineage": {
      "sourceQuery":  "SELECT ... FROM colleges_overview",
      "sourceSystem": "corthodex-warehouse",
      "dependencies": ["ipeds-2024", "scorecard-2024"]
    }
  },
  "metadata": { "requestId": "req-..." }
}
```

## `fields` shape

`data.fields` is a map keyed by field name. Each value is a
`FieldSchema`:

| Property | Type | Notes |
|---|---|---|
| `type` | string | One of `string`, `integer`, `number`, `boolean`, `array`, `object` |
| `required` | boolean | Whether the field is always present in records |
| `description` | string | Human-readable explanation |
| `min` / `max` | number | Range constraints (when applicable) |
| `pattern` | string | Regex constraint (string fields) |
| `enum` | array of string | Allowed values (when constrained to an enumeration) |

Use this map to drive client-side validation, build form inputs, or
limit which fields you request via the `fields` parameter on the
records endpoint.

## `freshness`

| Field | Notes |
|---|---|
| `generatedAt` | When the published JSON was last regenerated |
| `sourceLastModified` | When the upstream warehouse last updated the source |
| `ageHours` | Convenience: integer hours between `generatedAt` and now |
| `status` | `fresh`, `stale`, or `unknown`. Threshold for "stale" varies per dataset. |

If `status` is `stale` or `unknown`, the data is still served — the
flag is informational. Use it to decide whether to refresh, alert,
or fall back.

## `lineage`

| Field | Notes |
|---|---|
| `sourceQuery` | The warehouse query that produced this dataset |
| `sourceSystem` | The system the query ran against (typically `corthodex-warehouse`) |
| `dependencies` | Identifiers of upstream datasets / sources this depends on |

`lineage` is informational; partners use it to trace data back to
authoritative sources for verification or compliance.

## Authorization

Same as records: a key without scope for this dataset gets
`403 Forbidden`.

## Common patterns

### Discover field names before fetching records

```bash
NS=education COL=colleges-overview
curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
  "https://api-test.corthodex.ai/datasets/$NS/$COL/metadata" \
  | jq -r '.data.fields | keys[]'
```

### Verify data is fresh enough before a downstream sync

```bash
status=$(curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
  "https://api-test.corthodex.ai/datasets/$NS/$COL/metadata" \
  | jq -r '.data.freshness.status')

[ "$status" = "fresh" ] || { echo "stale, aborting"; exit 1; }
```

### Build a typed client from the field schemas

The `fields` map is structured enough to drive code generation in
many languages. Pair it with the OpenAPI spec for a complete typed
client.

## Versioning

`metadata` does **not** carry an explicit per-dataset version field
in the current spec. The closest signals are `generatedAt` (when this
copy was produced) and `lineage.dependencies` (which upstream
versions it was built from). A future spec update is expected to add
an explicit `version` field; until then treat `generatedAt` as the
version handle.
