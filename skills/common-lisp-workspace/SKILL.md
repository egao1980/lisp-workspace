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

## Docs

- [`.lisp-workspace/AGENTS.md`](../AGENTS.md)
- [`.lisp-workspace/MEMORY.md`](../MEMORY.md) — durable user preferences
- [`.lisp-workspace/LESSONS_LEARNED.md`](../LESSONS_LEARNED.md)
