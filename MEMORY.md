# Workspace memory

Durable **user instructions and preferences** for this Lisp workspace (similar in spirit to Claude Code’s project memory). **Agents should read this file** when starting work here and **edit it** when the user states a preference that should persist across sessions.

Keep entries **short and actionable**. Remove or supersede items that go stale.

---

## How to use

- **User:** add bullets under the sections below, or tell the agent to record something here.
- **Agent:** after the user gives a standing instruction (tool choice, style, workflow, “always…”, “never…”), add or update a line here and commit in `.lisp-workspace/` when appropriate.

---

## Preferences

<!-- Example: Prefer uv + ruff for Python touchpoints; line length 120; no black. -->

## Standing instructions

<!-- Example: Run tests before declaring done; use feature branches in subproject repos. -->

## Project-specific notes

<!-- Optional: quirks of cl-repository vs grpc vs … if not better placed in each repo’s AGENTS.md. -->
