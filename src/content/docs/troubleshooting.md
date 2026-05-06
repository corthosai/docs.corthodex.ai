---
title: Troubleshooting
description: Triage by symptom — what you're seeing, why, and the fastest path to a fix.
---

# Troubleshooting

This page is a triage aid. Find your symptom in one of the sections
below, follow the link to the relevant reference page, and (most of
the time) you'll have what you need.

If you're hitting an error you can't categorize, jump to
[Asking for help](#asking-for-help) at the bottom.

## Where to look first

When something doesn't work, check in this order:

1. **The HTTP response body** — every error response carries an
   `error` and `detail` field that name what went wrong. See
   [Errors](/api/errors/) for the canonical envelope and status-code
   map.
2. **The metadata endpoint for the collection you're querying** —
   field names, types, and filterable fields are listed at
   `GET /api/v1/{domain}/{category}/{collection}/metadata`. See
   [Metadata](/api/metadata/).
3. **This page** — for symptoms that don't have a clean error message
   or span multiple sources of truth.

## Authentication

### 401 Unauthorized on every request

The API didn't recognize your `X-API-Key` header. Common causes:

- The header is named `X-API-Key` (with that exact casing). `X-Api-Key`
  works on most servers but isn't guaranteed; stick to the canonical
  form.
- The key was truncated when copied. Corthodex keys are long; check
  the length.
- The key was rotated and the old value is still cached in your shell
  history. `unset CORTHODEX_API_KEY && export CORTHODEX_API_KEY=...`.
- You're hitting `https://api.corthodex.ai` (prod) with a test-only
  key, or vice versa.

See [Authentication](/api/authentication/) for the issuance flow.

### 403 Forbidden on a specific endpoint

The key is valid, but the action / collection / environment isn't in
your authorization scope. The `detail` field names what was rejected.
This is not a client-side fix — contact your Corthodex liaison and
quote the `detail` plus the `request_id` from the response.

## Querying

### 400 Bad Request — filter syntax

The query grammar is `?{collection}.{field}__{op}={value}`. Common
mistakes:

- Forgetting the operator suffix: `?admission.acceptance_rate=0.2`
  (no operator) instead of `?admission.acceptance_rate__lte=0.2`
- Using an operator the field doesn't support (string operators on
  numeric fields, etc.)
- Forgetting that boolean values are `true` / `false` (lowercase
  strings)

The full operator list and per-type semantics live at
[Filters](/api/filters/).

### Filter returns more results than expected

The default behavior is `eq` semantics on omitted operators where
that's defined; if you used `__contains` on a field that's actually a
nested array, you may have matched at the wrong nesting level. Check
the field's shape via the
[Metadata](/api/metadata/) endpoint and the
[Include & merge](/api/include-merge/) docs for nested-array
filtering.

### CIP code filter not narrowing the way I expect

`cip_begins_with` is a prefix match — `cip_begins_with=11` matches
both `11.0101` (Computer Science) and `11.99` (other CIP-11). To
filter to specific CIP4 buckets pass them explicitly:
`cip_begins_with=11.07,11.10`. CIP code semantics live at
[Filters § CIP code filtering](/api/filters/).

## Cohorts

### `group_by` returned an empty result

Either the cohort dimension you asked for isn't supported on this
collection, or the dimension key is misspelled. The metadata endpoint
lists supported dimensions for each cohort-aware collection. See
[Cohorts](/api/cohorts/) for the canonical key format.

### Dimension key looks wrong / different from another collection

Dimension keys are aliased per collection. `gender` may be the alias
for `student_gender` in one collection and `faculty_gender` in
another. Always check metadata before assuming.

## Pagination

### Hit a hard ceiling on results

Default page sizes vary per collection; see the per-collection
metadata endpoint or the [Pagination](/api/pagination/) reference
for limits. For walking large result sets use `limit`/`offset` with
sensible page sizes (50–200 rows per request).

### `limit` exceeded — what now

The API caps `limit` per collection. Walking pages with `offset` is
the right pattern for large lists; for very large sweeps consider
filtering down (e.g., `cip_begins_with` for programs/colleges) before
paging.

## Includes and merging

### `?include=overview,rankings` returns the base shape only

The `?include=` grammar performs a server-side merge of named
sub-collections. If the included collection isn't applicable to the
entity (e.g., asking for `rankings` on an institution that isn't
ranked), the included keys simply don't appear; this is not an error.
See [Include & merge](/api/include-merge/) for compatibility.

### Got a 404 on a slug I expected to exist

Slugs are URL-safe lowercased and may differ from the institution's
display name. Use the list endpoint
(`GET /api/v1/education/colleges/overview?limit=…`) and grep for the
name to find the canonical slug, or pass the institution's numeric
`unitid` instead.

## Rate limits

### 429 Too Many Requests

You hit the per-key concurrent or daily quota. The `detail` field
reports the limit and (for daily quotas) the reset window. Back off
to under 1 request/second per key for steady-state polling; for batch
work, request a quota uplift through your liaison.

## Versions

### Field disappeared between two requests

Collections support versioning via a `_versions.json` resolver.
Production resolves to `current` by default but the contract allows
per-collection overrides — see
[Metadata § Versioning](/api/metadata/) for the resolution rules.
If a field was renamed or removed in a new version, the changelog is
the place to look (link from the [API overview](/api/overview/)).

## Asking for help

If none of the above matches what you're seeing:

- Capture the failing request (URL + headers, body redacted)
- Capture the response (status, headers, body — quote the
  `request_id` field)
- Note the time (UTC) and which environment (test vs prod)
- File an issue in `corthosai/api.corthodex.ai` and tag your
  Corthodex liaison

The `request_id` is the single most useful piece of information —
it's the API's log-correlation handle.
