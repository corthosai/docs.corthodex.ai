---
title: Quickstart
description: From an issued API key to your first response in 5 minutes.
---

# Quickstart

This walkthrough takes you from a freshly-issued API key to a real
response from the Corthodex test environment. You should be able to
finish in about 5 minutes if your key is in hand.

The flow:

1. Set your API key as an environment variable.
2. Confirm the API is reachable (no auth needed).
3. Confirm your key is valid.
4. Look up a single college by slug.
5. Filter a list with one of the query operators.
6. Pull metadata for a collection.

We use simple GETs throughout — Corthodex is a read-only data API; no
state mutation, no approval gates. Once these calls work, the rest of
the surface (cohorts, includes, pagination, full filter grammar) is
explored in the [Concepts](/api/overview/) and [Querying](/api/filters/)
docs.

## Prerequisites

- An API key from Corthodex onboarding. If you don't have one, see
  [Authentication](/api/authentication/) for how to request one.
- `curl` and `jq` available on your shell. Substitute equivalents if
  you prefer.

## 1. Set your API key

```bash
export CORTHODEX_API_KEY="<paste-your-api-key-here>"
```

Treat this like any other credential — don't echo it in CI logs,
don't commit it, don't paste it into shared chat. The API never echoes
it back, but your shell history will.

## 2. Health check (no auth)

Confirm the API is reachable:

```bash
curl https://api-test.corthodex.ai/health
```

```json
{"status":"ok","version":"1.0.0"}
```

If you get anything other than `200 OK`, stop here — the rest will
fail for the same reason. Check your network path before continuing.

## 3. Confirm your API key works

A 401 from the next call means the API didn't recognize your key. A
200 with a JSON object means everything's wired correctly:

```bash
curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
  "https://api-test.corthodex.ai/api/v1/education/colleges/overview/harvard-university" | jq '{name: .name, state: .state, city: .city}'
```

```json
{
  "name": "Harvard University",
  "state": "MA",
  "city": "Cambridge"
}
```

The API uses `X-API-Key` as the header name (not `Authorization:
Bearer`). If you got a 401 here, see
[Authentication § Common errors](/api/authentication/) before
continuing.

## 4. Filter a list

The query grammar is `?{collection}.{field}__{op}={value}`. Filter
colleges to only those with an acceptance rate at or below 20%:

```bash
curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
  "https://api-test.corthodex.ai/api/v1/education/colleges/overview?admission.acceptance_rate__lte=0.2&limit=5" | jq '.[] | {name: .name, rate: .admission.acceptance_rate}'
```

Operators include `eq`, `ne`, `lt`, `lte`, `gt`, `gte`, `in`,
`not_in`, `contains`, `starts_with`, `between`, and the
domain-specific `cip_begins_with`. Full reference at
[Filters](/api/filters/).

## 5. Look up metadata

Every collection has a metadata endpoint that describes its fields:

```bash
curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
  "https://api-test.corthodex.ai/api/v1/education/colleges/overview/metadata" | jq '.fields | keys'
```

Use this to discover what's filterable and what types of values to
pass. See [Metadata](/api/metadata/) for the full shape.

## What's next

You've proven the auth + read + filter loop works end-to-end. From
here:

- **All endpoints**: the [API Reference](/reference/) is generated
  from the OpenAPI spec — every collection, every parameter
- **Concepts**: how the API thinks about [authentication](/api/authentication/),
  [errors](/api/errors/), and [pagination](/api/pagination/)
- **Querying**: [filters](/api/filters/), [cohorts](/api/cohorts/),
  [`?include=` server-side merge](/api/include-merge/), and
  [worked examples](/api/examples/) for common workflows
- **Production**: re-run this walkthrough against
  `https://api.corthodex.ai` once your key is authorized for the
  prod environment

If something doesn't work the way you expect, [Troubleshooting](/troubleshooting/)
is keyed by symptom.
