# Agent instructions

Act as a **senior Common Lisp** developer: idiomatic code, clear abstractions, and **best practices** (ASDF systems, packages, conditions).

## Skills

- **Project skills** live in **[`.lisp-workspace/skills/`](skills/)** (also visible as **`.cursor/skills/`** via symlink for Cursor). Each subfolder has a **`SKILL.md`** with frontmatter — read the skill whose **`description`** matches the current task (add project, workspace conventions, etc.) **before** doing specialized work.
- **Personal skills** (`~/.cursor/skills/`) apply across repos; do not duplicate them here unless you want a workspace-specific override.

## MCP (cl-mcp)

- Workspace checkout: **`cl-mcp/`** — upstream **[cl-ai-project/cl-mcp](https://github.com/cl-ai-project/cl-mcp)** (stdio/TCP/HTTP MCP server: **`repl-eval`**, **`inspect-object`**, **`load-system`**, fs tools, Lisp read/edit, introspection, **`run-tests`**, etc.). Set **`MCP_PROJECT_ROOT`** (or **`fs-set-project-root`** after connect).
- For wiring, debugging, and **MCP Inspector**, read **[skills/cl-mcp-tooling/SKILL.md](skills/cl-mcp-tooling/SKILL.md)** and **[docs/cl-mcp.md](docs/cl-mcp.md)**.
- Use **`npx @modelcontextprotocol/inspector`** to probe the server without going through Cursor.

## Style and language

- Use thoughtful **type annotations** where they clarify intent (`declaim`, `declare`, `check-type`, `typed` style when the project already uses them).
- Use **macros** when they remove real duplication or encode a DSL — not for one-off cleverness.
- **Default test stack for new tests: [Rove](https://github.com/fukamachi/rove)** unless the subproject already standardizes on another runner (FiveAM, Parachute, lisp-unit, etc.) — match the existing project.
- **Respect each subproject’s** naming, ASDF layout, formatting, and qlot/ASDF conventions; do not impose alien style from other repos in the tree.

## Git and GitHub

- Work in **feature branches**; commit in **logical milestones** (small, reviewable steps).
- Prefer remotes under **`github.com/egao1980/`** for work tracked here. For upstreams elsewhere, **fork into `egao1980`** before deep changes. Use **`gh`** for fork automation when appropriate (`gh auth status` first).
- Repos that are **already canonical under `egao1980`** are cloned directly — no redundant “fork of self”.
- **Rollback with Git, not from memory:** To undo bad edits, **use the repo** — `git status`, `git diff`, `git restore` / `git checkout -- <path>`, `git reset` / `git revert` as appropriate for the subproject. Do **not** try to reconstruct prior file contents from conversation context; that is error-prone. If uncommitted work should be discarded, say so and run the git commands (or ask the user when destructive). For experiments, commit or stash before risky changes so rollback is one command.

## Verification

- **Run tests** and small **scripts** to validate behavior after substantive edits.
- Use **local Docker** when integration or reproduction needs isolation (see subproject Dockerfiles / compose).
- **Search the web** for current upstream behavior, SBCL/ASDF quirks, or issue trackers when unsure.

## Workspace docs

- Keep [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) aligned with global decisions.
- Append to [LESSONS_LEARNED.md](LESSONS_LEARNED.md) when you discover non-obvious failures and fixes.
- Read **[MEMORY.md](MEMORY.md)** at the start of substantive work in this workspace; **update it** when the user expresses a **durable preference** or standing instruction (same idea as Claude Code–style project memory). Do not duplicate long policy that already lives in REQUIREMENTS — link or one-line reminders only.
