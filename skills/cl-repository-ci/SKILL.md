---
name: cl-repository-ci
description: >-
  cl-repository CI/publish: packaging = .asd :properties (:cl-repo) + auto-package-spec;
  first-party publish from owning repo; third-party via cl-stack-systems; natives via
  reusable workflow; OCI-bootstrap client + ci-install/ci-test. Use before GitHub Actions,
  qlot migration, OCI publish, or fork-vs-import decisions.
---

# cl-repository CI & publish

Policy sources: [MEMORY.md](../../MEMORY.md) · [REQUIREMENTS.md](../../docs/REQUIREMENTS.md) ·
[`cl-stack-systems`](https://github.com/egao1980/cl-stack-systems) · packager
`ghcr.io/egao1980/cl-repository/cl-repository-packager`.

**Convention over scripts.** Packaging metadata lives in the **`.asd`**
(`:properties (:cl-repo …)` + normal ASDF fields). Shared CI/publish tooling
reads it via `auto-package-spec`. Do **not** hand-write `package-spec` in
per-repo Lisp, and do **not** copy-paste `publish-source.lisp`.

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
│  │        source-only: publish-checkout.yml (or thin equivalent)
│  │        natives: reusable native publish workflow + .asd :cl-repo overlays
│  └─ third-party / unmodified upstream
│        → cl-stack-systems imports/<name>/qlfile + shared publish.yml
│
└─ Only consume deps in CI?
   → oras-bootstrap cl-repository-client + scripts/ci-install.lisp + ci-test.lisp
```

| Kind | Packaging metadata | Publish runner |
|------|--------------------|----------------|
| First-party **source-only** | your `.asd` | **owning repo** `publish-checkout.yml` |
| First-party **with natives** | `.asd` `:cl-repo` overlays | owning repo + reusable native workflow |
| Unmodified third-party | upstream `.asd` | cl-stack-systems `imports/` + shared publish |
| Patched third-party (fork) | fork `.asd` | cl-stack-systems pin → `egao1980/<fork>` **or** publish from the fork repo |

**Do not** publish owned first-party packages via `cl-stack-systems` — its token gets `permission_denied: write_package` on packages linked to the owning repo.

**Fork ↔ import exclusivity:** never import `fukamachi/X` while keeping a workspace fork of `X`.

## Pins (current)

| Piece | Value |
|-------|--------|
| Client image | `ghcr.io/egao1980/cl-repository/cl-repository-client` — CI uses **`CL_REPOSITORY_CLIENT_VERSION: latest`** (resolve system-name `:latest` anchor → annotated semver → `oras pull`) |
| Packager image | `ghcr.io/egao1980/cl-repository/cl-repository-packager:**0.15.0**` |
| Registry / namespace | `ghcr.io` / `egao1980/cl-systems` |
| oras (Actions) | `1.2.3` |
| SBCL (typical CI) | `2.6.7` via Roswell (`sbcl-bin`) |

Bump client when `ensure-*` APIs change; packager independently when packaging changes.

## Packaging contract = `.asd` (enough)

`cl-repository-packager/asdf-plugin:auto-package-spec` merges:

| From ASDF | Fields |
|-----------|--------|
| Standard | `:version` `:description` `:author` `:license` `:depends-on` `:source-directory` |
| `:properties (:cl-repo …)` | `:provides` `:cffi-libraries` `:overlays` |

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

`auto-package-spec` from the checkout `.asd`. Same idea as `http-protocol` /
`http-backend-dexador` `scripts/publish-checkout.lisp`.

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

New first-party repos: **cl-repo CI from day one**. No `qlfile` as the install story (qlot = legacy migrate-away).

### Non-negotiable

1. `actions/checkout` → **only** the repo under test.
2. Bootstrap **`cl-repository-client` from OCI** (`CL_REPOSITORY_CLIENT_VERSION: latest` → resolve `:latest` anchor → `oras pull …:<semver>`). Do **not** git-checkout `cl-repository` in consumer CI.
3. Deps from `ghcr.io/egao1980/cl-systems` via `cl-repo:ensure-system-dependencies` (OCI → QL). QL also for *client* bootstrap deps only.
4. Ship `scripts/ci-install.lisp` + `scripts/ci-test.lisp` (phase split: install must not ASDF-load cffi/cl+ssl mid-flight before overlays are ready).

### Workflow shape (canonical)

Mirror [`cl-stack-http/.github/workflows/test.yml`](https://github.com/egao1980/cl-stack-http/blob/main/.github/workflows/test.yml) /
[`http-backend-winhttp`](https://github.com/egao1980/http-backend-winhttp):

1. checkout self  
2. `oras-project/setup-oras@v2` (`1.2.3`)  
3. Roswell + `sbcl-bin/$SBCL_VERSION`  
4. `oras login` + pull client image → extract under `.cl-repository` / find `cl-oci-*`  
5. QL **client deps only** (yason, ironclad, babel, dexador, …)  
6. `CL_SOURCE_REGISTRY="$(pwd)//:${CLIENT_DIR}//:"`  
7. `ros -l scripts/ci-install.lisp -q` then `ros -l scripts/ci-test.lisp -q`  
8. Matrix: `ubuntu-latest`, `macos-latest`, `windows-latest` when the package claims Windows

### `ci-install.lisp` / `ci-test.lisp` conventions

Keep scripts **thin and parallel**. Gold shape:

```lisp
;; Load client FIRST — any later `cl-repo:` form is read against that package.
(asdf:load-system "cl-repository-client")
(cl-repo:add-registry "https://ghcr.io" :namespace "egao1980/cl-systems" :priority :prepend)
(cl-repo:ensure-system-dependencies "<sut>"
  :also-tests t
  :with '(…ci-only extras…)          ; optional
  :sources '(("babel" :ql) …))       ; optional policy pins
(uiop:quit 0)
```

Do **not** place helpers that mention `cl-repo:…` *above* the `load-system` form — the reader resolves package-qualified symbols when the form is read.

**Phase 1 (`ci-install`):** `ensure-system-dependencies` — walks SUT `.asd` (+ `/tests`), installs missing via OCI then QL. No ASDF-load of SUT/overlays.  
**Phase 2 (`ci-test`):** `configure-asdf-source-registry` + `load-system-init-files` → load checkout → `asdf:test-system`.

`:with` is for CI-only systems not in the `.asd` (e.g. `event-backend-libuv`, `cl-stack-ssl`, soft `http2/client`). Do **not** hand-list the full dep tree.

Env often used: `GITHUB_TOKEN`, `CL_SOURCE_REGISTRY`, `HTTP_ASYNC_EVENT_BACKEND`, `CL_STACK_SSL_VERSION` (written by install when ssl is `:with`).

### CI anti-patterns

- ❌ Second `actions/checkout` of `cl-repository` / `http-protocol` / event backends  
- ❌ Hand-maintained `ci-fetch` / `ci-ql` inventories of every package  
- ❌ qlot/`qlfile` as the primary CI install for new packages  
- ❌ Hand `oras pull` of natives + `LD_LIBRARY_PATH` as the *dep install* path (staging overlay libs for the test process is OK)  
- ❌ Sibling path hacks in `CL_SOURCE_REGISTRY` for deps  

## Gold vs migrate-away examples

| Good | Migrate away |
|------|----------------|
| `.asd` drives `auto-package-spec` | Hardcoded `package-spec` in `publish-source.lisp` |
| First-party publish from owning repo | First-party via cl-stack-systems import |
| cl-stack-systems = third-party imports only | Hand-written `package-spec` / divergent publish scripts |
| `:cl-repo` overlays in `.asd` (ssl/libuv) | Overlay lists only in workflow YAML / Lisp |
| cl-stack-http / winhttp — OCI client CI | qlot as the install story for new packages |

Tag releases (`v*`) matching the import pin / OCI tag. Update
[`cl-stack/docs/QUICKSTART.md`](https://github.com/egao1980/cl-stack/blob/main/docs/QUICKSTART.md)
pins in the **same** change set that publishes a user-facing feature.

## Checklist (agent)

Before adding CI or publish to a package:

- [ ] `.asd` has honest `:version` / `:depends-on` / `:cl-repo` (overlays if native) — **enough for package-spec**  
- [ ] First-party source-only? → owning-repo `publish-checkout` (not cl-stack-systems)  
- [ ] Third-party? → cl-stack-systems `imports/` + shared publish  
- [ ] Natives? → reusable native workflow in the **owning** repo, same `.asd`  
- [ ] Consumer CI: self-only checkout + OCI client **0.11.0** + thin `ensure-system-dependencies` `ci-install`/`ci-test`  
- [ ] Packager **0.10.0**; QUICKSTART pins updated if user-facing  
