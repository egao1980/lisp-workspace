# Staged improvements for lisp-mcp-tooling

## Pending

## Applied

- [2026-11-24] Reader conditionals in `edit-insert` / `edit-replace` code (from 2026-11-24) → fixed upstream, SKILL invariants. lisp-source-protocol 0.2.5 (#10, fixing #9) reads every `#+`/`#-` as a form with a CST of its branch, whatever the server's features. lisp-mcp 0.7.2 (#29) requires it and shows the `#-sbcl` prefix in the outline. The launcher default is now 0.7.2, so the `(progn #+sbcl … #-sbcl …)` workaround is no longer needed. Comments in inserted code are still dropped (lisp-source-protocol#11).

## Rejected
