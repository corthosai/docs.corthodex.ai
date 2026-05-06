#!/usr/bin/env bash
# scripts/build-content.sh
#
# Reads codex-synced content from .fractary/codex/cache/projects/{source}/...
# and assembles it into src/content/docs/ for Astro Starlight to build.
#
# This site has one upstream source: api.corthodex.ai. The source repo
# authors partner-facing narratives at docs/api/*.md (visibility: external)
# plus the OpenAPI spec at openapi.yaml; codex routing pulls them here.
#
# Run locally: ./scripts/build-content.sh  (or `npm run build:content`)
# Run by Amplify build (see amplify.yml).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE="$ROOT/.fractary/codex/cache/projects"
CONTENT="$ROOT/src/content/docs"

# Native chrome (index.mdx, quickstart.md, troubleshooting.md) is preserved —
# we wipe and rewrite ONLY the source-project subdirectories under CONTENT,
# never the native files at CONTENT root.

copy_api_source() {
  local src="$CACHE/api.corthodex.ai"
  local dst="$CONTENT/api"

  if [ ! -d "$src" ]; then
    echo "warning: api.corthodex.ai cache not found at $src — skipping"
    return
  fi

  rm -rf "$dst"
  mkdir -p "$dst"

  # Source repo's docs/api/README.md becomes our api/index.md so it's the
  # section's landing page in the rendered sidebar.
  cp "$src/docs/api/README.md" "$dst/index.md"
  cp "$src/docs/api/overview.md" "$dst/overview.md"
  cp "$src/docs/api/authentication.md" "$dst/authentication.md"
  cp "$src/docs/api/errors.md" "$dst/errors.md"
  cp "$src/docs/api/pagination.md" "$dst/pagination.md"
  cp "$src/docs/api/filters.md" "$dst/filters.md"
  cp "$src/docs/api/cohorts.md" "$dst/cohorts.md"
  cp "$src/docs/api/metadata.md" "$dst/metadata.md"
  cp "$src/docs/api/include-merge.md" "$dst/include-merge.md"
  cp "$src/docs/api/examples.md" "$dst/examples.md"

  # OpenAPI spec lives at the api section root for starlight-openapi to
  # pick up (configured in astro.config.mjs).
  cp "$src/openapi.yaml" "$dst/openapi.yaml"

  echo "  api: 9 narratives + openapi.yaml staged at $dst"
}

main() {
  echo "→ assembling content from codex cache..."
  copy_api_source
  echo "→ done."
}

main "$@"
