---
name: lisp-mcp-tooling
description: >-
  First-party lisp-mcp server (egao1980/lisp-mcp): source-* (static, no eval), edit-* (structural,
  never unbalanced), repl-*/debug-*/inspect-* (Swank/Slynk image). Use when wiring or using the
  Lisp MCP, editing .lisp through MCP, or working on lisp-source-protocol / repl-protocol / backends.
---

# lisp-mcp

Repos: [`lisp-mcp`](https://github.com/egao1980/lisp-mcp) (server) · [`lisp-source-protocol`](https://github.com/egao1980/lisp-source-protocol) (CST, recovery, lint, edits) · [`repl-protocol`](https://github.com/egao1980/repl-protocol) + [`repl-backend-swank`](https://github.com/egao1980/repl-backend-swank) / [`repl-backend-slynk`](https://github.com/egao1980/repl-backend-slynk). MCP wire is `mcp-protocol` ≥ **0.2.1** (tool annotations).

## Wire it

```bash
claude mcp add lisp-mcp -- ros -Q -- "$PWD/lisp-mcp/roswell/lisp-mcp.ros" --root "$PWD/<project>"
# flags: --transport http --port 3000 | --spawn swank|slynk | --attach host:port [--backend slynk]
```

stdout is JSON-RPC: the `.ros` launcher sends load output to stderr. Don't print to stdout in server code.

## Use it

| Step | Tool |
|------|------|
| Find | `source-outline`, `source-find-definitions`, `source-find-references` |
| Read | `source-read` (`locator`) → form text + **file hash** |
| Check | `source-check` (reader errors, imbalances + fix position, lint) |
| Edit | `edit-replace` / `-insert` / `-delete` / `-wrap` / `-splice` / `-raise` / `-slurp` / `-barf` / `-transpose` / `-rename-symbol` / `-add-export` / `-repair` / `-new-file`; pass `expected_hash`, `dry_run` for the diff |
| Run | `repl-spawn` (or `repl-connect`), `repl-compile` (form or file), `repl-load-system`, `repl-run-tests`, `repl-eval` |
| Debug | error → debugger **value**: `debug-backtrace`, `debug-frame-locals`, `debug-eval-in-frame`, `inspect-condition`, `debug-invoke-restart` |
| Inspect | `inspect` (`code` or `result` id from `repl-eval`), `inspect-part`, `inspect-back` |

Locators: `defun foo`, `defmethod print-object (my-class t)`, `path:0.2.1`, `line:12[:col]`, `offset:N`, `hash:H`. Never write `.lisp` with generic file tools when lisp-mcp is connected.

## Invariants (when changing the libraries)

- Source side never evaluates (`#.` → placeholder) or interns (`symbol-token`). Wire side never interns (`wire-symbol`); numbers parse only from strict number syntax.
- Broken files: a form that runs to EOF is re-read up to the next column-0 `(`; `imbalance` carries the fix. Edits refuse recovered nodes, sibling slots under `#+`/quote prefixes, the consing dot.
- `verify-plan` is the gate: no new reader errors/imbalances, declared top-level form delta. Corpus tests: `LISP_SOURCE_CORPUS=<dir>`.
- Swank evaluates `:emacs-rex` args → `rpc` quotes lists. Backends only map names (`rpc-symbol`); shared logic is `swank-family-connection`. Conformance: `repl-protocol/conformance` against a spawned image.

Legacy third-party server: skill **cl-mcp-tooling** (cl-ai-project/cl-mcp).
