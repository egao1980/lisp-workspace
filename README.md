# Lisp workspace housekeeping

Scripts and docs for this **multi-repo Common Lisp** tree live under **`.lisp-workspace/`** so the visible root stays mostly project checkouts. Prefer private **[egao1980/cl-workspace](https://github.com/egao1980/cl-workspace)** as that root (submodule + `scripts/bootstrap.sh`).

**Agent config** is tool-neutral and lives here: [AGENTS.md](AGENTS.md) (all agents), [CLAUDE.md](CLAUDE.md) (imports AGENTS.md + Claude Code notes), [skills/](skills/), [rules/](rules/). Claude Code is the primary agent; Cursor works from the same files. At the **workspace root** (parent of `.lisp-workspace/`), bootstrap links them in:

```bash
./.lisp-workspace/scripts/link-agent-config.sh   # or ./scripts/bootstrap.sh in cl-workspace
```

**This directory is its own Git repository.** Work here with `git add` / `git commit` so housekeeping stays separate from sibling checkouts (`cl-repository/`, `grpc/`, …). Default branch is **`main`**. Remote: **[egao1980/lisp-workspace](https://github.com/egao1980/lisp-workspace)** (private).

Flat checkout of interdependent projects (e.g. `cl-repository/`, `grpc/`, sibling libs). Prefer **Roswell** (`ros`), **qlot** per repo, and **ASDF** for systems — not global Quicklisp as the only story.

**`features/`** — checkout of [egao1980/features](https://github.com/egao1980/features) (Dev Container **Features** for Common Lisp: Roswell, Lem). Not an ASDF library; safe to ignore Lisp system discovery under that tree for coding tasks.

**lisp-mcp** — first-party MCP server for Lisp ([egao1980/lisp-mcp](https://github.com/egao1980/lisp-mcp), skill **lisp-mcp-tooling**). **cl-mcp** — [cl-ai-project/cl-mcp](https://github.com/cl-ai-project/cl-mcp), the legacy alternative, is not part of the workspace by default. Bootstrap if needed: [docs/cl-mcp.md](docs/cl-mcp.md), skill **cl-mcp-tooling**.

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
| [AGENTS.md](AGENTS.md) | Expectations for AI/human contributors (all agents) |
| [CLAUDE.md](CLAUDE.md) | Claude Code entry point: `@AGENTS.md` + Claude notes |
| [MEMORY.md](MEMORY.md) | Durable prefs + index |
| [memory/](memory/) | On-demand stack notes (http, agent-wire, data, runtime, CI pins) |
| [skills/](skills/) | Project skills ([Agent Skills](https://agentskills.io/) `SKILL.md` per folder) |
| [rules/](rules/) | Path-scoped rules (`paths:` for Claude Code, `globs:` for Cursor) |
| [skills/README.md](skills/README.md) | Skill index + **staging mechanism** for iterative improvement |
| [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) | Workspace requirements and Git policy |
| [docs/cl-mcp.md](docs/cl-mcp.md) | cl-ai-project/cl-mcp bootstrap and MCP notes |
| [LESSONS_LEARNED.md](LESSONS_LEARNED.md) | Issues and fixes in practice |

## Claude Code plugin

This repo is also a Claude Code plugin marketplace, `cl-stack`, with one plugin, `lisp-workspace`. Use it in any Common Lisp project, with no submodule:

```text
/plugin marketplace add egao1980/lisp-workspace
/plugin install lisp-workspace@cl-stack
```

Or pre-configure a project's `.claude/settings.json`, so collaborators are offered the plugin when they trust the folder:

```json
{
  "extraKnownMarketplaces": {
    "cl-stack": { "source": { "source": "github", "repo": "egao1980/lisp-workspace" } }
  },
  "enabledPlugins": { "lisp-workspace@cl-stack": true }
}
```

| Piece | From |
|---|---|
| Skills (`lisp-workspace:asdf`, `lisp-workspace:cl-unit-testing`, …) | [`skills/`](skills/) |
| MCP servers `lisp-code` (`--tools code`) and `lisp-image` (`--tools image`) | [`scripts/lisp-mcp.sh`](scripts/lisp-mcp.sh), rooted at the project (`$CLAUDE_PROJECT_DIR`) |
| Conventions and rules as session context | SessionStart hook [`scripts/plugin-session-start.sh`](scripts/plugin-session-start.sh): prints [`plugin/context.md`](plugin/context.md) and [`rules/`](rules/) |

- **Why a hook.** Plugins load no `CLAUDE.md` and no path-scoped rules, so the hook prints them.
- **Toolchain checks.** It reports a missing Roswell or cl-repo client. When both are present, it starts the lisp-mcp executable build in the background, so the first MCP start is fast.
- **No double loading.** In a project that has `.lisp-workspace/` (cl-workspace), the hook prints nothing, because `CLAUDE.md` already loads `AGENTS.md`. Don't enable the plugin there as well, or the lisp-mcp servers run twice.

Prerequisites: [Roswell](https://roswell.github.io/) with SBCL, and the cl-repo client ([`install.sh`](https://github.com/egao1980/cl-repository#quick-start) from cl-repository). Check the plugin with `claude plugin validate .`. The manifest sets no `version`, so installs follow the latest commit on `main`.

Example project: [egao1980/cl-stack-sample](https://github.com/egao1980/cl-stack-sample).

## cl-stack-code harness

[`cl-stack-code`](https://github.com/egao1980/cl-stack-code) is the cl-stack coding agent: a terminal session, or headless `-p` runs. [`scripts/cl-stack-code.sh`](scripts/cl-stack-code.sh) installs the published package from GHCR and runs it as a fast-start executable. It works like `lisp-mcp.sh`.

### Install

You need [Roswell](https://roswell.github.io/) with SBCL and the cl-repo client ([`install.sh`](https://github.com/egao1980/cl-repository#quick-start)). Then get the launcher in one of three ways:

- **Submodule** (cl-workspace): `.lisp-workspace/scripts/cl-stack-code.sh`.
- **Plugin**: the `cl-stack` marketplace is a clone of this repo, so the launcher is at `~/.claude/plugins/marketplaces/cl-stack/scripts/cl-stack-code.sh`.
- **Direct download**: a copy of the script on its own fetches its build driver ([`scripts/cl-stack-code-launch.lisp`](scripts/cl-stack-code-launch.lisp)) on first build.

  ```bash
  mkdir -p ~/.local/bin
  curl -fsSL https://raw.githubusercontent.com/egao1980/lisp-workspace/main/scripts/cl-stack-code.sh \
    -o ~/.local/bin/cl-stack-code && chmod +x ~/.local/bin/cl-stack-code
  ```

A symlink to the launcher works as well (`ln -s …/scripts/cl-stack-code.sh ~/.local/bin/cl-stack-code`).

### Build

```bash
cl-stack-code.sh --build    # install from ghcr.io, dump ~/.cache/cl-stack-code/cl-stack-code-<version>-<lisp>
cl-stack-code.sh --which    # print the executable path; builds it first when missing
```

- **When it builds.** The first run builds the executable, which takes about two minutes. `bootstrap.sh` builds it ahead of time. After that, a start takes well under a second.
- **Pinned version.** The launcher pins the cl-stack-code version in one place, `VERSION` in the script. Override it with `CL_STACK_CODE_VERSION`.
- **Rebuilds.** The executable's name carries the version and the Roswell Lisp, so a new pin or a new SBCL builds a new executable and removes the old one. It also rebuilds when a native library it reopens at startup is gone, for example libuv or libcrypto after a cl-repo client upgrade.
- **Output.** Build output goes to stderr. The executable prints no banner.

### CLI

```bash
cl-stack-code.sh                                   # interactive terminal session
cl-stack-code.sh -p "fix the failing test" --permission-mode acceptEdits \
  --allowed-tools 'bash(cl-repo test *) bash(program:cl-repo)'
cl-stack-code.sh -p "…" --permission-mode plan     # changes go to a copy; add --apply to apply them
cl-stack-code.sh --help
```

Arguments pass straight through. See the [cl-stack-code README](https://github.com/egao1980/cl-stack-code#readme) for output formats, sessions (`-c`, `-r`), plan mode, permission rules and settings files (`.cl-stack-code/settings.json`).

**Shell rules.** A `bash` call is allowed only when every resource it touches is allowed. Each simple command has two resources: `bash:<words>` and `program:<argv0>`. So allowing `cl-repo test` takes two rules: `bash(cl-repo test *)` and `bash(program:cl-repo)`.

### Models

`--model provider` or `--model provider:model`. The default is `anthropic`.

| Provider | Key | Endpoint | Model |
|---|---|---|---|
| `anthropic` | `ANTHROPIC_API_KEY` (or `ANTHROPIC_AUTH_TOKEN`) | `ANTHROPIC_BASE_URL` (default api.anthropic.com) | `ANTHROPIC_MODEL` |
| `openai` (any OpenAI-compatible server) | `OPENAI_API_KEY` (or `LM_API_TOKEN`) | `OPENAI_BASE_URL` (default api.openai.com/v1) | `OPENAI_MODEL` |

```bash
# a local OpenAI-compatible server (LM Studio, llama.cpp, vLLM, Unsloth Studio, …)
export OPENAI_BASE_URL=http://localhost:1234/v1 OPENAI_API_KEY=… OPENAI_MODEL=qwen/qwen3-coder
cl-stack-code.sh --model openai -p "…"
```

`--model provider:model` splits at the first colon. For a model id that has a colon in it (`org/model:quant`), set `OPENAI_MODEL` and pass `--model openai`. Sampling parameters go in `--model-param KEY=VALUE` or in the `modelParams` settings object.

### Editors (ACP)

`cl-stack-code.sh --acp` will serve the Agent Client Protocol to editors, starting with cl-stack-code 0.11.0. With the current pin, it prints a "needs cl-stack-code >= 0.11.0" message. Instructions for Zed, Emacs and VS Code will follow with 0.11.0.

## Agent integration

One source, generated adapters. [`scripts/link-agent-config.sh`](scripts/link-agent-config.sh) writes symlinks at the workspace root (all gitignored there):

| Source (here) | Claude Code | Cursor |
|---|---|---|
| `AGENTS.md` | via `CLAUDE.md` → `@AGENTS.md` | root `AGENTS.md` symlink |
| `skills/<name>/` | `.claude/skills/<name>` (per skill) | `.cursor/skills` → `skills/` |
| `rules/<name>.md` | `.claude/rules/<name>.md` | `.cursor/rules/<name>.mdc` |

Tracked at the workspace root (cl-workspace), not generated: `CLAUDE.md` (`@.lisp-workspace/CLAUDE.md`), `.claude/settings.json` (cloud SessionStart hook), `.cursor/environment.json` + `Dockerfile` (Cursor Cloud).

Re-run the script after adding a skill or rule.

**MCP.** The script also links `.mcp.json` (Claude Code) and `.cursor/mcp.json` (Cursor) to [`mcp/`](mcp/): both start the first-party [`lisp-mcp`](https://github.com/egao1980/lisp-mcp) through [`scripts/lisp-mcp.sh`](scripts/lisp-mcp.sh), rooted at the workspace, as two servers: `lisp-code` (`--tools code`: source, edit, output) and `lisp-image` (`--tools image`: repl, debug, inspect, jobs, output). An agent that only reads and edits loads only the `lisp-code` tool definitions. The launcher installs the published `lisp-mcp` from GHCR into `~/.cache/lisp-mcp/` and runs a dumped executable (built on first start, or by `bootstrap.sh`). `LISP_MCP_SOURCE=checkout` runs the workspace checkouts instead, for working on lisp-mcp itself. Skill **lisp-mcp-tooling**.

## Dev Container

**`.devcontainer/`** provides an isolated CL environment so the host Quicklisp/Roswell stay clean.

```bash
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . ros run
```

- **Base:** `mcr.microsoft.com/devcontainers/base:ubuntu`
- **Feature:** `ghcr.io/egao1980/features/roswell:1` — Roswell + SBCL + **Ultralisp** dist + qlot
- **Post-create** (`post-create.sh`): runs bootstrap, writes ASDF snippets for all workspace projects
- **Claude Code:** `ghcr.io/anthropics/devcontainer-features/claude-code:1.0` (run `claude` inside the container)

## ASDF

Snippets are named `50-lisp-workspace-<name>.conf`. Override config root with `XDG_CONFIG_HOME` if needed.
