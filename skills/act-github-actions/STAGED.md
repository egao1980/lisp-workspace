# Staged improvements

## Pending

### 2026-08-04 — Node 24 JS Actions majors

- **Source:** Node 20 deprecation warnings on GH Actions (checkout@v4, setup-oras@v1, artifact v4).
- **Proposed change:** Default pins: `actions/checkout@v5`, `oras-project/setup-oras@v2`, `actions/upload-artifact@v6`, `actions/download-artifact@v7`. Prefer bumping action majors that declare `runs.using: node24` over only setting `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24` (still warns). `devcontainers/action@v1` still node20 upstream — leave until they ship node24.
- **Why:** Runner already forces Node 24; warnings persist until action manifests declare node24.
