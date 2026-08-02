# Lisp workspace housekeeping

Scripts and docs for this **multi-repo Common Lisp** tree live under **`.lisp-workspace/`** so the visible root stays mostly project checkouts. Prefer private **[egao1980/cl-workspace](https://github.com/egao1980/cl-workspace)** as that root (submodule + `scripts/bootstrap.sh`).

**Cursor config** (`rules/`, `commands/`, `mcp.json`) lives in **`.lisp-workspace/.cursor/`** (this repo). At the **workspace root** (parent of `.lisp-workspace/`), bootstrap (or manually) symlink:

```bash
ln -sfn .lisp-workspace/.cursor .cursor
ln -sfn .lisp-workspace/AGENTS.md AGENTS.md
ln -sfn .lisp-workspace/LESSONS_LEARNED.md LESSONS_LEARNED.md
```

**`.lisp-workspace/.cursor/skills`** → **`../skills`** (no duplicate skill trees).

**This directory is its own Git repository.** Work here with `git add` / `git commit` so housekeeping stays separate from sibling checkouts (`cl-repository/`, `grpc/`, …). Default branch is **`main`**. Remote: **[egao1980/lisp-workspace](https://github.com/egao1980/lisp-workspace)** (private).

Flat checkout of interdependent projects (e.g. `cl-repository/`, `grpc/`, sibling libs). Prefer **Roswell** (`ros`), **qlot** per repo, and **ASDF** for systems — not global Quicklisp as the only story.

**`features/`** — checkout of [egao1980/features](https://github.com/egao1980/features) (Dev Container **Features** for Common Lisp: Roswell, Lem). Not an ASDF library; safe to ignore Lisp system discovery under that tree for coding tasks.

**`cl-mcp/`** — [cl-ai-project/cl-mcp](https://github.com/cl-ai-project/cl-mcp) (MCP server for Lisp: eval, inspect, ASDF, fs, structure-aware edit, tests). Bootstrap: [docs/cl-mcp.md](docs/cl-mcp.md).

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

### Windows: GitHub Actions self-hosted runner

Personal accounts are **repo-scoped** — run once per `owner/repo` (separate dir + service). Elevated PowerShell:

```powershell
.\.lisp-workspace\scripts\Install-GhaRunner.ps1 -Repo egao1980/cl-stack
.\.lisp-workspace\scripts\Install-GhaRunner.ps1 -Repo egao1980/grpc
```

Requires `gh auth` with repo admin (or pass `-Token`). Installs under `C:\actions-runners\<owner>\<repo-name>\` (one dir + service per `owner/repo`). Re-run replaces an existing registration (`config.cmd --replace`); bump `-RunnerVer` to stage that release then overlay binaries (stamped in `.gha-runner-ver`). Optional `-RunnerName` (≤64 chars). Workflow target: `runs-on: [self-hosted, windows, x64, overlay]`.

## Docs (this folder)

| File | Role |
|------|------|
| [AGENTS.md](AGENTS.md) | Expectations for AI/human contributors |
| [MEMORY.md](MEMORY.md) | Durable user preferences and standing instructions (agents read/update) |
| [skills/](skills/) | Cursor **project skills** (`SKILL.md` per folder); **`.lisp-workspace/.cursor/skills` → `../skills`** |
| [skills/README.md](skills/README.md) | Skill index + **staging mechanism** for iterative improvement |
| [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) | Workspace requirements and Git policy |
| [docs/cl-mcp.md](docs/cl-mcp.md) | cl-ai-project/cl-mcp bootstrap and MCP notes |
| [LESSONS_LEARNED.md](LESSONS_LEARNED.md) | Issues and fixes in practice |

## Cursor integration

| Path | Role |
|------|------|
| [`.cursor/`](.cursor/) | Rules, commands, `mcp.json` (versioned here). At workspace root: **`.cursor` → `.lisp-workspace/.cursor`**. |
| Root `AGENTS.md` / `LESSONS_LEARNED.md` | Symlinks → this folder so agents see them at the workspace root. |
| `.cursor/mcp.json` | cl-mcp MCP server config (stdio via `ros`) |
| `.cursor/rules/` | Project rules (always-apply workspace rule + glob-scoped Lisp REPL rule) |
| `.cursor/commands/` | `/load-and-test`, `/review-skill-improvements` |
| `.cursor/skills` → `../skills` | Symlink so Cursor discovers **this** `skills/` tree (no second copy) |

## Dev Container

**`.devcontainer/`** provides an isolated CL environment so the host Quicklisp/Roswell stay clean.

```bash
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . ros run
```

- **Base:** `mcr.microsoft.com/devcontainers/base:ubuntu`
- **Feature:** `ghcr.io/egao1980/features/roswell:1` — Roswell + SBCL + **Ultralisp** dist + qlot
- **Post-create** (`post-create.sh`): writes ASDF snippets for all workspace projects, installs cl-mcp deps via Quicklisp+Ultralisp, verifies cl-mcp loads
- **Env:** `MCP_PROJECT_ROOT` is set to the container workspace folder

## ASDF

Snippets are named `50-lisp-workspace-<name>.conf`. Override config root with `XDG_CONFIG_HOME` if needed.
