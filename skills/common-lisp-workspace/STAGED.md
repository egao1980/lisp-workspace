## Pending

### 2026-08-03 — new projects: cl-repo CI, not qlot

- **Source:** user correction during ws-protocol #35; MEMORY already said cl-repository for project deps, but new repo shipped `qlfile` + qlot CI.
- **Proposed change:** In `SKILL.md` / deps section, state explicitly: **new first-party systems ship `scripts/ci-install.lisp` + cl-repository CI from day one**; do not introduce `qlfile` as the install story. Qlot = legacy on unmigrated checkouts only. QL fallback only via `ci-install` for unpublished `cl-systems` imports.
- **Action:** apply on next `/review-skill-improvements`.
