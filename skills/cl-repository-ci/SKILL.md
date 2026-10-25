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

**Convention over scripts.** The `.asd` is the project file. A directory with
`qlfile` is a project. Locally and in CI the interface is the CLI:

```sh
cl-repo sync
cl-repo test
cl-repo publish
cl-repo add-overlay          # edits the .asd only. bare = this machine's os+arch
cl-repo publish --overlay    # one overlay. a name selects it
cl-repo grovel
cl-repo sync --overlay cuda  # named overlays stay out until asked
```

Defaults are `https://ghcr.io` / `egao1980/cl-systems`, source `:oci`. No
`CL_SOURCE_REGISTRY`, no `ql:quickload`, no copied install script. A missing
`:depends-on` or qlfile name is published, then installed. Do **not** copy
`ci-install.lisp` / `ci-test.lisp` / `publish-checkout.lisp`. Hooks in
`scripts/ci/` only when the canned path cannot express the step.

`add-overlay` keys are the parts you pass (`--os`, `--arch`, `--lisp`). A
lisp-only overlay is not the universal manifest. `sync` stacks every matching
unnamed overlay, generic first. Same specificity installs both, name order.
`:ci :env` selects install and pre-test systems from an environment variable.

New system shape (no `:cl-repo` unless overlays; `:oci` implied) → skill **asdf**.

Upstream: [cl-repository examples/06-asd-embedded-config](https://github.com/egao1980/cl-repository/tree/main/examples/06-asd-embedded-config).

## Decision tree

```text
Need to ship a Lisp system to ghcr.io/egao1980/cl-systems?
│
├─ New first-party protocol / backend / parity?
│     Create egao1980/<name> NOW (`create-first-party-repo.sh`).
│     Workspace-only trees are not a system — no repo ⇒ never on GHCR.
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
| Actions (node24) | `checkout@v5` `setup-oras@v2` `cache@v5` `upload-artifact@v6` `download-artifact@v7` `setup-java@v5` — bump majors, not `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24` |

**Verified (2026-08-25):** `publish-source.yml@main` republished `schema-protocol:0.1.0`.

**GitHub `uses:` cannot interpolate** (`@${{ inputs.* }}` / `@${{ github.action_ref }}`). Composite actions are hardcoded `@main` (cl-repository#25).
**`run.lisp` is one `ros -l`.** Do not add `cl-repository-packager/…:` or `cl-oci-client/…:` tokens there (cl-repository#26).
**`publish.lisp` is `LOAD`ed (read) too:** colon-qualify only symbols in every packager a caller may pin (`packager-version`, default `latest`); newer helpers → `find-symbol` + fallback.

## Consumer CI (non-negotiable)

1. `actions/checkout` → **only** the repo under test.
2. Bootstrap client from OCI (`setup-lisp` / `setup-client@main`, `version: latest`). **No QL bootstrap.** Do **not** git-checkout `cl-repository`.
3. Deps from `ghcr.io/egao1980/cl-systems`. The canned `ci` install phase is `cl-repo sync`. Test phase is `cl-repo test`.
4. No copied `ci-*.lisp`. Extras in `.asd` `:cl-repo :ci`. Hooks only in `scripts/ci/`.
5. No `:sources (("foo" :ql))` — publish `foo` to `cl-systems`, then drop the pin.
6. Natives: grovel at overlay build; resolve via `cffi:*foreign-library-directories*` + absolute preload — **never** `LD_LIBRARY_PATH` / `DYLD_LIBRARY_PATH`. Auto-load on ASDF load.
7. **Never pack `.cl-repository`** into a source layer (sse-protocol:0.1.0 was a 10MB broken layer).

Canonical workflow: `uses: egao1980/cl-repository/.github/workflows/test-system.yml@main`. Compose YAML + `:ci` examples → [reference.md](reference.md).

Phase 1 = `cl-repo sync`. Phase 2 = `cl-repo test` (`asdf:test-system`; a system with no test-op exits 0). Native jobs are `cl-repo grovel` and `cl-repo publish --overlay`.

`setup-lisp`: Ubuntu runs in the `ci-base` **job container** (ros/SBCL/client baked in; `shell: bash` — container default is `sh`). Not a Docker *action* — its SBCL does not survive into later steps. Job containers are Linux-only: macOS/Windows install and `actions/cache` Roswell + the client tree keyed on the **resolved semver** (never `:latest`). Custom jobs use `setup-lisp`, not `setup-client` + `setup-roswell`.

**Resolution traps:**

- Client loads from `CL_REPOSITORY_DEST` **alone**; the checkout joins the registry after (`clear-checkout-systems`). Hooks / local scripts must not load the client with the checkout on the registry — a checkout in the client graph shadows the bundled copy (`http-encoding-chipz` → `compression-protocol` not found). Optional client-graph deps go in `:ci :with`, not `:depends-on` (`http-backend-dexador` → chipz).
- `:ci :with` adds install **roots**. `:sources` only pins the origin of names already in the set — a SAT-missed transitive (`dbi` → `dbd-postgres` → `cl-postgres`) belongs in `:with`.
- `foo/bar` is not a GHCR repo: the client maps it to primary `foo` (`+` → `-plus-`); publish keeps slash provides as metadata. `:with ("foo/bar")` installs `foo`; a secondary of the SUT is a local root, never installed. Do not remap in consumer scripts.
- Layer extract streams gzip (`chipz` Gray streams; ABCL still buffers). Do not redefine `extract-layer` in a pre-install hook. Native publish heap → [reference.md](reference.md).

Extra impls (`test-abcl` / `test-ecl` / `test-ccl` beside `test-system.yml`): [reference.md](reference.md) · [`cl-stack/docs/multi-impl.md`](https://github.com/egao1980/cl-stack/blob/main/docs/multi-impl.md).

**Reproduce CI locally:** `cl-repo test` in the project directory. `cl-repo sync --locked` installs `cl-repo.lock`. Do not export `CL_SOURCE_REGISTRY` or bootstrap Quicklisp.
`cl-repo.lock` / `.cl-repository/` are local artifacts — never commit them (`create-first-party-repo.sh` seeds `.gitignore`).

Update [`cl-stack/docs/QUICKSTART.md`](https://github.com/egao1980/cl-stack/blob/main/docs/QUICKSTART.md) pins in the **same** change set that publishes a user-facing feature.

After a green PR: merge then trigger publish — skill **[pr-merge-publish](../pr-merge-publish/SKILL.md)**. No human review wait.

## Checklist

- [ ] `.asd` honest `:version` / `:depends-on` / `:cl-repo` (overlays if native)
- [ ] First-party protocol/backend/parity → `egao1980/<name>` exists (never workspace-only)
- [ ] First-party source-only → owning-repo `publish-source.yml`
- [ ] Third-party → cl-stack-systems `imports/`
- [ ] Natives → reusable native workflow in the **owning** repo
- [ ] Consumer CI: self-only checkout + canned workflow — **no copied Lisp**
- [ ] Packager **latest**; QUICKSTART updated if user-facing
