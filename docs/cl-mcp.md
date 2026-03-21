# cl-mcp bootstrap (this workspace)

Siblings: **`cl-mcp/`** ([quasi/cl-mcp](https://github.com/quasi/cl-mcp)), **`cl-mcp-server/`** ([quasi/cl-mcp-server](https://github.com/quasi/cl-mcp-server)). Remotes: **`origin`** = `egao1980`, **`upstream`** = `quasi`.

## Why two repos

- **`cl-mcp`** — MCP protocol library (server + client).
- **`cl-mcp-server`** — Depends on **`:cl-mcp`**; exposes the REPL and tool surface agents use.

## Load and run

After Quicklisp/qlot deps are satisfied for both projects:

```bash
sbcl --eval "(require :asdf)" \
     --eval "(asdf:load-system :cl-mcp-server)" \
     --quit
```

Run the stdio server (path = your machine):

```bash
sbcl --script "$LISP_WS/cl-mcp-server/run-server.lisp"
```

Wire that command into **Cursor MCP**, Claude Code (`claude mcp add …`), or **MCP Inspector** (`npx @modelcontextprotocol/inspector`) for debugging.

## Skill

See **[`../skills/cl-mcp-tooling/SKILL.md`](../skills/cl-mcp-tooling/SKILL.md)** for agent-oriented instructions.
