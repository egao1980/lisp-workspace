## Pending

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
