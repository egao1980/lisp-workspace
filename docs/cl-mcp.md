# cl-mcp bootstrap (this workspace)

Not cloned by default (dropped from `repos.manifest` 2026-11-06). To use it: `./.lisp-workspace/scripts/add-cl-project.sh egao1980/cl-mcp`. Upstream **[cl-ai-project/cl-mcp](https://github.com/cl-ai-project/cl-mcp)** (fork **`egao1980/cl-mcp`**). Remotes: **`origin`** → `egao1980`, **`upstream`** → `cl-ai-project`.

## What it is

One **MCP server** for Common Lisp: **stdio**, **TCP**, or **HTTP**; structured tools for REPL eval, ASDF **`load-system`**, **`inspect-object`**, project-scoped **fs-***, Lisp-aware read/edit, **`code-find`** / xref, **`clhs-lookup`**, **`run-tests`**, etc. See **`cl-mcp/README.md`** for the full list and protocol versions.

## Project root

Set **`MCP_PROJECT_ROOT`** to your project directory before starting the server. If unset, call the **`fs-set-project-root`** tool immediately after connecting.

## Load and run (examples)

```bash
export MCP_PROJECT_ROOT=/path/to/your/project
ros run -s cl-mcp -e "(cl-mcp:run :transport :stdio)"
```

ASDF-only:

```bash
export MCP_PROJECT_ROOT=$(pwd)
sbcl --eval "(require :asdf)" \
     --eval "(asdf:load-system :cl-mcp)" \
     --eval "(cl-mcp:run :transport :stdio)"
```

Wire that command into **Cursor MCP**, Claude Code, or **MCP Inspector** (`npx @modelcontextprotocol/inspector`) for debugging.

## Skill

See **[`../skills/cl-mcp-tooling/SKILL.md`](../skills/cl-mcp-tooling/SKILL.md)** for agent-oriented notes (worker pool, env vars).
