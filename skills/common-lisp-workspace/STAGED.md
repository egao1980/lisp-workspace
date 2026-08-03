## Pending

### 2026-08-03 — new projects: cl-repo CI, not qlot

- **Source:** user correction during ws-protocol #35; MEMORY already said cl-repository for project deps, but new repo shipped `qlfile` + qlot CI.
- **Proposed change:** In `SKILL.md` / deps section, state explicitly: **new first-party systems ship `scripts/ci-install.lisp` + cl-repository CI from day one**; do not introduce `qlfile` as the install story. Qlot = legacy on unmigrated checkouts only. QL fallback only via `ci-install` for unpublished `cl-systems` imports.
- **Status:** applied 2026-08-03 (SKILL Deps bullet + no-sibling CI rule).

### 2026-08-03 — no sibling checkouts for project deps

- **Source:** user: “no sibling - cl-repository - add to rules”.
- **Proposed change:** Rules/MEMORY/REQUIREMENTS: CI may checkout only the project under test + `egao1980/cl-repository`; never sibling-checkout other first-party deps for ASDF.
- **Status:** applied 2026-08-03; **superseded** same day — bootstrap client from OCI, no git checkout of cl-repository either.

### 2026-08-03 — cl-repository-client from GHCR OCI

- **Source:** user: “cl-repository is also available from GHCR OCI repo”.
- **Proposed change:** Prefer `oras pull ghcr.io/egao1980/cl-repository/cl-repository-client:<ver>` for consumer CI bootstrap; git checkout only when developing cl-repository. Document packager image too.
- **Status:** applied 2026-08-03 (MEMORY, mdc, REQUIREMENTS, AGENTS, SKILL + winhttp CI).
