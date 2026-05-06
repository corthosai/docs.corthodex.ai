# docs.corthodex.ai

Public documentation site for the Corthodex education + employment
data API, served at <https://docs.corthodex.ai>.

This repo is a **publish/aggregation layer** — it has zero authored API
content of its own. Site chrome (theme, navigation, landing page,
troubleshooting), the build agent that pulls codex content, and the AWS
Amplify config live here. Everything else flows in from
[`api.corthodex.ai`](https://github.com/corthosai/api.corthodex.ai)
via codex sync.

## Local dev

```bash
npm install
npm run dev                                   # http://localhost:4321
```

The site builds from the API content committed at `src/content/docs/api/`.

## Refreshing API content (when upstream api repo changes)

```bash
fractary-codex sync --direction from-codex   # pull upstream content into cache
npm run build:content                         # restage cache → src/content/docs/api/
git add src/content/docs/api/                 # commit the refreshed content
git commit -m "chore: refresh API content from codex"
git push
```

`fractary-codex sync` is **never** run by CI or Amplify — only by
developers locally. Amplify builds whatever is committed at
`src/content/docs/api/`.

## Sibling sites

Same architecture, different domain:

- [`docs.corthography.ai`](https://github.com/corthosai/docs.corthography.ai) — documents the Corthography Press service (api / press / client)

This is the site bootstrap template — `scripts/build-content.sh`,
`astro.config.mjs`, the ink palette, and the `.fractary/config.yaml`
shape were cloned from there.
