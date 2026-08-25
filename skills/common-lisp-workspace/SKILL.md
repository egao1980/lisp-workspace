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
- **Deps / CI / publish:** skill **[cl-repository-ci](../cl-repository-ci/SKILL.md)** — canned GH Actions (`test-system.yml` / `publish-source.yml`), `.asd` `:cl-repo`, no copied `ci-*.lisp`. Qlot = legacy migrate-away.
- **Impl:** **Roswell** (`ros`) typical.
- **Tests:** **Rove** — **[cl-unit-testing](../cl-unit-testing/SKILL.md)**.

## Git

- Prefer **`github.com/egao1980/`**; fork third-party via `gh`; **upstream** remote on forks.
- **Source-only packages** (third-party or first-party): **`cl-stack-systems` import** — not a custom publish script. Fork/clone only for patches or **native overlays**. See [docs/REQUIREMENTS.md](../../docs/REQUIREMENTS.md) + **cl-repository-ci**.
- **Fork ↔ import exclusivity:** never both for the same upstream.
- **Rollback:** use `git restore` / `git revert` — not hand-edited recall.

## MCP (Lisp tools for agents)

- **`cl-mcp/`** — [cl-ai-project/cl-mcp](https://github.com/cl-ai-project/cl-mcp): MCP server (eval, **`inspect-object`**, ASDF, fs, code tools, tests); see **[cl-mcp-tooling](../cl-mcp-tooling/SKILL.md)** and [docs/cl-mcp.md](../../docs/cl-mcp.md).

## Devcontainers

- Sibling checkout **`features/`** — [egao1980/features](https://github.com/egao1980/features) (Roswell / Lem Features). See skill **[egao1980-devcontainers](../egao1980-devcontainers/SKILL.md)** and **[docker-devcontainers](../docker-devcontainers/SKILL.md)** for spec-level Docker/Dev Container guidance.

## Docs

- [`.lisp-workspace/AGENTS.md`](../AGENTS.md)
- [`.lisp-workspace/MEMORY.md`](../MEMORY.md) — durable user preferences
- [`.lisp-workspace/LESSONS_LEARNED.md`](../LESSONS_LEARNED.md)
