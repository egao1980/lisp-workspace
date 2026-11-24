# Staged improvements for lisp-mcp-tooling

## Pending

## Applied

- [2026-11-24] Comments and layout of `edit-insert` / `edit-replace` code (lisp-source-protocol#11, #14, #15; lisp-mcp#28) → fixed upstream, SKILL invariants. lisp-source-protocol 0.2.6 (#16) writes the code's comments where they were, indents it in the context of the enclosing forms (`cond` clauses 2 in, a replaced `labels` binding as a local function) and gives a form inserted first or last next to siblings on their own lines its own line. lisp-mcp 0.7.3 requires it; the launcher default is 0.7.3, so comments no longer have to go inside the form.
- [2026-11-24] Reader conditionals in `edit-insert` / `edit-replace` code (from 2026-11-24) → fixed upstream, SKILL invariants. lisp-source-protocol 0.2.5 (#10, fixing #9) reads every `#+`/`#-` as a form with a CST of its branch, whatever the server's features. lisp-mcp 0.7.2 (#29) requires it and shows the `#-sbcl` prefix in the outline. The launcher default is now 0.7.2, so the `(progn #+sbcl … #-sbcl …)` workaround is no longer needed. Comments in inserted code are still dropped (lisp-source-protocol#11).

## Rejected
