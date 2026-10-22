# Staged improvements for common-lisp-workspace

## Pending

## Applied

- 2026-08-03 new projects use cl-repo CI, not qlot — SKILL "Qlot = legacy"; its "ship `scripts/ci-install.lisp`" wording is superseded by canned CI (cl-repository-ci).
- 2026-08-03 no sibling checkouts — MEMORY / `memory/ci.md`; superseded same day by client-from-OCI.
- 2026-08-03 cl-repository-client from GHCR OCI — MEMORY / REQUIREMENTS / cl-repository-ci.

## Rejected

Router skill: these already live in the owning doc; repeating them here is duplication.

- [2026-10-22] CFFI natives auto-load on ASDF load — `common-lisp-workspace.mdc`, `memory/ci.md`, cl-repository-ci rule 6.
- [2026-10-22] Do not silently close PRs — pr-merge-publish (step 1 + "when to close") and `pr-merge-publish.mdc`.
- [2026-10-22] Never `--delete-branch` an open upstream PR head — pr-merge-publish (rove#76 note) and `.mdc`.
- [2026-10-22] Living QUICKSTART — MEMORY, cl-repository-ci, pr-merge-publish.
- [2026-10-22] http-parity async binds backend + loop + maker — accurate, but documented in `http-parity` `with-parity` docstring and MEMORY "HTTP client" line.
- [2026-10-22] 2026-08-05 publish-checkout with packager 0.12.0 / force `:provides` to `PKG_SYSTEM` — stale (packager `latest`; canned `publish.lisp` keeps provides). ACL / cl-stack-systems parts are in cl-repository-ci.
