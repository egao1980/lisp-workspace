---
name: common-lisp-workspace
description: >-
  Multi-repo Common Lisp workspace: Roswell, qlot, pure ASDF, egao1980 GitHub forks, Rove tests by default,
  senior CL style. Use when navigating this tree, choosing test frameworks, ASDF/registry issues, or
  cross-repo Common Lisp conventions — read before large edits.
---

# Lisp workspace context

## Stack

- **ASDF:** `~/.config/common-lisp/source-registry.conf.d/50-lisp-workspace-*.conf` from add-cl-project.
- **Deps:** **cl-repository** → `ghcr.io/egao1980/cl-systems` (`scripts/ci-install.lisp` / `ci-test.lisp`). Bootstrap **`cl-repository-client` from OCI** (`ghcr.io/egao1980/cl-repository/cl-repository-client:<ver>`). **No sibling CI checkouts** — only the repo under test; never git-checkout `cl-repository` or other deps for install. Qlot = legacy on unmigrated checkouts only; do not ship `qlfile` as the install story for new repos.
- **Impl:** **Roswell** (`ros`) typical.
- **Tests:** **Rove** for new tests unless the subproject already uses another runner.

## Git

- Prefer **`github.com/egao1980/`**; fork third-party via `gh`; **upstream** remote on forks.
- **Unforked deps:** add to **`egao1980/cl-stack-systems`** (`imports/<name>/qlfile`) → publish to `ghcr.io/egao1980/cl-systems`. Do not fork/clone into the workspace unless patching or owning native overlays. See [docs/REQUIREMENTS.md](../../docs/REQUIREMENTS.md).
- **Fork ↔ import exclusivity:** never both. On fork, delete `cl-stack-systems/imports/<name>/`. On import, do not keep a workspace fork.
- **Rollback:** use `git restore` / `git revert` — not hand-edited recall.

## MCP (Lisp tools for agents)

- **`cl-mcp/`** — [cl-ai-project/cl-mcp](https://github.com/cl-ai-project/cl-mcp): MCP server (eval, **`inspect-object`**, ASDF, fs, code tools, tests); see **[cl-mcp-tooling](../cl-mcp-tooling/SKILL.md)** and [docs/cl-mcp.md](../../docs/cl-mcp.md).

## Devcontainers

- Sibling checkout **`features/`** — [egao1980/features](https://github.com/egao1980/features) (Roswell / Lem Features). See skill **[egao1980-devcontainers](../egao1980-devcontainers/SKILL.md)** and **[docker-devcontainers](../docker-devcontainers/SKILL.md)** for spec-level Docker/Dev Container guidance.

## Docs

- [`.lisp-workspace/AGENTS.md`](../AGENTS.md)
- [`.lisp-workspace/MEMORY.md`](../MEMORY.md) — durable user preferences
- [`.lisp-workspace/LESSONS_LEARNED.md`](../LESSONS_LEARNED.md)
