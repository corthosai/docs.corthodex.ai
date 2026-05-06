---
title: "Authentication"
description: "The X-API-Key header model: where keys come from, how they're scoped, and how to rotate them."
visibility: external
audience: integrators
order: 2
---

# Authentication

Every endpoint except `/health` requires an API key passed in the
`X-API-Key` header. Keys are scoped per partner and per environment
(test vs prod) — a key valid for one is not valid for the other.

## Header

```http
GET /datasets HTTP/2
Host: api-test.corthodex.ai
X-API-Key: <your-key>
```

The header name is exactly `X-API-Key`. Other casings (`X-Api-Key`,
`x-api-key`) work in most server stacks but aren't guaranteed by the
spec; stick to the canonical form for portability.

## Where keys come from

Keys are issued during partner onboarding. To request one, open an
issue in `corthosai/api.corthodex.ai` (or contact your Corthodex
liaison directly) and include:

- Your partner / organization name
- The datasets you need access to (namespace + collection pairs, or
  "all read")
- Whether you need test, prod, or both
- A contact for key rotation

Keys are delivered out of band (typically via 1Password share or
signed message) — never echoed in tickets, never committed.

## Scope

A key authorizes:

- A set of `(namespace, collection)` pairs — datasets you may read
- An environment — test or prod (separate keys)

Calling an in-scope endpoint with an out-of-scope dataset returns a
`403 Forbidden` (see [errors.md § 403](./errors.md)). The set of
authorized datasets is the registry side of partner config; partners
can't enumerate it from the API directly today — coordinate with
your liaison if you're unsure of your scope.

## Storage

Treat the key like a database password:

- Don't commit it to source control
- Don't echo it in CI logs
- Don't paste it into shared chat
- Store it in your CI's secrets manager or an env file ignored by git

A typical local setup:

```bash
# In your shell profile, or per-session:
export CORTHODEX_API_KEY="<your-key>"

# In code:
curl -H "X-API-Key: $CORTHODEX_API_KEY" "$BASE_URL/datasets"
```

## Rotation

To rotate, request a new key through the same channel. Both old and
new keys remain valid through a brief overlap window (default 7 days)
so you can deploy the new key without an outage. After the window the
old key is revoked.

## Revocation

If a key leaks or you suspect compromise, file an urgent issue and
include the **first and last 4 characters** of the leaked key for
identification (never the full key). Your liaison revokes immediately;
expect a new key within one business day.

## Auth-related responses

| Status | When |
|---|---|
| `401 Unauthorized` | Header missing, malformed, unknown, or revoked |
| `403 Forbidden` | Key valid but the requested dataset is out of scope |

The full envelope for both is documented in [errors.md](./errors.md).

## Implementation note (transparency)

The current implementation uses an in-tree key validation surface;
production validates against the `VALID_API_KEYS` env-var-managed
list. The intent is a managed key store; until that lands, key
issuance is a manual step (the issue-based flow above). This doesn't
affect partner-facing behavior — same `X-API-Key` header, same 401/403
semantics — but it's why key rotation has a 1-business-day SLA rather
than an instant self-serve flow.
