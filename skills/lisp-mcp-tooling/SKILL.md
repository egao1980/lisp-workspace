---
name: lisp-mcp-tooling
description: >-
  First-party lisp-mcp server (egao1980/lisp-mcp): source-* (static, no eval), edit-* (structural,
  never unbalanced), repl-*/debug-*/inspect-* (Swank/Slynk image). Use when wiring or using the
  Lisp MCP, editing .lisp through MCP, or working on lisp-source-protocol / repl-protocol / backends.
---

# lisp-mcp

Repos: [`lisp-mcp`](https://github.com/egao1980/lisp-mcp) (server) · [`lisp-source-protocol`](https://github.com/egao1980/lisp-source-protocol) (CST, recovery, lint, edits) · [`repl-protocol`](https://github.com/egao1980/repl-protocol) + [`repl-backend-swank`](https://github.com/egao1980/repl-backend-swank) / [`repl-backend-slynk`](https://github.com/egao1980/repl-backend-slynk). MCP wire is `mcp-protocol` ≥ **0.3.0** (server notifications). Recipes: [cl-stack cookbook](https://github.com/egao1980/cl-stack/blob/main/docs/cookbooks/lisp-mcp.md).

## Wire it

In this workspace it is already wired: `.mcp.json` / `.cursor/mcp.json` (linked by `link-agent-config.sh`) run `.lisp-workspace/scripts/lisp-mcp.sh`. That installs the **published** `lisp-mcp` (`LISP_MCP_VERSION`, default 0.4.0) from GHCR, with `swank` and `slynk` as install roots in the same private tree, and execs a dumped executable in `~/.cache/lisp-mcp/` (first start builds it; `lisp-mcp.sh --build` / `bootstrap.sh` ahead of time; `--which` shows what runs). Developing lisp-mcp itself: `LISP_MCP_SOURCE=checkout` loads the sibling checkouts.

Elsewhere:

```bash
claude mcp add lisp-mcp -- ros +Q -- "$PWD/lisp-mcp/roswell/lisp-mcp.ros" --root "$PWD/<project>"
# flags: --transport http --port 3000 | --spawn swank|slynk | --attach host:port [--backend slynk]
```

stdout is JSON-RPC: the `.ros` launcher sends load output to stderr. Don't print to stdout in server code.

## Use it

| Step | Tool |
|------|------|
| Find | `source-outline`, `source-find-definitions`, `source-find-references`, `source-packages`; `live: true` adds the image's answer (`[image]`) |
| Read | `source-read` (`locator`) → form text + **file hash** |
| Check | `source-check` (reader errors, imbalances + fix position, lint) |
| Edit | `edit-replace` / `-insert` / `-delete` / `-wrap` / `-splice` / `-raise` / `-slurp` / `-barf` / `-transpose` / `-move` (also across files) / `-rename-symbol` / `-add-export` / `-repair` / `-new-file`; pass `expected_hash`, `dry_run` for the diff, `compile: true` to get the image's compiler notes for the changed forms in the same result. A miss lists close matches, and a stale hash shows the current form plus the hash to retry with, so there is no need to re-read. Inserted code is re-indented (standard table + image hints + project `defmacro` `&body`) |
| Run | `repl-spawn` (or `repl-connect`), `repl-compile` (form or file), `repl-load-system`, `repl-run-tests`, `repl-eval` |
| Debug | error → debugger **value**: `debug-backtrace`, `debug-frame-locals`, `debug-eval-in-frame`, `debug-step` (`into`/`next`/`out`), `inspect-condition`, `debug-invoke-restart` |
| Channels (Slynk) | `repl-channel-open` → `repl-eval {"channel"}` prints `#v<entry>:<i>`; `inspect-history`, `repl-channel-close` |
| Watch | resources `lisp-source:///{+path}`, `repl://{conn}/output`, `repl://{conn}/debugger` (subscribe), `repl://connections`; debugger entries arrive as `warning` log messages |
| Terse / verbose | output is terse by default (4 backtrace frames, written edits as `+a -b lines`, passing Rove checks dropped, no hints). Pass `verbose: true` only when you need the diff, the full backtrace or the hints; `--verbose` / `LISP_MCP_VERBOSE=1` flips the default |
| Long output | a result over 120 lines / 10k chars (4x with `verbose`) shows head + tail + `Stored as oN`: `output-read {"id":"oN","grep":"FAIL\|error"}` or `offset`/`limit`, or resource `lisp-output://oN[/lines/a-b\|/grep/p]`. Grep the stored output; don't re-run the build or test to see more |
| Long runs | `repl-eval` / `repl-compile` / `repl-load-system` / `repl-run-tests` / `debug-invoke-restart` / `debug-step` past their `timeout` (60 s; 300 load, 600 tests) keep running as **job jN** and return at once. Do **not** call it again: the same tool + arguments returns the running job. Wait for the `lisp-mcp/jobs` log message, or `job-status {"id":"jN"}` / `job-wait` (≤ 300 s); `job-list`; `job-cancel` interrupts it (then the job reports the debugger). Pass a larger `timeout` only to block longer |
| Inspect | `inspect` (`code` or `result` id from `repl-eval`), `inspect-part`, `inspect-back` |

Locators: `defun foo`, `defmethod print-object (my-class t)`, `path:0.2.1`, `line:12[:col]`, `offset:N`, `hash:H`. Never write `.lisp` with generic file tools when lisp-mcp is connected.

## Invariants (when changing the libraries)

- Source side never evaluates (`#.` → placeholder) or interns (`symbol-token`). Wire side never interns (`wire-symbol`); numbers parse only from strict number syntax.
- Broken files: a form that runs to EOF is re-read up to the next column-0 `(`; `imbalance` carries the fix. Edits refuse recovered nodes, sibling slots under `#+`/quote prefixes, the consing dot.
- `verify-plan` is the gate: no new reader errors/imbalances, declared top-level form delta. Corpus tests: `LISP_SOURCE_CORPUS=<dir>`.
- Swank evaluates `:emacs-rex` args → `rpc` quotes lists. Backends only map names (`rpc-symbol`); shared logic is `swank-family-connection`. Conformance: `repl-protocol/conformance` against a spawned image.
- `compile-file-for-emacs` only compiles; `repl-compile-file :load t` loads the fasl with `load-file` (SLIME does the same). An out-of-range restart gets no reply from the server, so `repl-invoke-restart` refuses it (`repl-invalid-restart`).
- Slynk mrepl announces a dedicated output socket (`:open-dedicated-output-stream port`) and blocks `create-mrepl` until the client connects; `inspect-entry` must run in the channel's thread.
- `repl-spawn` starts `ros +Q run` (no Quicklisp). Swank/Slynk load with `asdf:load-system`: `repl-protocol:system-registry-form` puts the directories where the server finds them (its cl-repo tree; GHCR `swank` / `slynk` are cl-stack-systems imports) in front of the child registry. Install them as `:ci :with` roots / launcher `:with`, never as `:depends-on` (the server must not load them).
- Do not set Swank's `*globally-redirect-io*` in a spawned image without an Emacs REPL: requests block after the first redirected write.
- Notifications: the image event listener runs on the wire reader thread; stdio writes are serialized by `rpc-backend-stdio`'s lock. Over HTTP only in-request notifications are delivered.
- Background jobs (lisp-mcp ≥ 0.4.0): the worker answers `repl-timeout` with `keep-waiting` and transfers its errors to the waiting call (restart `transfer-error`). Concurrent requests on one connection rely on repl-protocol ≥ 0.2.6 attributing a debugger level by the `:debug` event's continuations.
- lisp-mcp caches parsed files by write date + length; call `forget-source` after any write the server makes (same-second, same-length writes are otherwise invisible).

Legacy third-party server: skill **cl-mcp-tooling** (cl-ai-project/cl-mcp).
