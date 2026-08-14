## Pending

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

### 2026-08-14 — setup-roswell reuses test.yml Lisp steps

- **Source:** user: "reuse test.yaml steps" while migrating native `publish-oci.yml`.
- **Proposed change:** Gold workflow shape is `setup-client` + `setup-roswell` + `ros -l scripts/ci-install.lisp` + `ci-test.lisp`. Native publish uses the same three steps (not `CI_INSTALL_DEPS_ONLY` / QL client bootstrap). ECL/CCL jobs: `setup-roswell` with `install-sbcl: false`.
- **Why:** Roswell/SBCL YAML was copy-pasted in every consumer `test.yml` and diverged in `publish-oci.yml`.

### 2026-08-07 — multi-impl ECL smoke row

- **Source:** cl-stack#42 kickoff (local ECL 26.5.5 green for crypto/secrets).
- **Proposed change:** Extend workflow shape: keep SBCL×OS job; add separate `test-ecl` on `ubuntu-latest` (`ros install ecl`, 90m timeout, C toolchain apt pkgs). Link `cl-stack/docs/multi-impl.md`. Warn: never JSON commas in `:sources` quoted lists; ECL needs `--nodebug` + quit hook.
- **Why:** README claims ECL/ABCL; SBCL-only CI is the gap.
