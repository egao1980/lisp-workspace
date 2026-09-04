---
name: cl-repository-ci
description: >-
  cl-repo CI/publish: .asd :cl-repo, canned test-system.yml / publish-source.yml,
  owning-repo first-party, cl-stack-systems third-party. Use before GH Actions,
  OCI publish, or fork-vs-import.
---

# cl-repository CI & publish

Policy: [MEMORY.md](../../MEMORY.md) · [memory/ci.md](../../memory/ci.md) · [REQUIREMENTS.md](../../docs/REQUIREMENTS.md).
Examples / YAML / `.asd` snippets: [reference.md](reference.md).

**Convention over scripts.** Packaging **and** CI extras live in the **`.asd`**
(`:properties (:cl-repo …)` + ASDF fields). Canned GH Actions in
`egao1980/cl-repository` read them. Do **not** copy `ci-install.lisp` /
`ci-test.lisp` / `publish-checkout.lisp`. Hooks in `scripts/ci/` only when
canned cannot express the step.

Upstream: [cl-repository examples/06-asd-embedded-config](https://github.com/egao1980/cl-repository/tree/main/examples/06-asd-embedded-config).

## Decision tree

```text
Need to ship a Lisp system to ghcr.io/egao1980/cl-systems?
│
├─ Packaging truth = .asd (:version :depends-on :properties :cl-repo …)
│     auto-package-spec is enough — no custom package-spec
│
├─ Who owns the GitHub repo?
│  ├─ egao1980/<first-party> → publish FROM THAT REPO
│  │     source-only: publish-source.yml
│  │     natives: reusable native publish + .asd :cl-repo overlays
│  └─ third-party / unmodified → cl-stack-systems imports/<name>/qlfile
│
└─ Only consume deps in CI?
   → setup-lisp / setup-client + canned ci / test-system.yml (no copied Lisp)
```

| Kind | Packaging metadata | Publish runner |
|------|--------------------|----------------|
| First-party **source-only** | your `.asd` | **owning repo** `publish-source.yml` |
| First-party **with natives** | `.asd` `:cl-repo` overlays | owning repo + reusable native workflow |
| Unmodified third-party | upstream `.asd` | cl-stack-systems `imports/` + shared publish |
| Patched third-party (fork) | fork `.asd` | cl-stack-systems pin → `egao1980/<fork>` **or** publish from the fork |

**Do not** publish owned first-party packages via `cl-stack-systems` (GHCR write ACL follows the owner).
**Fork ↔ import exclusivity:** never import `fukamachi/X` while keeping a workspace fork of `X`.

## Pins (current)

| Piece | Value |
|-------|--------|
| Client image | `ghcr.io/egao1980/cl-repository/cl-repository-client` — CI **`CL_REPOSITORY_CLIENT_VERSION: latest`** |
| Packager image | `ghcr.io/egao1980/cl-repository/cl-repository-packager:latest` (`v0.18.0`) |
| Registry / namespace | `ghcr.io` / `egao1980/cl-systems` |
| oras (Actions) | `1.2.3` |
| SBCL (typical CI) | `2.6.7` via Roswell (`sbcl-bin`) |
| Reusable workflows | `egao1980/cl-repository/.github/workflows/{test-system,publish-source}.yml@main` |
| cffi | `ghcr.io/egao1980/cl-systems/cffi:0.24.1` (+ `cffi-grovel:0.24.1`; upstream asd has no `:version`) |
| log4cl | `ghcr.io/egao1980/cl-systems/log4cl:1.1.4` (sharplispers `fe3da517`; `v1.1.2` package-locks on SBCL 2.6.7) |
| rove | `ghcr.io/egao1980/cl-systems/rove` (`egao1980/rove`); `:depends-on ("rove")` on `/tests` — no `:ci :sources` |

**Verified (2026-08-25):** `publish-source.yml@main` republished `schema-protocol:0.1.0`.

**GitHub `uses:` cannot interpolate** (`@${{ inputs.* }}` / `@${{ github.action_ref }}`). Composite actions are hardcoded `@main` (cl-repository#25).
**`run.lisp` is one `ros -l`.** Do not add `cl-repository-packager/…:` or `cl-oci-client/…:` tokens there (cl-repository#26).

## Consumer CI (non-negotiable)

1. `actions/checkout` → **only** the repo under test.
2. Bootstrap client from OCI (`setup-lisp` / `setup-client@main`, `version: latest`). **No QL bootstrap.** Do **not** git-checkout `cl-repository`.
3. Deps from `ghcr.io/egao1980/cl-systems` via canned `ci` (`phase: install`) → `ensure-system-dependencies`.
4. No copied `ci-*.lisp`. Extras in `.asd` `:cl-repo :ci`. Hooks only in `scripts/ci/`.
5. No `:sources (("foo" :ql))` — publish `foo` to `cl-systems`, then drop the pin.
6. Natives: grovel at overlay build; resolve via `cffi:*foreign-library-directories*` + absolute preload — **never** `LD_LIBRARY_PATH` / `DYLD_LIBRARY_PATH`. Auto-load on ASDF load.
7. **Never pack `.cl-repository`** into a source layer (sse-protocol:0.1.0 was a 10MB broken layer).

Canonical workflow: `uses: egao1980/cl-repository/.github/workflows/test-system.yml@main`. Compose YAML + `:ci` examples → [reference.md](reference.md).

Phase 1 = install (no ASDF-load of overlays). Phase 2 = test (`configure-asdf-source-registry` + `load-system-init-files` → `asdf:test-system`). Client order = OCI then QL.

Update [`cl-stack/docs/QUICKSTART.md`](https://github.com/egao1980/cl-stack/blob/main/docs/QUICKSTART.md) pins in the **same** change set that publishes a user-facing feature.

After a green PR: merge then trigger publish — skill **[pr-merge-publish](../pr-merge-publish/SKILL.md)**. No human review wait.

## Checklist

- [ ] `.asd` honest `:version` / `:depends-on` / `:cl-repo` (overlays if native)
- [ ] First-party source-only → owning-repo `publish-source.yml`
- [ ] Third-party → cl-stack-systems `imports/`
- [ ] Natives → reusable native workflow in the **owning** repo
- [ ] Consumer CI: self-only checkout + canned workflow — **no copied Lisp**
- [ ] Packager **latest**; QUICKSTART updated if user-facing
