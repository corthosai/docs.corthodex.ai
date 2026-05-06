---
title: "Examples"
description: "End-to-end worked examples for the most common Corthodex workflows."
visibility: external
audience: integrators
order: 8
---

# Examples

Worked end-to-end examples covering the most common partner
workflows: discovery, single-page reads, full-collection sync, and
freshness-gated workflows. All examples target the **test** server;
swap to `https://api.corthodex.ai` once your key is prod-authorized.

## 1. First request (smoke test)

```bash
export CORTHODEX_API_KEY="<your-key>"
curl -s https://api-test.corthodex.ai/health | jq
```

Health is unauthenticated. If this fails, your network path is
broken. If it succeeds and an authenticated call still 401s, your
key isn't valid — see [authentication.md](./authentication.md).

## 2. Discover what you can read

```bash
curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
  "https://api-test.corthodex.ai/datasets?limit=1000" \
  | jq '.data.datasets[] | "\(.namespace)/\(.collection)"' \
  | sort -u
```

The list is your authorization scope. An empty list means your scope
is empty — coordinate with your Corthodex liaison.

## 3. Inspect a dataset before pulling records

```bash
NS=education COL=colleges-overview
curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
  "https://api-test.corthodex.ai/datasets/$NS/$COL/metadata" \
  | jq '{recordCount: .data.recordCount, fields: (.data.fields | keys), status: .data.freshness.status}'
```

Use this to confirm the dataset has the fields you expect and the
data is fresh.

## 4. Fetch a small slice with field selection

```bash
curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
  "https://api-test.corthodex.ai/datasets/education/colleges-overview?limit=10&fields=unitid,name,state" \
  | jq '.data.records'
```

`fields=` reduces payload size — useful when you only need a few
columns from a wide schema.

## 5. Walk a full collection (paginated batch sync)

```bash
NS=education COL=colleges-overview
LIMIT=5000 OFFSET=0 OUTPUT=colleges.ndjson
> "$OUTPUT"

while true; do
  body=$(curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
    "https://api-test.corthodex.ai/datasets/$NS/$COL?limit=$LIMIT&offset=$OFFSET")
  echo "$body" | jq -c '.data.records[]' >> "$OUTPUT"
  more=$(echo "$body" | jq -r '.pagination.hasMore')
  total=$(echo "$body" | jq -r '.pagination.total')
  echo "fetched offset=$OFFSET (total=$total) more=$more"
  [ "$more" = "true" ] || break
  OFFSET=$((OFFSET + LIMIT))
done

wc -l "$OUTPUT"   # one record per line
```

For very large collections (>1M rows), watch for slow responses at
high offsets — see
[pagination.md § cursor-based pagination](./pagination.md).

## 6. Filter datasets by tag

```bash
curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
  "https://api-test.corthodex.ai/datasets?tag=ipeds&limit=100" \
  | jq '.data.datasets[].collection'
```

Tags are the closest thing to dataset categorization. The available
tags are visible in any dataset's response under `data.datasets[].tags`.

## 7. Freshness-gated downstream sync

Skip the sync if the dataset hasn't been refreshed since your last
run:

```bash
NS=education COL=colleges-overview
LAST_RUN_FILE=.last-sync-$NS-$COL

last_seen=$(cat "$LAST_RUN_FILE" 2>/dev/null || echo "1970-01-01T00:00:00Z")
generated=$(curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
  "https://api-test.corthodex.ai/datasets/$NS/$COL/metadata" \
  | jq -r '.data.freshness.generatedAt')

if [ "$generated" \> "$last_seen" ]; then
  echo "new data ($generated > $last_seen), syncing..."
  # ... do the sync ...
  echo "$generated" > "$LAST_RUN_FILE"
else
  echo "no new data (still $generated), skipping"
fi
```

## 8. Robust error handling

```bash
NS=education COL=colleges-overview

response=$(curl -s -w "\n%{http_code}" -H "X-API-Key: $CORTHODEX_API_KEY" \
  "https://api-test.corthodex.ai/datasets/$NS/$COL?limit=1")

http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | head -n -1)
request_id=$(echo "$body" | jq -r '.metadata.requestId')

case "$http_code" in
  200) echo "ok (request_id=$request_id)" ;;
  401) echo "auth failed (request_id=$request_id) — check X-API-Key"; exit 1 ;;
  403) echo "scope error (request_id=$request_id) — contact liaison"; exit 1 ;;
  404) echo "not found (request_id=$request_id) — dataset name typo?"; exit 2 ;;
  4??) echo "client error $http_code (request_id=$request_id): $(echo "$body" | jq -c '.error')"; exit 1 ;;
  5??) echo "server error $http_code (request_id=$request_id), retrying..."; sleep 5 ; ;;
  *)   echo "unexpected $http_code"; exit 99 ;;
esac
```

The `request_id` is the most useful piece of data when filing an
issue — it correlates your logs with the API's. See
[errors.md § What to log](./errors.md#what-to-log).

## 9. Polite polling (rate-limit-friendly)

If you're polling for fresh data, stay under 1 request per second
per key:

```bash
while true; do
  curl -s -H "X-API-Key: $CORTHODEX_API_KEY" \
    "https://api-test.corthodex.ai/datasets/$NS/$COL/metadata" \
    | jq '.data.freshness.generatedAt'
  sleep 5    # don't hammer the API
done
```

For batch syncs that don't need to be near-real-time, 1 request per
second is fine; for monitoring loops, 5–60 seconds between checks
keeps the partner well under quota.

## TypeScript client sketch

```ts
const BASE = process.env.CORTHODEX_BASE ?? "https://api-test.corthodex.ai";
const KEY = process.env.CORTHODEX_API_KEY!;

async function fetchPage<T>(path: string, qs: Record<string, string | number> = {}) {
  const url = new URL(BASE + path);
  for (const [k, v] of Object.entries(qs)) url.searchParams.set(k, String(v));
  const res = await fetch(url, { headers: { "X-API-Key": KEY } });
  const body = await res.json();
  if (!res.ok) {
    throw new Error(`${body.error?.code ?? res.status}: ${body.error?.message ?? ""} (req=${body.metadata?.requestId})`);
  }
  return body as { success: true; data: T; pagination?: any; metadata: any };
}

// Usage:
const { data, pagination } = await fetchPage<{ records: any[] }>(
  "/datasets/education/colleges-overview",
  { limit: 100, fields: "unitid,name,state" }
);
console.log(data.records.length, "of", pagination.total);
```

This is the minimum viable typed client; for production use, layer
in retry/backoff (see [errors.md § 5xx](./errors.md)) and structured
logging of `requestId`.
