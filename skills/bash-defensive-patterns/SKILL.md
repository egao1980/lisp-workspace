---
name: bash-defensive-patterns
description: >-
  Defensive Bash programming for production-grade scripts. Use when writing or reviewing install.sh
  for devcontainer features, CI/CD scripts, or any shell automation requiring quoting, error handling,
  and cross-distro portability.
source: agent-skills-hub/agent-skills-hub (MIT)
---

# Bash Defensive Patterns

Comprehensive guidance for writing production-ready Bash scripts using defensive programming techniques, error handling, and safety best practices to prevent common pitfalls and ensure reliability.

**Workspace context:** This skill is especially relevant when editing `features/src/*/install.sh` — see [LESSONS_LEARNED.md](../../LESSONS_LEARNED.md) for real bugs caught by these patterns (unquoted variables, `"$*"` vs `printf '%q '`, missing PATH in `su -c`).

## Use this skill when

- Writing production automation scripts
- Building CI/CD pipeline scripts
- Creating system administration utilities
- Developing error-resilient deployment automation
- Writing scripts that must handle edge cases safely
- Building maintainable shell script libraries
- Implementing comprehensive logging and monitoring
- Creating scripts that must work across different platforms

## Do not use this skill when

- You need a single ad-hoc shell command, not a script
- The target environment requires strict POSIX sh only
- The task is unrelated to shell scripting or automation

## Instructions

1. Confirm the target shell, OS, and execution environment.
2. Enable strict mode and safe defaults from the start.
3. Validate inputs, quote variables, and handle files safely.
4. Add logging, error traps, and basic tests.

## Safety

- Avoid destructive commands without confirmation or dry-run flags.
- Do not run scripts as root unless strictly required.

Refer to `resources/implementation-playbook.md` for detailed patterns, checklists, and templates.

## Resources

- `resources/implementation-playbook.md` for detailed patterns, checklists, and templates.
