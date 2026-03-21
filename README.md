# Lisp workspace housekeeping

Scripts and docs for this **multi-repo Common Lisp** tree live under **`.lisp-workspace/`** so the visible root stays mostly project checkouts. Cursor-specific rules stay in **`.cursor/rules/`**.

**This directory is its own Git repository.** Work here with `git add` / `git commit` so housekeeping stays separate from sibling checkouts (`cl-repository/`, `grpc/`, …). Default branch is **`main`**. Add `origin` when you want a remote (e.g. private `egao1980/lisp-workspace-meta`).

Flat checkout of interdependent projects (e.g. `cl-repository/`, `grpc/`, sibling libs). Prefer **Roswell** (`ros`), **qlot** per repo, and **ASDF** for systems — not global Quicklisp as the only story.

**`features/`** — checkout of [egao1980/features](https://github.com/egao1980/features) (Dev Container **Features** for Common Lisp: Roswell, Lem). Not an ASDF library; safe to ignore Lisp system discovery under that tree for coding tasks.

**`cl-mcp/`**, **`cl-mcp-server/`** — [quasi/cl-mcp](https://github.com/quasi/cl-mcp) + [quasi/cl-mcp-server](https://github.com/quasi/cl-mcp-server) (MCP tooling for Lisp: REPL, inspect/introspection tools). Bootstrap: [docs/cl-mcp.md](docs/cl-mcp.md).

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
| [MEMORY.md](MEMORY.md) | Durable user preferences and standing instructions (agents read/update) |
| [skills/](skills/) | Cursor **project skills** (`SKILL.md` per folder); hooked as **`.cursor/skills` → `skills/`** |
| [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) | Workspace requirements and Git policy |
| [docs/cl-mcp.md](docs/cl-mcp.md) | cl-mcp + cl-mcp-server bootstrap and MCP notes |
| [LESSONS_LEARNED.md](LESSONS_LEARNED.md) | Issues and fixes in practice |

## ASDF

Snippets are named `50-lisp-workspace-<name>.conf`. Override config root with `XDG_CONFIG_HOME` if needed.
