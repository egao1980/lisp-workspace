---
name: add-cl-project
description: >-
  add-cl-project.sh: gh fork into egao1980, clone, ASDF registry. New first-party
  protocol/backend/parity → create-first-party-repo.sh (own egao1980 repo).
  Unmodified third-party source-only → cl-stack-systems import.
---

# Add a CL project to the workspace

## New first-party protocol / backend / parity

**Create `egao1980/<name>` the same day.** Workspace-only trees never reach GHCR.

```bash
./.lisp-workspace/scripts/create-first-party-repo.sh <name>
```

That inits git if needed, `gh repo create`, pushes `main`, registers ASDF. Ship canned `test-system.yml` / `publish-source.yml` from day one, then publish from that repo (skill **[cl-repository-ci](../cl-repository-ci/SKILL.md)**).

## When *not* to use `add-cl-project.sh`

**Unmodified third-party** source-only → [`egao1980/cl-stack-systems`](https://github.com/egao1980/cl-stack-systems) import (`./scripts/add-import.sh …`). Do **not** import first-party protocols/backends. Do **not** add per-repo `publish-source.lisp`.

```bash
cd cl-stack-systems && ./scripts/add-import.sh owner/repo <ref>
```

Use **this** script (fork/clone) for patches, **native overlay** ownership, or local editing of an **existing** first-party repo (CI still installs deps from OCI).

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
