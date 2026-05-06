---
title: "API Documentation"
description: "Index of partner-facing narrative docs that travel alongside openapi.yaml."
visibility: external
audience: integrators
---

# API documentation

These eight companion docs cover what `openapi.yaml` alone can't carry:
the auth model, the response envelope, the dataset query surface, the
metadata shape, error handling, pagination, and worked examples.

| File | Topic |
|---|---|
| [overview.md](./overview.md) | What the API is, base URLs, response envelope, `/health` smoke test |
| [authentication.md](./authentication.md) | The `X-API-Key` header model and where keys come from |
| [errors.md](./errors.md) | `ApiError` envelope, status codes, common failure modes |
| [pagination.md](./pagination.md) | `limit` / `offset` mechanics for list endpoints |
| [datasets.md](./datasets.md) | Listing and filtering datasets via `/datasets` |
| [records.md](./records.md) | Fetching dataset records via `/datasets/{namespace}/{collection}` |
| [metadata.md](./metadata.md) | Dataset metadata via `/datasets/{namespace}/{collection}/metadata` |
| [examples.md](./examples.md) | End-to-end worked examples for common workflows |

The machine-readable contract lives at `openapi.yaml` (symlinked from
`docs/schema/openapi.yaml`) and is rendered as the **API Reference**
sidebar group on the published docs site.

These files are tagged `visibility: external` so the codex sync flow
can transport them to `docs.corthodex.ai` for public publishing.
