# Staged improvements for lisp-mcp-tooling

## Pending

- [2026-11-24] **Reader conditionals in `edit-insert` / `edit-replace` code.** lisp-code reads the new code with the server image's own features, so a top-level form that a reader conditional excludes there (`#-sbcl …` on an SBCL server) is dropped silently. The edit still reports success and the diff reads cleanly. Until lisp-source-protocol#9 is fixed, put both branches inside one form, e.g. `(progn #+sbcl (…) #-sbcl (…))`, and check the dry-run diff for every conditional branch. Found when an ECL-only save hook went missing in http-protocol#58; ECL CI caught it.

## Applied

## Rejected
