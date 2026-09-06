## Pending

### 2026-09-06 — canned CI must not load the client through the checkout
- **Source:** wave 3 `http-encoding-chipz` 0.1.1. Install/publish died in `run.lisp` `(asdf:load-system "cl-repository-client")` with `Component "compression-protocol" not found`. `CL_SOURCE_REGISTRY` is checkout-first (`activate.sh` / `setup-client`). Client graph is `cl-oci-client/http` → `http-backend-dexador` → `http-encoding-chipz`, so the checkout asd shadows the bundled 0.1.0.
- **Proposed change:** `%load-client` drops the checkout from the existing `CL_SOURCE_REGISTRY` (setup-lisp already wrote it), loads the client, re-reads the env registry, `clear-checkout-systems`. No `CL_REPOSITORY_DEST` / sibling registry. Encoding repos already use `test-system.yml@main`; leftover old bit is `packager_version` default `0.16.0`. Soft-dep `http-encoding-chipz` from `http-backend-dexador` so the client graph stops hard-requiring it.
- **Why:** pre-publish hooks never run — the process dies during client load. GHCR already had `compression-protocol:0.1.1`.
- **Status:** applied in `egao1980/cl-repository` `cursor/unshadow-client-load-fe7c` (`run.lisp` / `ci-lib.lisp`). Promote to SKILL/MEMORY after merge.

### 2026-09-01 — native publish loads packager via setup-lisp, not QL
- **Source:** user: native publish ships non-Lisp binaries; Lisp (packager/client) loads like other Lisp. cl-stack-snappy #33454477509 (`latest` oras untitled layers) and #33454938426 (`0.18.0` then `ql:quickload` → `http-protocol` missing).
- **Proposed change:** `publish-native-package.yml` = `setup-lisp` + `cl-repo:ensure-systems` (same as `publish-source.yml` / `ci` `phase: publish`). Drop apt SBCL, Quicklisp bootstrap, and raw `oras pull` of the packager tarball. `packager-tag` defaults to `latest` (client resolves). Do **not** pin `0.10.0`/`0.12.0` as a workaround. Callers that still pin those (zstd/brotli/ssl/libuv/libev/icu/llama-cpp/vllm-cpp/snappy) drop the pin after this workflow is on `@main`. `cl-protobufs` cannot use the reusable workflow yet (`generated-source` overlays) but must use the same load path.
- **Why:** the QL path only extracted the packager tarball; current packager depends on GHCR systems (`http-protocol`, …). Pinning a pre-http-protocol packager papers over that.
- **Status:** applied to SKILL.md + MEMORY (2026-09-01). Supersedes the “pin packager-tag 0.10.0” draft.

### 2026-09-01 — REJECTED: native publish must pin packager-tag, not latest
- **Source:** cl-stack-snappy publish-oci #33454477509 / #33454938426.
- **Proposed change:** Native callers must set `packager-tag` to a **pre-http-protocol** packager (`0.10.0` / `0.12.0`). Do not pass `latest`/`0.18.0`.
- **Why rejected:** workaround. Gold is fix the reusable workflow load path (item above). We do not use QL.

### 2026-08-29 — composed CI uses setup-lisp, not setup-client + setup-roswell
- **Source:** after cl-repository#37 client-cache + ci-base.
- **Proposed change:** Gold compose example should be `setup-lisp@main` (not `setup-client` then `setup-roswell`). Extra-impl: `install-sbcl: false`. Ubuntu SBCL without sudo/peers/native toolchain can set `container: ci-base` + `defaults.run.shell: bash`. Repos already on `test-system.yml@main` inherit both automatically.
- **Why:** skill still shows the pre-cache two-step; that's the Windows oras-walk path.

### 2026-08-29 — setup-lisp caches the client tree on resolved semver
- **Source:** json-patch warm Windows (`#33274454875`): `~/.roswell` cache hit still re-unzipped Roswell and oras-pulled the entire client tree (yason/ironclad/dexador). `setup-client.sh` `rm -rf` dest, so a restored `.cl-repository` would be wiped. `:latest` is a moving alias — must not be the cache key.
- **Proposed change:** Gold VM path (`setup-lisp` without ci-base): resolve `:latest` → semver (`oras manifest fetch`) *before* `actions/cache` of `inputs.dest`. Hit + valid asd → skip `setup-client`, export `CL_*` only. Roswell/SBCL cache key stays independent of the client tag. Document that Windows has no job containers; this cache is the remaining Windows win.
- **Why:** client pull dominated warm Windows; SBCL cache alone did not skip oras.

### 2026-08-29 — Ubuntu CI is a job container, not a Docker action
- **Source:** user: cache ros/sbcl/client in a base image; small library CI must be short.
- **Proposed change:** Gold Ubuntu path is `jobs.<id>.container: ghcr.io/egao1980/cl-repository/ci-base` + `setup-lisp` (wire env only). Document that a Docker *action* (`runs.using: docker`) is the wrong tool — isolated sibling, only workspace persists, SBCL does not survive into `ci`. Job containers are Linux-only (official workflow syntax note). macOS/Windows stay on `setup-lisp` install + `actions/cache` of `~/.roswell`. Job-container default shell is `sh` — keep `shell: bash`. Image rebuild: `publish-ci-base.yml`.
- **Why:** every consumer was paying `install-for-ci.sh` + `ros install sbcl-bin` + oras client pull. Cache is per-repo / 7-day eviction and does not share across the small-library fleet.



### 2026-08-27 — canned publish.lisp must not colon-qualify unpublished packager symbols
- **Source:** blackboard/telemetry/mcp/a2a/ag-ui publish runs 33119141595+ died `INPUT-ERROR-IN-LOAD` / `Symbol "FILTER-PUBLISH-PROVIDES" not found` after cl-repository#30.
- **Proposed change:** Document that `publish.lisp` is still a `LOAD`/`READ`. Colon-qualify only symbols that exist in the **pinned packager** (`0.16.0`). New helpers → `find-symbol` + fallback. `#30` added `filter-publish-provides` in source and called it from canned CI `@main` before that function shipped in `cl-oci-0.16.0`.
- **Why:** canned `@main` + packager pin 0.16.0 is the consumer publish path; source-only packager asd is still `0.1.0` and is not what CI pulls.

### 2026-08-27 — slash secondaries are SAT/OCI names, not demo remaps
- **Source:** user: "don't hack around" (cl-stack-llm-demo `ai-agent-protocol/mcp`).
- **Proposed change:** Document that ASDF `foo/bar` is **not** a GHCR repo. Client `oci-package-name` maps slash → primary and `+` → `-plus-`. Publish keeps `auto-package-spec` provides (drop tests only); publisher skips extra repos for `/` names. Do **not** remap `foo/bar` → `foo` in consumer `install.lisp`. After this client ships, `:ci :with ("llm-protocol/capability")` is valid (installs `llm-protocol` / `capability-protocol` primary as appropriate).
- **Why:** canned `publish.lisp` used to wipe provides to `(list system)`, and SAT listed `ns/foo/bar`. Demo-side `%oci-name` was papering over the resolver.

### 2026-08-27 — consumer CI heap for fat native overlays
- **Source:** llm-protocol-vllm-cpp#1 run 33040261654. Ubuntu install OOM: `Heap exhausted … 816087040 bytes available, 1605702608 requested` while chipz-decompressing `vllm-cpp:0.1.1` linux/amd64 CUDA overlay. macOS/Windows install survived (CPU/MLX overlays) then test died on `Component "capability-protocol" not found` because `:ci :with ("llm-protocol/capability")` is a secondary system, not an OCI package.
- **Proposed change:** (1) `:ci :with` names **registry packages** (`capability-protocol`), not `foo/secondary`. (2) Client `gunzip-octets` must stream on SBCL (`chipz:make-decompressing-stream`) — buffer `chipz:decompress` doubles 2GiB→4GiB while holding the gzip blob and OOMs an 8GB heap (`4294967312 requested`). Heap bump alone is not enough. Until the client ships that, consumers use `scripts/ci/pre-install.lisp` to redefine `extract-layer*`. Do not start another CUDA compile.
- **Why:** publish heap input exists only on `publish-native-package.yml`. Consumer `ros -l` still uses default ~1GB heap.

### 2026-08-27 — native publish SBCL heap
- **Source:** vllm-cpp reuse publish 33032941212. Packager 0.10.0 got past `ql:quickload`, then `HEAP-EXHAUSTED-ERROR` in salza2 while gzipping `lib/linux-amd64` CUDA overlays (~1.3GB artifact). Apt SBCL default heap ~1GB. Follow-up 33034565305: `sbcl --noinform --dynamic-space-size` dies (`C runtime option --dynamic-space-size in the middle of Lisp options`).
- **Proposed change:** Document `publish-native-package.yml` input `sbcl-dynamic-space-mb` (default 8192). `--dynamic-space-size` must precede `--noinform`/`--load`. Do not put `#` comments inside `VAR=val \\` continuations (bash applies env to a no-op; SBCL `ensure-directory-pathname` of NIL). Use `export`. Callers with fat CUDA overlays should pass 8192–16384. Do not copy the reusable workflow.
- **Why:** source-only packager 0.16.0 is a different failure (`http-protocol` missing); natives that actually gzip large `.so`s die on heap first.

### 2026-08-27 — `:sources` does not add install roots
- **Source:** sql-protocol#7 postgres still `Component "cl-postgres" not found` after `:sources (("cl-postgres" :oci) ("dbd-postgres" :oci))`.
- **Proposed change:** Document that `:ci :sources` only pins origin for systems already in the install set. `ensure-system-dependencies` will not pull a SAT-missed transitive (e.g. `dbi` OCI tarball `provides` `dbd-postgres` via symlink and never walks `dbd-postgres.asd` → `cl-postgres`). Put those names in `:ci :with` (and/or workflow `with:`) as extra roots. Do not invent `:ql` pins.
- **Why:** pin-drop of `:ql` sources left postgres CI red; `:oci` pins alone were a no-op.

### 2026-08-26 — do not `:sources (("rove" :ql))`
- **Source:** user standing instruction (log-protocol split; then “any `:ql` pin is a mistake”).
- **Proposed change:** Drop the gold-shape example `:sources (("rove" :ql))`. **Any** `:sources (("foo" :ql))` is forbidden — publish `foo` to `cl-systems` (import or owning repo), then rely on OCI-then-QL. `:depends-on ("rove")` on `/tests` is enough.
- **Why:** agents keep copying the skill example onto every new first-party `.asd`.
- **Status:** applied to SKILL.md gold example + MEMORY (2026-08-26).

### 2026-08-07 — CFFI natives auto-load on ASDF load
- **Source:** user standing instruction (cl-stack-icu).
- **Proposed change:** Document that first-party native/CFFI packages must `load-foreign-library` at system load (`eval-when (:load-toplevel :execute)`); consumers must not need `load-*` / `ensure-*`. Absolute preload preferred; no LD_LIBRARY_PATH.


### 2026-08-04 — first-party source-only migration landed

- **Source:** agent migration (cl-stack-systems#5 + drop-source-publish PRs across stack).
- **Proposed change:** Note in checklist that default branches differ (`cl-idna`/`cl-mime`/`quri` = `master`); prefer release tags in qlfile when present (`v0.1.0`, `v0.7.1`) else full SHA of the asd that matches the published `:version`. Mention README Publish blurb template after dropping per-repo publish scripts.
- **Why:** agents assumed `main` for every egao1980 repo and skipped mime/quri until corrected.


### 2026-08-04 — native callers + import publish races

- **Source:** native packager migration + cl-stack-systems import matrix failures.
- **Proposed change:** Checklist: natives must call upstream `publish-native-package.yml@main` with packager **0.10.0** (no vendored copy); optional `source-overlay-artifact` for version-synced sources. Import publish: parallel matrix races on deps → retry/soft-fail in `publish-import.lisp`; add missing QL pins (blackbird/vom/cl-cookie/…) before expecting a green all-imports push.
- **Why:** ssl had a forked reusable; first-party import publish failed on blackbird + races even when sibling imports succeeded in the same run.

### 2026-08-04 — CI action pins Node 24

- **Source:** workspace-wide Node 20 deprecation warnings.
- **Proposed change:** Workflow checklist pins: checkout@v5, setup-oras@v2, upload-artifact@v6, download-artifact@v7 (reusable native publish).
- **Why:** keep consumer CI examples warning-free.

### 2026-08-04 — ci-install = client dep install for the system

- **Source:** user correction (chat).
- **Status:** applied to SKILL.md + MEMORY + consumer `ci-install.lisp` rewrite (`ensure-system-dependencies`, client **0.11.0**).
- **Proposed change:** ~~Rewrite skill §`ci-install`/`ci-test`…~~ Done.

### 2026-08-04 — load client before any `cl-repo:` form

- **Source:** CI failure (`Package CL-REPO does not exist` while reading `ci-install.lisp`).
- **Proposed change:** In skill gold shape, stress that `(asdf:load-system "cl-repository-client")` must run **before** any top-level form whose *source text* contains `cl-repo:…` (helpers using `cl-repo:installed-system-version` included). Reader resolves package-qualified symbols at read time.
- **Why:** `defun` bodies are not evaluated early, but `cl-repo:foo` still requires the package to exist when the form is read.
- **Status:** applied to SKILL.md gold shape.


### 2026-08-05 — GHCR write_package ACL after import migration

- **Source:** cl-stack-systems publish failed with `permission_denied: write_package` (HTTP 403); user clarified first-party stays on owning repo.
- **Status:** applied — MEMORY + SKILL: first-party publish from owning repo; cl-stack-systems = third-party only. ACL grant to cl-stack-systems not required for owned packages.
- **Follow-up (optional):** drop obsolete first-party dirs under `cl-stack-systems/imports/` (http-protocol, backends, cl-stack-*, …) so nobody dispatches them there by habit.

### 2026-08-14 — import publish must not drop :feature deps

- **Source:** dexador OCI `depends-on` had `cl+ssl` but not `winhttp`; Windows `setup-client` had to hardcode the pull.
- **Proposed change:** `cl-stack-systems/scripts/publish-import.lisp` must not filter `(:feature EXPR DEP)` against the publish-host `*features*`. Packager 0.16.0 already keeps feature deps as metadata; the import script’s `normalize-dep*` override was a leftover 0.8.0 workaround that dropped `:windows` on Linux CI. After changing it, republish `dexador` (`workflow_dispatch -f import=dexador`), not the full matrix.
- **Why:** Linux publish host → `(:feature :windows "winhttp")` vanished; consumers loading dexador on Windows died before ci-install.
- **Status:** code landed — cl-stack-systems#31 merged; `dexador:0.9.16` now lists `winhttp,flexi-streams,cl+ssl`. Skill text still pending. Follow-up: drop the setup-client MINGW `pull_system_tree winhttp` hardcode (cl-repository#21); `pull_system_tree` now walks the annotation on every OS.

### 2026-08-14 — setup-client Windows (CRLF, cygpath, ASDF `;`)

- **Source:** consumer `windows-latest` after cl-repository#18/#19: `cl-repository-client` not found / `:0.16.0` missing / `tar -C D:\…`.
- **Proposed change:** Gold notes for `setup-client`: Git Bash Python emits CRLF (strip CR); `tar -C` needs `cygpath -u`; export `D:/` via `cygpath -m`; **Windows `CL_SOURCE_REGISTRY` uses `;`** (`D:/ws//;D:/dest//;`) because `:` splits drive letters. Consumer `run:` steps need `shell: bash`. `highest_tag` must `fullmatch` semver so SHA `677cabae…` does not beat `cffi:0.24.1`. Cover `windows-latest` in the action’s own job; smoke-load from extract dest only (checkout asd hides registry bugs).
- **Why:** Unix consumer CI was green; Windows failed until cl-repository#19+#20.

### 2026-08-14 — setup-roswell reuses test.yml Lisp steps

- **Source:** user: "reuse test.yaml steps" while migrating native `publish-oci.yml`.
- **Proposed change:** Gold workflow shape is `setup-client` + `setup-roswell` + `ros -l scripts/ci-install.lisp` + `ci-test.lisp`. Native publish uses the same three steps (not `CI_INSTALL_DEPS_ONLY` / QL client bootstrap). ECL/CCL jobs: `setup-roswell` with `install-sbcl: false`.
- **Why:** Roswell/SBCL YAML was copy-pasted in every consumer `test.yml` and diverged in `publish-oci.yml`.

### 2026-08-07 — multi-impl ECL smoke row

- **Source:** cl-stack#42 kickoff (local ECL 26.5.5 green for crypto/secrets).
- **Proposed change:** Extend workflow shape: keep SBCL×OS job; add separate `test-ecl` on `ubuntu-latest` (`ros install ecl`, 90m timeout, C toolchain apt pkgs). Link `cl-stack/docs/multi-impl.md`. Warn: never JSON commas in `:sources` quoted lists; ECL needs `--nodebug` + quit hook.
- **Why:** README claims ECL/ABCL; SBCL-only CI is the gap.

### 2026-08-07 — multi-impl CCL smoke row

- **Source:** cl-stack#42 continuation (local CCL 1.13 Rosetta green for crypto/secrets).
- **Proposed change:** Add `test-ccl` on `ubuntu-latest`: `ros install ccl-bin` (not `ccl`; no arm64). Document no Apple Silicon CCL — darwin local = Rosetta or skip. Link `cl-stack/docs/multi-impl.md`.
- **Why:** CCL is “strongly recommended” in #42; linux binary smoke is cheap once Roswell matrix exists.

### 2026-08-07 — ABCL OCI extract (source: multi-impl #42 / crypto-backend test-abcl)
- Document that client installer must use `chipz:decompress` (not Gray `make-decompressing-stream`) for ABCL.
- ABCL CI needs JNA jars on `CLASSPATH` whenever CFFI/dexador is on the path.

## Applied

### 2026-08-25 — publish-source.yml verified + GH uses:/read traps
- **Source:** schema-protocol canary after cl-repository#24/#25/#26.
- **Applied:** SKILL/MEMORY/REQUIREMENTS/LESSONS: `publish-source.yml@main` published `schema-protocol:0.1.0`. `uses:` refs must be literal `@main`. `run.lisp` must not contain packager/oci-client package-qualified symbols (they belong in `publish.lisp`).
- **Follow-up:** finish migrating remaining copied `ci-*.lisp` consumers (first wave PRs opened 2026-08-25). Extra-impl / event-backend-hook / dialect-publish repos stay composed, not the thin reusable.

### 2026-08-25 — canned GH Actions, not copied CI Lisp
- **Source:** user: original cl-repo idea is `.asd` conventions + canned GH Action; hooks only if needed.
- **Applied:** SKILL/MEMORY/REQUIREMENTS: gold path is `test-system.yml` / `publish-source.yml` / `ci` action. `:cl-repo :ci` for extras. No new `ci-install.lisp` / `publish-checkout.lisp`. Existing copied scripts = migrate-away.
- **Supersedes:** pending notes that still say “ship `scripts/ci-install.lisp`” as gold.
