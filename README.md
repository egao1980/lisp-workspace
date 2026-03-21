# Lisp workspace housekeeping

Scripts and docs for this **multi-repo Common Lisp** tree live under **`.lisp-workspace/`** so the visible root stays mostly project checkouts. Cursor-specific rules stay in **`.cursor/rules/`**.

**This directory is its own Git repository** (`git init` here). Commit script and doc changes under `.lisp-workspace/` without tying them to sibling project repos (`cl-repository/`, `grpc/`, etc.). Add a remote when you want to back up or share housekeeping (e.g. a private `egao1980/lisp-workspace-meta` repo).

Flat checkout of interdependent projects (e.g. `cl-repository/`, `grpc/`, sibling libs). Prefer **Roswell** (`ros`), **qlot** per repo, and **ASDF** for systems — not global Quicklisp as the only story.

## Add a project from GitHub

Use [`.lisp-workspace/scripts/add-cl-project.sh`](scripts/add-cl-project.sh):

- **Third-party upstream** (`qitab/cl-protobufs`): the script **runs `gh repo fork`**, verifies the fork, clones, sets **`upstream`**, writes ASDF config. You need **`gh auth`**.
  ```bash
  gh auth status
  ./.lisp-workspace/scripts/add-cl-project.sh qitab/cl-protobufs
  ```
  Clones `https://github.com/egao1980/<repo>.git` into the workspace root; snippet under `~/.config/common-lisp/source-registry.conf.d/`. Use **`--no-fork`** to skip the fork step if the repo already exists.
- **Already under `egao1980`**: `./.lisp-workspace/scripts/add-cl-project.sh egao1980/myproject` clones without forking.
- Options: `--qlot`, `--quicklisp`, `--no-fork`, `--upstream URL`, `--workspace PATH`. See `./.lisp-workspace/scripts/add-cl-project.sh --help`.

Remove wiring (optional delete tree with `--purge`):

```bash
./.lisp-workspace/scripts/remove-cl-project.sh [--quicklisp] [--purge] <project-name>
```

## Docs (this folder)

| File | Role |
|------|------|
| [AGENTS.md](AGENTS.md) | Expectations for AI/human contributors |
| [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) | Workspace requirements and Git policy |
| [LESSONS_LEARNED.md](LESSONS_LEARNED.md) | Issues and fixes in practice |

## ASDF

Snippets are named `50-lisp-workspace-<name>.conf`. Override config root with `XDG_CONFIG_HOME` if needed.
