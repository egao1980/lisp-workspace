# cl-repository CI — examples

Read [SKILL.md](SKILL.md) first.

## Packaging contract = `.asd`

`auto-package-spec` merges:

| From ASDF | Fields |
|-----------|--------|
| Standard | `:version` `:description` `:author` `:license` `:depends-on` `:source-directory` |
| `:properties (:cl-repo …)` | `:provides` `:cffi-libraries` `:overlays` `:ci` |

### Source-only

```lisp
(defsystem "cl-stack-http"
  :version "0.1.7"
  :description "…"
  :author "egao1980"
  :license "MIT"
  :depends-on ("http-protocol" "cl-stack-pathlib" …)
  ;; optional: :properties (:cl-repo (:provides ("cl-stack-http")))
  …)
```

Do **not** duplicate depends-on / version / description in a publish script.

### With natives

See `cl-stack-ssl.asd`, `event-backend-libuv.asd`:

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

## Publish commands

First-party source-only — tag/release on `egao1980/<repo>`, then:

```bash
gh workflow run publish-checkout.yml -R egao1980/http-protocol -f version=0.3.0
# (or omit -f version to use .asd :version)
```

Thin wrapper around `publish-source.yml@main` — no `scripts/publish-checkout.lisp`.

Third-party — `imports/<name>/qlfile` is only a source locator:

```bash
cd cl-stack-systems
./scripts/add-import.sh alexandria/alexandria v1.4
gh workflow run publish.yml -R egao1980/cl-stack-systems -f import=alexandria
```

Optional `imports/<name>/system` when ASDF name ≠ directory (e.g. `cl+ssl`).

### Native publish

Reuse `egao1980/cl-repository/.github/workflows/publish-native-package.yml`.
Honor `.asd` `:cl-repo` overlays — not a parallel YAML-only inventory.

Lisp load path = source publish: `setup-lisp` + `cl-repo:ensure-systems` of packager / oci-client (same as canned `ci` `phase: publish`). Binaries stay in `native-<os>-<arch>` artifacts → `lib/<os>-<arch>/`. Do **not** apt-install SBCL, bootstrap Quicklisp, or raw-`oras pull` the packager tarball. `packager-tag` defaults to `latest`. Do not pin `0.10.0` / `0.12.0` to dodge a missing `http-protocol`.

`cl-protobufs` still has a repo-local publish script (`generated-source` overlays) but must load packager via `setup-lisp` + `ensure-systems`, not QL.

GHCR ACL exception: **sql-query-postgres / sql-query-sqlite3** were first published from `sql-query` — owning-repo publish is still 403 (2026-08-25); keep `sql-query` `publish_dialects` until Package → Manage Actions grants Write. If a first-party package was first published from the wrong repo, `delete-package.yml` on the linked repo and republish from the owner — do not keep a proxy publish job.

## Consumer compose

```yaml
jobs:
  test:
    uses: egao1980/cl-repository/.github/workflows/test-system.yml@main
```

Custom matrix (ABCL/ECL, extra env):

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

Call `setup-client` / `setup-lisp` in **every job** that needs the client. Default matrix: `ubuntu-latest`, `macos-latest`, `windows-latest`. Override with `os-json`.

### `.asd` `:ci`

```lisp
:properties
(:cl-repo
 (:ci (:with ("dissect" "cl-stack-ssl")     ; not in :depends-on
       ;; no :sources (("…" :ql))
       :also-tests t
       :load-before-test ("cl-stack-ssl")
       :record-versions (("cl-stack-ssl" . "CL_STACK_SSL_VERSION")))))
```

Honest `:depends-on` + `foo/tests` is enough for most packages. `:ci` is ignored by `auto-package-spec`.

Hooks (only if `:ci` cannot express it), loaded after the client:

`scripts/ci/pre-install.lisp` `post-install.lisp` `pre-test.lisp` `post-test.lisp` `pre-publish.lisp` `post-publish.lisp`

`pre-install` may push onto `cl-repository-ci-lib:*extra-with*` (e.g. event backend from `HTTP_ASYNC_EVENT_BACKEND`). Existing copied `ci-*.lisp` is migrate-away.

## Anti-patterns

Publish:

- `make-instance 'package-spec` in repo scripts
- New `scripts/publish-source.lisp` / copy-pasted `publish-oci.yml`
- Divergent depends-on/version between `.asd` and a publish helper
- Packager tag `0.8.0` / `0.10.0` as a QL-workaround
- apt SBCL + Quicklisp bootstrap + raw `oras pull` of the packager
- Import upstream **and** keep a workspace fork

CI:

- New `scripts/ci-install.lisp` / `ci-test.lisp` / `publish-checkout.lisp`
- Second `actions/checkout` of `cl-repository` / sibling deps
- Copy-pasted `oras pull` + QL client-bootstrap
- Hand-maintained `ci-fetch` / `ci-ql` inventories
- `:sources (("foo" :ql))`
- qlot/`qlfile` as the primary CI install for new packages
- Hand `oras pull` of natives + `LD_LIBRARY_PATH` as the dep install path
- Sibling path hacks in `CL_SOURCE_REGISTRY` for deps

## Gold vs migrate-away

| Good | Migrate away |
|------|----------------|
| `.asd` drives `auto-package-spec` | Hardcoded `package-spec` in `publish-source.lisp` |
| First-party publish from owning repo | First-party via cl-stack-systems import |
| cl-stack-systems = third-party imports only | Hand-written `package-spec` / divergent publish scripts |
| `:cl-repo` overlays in `.asd` | Overlay lists only in workflow YAML / Lisp |
| cl-stack-http / winhttp — OCI client CI | qlot as the install story for new packages |
| canned `test-system.yml` / `ci` action | Copied `scripts/ci-install.lisp` per repo |

Tag releases (`v*`) matching the import pin / OCI tag.
