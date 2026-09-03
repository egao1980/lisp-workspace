---
name: common-lisp-workspace
description: >-
  Multi-repo CL workspace conventions (ASDF registry, egao1980 forks, Rove default).
  Use when navigating this tree or before large cross-repo edits.
---

# Lisp workspace context

Router — do not duplicate AGENTS / MEMORY / other skills here.

| Need | Open |
|------|------|
| Always-on policy | [AGENTS.md](../../AGENTS.md) |
| Prefs + stack index | [MEMORY.md](../../MEMORY.md) |
| CI / publish | [cl-repository-ci](../cl-repository-ci/SKILL.md) |
| Tests | [cl-unit-testing](../cl-unit-testing/SKILL.md) |
| Errors | [cl-stack-conditions](../cl-stack-conditions/SKILL.md) |
| MCP | [cl-mcp-tooling](../cl-mcp-tooling/SKILL.md) |
| Devcontainers | [egao1980-devcontainers](../egao1980-devcontainers/SKILL.md) · [docker-devcontainers](../docker-devcontainers/SKILL.md) |
| Policy | [REQUIREMENTS.md](../../docs/REQUIREMENTS.md) |
| Gotchas | [LESSONS_LEARNED.md](../../LESSONS_LEARNED.md) |

- **ASDF:** `~/.config/common-lisp/source-registry.conf.d/50-lisp-workspace-*.conf` from add-cl-project.
- **Impl:** Roswell (`ros`). Qlot = legacy migrate-away.
- **Git:** `github.com/egao1980/`; fork ↔ import exclusive. Rollback with git, not recall.
