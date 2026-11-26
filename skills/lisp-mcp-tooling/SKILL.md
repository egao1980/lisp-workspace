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

In this workspace it is already wired: `.mcp.json` / `.cursor/mcp.json` (linked by `link-agent-config.sh`) and the plugin manifest run `.lisp-workspace/scripts/lisp-mcp.sh` as **two servers**: `lisp-code` (`--tools code`) and `lisp-image` (`--tools image`). That installs the **published** `lisp-mcp` (`LISP_MCP_VERSION`, default 0.7.4) from GHCR, with `swank` and `slynk` as install roots in the same private tree, and execs a dumped executable in `~/.cache/lisp-mcp/` (first start builds it; `lisp-mcp.sh --build` / `bootstrap.sh` ahead of time; `--which` shows what runs). Developing lisp-mcp itself: `LISP_MCP_SOURCE=checkout` loads the sibling checkouts.

Elsewhere:

```bash
claude mcp add lisp-mcp -- ros +Q -- "$PWD/lisp-mcp/roswell/lisp-mcp.ros" --root "$PWD/<project>"
# flags: --transport http --port 3000 | --spawn swank|slynk | --attach host:port [--backend slynk]
#        --tools GROUPS (or LISP_MCP_TOOLS)
```

**Tool groups (≥ 0.5.0).** `--tools` takes a comma list of `source`, `edit`, `output`, `repl`, `debug`, `inspect`, `jobs`, or a preset: `code` = source,edit,output; `image` = repl,debug,inspect,jobs,output; `all` (default). Instructions, resources (`repl://` with the image groups) and image log messages follow the groups. Without an image group the source/edit schemas drop `live`, `compile` and `connection`. The two servers are separate processes, so `compile: true` on an edit and `live: true` on a source tool need `--tools all`; in the split, compile with `repl-compile` (`path` + `locator`) on `lisp-image`. Claude Code tool names: `mcp__lisp-code__edit-replace`, `mcp__lisp-image__repl-eval`.

stdout is JSON-RPC: the `.ros` launcher sends load output to stderr. Don't print to stdout in server code.

## Use it

| Step | Tool |
|------|------|
| Find | `source-outline`, `source-find-definitions`, `source-find-references`, `source-packages`; `live: true` adds the image's answer (`[image]`) |
| Read | `source-read` (`locator`) → form text + **file hash** |
| Check | `source-check` (reader errors, imbalances + fix position, lint) |
| Edit | `edit-replace` / `-insert` / `-delete` / `-rename-symbol` / `-add-export` / `-new-file`, and `edit-structure` with `op` `wrap` (`head`) / `splice` / `raise` / `slurp` / `barf` (`direction`) / `transpose` / `move` (`target_locator`, `target_path`: also across files) / `repair` (`index`, no locator). 0.5.0 removed the separate `edit-wrap` … `edit-move`, `edit-repair` tools. Pass `expected_hash`, `dry_run` for the diff, `compile: true` to get the image's compiler notes for the changed forms in the same result. A miss lists close matches, and a stale hash shows the current form plus the hash to retry with, so there is no need to re-read. Inserted code keeps its comments and is re-indented in place (standard table + image hints + project `defmacro` `&body`, in the context of the enclosing forms) |
| Run | `repl-spawn` (or `repl-connect`), `repl-compile` (form or file), `repl-load-system`, `repl-run-tests`, `repl-eval` |
| Debug | error → debugger **value**: `debug-backtrace`, `debug-frame-locals`, `debug-eval-in-frame`, `debug-step` (`into`/`next`/`out`), `inspect-condition`, `debug-invoke-restart` |
| Channels (Slynk) | `repl-channel-open` → `repl-eval {"channel"}` prints `#v<entry>:<i>`; `inspect-history`, `repl-channel-close` |
| Watch | resources `lisp-source:///{+path}`, `repl://{conn}/output`, `repl://{conn}/debugger` (subscribe), `repl://connections`; debugger entries arrive as `warning` log messages |
| Terse / verbose | output is terse by default (4 backtrace frames, written edits as `+a -b lines`, passing Rove checks dropped, no hints). Pass `verbose: true` only when you need the diff, the full backtrace or the hints; `--verbose` / `LISP_MCP_VERBOSE=1` flips the default |
| Long output | a result over 120 lines / 10k chars (4x with `verbose`) shows head + tail + `Stored as oN`: `output-read {"id":"oN","grep":"FAIL\|error"}` or `offset`/`limit`, or resource `lisp-output://oN[/lines/a-b\|/grep/p]`. Grep the stored output; don't re-run the build or test to see more |
| Long runs | `repl-eval` / `repl-compile` / `repl-load-system` / `repl-run-tests` / `debug-invoke-restart` / `debug-step` past their `timeout` (60 s; 300 load, 600 tests) keep running as **job jN** and return at once. Do **not** call it again: the same tool + arguments returns the running job. Wait for the `lisp-mcp/jobs` log message, or `job-status {"id":"jN"}` / `job-wait` (≤ 300 s); `job-list`; `job-cancel` interrupts it (then the job reports the debugger). Pass a larger `timeout` only to block longer |
| Inspect | `inspect` (`code` or `result` id from `repl-eval`), `inspect-part`, `inspect-back` |

Locators: `defun foo`, `defmethod print-object (my-class t)`, `path:0.2.1`, `line:12[:col]`, `offset:N`, `hash:H`, `comment:N[-M]` (lisp-mcp ≥ 0.7.4: the comment lines starting on line N, through M; `line:N` on a top-level comment gives the same block; `source-outline` lists top-level blocks as `[comment:N]`). `edit-replace` (comments and/or forms) and `edit-delete` work on a comment block between forms. Never write `.lisp` with generic file tools when lisp-mcp is connected.

## Invariants (when changing the libraries)

- Source side never evaluates (`#.` → placeholder) or interns (`symbol-token`). Wire side never interns (`wire-symbol`); numbers parse only from strict number syntax.
- Reader conditionals are source (lisp-source-protocol ≥ 0.2.5, lisp-mcp ≥ 0.7.2): every `#+`/`#-` is a `:feature-conditional` form whatever the server's features, an excluded branch re-read as plain Lisp (`feature-excluded-p`). Outline, locators, references and edits see every branch; insert / delete / transpose / move on a branch's form act on the whole conditional. Features never decide what an edit writes. Comments in edit code are source too (lisp-source-protocol ≥ 0.2.6, lisp-mcp ≥ 0.7.3): `;` lines, `#| |#` and trailing comments are written where they were; a comment that ends the anchor's line stays there; one after the last new form goes after the closers that follow. Comment blocks (lisp-source-protocol ≥ 0.2.7): consecutive own-line `;` / `#| |#` comments with no blank line between are a `:comment-block` node built by the locator, not by the reader (not among its parent's children, no path); replace / delete / insert take it, other ops refuse it.
- Broken files: a form that runs to EOF is re-read up to the next column-0 `(` or `#+`/`#-`; `imbalance` carries the fix. Edits refuse recovered nodes, sibling slots under quote prefixes and a `#+`/`#-` feature expression, the consing dot.
- `verify-plan` is the gate: no new reader errors/imbalances, declared top-level form delta. Corpus tests: `LISP_SOURCE_CORPUS=<dir>`.
- Swank evaluates `:emacs-rex` args → `rpc` quotes lists. Backends only map names (`rpc-symbol`); shared logic is `swank-family-connection`. Conformance: `repl-protocol/conformance` against a spawned image.
- `compile-file-for-emacs` only compiles; `repl-compile-file :load t` loads the fasl with `load-file` (SLIME does the same). An out-of-range restart gets no reply from the server, so `repl-invoke-restart` refuses it (`repl-invalid-restart`).
- Slynk mrepl announces a dedicated output socket (`:open-dedicated-output-stream port`) and blocks `create-mrepl` until the client connects; `inspect-entry` must run in the channel's thread.
- `repl-spawn` starts `ros +Q run` (no Quicklisp). Swank/Slynk load with `asdf:load-system`: `repl-protocol:system-registry-form` puts the directories where the server finds them (its cl-repo tree; GHCR `swank` / `slynk` are cl-stack-systems imports) in front of the child registry. Install them as `:ci :with` roots / launcher `:with`, never as `:depends-on` (the server must not load them).
- Do not set Swank's `*globally-redirect-io*` in a spawned image without an Emacs REPL: requests block after the first redirected write.
- Notifications: the image event listener runs on the wire reader thread; stdio writes are serialized by `rpc-backend-stdio`'s lock. Over HTTP only in-request notifications are delivered.
- Background jobs (lisp-mcp ≥ 0.4.0): the worker answers `repl-timeout` with `keep-waiting` and transfers its errors to the waiting call (restart `transfer-error`). Concurrent requests on one connection rely on repl-protocol ≥ 0.2.6 attributing a debugger level by the `:debug` event's continuations.
- Catalog size (0.5.0): common arguments (`path`, `locator`, `expected_hash`, `dry_run`, `compile`, `connection`, `symbol`, `package`, `verbose`) carry no schema description; the server instructions explain them and the locator syntax once (`*argument-notes*`, `*instruction-parts*` in `server.lisp`). `groups-test` budgets the tools/list bytes for the catalog (≤ 18.4 KB) and per group; keep new tools inside them.
- Layout (lisp-source-protocol ≥ 0.2.6): `indent-code` starts from the lists open at the edit point (`indent-state`), so a replaced `labels` binding or `handler-case` clause indents as one; `cond` is `(:rest 2)`, `let`-like operators `:bindings`. New code next to a sibling on its own line gets its own line at the siblings' column, also first or last; move and slurp place forms the same way. Moving a form never shifts lines inside its strings.
- lisp-mcp caches parsed files by write date + length; call `forget-source` after any write the server makes (same-second, same-length writes are otherwise invisible).

Legacy third-party server: skill **cl-mcp-tooling** (cl-ai-project/cl-mcp).
