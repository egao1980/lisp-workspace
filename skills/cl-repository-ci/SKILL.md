---
name: cl-repository-ci
description: >-
  cl-repository CI/publish: packaging + CI extras = .asd :properties (:cl-repo);
  canned GH Actions (test-system.yml / publish-source.yml / ci); first-party
  publish from owning repo; third-party via cl-stack-systems; natives via
  reusable workflow. Use before GitHub Actions, qlot migration, OCI publish,
  or fork-vs-import decisions.
---

# cl-repository CI & publish

Policy sources: [MEMORY.md](../../MEMORY.md) · [REQUIREMENTS.md](../../docs/REQUIREMENTS.md) ·
[`cl-stack-systems`](https://github.com/egao1980/cl-stack-systems) · packager
`ghcr.io/egao1980/cl-repository/cl-repository-packager`.

**Convention over scripts.** Packaging **and** CI extras live in the **`.asd`**
(`:properties (:cl-repo …)` + normal ASDF fields). Canned GH Actions in
`egao1980/cl-repository` read them. Do **not** copy `ci-install.lisp` /
`ci-test.lisp` / `publish-checkout.lisp`. Hooks in `scripts/ci/` only when
the canned path cannot express the step.

Upstream pattern: [cl-repository examples/06-asd-embedded-config](https://github.com/egao1980/cl-repository/tree/main/examples/06-asd-embedded-config).

## Decision tree

```text
Need to ship a Lisp system to ghcr.io/egao1980/cl-systems?
│
├─ Packaging truth = .asd (:version :depends-on :properties :cl-repo …)
│     auto-package-spec is enough — no custom package-spec
│
├─ Who owns the GitHub repo?
│  ├─ egao1980/<first-party> (http-protocol, backends, cl-stack-*, …)
│  │     → publish FROM THAT REPO (GHCR write ACL follows the owner)
│  │        source-only: publish-source.yml reusable (thin wrapper OK)
│  │        natives: reusable native publish workflow + .asd :cl-repo overlays
│  └─ third-party / unmodified upstream
│        → cl-stack-systems imports/<name>/qlfile + shared publish.yml
│
└─ Only consume deps in CI?
   → setup-client + canned ci action / test-system.yml (no copied Lisp)
```

| Kind | Packaging metadata | Publish runner |
|------|--------------------|----------------|
| First-party **source-only** | your `.asd` | **owning repo** `publish-source.yml` |
| First-party **with natives** | `.asd` `:cl-repo` overlays | owning repo + reusable native workflow |
| Unmodified third-party | upstream `.asd` | cl-stack-systems `imports/` + shared publish |
| Patched third-party (fork) | fork `.asd` | cl-stack-systems pin → `egao1980/<fork>` **or** publish from the fork repo |

**Do not** publish owned first-party packages via `cl-stack-systems` — its token gets `permission_denied: write_package` on packages linked to the owning repo.

**Fork ↔ import exclusivity:** never import `fukamachi/X` while keeping a workspace fork of `X`.

## Pins (current)

| Piece | Value |
|-------|--------|
| Client image | `ghcr.io/egao1980/cl-repository/cl-repository-client` — CI uses **`CL_REPOSITORY_CLIENT_VERSION: latest`** (resolve system-name `:latest` anchor → annotated semver → `oras pull`) |
| Packager image | `ghcr.io/egao1980/cl-repository/cl-repository-packager:**0.16.0**` |
| Registry / namespace | `ghcr.io` / `egao1980/cl-systems` |
| oras (Actions) | `1.2.3` |
| SBCL (typical CI) | `2.6.7` via Roswell (`sbcl-bin`) |
| Reusable workflows | `egao1980/cl-repository/.github/workflows/{test-system,publish-source}.yml@main` |

**Verified (2026-08-25):** `publish-source.yml@main` republished `ghcr.io/egao1980/cl-systems/schema-protocol:0.1.0` from `egao1980/schema-protocol` #4. Test-system.yml green on ubuntu/macos/windows.

**GitHub `uses:` cannot interpolate.** Do not write `uses: …@${{ inputs.anything }}` or `@${{ github.action_ref }}` — parse-time `Unrecognized named-value`. Composite actions in the reusable workflows are hardcoded `@main` (cl-repository#25). Pin a SHA only by editing those `uses:` lines.

**`run.lisp` is one `ros -l`.** The reader interned `cl-repository-packager/…:` and `cl-oci-client/…:` before `%ensure-packager` and killed install+test (schema-protocol canary). Those symbols live in `publish.lisp`, loaded after the packager (cl-repository#26). Do not add package-qualified packager/oci-client forms to `run.lisp`.

Bump client when `ensure-*` APIs change; packager independently when packaging changes.

## Packaging contract = `.asd` (enough)

`cl-repository-packager/asdf-plugin:auto-package-spec` merges:

| From ASDF | Fields |
|-----------|--------|
| Standard | `:version` `:description` `:author` `:license` `:depends-on` `:source-directory` |
| `:properties (:cl-repo …)` | `:provides` `:cffi-libraries` `:overlays` `:ci` |

### Source-only (typical first-party)

Honest `.asd` is enough — `:cl-repo` optional unless you need extra `:provides`:

```lisp
(defsystem "cl-stack-http"
  :version "0.1.7"
  :description "…"
  :author "egao1980"
  :license "MIT"
  :depends-on ("http-protocol" "cl-stack-pathlib" …)
  ;; optional:
  ;; :properties (:cl-repo (:provides ("cl-stack-http")))
  …)
```

Do **not** duplicate depends-on / version / description in a publish script.

### With natives

Declare overlays in the same place (see `cl-stack-ssl.asd`, `event-backend-libuv.asd`):

```lisp
:properties
(:cl-repo
 (:cffi-libraries ("libuv")
  :provides ("event-backend-libuv")
  :overlays ((:platform (:os "linux" :arch "amd64")
              :layers ((:role "native-library" :files (…))
                       (:role "cffi-grovel-output" :files (…))))
             …)))
```

### Publish: first-party source-only → owning repo

Tag/release on `egao1980/<repo>`, then:

```bash
gh workflow run publish-checkout.yml -R egao1980/http-protocol -f version=0.3.0
# (or omit -f version to use .asd :version)
```

`auto-package-spec` from the checkout `.asd`. Consumer workflow is a thin
wrapper around `egao1980/cl-repository/.github/workflows/publish-source.yml@main`
— do **not** add `scripts/publish-checkout.lisp`.

### Publish: third-party → cl-stack-systems

`imports/<name>/qlfile` is only a **source locator** (where to clone):

```bash
cd cl-stack-systems
./scripts/add-import.sh alexandria/alexandria v1.4
gh workflow run publish.yml -R egao1980/cl-stack-systems -f import=alexandria
```

Optional `imports/<name>/system` when ASDF name ≠ directory (e.g. `cl+ssl`).

### Native publish

Reuse `egao1980/cl-repository/.github/workflows/publish-native-package.yml`.
It must still honor `.asd` `:cl-repo` overlays — not a parallel YAML-only inventory.
Grovel at overlay build time; consumers load without a C toolchain.
Resolve natives via `cffi:*foreign-library-directories*` + absolute preload —
**never** require `LD_LIBRARY_PATH` / `DYLD_LIBRARY_PATH` for correctness.

### Anti-patterns (publish)

- ❌ `make-instance 'package-spec` (or equivalent) in repo scripts — use `.asd` + `auto-package-spec`
- ❌ New `scripts/publish-source.lisp` / copy-pasted source `publish-oci.yml`
- ❌ Divergent depends-on/version between `.asd` and a publish helper
- ❌ Packager tag `0.8.0` on new work
- ❌ Import upstream **and** keep a workspace fork of that upstream
## CI install / test (consumer repos)

New first-party repos: **canned cl-repo CI from day one**. No `qlfile`. No copied Lisp scripts.

### Non-negotiable

1. `actions/checkout` → **only** the repo under test.
2. Bootstrap **`cl-repository-client` from OCI** via `egao1980/cl-repository/.github/actions/setup-client@main` (default `version: latest`). **No QL bootstrap.** Do **not** git-checkout `cl-repository` in consumer CI.
3. Project deps from `ghcr.io/egao1980/cl-systems` via canned `ci` (`phase: install`) → `ensure-system-dependencies` (walks SUT `.asd` + `/tests`).
4. **Do not** add `scripts/ci-install.lisp` / `ci-test.lisp` / `publish-checkout.lisp`. Put extras in `.asd` `:cl-repo :ci`. Hooks only in `scripts/ci/`.

### Workflow shape (canonical)

```yaml
jobs:
  test:
    uses: egao1980/cl-repository/.github/workflows/test-system.yml@main
```

Compose when you need a custom matrix (ABCL/ECL, extra env):

```yaml
permissions:
  contents: read
  packages: read
steps:
  - uses: actions/checkout@v5
  - uses: egao1980/cl-repository/.github/actions/setup-client@main
  - uses: egao1980/cl-repository/.github/actions/setup-roswell@main
  - uses: egao1980/cl-repository/.github/actions/ci@main
    with: { phase: install }
  - uses: egao1980/cl-repository/.github/actions/ci@main
    with: { phase: test }
```

Call `setup-client` in **every job** that needs the client (runner disks are not shared).

Default matrix (reusable workflow): `ubuntu-latest`, `macos-latest`, `windows-latest`. Override with `os-json`.

### `.asd` `:ci` (not copied scripts)

```lisp
:properties
(:cl-repo
 (:ci (:with ("dissect" "cl-stack-ssl")     ; not in :depends-on
       :sources (("rove" :ql))              ; optional policy pins
       :also-tests t
       :load-before-test ("cl-stack-ssl")
       :record-versions (("cl-stack-ssl" . "CL_STACK_SSL_VERSION")))))
```

Honest `:depends-on` + `foo/tests` is enough for most packages. `:ci` is ignored by `auto-package-spec`.

**Phase 1 (install):** `ensure-system-dependencies` — no ASDF-load of SUT/overlays.  
**Phase 2 (test):** `configure-asdf-source-registry` + `load-system-init-files` → `asdf:test-system`.

### Hooks (only if `:ci` cannot express it)

If present, loaded after the client:

`scripts/ci/pre-install.lisp` `post-install.lisp` `pre-test.lisp` `post-test.lisp` `pre-publish.lisp` `post-publish.lisp`

`pre-install` may push onto `cl-repository-ci-lib:*extra-with*` (e.g. event backend from `HTTP_ASYNC_EVENT_BACKEND`). Existing copied `ci-*.lisp` is migrate-away, not gold.

### CI anti-patterns

- ❌ New `scripts/ci-install.lisp` / `ci-test.lisp` / `publish-checkout.lisp`  
- ❌ Second `actions/checkout` of `cl-repository` / sibling deps  
- ❌ Copy-pasted `oras pull` + QL client-bootstrap (use `setup-client`)  
- ❌ Hand-maintained `ci-fetch` / `ci-ql` inventories  
- ❌ qlot/`qlfile` as the primary CI install for new packages  
- ❌ Hand `oras pull` of natives + `LD_LIBRARY_PATH` as the *dep install* path  
- ❌ Sibling path hacks in `CL_SOURCE_REGISTRY` for deps  

## Gold vs migrate-away examples

| Good | Migrate away |
|------|----------------|
| `.asd` drives `auto-package-spec` | Hardcoded `package-spec` in `publish-source.lisp` |
| First-party publish from owning repo | First-party via cl-stack-systems import |
| cl-stack-systems = third-party imports only | Hand-written `package-spec` / divergent publish scripts |
| `:cl-repo` overlays in `.asd` (ssl/libuv) | Overlay lists only in workflow YAML / Lisp |
| cl-stack-http / winhttp — OCI client CI | qlot as the install story for new packages |
| canned `test-system.yml` / `ci` action | Copied `scripts/ci-install.lisp` per repo |

Tag releases (`v*`) matching the import pin / OCI tag. Update
[`cl-stack/docs/QUICKSTART.md`](https://github.com/egao1980/cl-stack/blob/main/docs/QUICKSTART.md)
pins in the **same** change set that publishes a user-facing feature.

## Checklist (agent)

Before adding CI or publish to a package:

- [ ] `.asd` has honest `:version` / `:depends-on` / `:cl-repo` (overlays if native) — **enough for package-spec**  
- [ ] First-party source-only? → owning-repo `publish-source.yml` (not cl-stack-systems, not `publish-checkout.lisp`)  
- [ ] Third-party? → cl-stack-systems `imports/` + shared publish  
- [ ] Natives? → reusable native workflow in the **owning** repo, same `.asd`  
- [ ] Consumer CI: self-only checkout + `test-system.yml` or `setup-client` + `ci` — **no copied Lisp**  
- [ ] CI extras in `.asd` `:cl-repo :ci` (or `scripts/ci/` hook)  
- [ ] Packager **0.16.0**; QUICKSTART pins updated if user-facing  
