---
name: cl-mcp-tooling
description: >-
  cl-mcp (MCP framework) and cl-mcp-server (REPL + ~36 Lisp tools: evaluate-lisp, describe-symbol, ASDF, profiling).
  Use when wiring MCP for Cursor/Claude, debugging stdio MCP, running MCP Inspector, or editing MCP-related Lisp in
  workspace checkouts cl-mcp/ and cl-mcp-server/.
---

# cl-mcp + CL-MCP-Server

Upstream: [quasi/cl-mcp](https://github.com/quasi/cl-mcp) (framework), [quasi/cl-mcp-server](https://github.com/quasi/cl-mcp-server) (server + tools). This workspace keeps forks under **`cl-mcp/`** and **`cl-mcp-server/`** with **`upstream`** → `quasi/*` (see `add-cl-project.sh` ASDF snippets).

## Role

- **`cl-mcp`** — JSON-RPC/MCP framing, `make-server`, `register-tool`, `run-server`; also **client** API (`cl-mcp/client`).
- **`cl-mcp-server`** — Stateful Lisp REPL over MCP: **evaluate-lisp**, introspection (**describe-symbol**, **apropos-search**, **macroexpand-form**, …), ASDF helpers, Quicklisp tools, profiling, session **reset-session**, optional Telos tools — see upstream README “Available Tools”.

## Bootstrap (local dev)

1. Ensure both repos are on ASDF’s source path (workspace **`add-cl-project`** snippets under `~/.config/common-lisp/...`).
2. Install deps (Quicklisp **or** qlot per project — follow each repo’s README if it adds `qlfile`).
3. Quick sanity load:
   ```bash
   sbcl --eval "(require :asdf)" \
        --eval "(asdf:load-system :cl-mcp)" \
        --eval "(asdf:load-system :cl-mcp-server)" \
        --quit
   ```
4. Run the MCP server (adjust path to your workspace):
   ```bash
   sbcl --script /path/to/lisp/cl-mcp-server/run-server.lisp
   ```
   Point Cursor / Claude / other MCP clients at this **stdio** command (see upstream README for **claude mcp add** and JSON samples).

## MCP Inspector (debug any MCP server)

Official inspector: **`npx @modelcontextprotocol/inspector`** ([modelcontextprotocol/inspector](https://github.com/modelcontextprotocol/inspector)) — use to exercise tools and inspect JSON-RPC without the IDE.

## Cursor

Configure MCP in Cursor’s MCP settings with command **`sbcl`** (or `ros run` wrapper) and args **`--script`** + absolute path to **`cl-mcp-server/run-server.lisp`**. Restart the agent after changes.

## References

- Upstream integration notes: `cl-mcp/.claude/skills/integration/SKILL.md` (in checkout).
- Server docs: `cl-mcp-server/docs/` in checkout.
