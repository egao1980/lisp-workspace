## Pending

### 2026-08-07 — CFFI natives auto-load on ASDF load
- **Source:** user standing instruction (cl-stack-icu).
- **Proposed change:** Document that first-party native/CFFI packages must `load-foreign-library` at system load (`eval-when (:load-toplevel :execute)`); consumers must not need `load-*` / `ensure-*`. Absolute preload preferred; no LD_LIBRARY_PATH.


- [2026-08-04] Do not silently close PRs; fix conflicts and merge when asked
  - Source: user correction after agent closed conflicting PRs (#16, #74) instead of resolving
  - Proposed change: under Git — never `gh pr close` for conflict/supersede without explicit user ask; rebase/fix and merge when the user wants pending PRs landed.


- [2026-08-04] Never delete branches that head open upstream PRs
  - Source: user correction after `gh pr merge --delete-branch` risked fukamachi/rove#76 head
  - Proposed change: under Git — do not pass `--delete-branch` when merging a fork PR if that branch is (or may be) the head of an open PR against upstream; wait until upstream merges/abandons.


### 2026-08-04 — living QUICKSTART (source: agent / user)

When shipping a published stack feature, update `egao1980/cl-stack` `docs/QUICKSTART.md`
(pin table + minimal snippets) in the same change set as the OCI publish. Cookbooks stay
deep recipes; QUICKSTART stays the 5-minute path. Link: https://github.com/egao1980/cl-stack/blob/main/docs/QUICKSTART.md


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

## Pending

- 2026-08-04 | http-parity | Async sync-SEND / await requires binding `event-protocol:*event-backend*`, `*event-loop*`, and `http-backend-async:*event-backend-maker*` (mirror `with-async-test`). Maker alone is insufficient for promise `await` on the same loop as `send-async`.

## Pending

- **2026-08-05** (push-merge-publish): First-party OCI publish = owning-repo `publish-checkout.yml` (packager **0.12.0**). Load packager *before* project ASDF tree; force `:provides` to `PKG_SYSTEM` only. Never `sed … > same-file` when propagating templates. `cl-stack-systems` = third-party imports only; use `delete-package.yml` to reclaim GHCR ACL after mistaken first-party publishes.
