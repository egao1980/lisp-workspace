---
name: add-cl-project
description: >-
  Registers a GitHub Common Lisp repo in this workspace using .lisp-workspace/scripts/add-cl-project.sh
  (gh fork into egao1980 when needed, clone, upstream remote, ASDF source-registry snippet, optional qlot
  or Quicklisp local-projects). Use when adding a new CL dependency repo, cloning a fork, wiring ASDF for
  a sibling project, or onboarding libraries next to cl-repository/grpc.
---

# Add a CL project to the workspace

## When *not* to use this

If the library is an **unmodified** third-party dependency (no patches, no native overlay ownership), **do not** fork/clone it here. Add an import to **[`egao1980/cl-stack-systems`](https://github.com/egao1980/cl-stack-systems)** instead:

```bash
cd cl-stack-systems && ./scripts/add-import.sh owner/repo <ref>
```

Use this skill only for forks you will patch, overlay packages you own, or first-party `egao1980` checkouts.

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
