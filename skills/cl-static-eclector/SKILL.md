---
name: cl-static-eclector
description: >-
  Static Common Lisp check with Eclector. Reads .lisp/.asd into a CST and
  does not evaluate. Use before load-system, when the user asks for a syntax
  or reader check, or when #. must not run.
---

# Static check (Eclector)

[`scripts/static-eclector.lisp`](../../scripts/static-eclector.lisp) reads each form with `eclector.concrete-syntax-tree:read`. It does not `load`, `compile`, or `eval`.

```bash
ros scripts/static-eclector.lisp file.lisp src/
```

`ros -l` does not forward arguments. Roswell puts them in `roswell:*argv*`.

Exit 0 when every file reads. Exit 1 when a file does not. One issue per file, then the next file. Directories are walked; directories whose name starts with `.` are skipped. Extensions: `lisp`, `lsp`, `cl`, `asd`, `ros`.

What fails:

- Reader errors (unclosed list, comma outside a backquote, bad tokens).
- `#.` and any other read-time eval. `cl:*read-eval*` is nil. `evaluate-expression` on the static client signals instead of calling `cl:eval`.

What does not fail:

- A package marker whose package is not loaded (`missing-pkg:bar`). The marker is still parsed.
- `#S(...)`. The structure is not constructed.
- `#+` / `#-` against the host `*features*`.

Report lines are `path:line:column: message`. This is not a substitute for `asdf:test-system`.

Regression: `ros -l scripts/test-static-eclector.lisp`.
