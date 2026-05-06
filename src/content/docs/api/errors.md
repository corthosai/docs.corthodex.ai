---
title: "Errors"
description: "ApiError envelope, status code map, common failure modes, and what to retry."
visibility: external
audience: integrators
order: 3
---

# Errors

Every non-2xx response uses the same envelope: a `success: false`
top-level marker, an `error` object with a stable `code` plus a
human-readable `message`, optional `details`, and the standard
response `metadata` (most usefully the `requestId`).

This file is the single source of truth for the status code map.
Other narratives reference codes in context; they don't redefine
them here.

## Envelope

```json
{
  "success": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "Dataset not found",
    "details": { "namespace": "education", "collection": "unicorn-overview" }
  },
  "metadata": {
    "requestId": "req-c3a8f1b2",
    "timestamp": "2026-05-06T01:23:45Z",
    "version": "1.0",
    "processingTime": 12
  }
}
```

| Field | Notes |
|---|---|
| `success` | Always `false` for errors |
| `error.code` | Stable machine-readable identifier — branch on this, not on `message` |
| `error.message` | Human-readable summary |
| `error.details` | Optional. Endpoint-specific shape; check before relying on a field |
| `metadata.requestId` | Quote this when filing issues |

## Status code map

| Status | Class | Common causes | Retry? |
|---|---|---|---|
| `400 Bad Request` | `BadRequest` | Malformed query parameter, invalid value (e.g., `limit=0`), unknown field name in `fields=...` | No (fix the request) |
| `401 Unauthorized` | `Unauthorized` | `X-API-Key` header missing, malformed, unknown, or revoked | No (fix the key — see [authentication.md](./authentication.md)) |
| `403 Forbidden` | `Forbidden` | Key valid but the requested dataset isn't in scope | No (request scope expansion through your liaison) |
| `404 Not Found` | `NotFound` | Dataset namespace + collection doesn't exist (or has been deprecated and is no longer published) | No (check `/datasets` for current names) |
| `5xx Server Error` | (varies) | Upstream issue (S3 unavailable, Lambda cold start storm) | Yes — retry with exponential backoff |

The 4 named 4xx classes (`BadRequest`, `Unauthorized`, `Forbidden`,
`NotFound`) are stable contract — partners can branch on them. 5xx
codes don't have a fixed `code` value beyond the HTTP status.

## Common error classes

### `BadRequest` — 400

Returned when a query parameter doesn't validate. The `details`
object names the offending field and the constraint:

```json
{
  "success": false,
  "error": {
    "code": "BadRequest",
    "message": "limit must be between 1 and 1000",
    "details": { "field": "limit", "value": 0, "constraint": "min=1" }
  },
  "metadata": { "requestId": "req-..." }
}
```

Fix the request and retry.

### `Unauthorized` — 401

The `X-API-Key` header is missing, malformed, or unrecognized. The
API doesn't distinguish "wrong key" from "revoked key" in the
response — both are 401 to discourage probing.

Fix the key (see [authentication.md](./authentication.md)) and
retry. If you believe the key is correct, double-check casing
(`X-API-Key`, not `x-api-key`) and confirm you're hitting the right
environment (test key on test URL, prod key on prod URL).

### `Forbidden` — 403

Your key is valid, but the dataset you requested isn't in your
authorization scope. The `details` object names the dataset:

```json
{
  "success": false,
  "error": {
    "code": "Forbidden",
    "message": "Dataset not in scope for this API key",
    "details": { "namespace": "education", "collection": "internal-metrics" }
  },
  "metadata": { "requestId": "req-..." }
}
```

This is not a client-side issue — your scope in the API key registry
doesn't include this dataset. Contact your liaison and quote the
`requestId`.

### `NotFound` — 404

The namespace + collection combination doesn't exist. Either:

- The dataset name is misspelled — check `/datasets` for the
  authoritative list
- The dataset was deprecated and is no longer published — the
  changelog (linked from [overview.md](./overview.md)) is the place to
  look

### 5xx — server-side

The API itself is degraded. Common patterns:

- `502 Bad Gateway` — upstream Lambda timed out or returned an
  unparseable body
- `503 Service Unavailable` — upstream S3 or another dependency is
  unhealthy
- `504 Gateway Timeout` — request exceeded the API Gateway window
  (rare for datasets; possible for large `limit` values on big
  collections)

Retry with exponential backoff (start at 1 second, double up to 30
seconds, 5 attempts max). If 5xx persists for more than 10 minutes,
file an incident issue with the `requestId`.

## What to log

For your own observability, log the `requestId` from every response —
success or failure. It's the single piece of data that lets the
Corthodex team correlate your client logs with their server logs
during an incident.

## Rate limits

Quota enforcement is per-API-key. Hitting the limit returns
`429 Too Many Requests` (no fixed envelope today; check the response
body for the reset window). Back off to under 1 request per second
per key for steady-state polling; see
[troubleshooting](https://docs.corthodex.ai/troubleshooting/) on the
docs site for the symptoms.

> Note: the formal `429` response shape isn't yet pinned in
> `openapi.yaml`. Treat it as standard `ApiError` with `code:
> "RateLimitExceeded"` and a `details.retryAfter` field for now;
> a future spec update will codify this.
