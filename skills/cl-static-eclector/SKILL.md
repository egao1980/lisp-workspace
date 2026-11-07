---
name: cl-static-eclector
description: >-
  Static Common Lisp check with Eclector. Reads .lisp/.asd into a CST and
  does not evaluate. Use before load-system, when the user asks for a syntax
  or reader check, or when #. must not run.
---

# Static check (Eclector)

[`scripts/static-eclector.lisp`](../../scripts/static-eclector.lisp) reads files with [`lisp-source-protocol`](https://github.com/egao1980/lisp-source-protocol) (an Eclector CST client, the same reader as the `lisp-mcp` `source-check` tool). It does not `load`, `compile`, or `eval`. `lisp-source-protocol` must be on the ASDF path (workspace registry, or `cl-repo sync`); otherwise the script exits 2.

```bash
ros scripts/static-eclector.lisp file.lisp src/
```

`ros -l` does not forward arguments. Roswell puts them in `roswell:*argv*`.

Exit 0 when every file reads. Exit 1 when any file does not. Every reader error is reported: a broken form does not hide the forms after it. Paren imbalances add a hint with the suggested fix position (`1 closing parenthesis missing (fix at 12:9)`). Directories are walked; directories whose name starts with `.` are skipped. Extensions: `lisp`, `lsp`, `cl`, `asd`, `ros`.

What fails:

- Reader errors (unclosed list, comma outside a backquote, bad tokens).
- `#.` and any other read-time eval. The client never calls `cl:eval`; the form is reported.

What does not fail:

- A package marker whose package is not loaded (`missing-pkg:bar`). The marker is still parsed.
- `#S(...)`. The structure is not constructed.
- `#+` / `#-` against the host `*features*`.

For lint (unused variables, undefined exports, missing docstrings, missing ASDF components) and structural edits, use the `lisp-mcp` server (skill **lisp-mcp-tooling**) or call `lisp-source-protocol:lint` directly.

Report lines are `path:line:column: message`. This is not a substitute for `asdf:test-system`.

Regression: `ros -l scripts/test-static-eclector.lisp`.
