---
name: cl-repository-ci
description: >-
  cl-repository CI install/test and OCI publish for egao1980 packages: oras-bootstrap
  cl-repository-client, scripts/ci-install + ci-test, cl-stack-systems for source-only
  publish (no per-repo publish scripts), native overlays via reusable workflows. Use before
  adding GitHub Actions, migrating off qlot, publishing to ghcr.io/egao1980/cl-systems, or
  deciding fork vs import.
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
│     auto-package-spec is enough — no custom publish script
│
├─ Has native overlays / grovel / CFFI libs to ship?
│  ├─ YES → declare :overlays / :cffi-libraries in .asd :cl-repo
│  │         + cl-repository *reusable native publish* workflow
│  └─ NO  → cl-stack-systems import (qlfile = source pin only)
│            Shared publish.yml → auto-package-spec from that .asd
│
└─ Only consume deps in CI?
   → oras-bootstrap cl-repository-client + scripts/ci-install.lisp + ci-test.lisp
```

| Kind | Source pin | Packaging metadata | Publish runner |
|------|------------|--------------------|----------------|
| Unmodified third-party | `imports/<name>/qlfile` | upstream `.asd` (as-is) | cl-stack-systems shared |
| First-party **source-only** | `imports/<name>/qlfile` → `egao1980/<repo>` tag | **your** `.asd` / `:cl-repo` | cl-stack-systems shared |
| First-party **with natives** | own repo tag | `.asd` `:cl-repo` overlays | reusable native workflow |
| Patched third-party | import pin to `egao1980/<fork>` | fork `.asd` | shared import workflow |

**Fork ↔ import exclusivity:** never import `fukamachi/X` while keeping a workspace fork of `X`. Importing `egao1980/X` (the fork) for OCI while developing that fork locally is OK.

## Pins (current)

| Piece | Value |
|-------|--------|
| Client image | `ghcr.io/egao1980/cl-repository/cl-repository-client:**0.10.0**` |
| Packager image | `ghcr.io/egao1980/cl-repository/cl-repository-packager:**0.10.0**` |
| Registry / namespace | `ghcr.io` / `egao1980/cl-systems` |
| oras (Actions) | `1.2.3` |
| SBCL (typical CI) | `2.4.11` via Roswell |

Bump packager/client together; do not leave consumer workflows on `0.8.0`.

## Publish: source-only → cl-stack-systems (no custom scripts)

### Add / update an import

```bash
cd cl-stack-systems
./scripts/add-import.sh egao1980/cl-stack-http v0.1.7   # first-party source-only
./scripts/add-import.sh alexandria/alexandria v1.4      # third-party
# optional: imports/<name>/system  when ASDF name ≠ directory (e.g. cl+ssl)
```

`imports/<name>/qlfile` is the **only** per-package publish config:

```text
github egao1980/cl-stack-http v0.1.7
```

### Ship it

```bash
gh workflow run publish.yml -R egao1980/cl-stack-systems -f import=<name>
```

Shared path: `.github/workflows/publish.yml` → `scripts/publish-import.lisp`
(`PKG_QLFILE`, `OCI_*`, `GITHUB_TOKEN`). Uses packager `build-package-from-github` /
`auto-package-spec` — metadata comes from the **ASDF system**, not a hand-written spec in the consumer repo.

### Anti-patterns (publish)

- ❌ New `scripts/publish-source.lisp` in a source-only package
- ❌ Copy-pasted `publish-oci.yml` that stages trees + hardcodes `package-spec`
- ❌ Publishing source-only first-party from the package repo instead of cl-stack-systems
- ❌ Packager tag `0.8.0` on new work
- ❌ Import **and** fork of the same upstream (except documented egao1980-fork pin + local edit)

### Native overlays only

- Reuse `egao1980/cl-repository/.github/workflows/publish-native-package.yml` (or its documented entrypoints).
- Grovel at **overlay build** time; consumers load without a C toolchain.
- Resolve natives via `cffi:*foreign-library-directories*` + absolute preload — **never** require `LD_LIBRARY_PATH` / `DYLD_LIBRARY_PATH` for correctness.
- Overlay keys may include `os` / `release` / `arch`.

## CI install / test (consumer repos)

New first-party repos: **cl-repo CI from day one**. No `qlfile` as the install story (qlot = legacy migrate-away).

### Non-negotiable

1. `actions/checkout` → **only** the repo under test.
2. Bootstrap **`cl-repository-client` from OCI** (`oras pull` … `cl-repository/cl-repository-client:0.10.0`). Do **not** git-checkout `cl-repository` in consumer CI.
3. Deps from `ghcr.io/egao1980/cl-systems` via `cl-repo:add-registry` + fetch/load. QL only for unpublished leftovers / client bootstrap deps.
4. Ship `scripts/ci-install.lisp` + `scripts/ci-test.lisp` (phase split: install must not ASDF-load cffi/cl+ssl mid-flight before overlays are ready).

### Workflow shape (canonical)

Mirror [`cl-stack-http/.github/workflows/test.yml`](https://github.com/egao1980/cl-stack-http/blob/main/.github/workflows/test.yml) /
[`http-backend-winhttp`](https://github.com/egao1980/http-backend-winhttp):

1. checkout self  
2. `oras-project/setup-oras@v1` (`1.2.3`)  
3. Roswell + `sbcl-bin/$SBCL_VERSION`  
4. `oras login` + pull client image → extract under `.cl-repository` / find `cl-oci-*`  
5. QL **client deps only** (yason, ironclad, babel, dexador, …)  
6. `CL_SOURCE_REGISTRY="$(pwd)//:${CLIENT_DIR}//:"`  
7. `ros -l scripts/ci-install.lisp -q` then `ros -l scripts/ci-test.lisp -q`  
8. Matrix: `ubuntu-latest`, `macos-latest`, `windows-latest` when the package claims Windows

### `ci-install.lisp` / `ci-test.lisp` conventions

Keep scripts **thin and parallel** across repos (same structure). Prefer copying from a gold-standard consumer (`cl-stack-http`, `http-backend-winhttp`) over inventing new helpers. Future: shared helper system — until then, do not diverge.

**Phase 1 (`ci-install`):** load client → `add-registry` `egao1980/cl-systems` → plan/ensure OCI deps → optional `ci-ql` for gaps → quit.  
**Phase 2 (`ci-test`):** `configure-asdf-source-registry` + `load-system-init-files` → load checkout → `asdf:test-system`.

Env often used: `GITHUB_TOKEN`, `CL_SOURCE_REGISTRY`, optional version pins (`CL_STACK_SSL_VERSION`, …).

### CI anti-patterns

- ❌ Second `actions/checkout` of `cl-repository` / `http-protocol` / event backends  
- ❌ qlot/`qlfile` as the primary CI install for new packages  
- ❌ Hand `oras pull` of natives + `LD_LIBRARY_PATH` in consumer test jobs  
- ❌ Sibling path hacks in `CL_SOURCE_REGISTRY` for deps  

## ASDF packaging metadata

For clean `auto-package-spec` / import publish, keep `.asd` honest:

- `:version`, `:description`, `:license`, `:author`, `:depends-on`
- Optional `:properties ((:cl-repo …))` for `:provides` / overlay hints when needed

Tag releases (`v*`) that match the import pin / OCI tag consumers will use. Update
[`cl-stack/docs/QUICKSTART.md`](https://github.com/egao1980/cl-stack/blob/main/docs/QUICKSTART.md) pins in the **same** change set that publishes a user-facing feature.

## Gold vs migrate-away examples

| Good | Migrate away |
|------|----------------|
| cl-stack-http / winhttp — OCI client CI | http-protocol / event-protocol — qlot test CI |
| cl-stack-systems import publish | Per-repo `publish-source.lisp` + staged `publish-oci.yml` for source-only |
| cl-repository native reusable workflow | Copy-pasted native publish + `LD_*` |

## Checklist (agent)

Before adding CI or publish to a package:

- [ ] Source-only? → **cl-stack-systems import**, no custom publish script  
- [ ] Natives? → reusable native workflow, not a new one-off  
- [ ] Consumer CI checkouts **self only** + OCI client **0.10.0**  
- [ ] `ci-install.lisp` + `ci-test.lisp` present; no qlfile install story  
- [ ] Packager **0.10.0**; QUICKSTART / MEMORY pins updated if user-facing  
