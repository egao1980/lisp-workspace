# Staged improvements for cl-repository-ci

## Pending

## Applied

- [2026-10-22] Client loads without the checkout (09-06) → SKILL resolution traps. Verified: `run.lisp` `%load-client` uses `CL_REPOSITORY_DEST` only, `setup-lisp` no longer exports `CL_SOURCE_REGISTRY`; `http-backend-dexador` 0.1.5 has chipz in `:ci :with`; `packager-version` defaults `latest`.
- [2026-10-22] Composed CI = `setup-lisp` (08-29) → SKILL + reference.md compose example (was `setup-client` + `setup-roswell`).
- [2026-10-22] `setup-lisp` caches the client on resolved semver (08-29) → SKILL. Verified in `setup-lisp/action.yml` (`resolve-client.sh` before `actions/cache`).
- [2026-10-22] Ubuntu = `ci-base` job container, not a Docker action (08-29) → SKILL. Verified in `test-system.yml` / `publish-native-package.yml`.
- [2026-10-22] `publish.lisp` read-time symbols (08-27) → SKILL, generalized to "every packager a caller may pin" (default is now `latest`, not 0.16.0).
- [2026-10-22] Slash secondaries are not GHCR repos (08-27) → SKILL. Verified `cl-oci/system-names:oci-package-name`; plus cl-repository#50 (SUT secondaries in `:with` are local roots).
- [2026-10-22] Consumer heap, part 2 (08-27) → SKILL: client gunzip is still buffered `chipz:decompress`; `llm-backend-vllm-cpp/scripts/ci/pre-install.lisp` stream override is the live workaround.
- [2026-10-22] Native publish heap (08-27) → reference.md. Verified `sbcl-dynamic-space-mb` input (default 8192) and the continuation-comment note in the workflow.
- [2026-10-22] `:sources` does not add install roots (08-27) → SKILL. Verified `ensure-system-dependencies`: `:sources` only forwarded to `ensure-systems`.
- [2026-10-22] Default branches / qlfile tags (08-04) → reference.md (`cl-idna` / `cl-mime` / `quri` / `rove` = `master`, checked via `gh api`).
- [2026-10-22] Node 24 action pins (08-04) → SKILL pins row; added `cache@v5` / `setup-java@v5` (v4 of both is node20; checked `action.yml`).
- [2026-10-22] Multi-impl ECL / CCL / ABCL rows (08-07) → reference.md fragment from `crypto-protocol` (≈20 repos carry it).
- 2026-09-01 native publish via `setup-lisp` + `ensure-systems` — already in SKILL/reference/MEMORY.
- 2026-08-26 no `:sources (("rove" :ql))` — already in SKILL rule 5.
- 2026-08-07 CFFI natives auto-load — already in SKILL rule 6 + MEMORY.
- 2026-08-04 ci-install = client dep install; load client before `cl-repo:` forms — both superseded by canned `run.lisp` (SKILL `run.lisp` rule).
- 2026-08-05 GHCR write ACL — in SKILL/MEMORY; follow-up done (`cl-stack-systems/imports/` holds no first-party dirs).
- 2026-08-25 `publish-source.yml` verified + GH `uses:`/read traps — SKILL/MEMORY/REQUIREMENTS/LESSONS.
- 2026-08-25 canned GH Actions, not copied CI Lisp — SKILL/MEMORY/REQUIREMENTS.

## Rejected

- [2026-10-22] Consumer heap, part 1 (08-27) "`:with` must name registry packages, not `foo/bar`" — stale: client maps slash → primary; SUT secondaries are local roots (#50).
- [2026-10-22] Native callers pin packager 0.10.0 + import races (08-04) — pin superseded by `latest`; races handled by `publish-import.lisp` retry/warn.
- [2026-10-22] Import publish keeps `:feature` deps (08-14) — landed (cl-stack-systems#31) with an in-code comment; setup-client `winhttp` hardcode is gone. No agent-facing rule left.
- [2026-10-22] setup-client Windows CRLF / cygpath / `;` registry (08-14) — implemented and commented in `setup-client.sh`; `;` part stale (no `CL_SOURCE_REGISTRY` export). Consumer-facing bit (`shell: bash`) is in SKILL.
- [2026-10-22] `setup-roswell` reuses test.yml steps (08-14) — superseded by `setup-lisp`.
- [2026-10-22] README Publish blurb template (08-04) — per-repo publish scripts are gone; nothing to template.
- 2026-09-01 native publish must pin packager-tag — workaround; fixed the load path instead.
