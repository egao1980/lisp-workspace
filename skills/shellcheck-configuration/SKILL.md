---
name: shellcheck-configuration
description: >-
  ShellCheck for install.sh / CI shell. Use when linting Bash/sh — quoting, undefined vars, portability.
---

# ShellCheck

Workspace: `shellcheck features/src/*/install.sh` before committing feature changes.
Bugs we hit: SC2086 unquoted vars, SC2046 word splitting. See [LESSONS_LEARNED.md](../../LESSONS_LEARNED.md).

```bash
brew install shellcheck   # or apt-get install shellcheck
shellcheck --shell=bash features/src/*/install.sh
```

Config / codes / CI / suppressions: [resources/reference.md](resources/reference.md). Quoting / `su -c`: [bash-defensive-patterns](../bash-defensive-patterns/SKILL.md).
