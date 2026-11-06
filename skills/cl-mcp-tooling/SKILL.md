---
name: cl-mcp-tooling
description: >-
  cl-mcp (cl-ai-project): repl-eval, inspect-object, load-system, lisp-edit-form, run-tests,
  MCP_PROJECT_ROOT. Use when wiring/debugging MCP or editing cl-mcp/.
---

# cl-mcp (cl-ai-project)

Upstream: **[cl-ai-project/cl-mcp](https://github.com/cl-ai-project/cl-mcp)** — one repo (JSON-RPC/MCP, tools, transports). This workspace keeps **`cl-mcp/`** with **`origin`** → `egao1980/cl-mcp`, **`upstream`** → `cl-ai-project/cl-mcp` (see `add-cl-project.sh` ASDF snippet).

## Role

Single **MCP server** image: **stdio**, **TCP**, or **HTTP** (Streamable HTTP). Tools include **`repl-eval`** (with **`result_object_id`** + **`inspect-object`** for complex values), **`load-system`**, **`fs-*`**, **`lisp-read-file`**, **`lisp-edit-form`** / **`lisp-patch-form`**, **`code-find`** / **`code-describe`** / **`code-find-references`**, **`clhs-lookup`**, **`run-tests`**, **`clgrep-search`**, **`lisp-check-parens`**, **`pool-status`** / **`pool-kill-worker`**. Eval-heavy tools run in an **isolated worker SBCL** by default; set **`MCP_NO_WORKER_POOL=1`** for single-process mode.

## Bootstrap (local dev)

1. Ensure **`cl-mcp/`** is on ASDF’s source path (workspace **`add-cl-project`** snippet under `~/.config/common-lisp/...`).
2. Install deps (Quicklisp and/or qlot per that repo’s README).
3. **Set project root** before start: **`export MCP_PROJECT_ROOT=/path/to/project`** (or call **`fs-set-project-root`** right after connect).
4. Quick sanity load:
   ```bash
   sbcl --eval "(require :asdf)" \
        --eval "(asdf:load-system :cl-mcp)" \
        --quit
   ```
5. **Stdio** (one JSON-RPC line per message):
   ```bash
   export MCP_PROJECT_ROOT=$(pwd)
   ros run -s cl-mcp -e "(cl-mcp:run :transport :stdio)"
   ```
   Point Cursor / Claude / other MCP clients at this command. For **HTTP** (e.g. Claude Code sharing the same REPL), load **`cl-mcp`** in a REPL and **`(cl-mcp:start-http-server :port 3000)`** — see upstream README.

## MCP Inspector (debug any MCP server)

**`npx @modelcontextprotocol/inspector`** ([modelcontextprotocol/inspector](https://github.com/modelcontextprotocol/inspector)) — exercise tools and inspect JSON-RPC without the IDE.

## Cursor

Configure MCP with command **`ros`** (or **`sbcl`**) and args that load **`:cl-mcp`** and call **`(cl-mcp:run …)`**, with env **`MCP_PROJECT_ROOT`** set (often **`${workspaceFolder}`**). Restart the agent after changes.

Syntax without the server: skill **cl-static-eclector** (`scripts/static-eclector.lisp`). That path does not eval.

## References

- Upstream README: **`cl-mcp/README.md`** in checkout — full tool list, env vars, security notes.
