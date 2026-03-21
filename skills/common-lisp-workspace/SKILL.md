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
- **Deps:** **qlot** per subproject when present; not only global Quicklisp.
- **Impl:** **Roswell** (`ros`) typical.
- **Tests:** **Rove** for new tests unless the subproject already uses another runner.

## Git

- Prefer **`github.com/egao1980/`**; fork third-party via `gh`; **upstream** remote on forks.
- **Rollback:** use `git restore` / `git revert` — not hand-edited recall.

## MCP (Lisp tools for agents)

- **`cl-mcp/`** + **`cl-mcp-server/`** — MCP server with persistent REPL and many introspection/edit-adjacent tools; see **[cl-mcp-tooling](../cl-mcp-tooling/SKILL.md)** and [docs/cl-mcp.md](../../docs/cl-mcp.md).

## Devcontainers

- Sibling checkout **`features/`** — [egao1980/features](https://github.com/egao1980/features) (Roswell / Lem Features). See skill **[egao1980-devcontainers](../egao1980-devcontainers/SKILL.md)** and **[docker-devcontainers](../docker-devcontainers/SKILL.md)** for spec-level Docker/Dev Container guidance.

## Docs

- [`.lisp-workspace/AGENTS.md`](../AGENTS.md)
- [`.lisp-workspace/MEMORY.md`](../MEMORY.md) — durable user preferences
- [`.lisp-workspace/LESSONS_LEARNED.md`](../LESSONS_LEARNED.md)
