---
name: add-cl-project
description: >-
  add-cl-project.sh: gh fork into egao1980, clone, ASDF registry. Use when adding a CL
  checkout (not for unmodified source-only — that is a cl-stack-systems import).
---

# Add a CL project to the workspace

## When *not* to use this

If the library is **source-only** (no native overlays) — third-party **or** first-party — publish via **[`egao1980/cl-stack-systems`](https://github.com/egao1980/cl-stack-systems)** import (`./scripts/add-import.sh …`). Do **not** add per-repo `publish-source.lisp`. See skill **[cl-repository-ci](../cl-repository-ci/SKILL.md)**.

```bash
cd cl-stack-systems && ./scripts/add-import.sh owner/repo <ref>
```

Use **this** skill (fork/clone) only for patches, **native overlay** ownership, or local editing of first-party repos (CI still installs deps from OCI).

**Exclusivity:** after forking with this script, **remove** any matching `cl-stack-systems/imports/<name>/`. Conversely, if you add an import, do **not** also `add-cl-project` / fork that upstream.

## Steps

1. Confirm **`gh auth status`** if the repo needs forking (`owner/repo` form).
2. From the **workspace root** (parent of `.lisp-workspace/`), run:
   ```bash
   ./.lisp-workspace/scripts/add-cl-project.sh <owner/repo-or-short-name> [target-dir]
   ```
   See `--help` for `--qlot`, `--quicklisp`, `--no-fork`, `--upstream`.
3. Prefer **third-party** repos as `qitab/cl-protobufs` so the script runs **`gh repo fork`** (user login = org name: fork without `--org`; real org: `--org`).
4. After clone, use **`qlot exec ros …`** inside that project if it has a `qlfile`.

## References

- [`.lisp-workspace/README.md`](../README.md)
- [`.lisp-workspace/docs/REQUIREMENTS.md`](../docs/REQUIREMENTS.md)
