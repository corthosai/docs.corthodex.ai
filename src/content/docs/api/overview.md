---
title: "Overview"
description: "What the Corthodex API does, base URLs, the response envelope, and a smoke test."
visibility: external
audience: integrators
order: 1
---

# Overview

The Corthodex API serves structured JSON datasets — colleges,
programs, occupations, rankings, places, and other education and
employment reference data — published by the Corthodex core system.
It's a read-only GET surface; writes happen out of band via the
upstream pipelines.

The published contract is `openapi.yaml`. Four endpoints today: a
health probe plus three under `/datasets`.

## Base URLs

| Environment | URL |
|---|---|
| Test  | `https://api-test.corthodex.ai` |
| Prod  | `https://api.corthodex.ai`      |

Test and prod are completely separate stacks (separate API keys,
separate datasets). Use test for integration work; promote to prod
once your scope is approved.

## Response envelope

Every successful response has the same outer shape:

```json
{
  "success": true,
  "data": { ... },
  "pagination": { ... },     // present on list endpoints
  "metadata": { ... }
}
```

- `data` carries the payload (the shape varies per endpoint)
- `pagination` is present whenever the endpoint supports paging — see [pagination.md](./pagination.md)
- `metadata` carries response-level info (request id, timing,
  upstream freshness)

Errors use a separate envelope — see [errors.md](./errors.md).

## Versioning

The version is reported in `info.version` of `openapi.yaml` and in the
`/health` payload. Breaking schema changes get a coordinated rollout
through the dataset versioning machinery (see
[metadata.md § freshness and lineage](./metadata.md)) — not a URL
version bump.

## Authentication

Every endpoint except `/health` requires an `X-API-Key` header. See
[authentication.md](./authentication.md) for the issuance flow.

## Quick smoke test

```bash
# Health check (no auth)
curl https://api-test.corthodex.ai/health
```

```json
{
  "success": true,
  "data": {
    "status": "ok",
    "timestamp": "2026-05-06T01:23:45Z",
    "environment": "test",
    "version": "1.0.0",
    "uptime": 12345.67,
    "services": { "s3": "ok", "lambda": "ok" }
  },
  "metadata": { ... }
}
```

```bash
# Authenticated route fails without a key
curl -i https://api-test.corthodex.ai/datasets
# → HTTP/2 401  {"success":false,"error":{"code":"Unauthorized","message":"..."}}

# With a key
export CORTHODEX_API_KEY="<your-key>"
curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
     "https://api-test.corthodex.ai/datasets?limit=5" | jq '.data.datasets | length'
# → 5
```

If `/datasets` returns the count you expect, your key is valid and
the API is reachable. From there the next step is fetching real
records — see [records.md](./records.md).

## Where to read next

1. Get a key: [authentication.md](./authentication.md)
2. Discover available datasets: [datasets.md](./datasets.md)
3. Fetch records: [records.md](./records.md)
4. Inspect metadata: [metadata.md](./metadata.md)
5. Handle errors: [errors.md](./errors.md)
6. Worked patterns: [examples.md](./examples.md)
7. Schema reference: `openapi.yaml` (rendered as **API Reference** in
   the docs site sidebar)
