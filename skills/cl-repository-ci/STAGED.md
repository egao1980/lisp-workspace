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
