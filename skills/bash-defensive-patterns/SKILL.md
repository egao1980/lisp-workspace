---
name: bash-defensive-patterns
description: >-
  Defensive Bash for install.sh / CI: quoting, error handling, portability.
  Use when writing or reviewing feature install.sh or shell automation.
source: agent-skills-hub/agent-skills-hub (MIT)
---

# Bash Defensive Patterns

Especially for `features/src/*/install.sh`. Real bugs: [LESSONS_LEARNED.md](../../LESSONS_LEARNED.md) (unquoted vars, `"$*"` vs `printf '%q '`, missing PATH in `su -c`).

1. Confirm target shell, OS, and execution environment.
2. Strict mode + safe defaults from the start.
3. Validate inputs, quote variables, handle files safely.
4. Logging, error traps, basic tests.
5. No destructive commands without confirmation / dry-run. No root unless required.

Patterns / checklists / templates: [resources/implementation-playbook.md](resources/implementation-playbook.md).
