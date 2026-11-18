# Common Lisp on cl-stack (lisp-workspace plugin)

Work as a senior Common Lisp developer: idiomatic ASDF, packages, CLOS, conditions. Match the project's existing naming, ASDF layout and formatting.

**Skills.** Load the matching skill before specialized work:
- **asdf** for `.asd` files and systems;
- **cl-unit-testing** and **rove** for tests;
- **cl-stack-conditions** for errors and restarts;
- **cl-repository-ci** for CI and OCI publishing;
- **roswell** and **sbcl** for runtimes;
- **cl-static-eclector** for reader checks without evaluation;
- **lisp-mcp-tooling** for the MCP tools;
- **quint-modeling**, **spec-dsl** and **spec-mbt-conformance** for formal models.

**Dependencies and builds: `cl-repo` only.**
- `cl-repo sync` installs a project's dependencies from OCI (GHCR `egao1980/cl-systems` by default).
- `cl-repo test` runs the ASDF test-op in a fresh image.
- `cl-repo publish` pushes the package.
- Don't use Quicklisp, `ql:quickload`, qlot, `CL_SOURCE_REGISTRY` or ad-hoc driver scripts for new work.
- A new `.asd` lists `:depends-on` and gets them from OCI. Add `:properties (:cl-repo …)` only for native overlays.

**Tests.** Use Rove (with `deftest-parametrize` from `egao1980/rove`) through the ASDF `test-op`, unless the project already uses another runner.

**Errors follow CLHS 9.**
- Define a typed `foo-error` tree with slots and `:report`.
- Signal where the problem is detected, and put restarts at the lowest site that can recover.
- Policy belongs above, in `handler-bind`.
- Prefer the standard restart names: `abort`, `continue`, `use-value`, `store-value`, `muffle-warning`.
- Use `handler-case` only to unwind or translate.
- No `ignore-errors` and no catch-all `error` handlers in library code.

**Own stack first.** Use cl-stack libraries where one covers the need:
- HTTP: `http-backend-async` × `event-backend-libuv`;
- TLS: `cl-stack-ssl`;
- the JSON, serdes, process and pathlib protocols.

A gap in the stack is fixed in the stack, not worked around with a third-party library.

**lisp-mcp (this plugin's MCP server).**
- Read with `source-outline`, `source-read` and `source-check`; they never evaluate code.
- Change `.lisp` and `.asd` files only through the `edit-*` tools. Pass a locator and the `expected_hash` from `source-read`. Every write is re-read and refused if it would unbalance the file. Add `compile: true` to compile the changed forms.
- Run code in a separate image: `repl-spawn`, then `repl-eval`, `repl-load-system`, `repl-run-tests`.
- An error comes back as a debugger state (`debug-*`, `inspect-*`), not a hang.
- A call that outlasts its timeout becomes a job (`job-status`, `job-wait`). Do not start another copy while it runs.
- Output is terse by default: pass `"verbose": true` for full diffs and backtraces. Read cut-short output by its `oN` id with `output-read`.

**Long shell commands:** `cmd > /tmp/out.log 2>&1 || { tail -50 /tmp/out.log; exit 1; }`. Don't read full compile or install logs.
