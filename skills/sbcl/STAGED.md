# Staged improvements for sbcl

Pending corrections, additions, and refinements discovered during use.

## Pending

- [2026-07-02] `ros -e '...'` does NOT reliably disable the interactive debugger — a `ql:quickload`/network error inside `-e` hung an agent shell until interrupted.
  - Source: user correction ("it's CL - the command needs to be run with no interactive debugger")
  - Proposed change: replace "Via Roswell: `ros -e '...'` ... typically handle this" with explicit guidance: for one-shot ros/sbcl commands always set `*debugger-hook*` first (e.g. `ros -e '(setf *debugger-hook* (lambda (c h) (declare (ignore h)) (format t "UNHANDLED: ~A~%" c) (uiop:quit 1)))' -e '...'`) or use `sbcl --non-interactive`, and redirect output to a log file per the long-running-command rule.

- [2026-07-02] Loading Roswell's quicklisp into plain `sbcl` breaks two ways: `--no-userinit --load ~/.roswell/lisp/quicklisp/setup.lisp` fails in `local-init/roswell.lisp` ("Package ROSWELL does not exist"), and without `--no-userinit` a second `~/quicklisp` install can leave stale fasls (e.g. cl-syntax readtable conflict via ultralisp cache paths).
  - Source: agent observation (dexador test runs)
  - Proposed change: note that for Roswell-managed environments, one-shot commands should use `ros -e` with `*debugger-hook*` set in the FIRST `-e` form (every form after an unhooked error falls into the debugger), not `sbcl --load .roswell/.../setup.lisp`.

## Applied

## Rejected
- `(directory (merge-pathnames #p"*" dir))` only matches files with **no type/extension** on SBCL (`#p"*"` has `:type nil`). To list all files in a directory use `uiop:directory-files` (or `uiop:*wild-file-for-directory*`). Bit us in the grpc OCI publish pipeline: `grpc.so` never matched, so native overlays were published empty. (2026-07-02, grpc/cl-protobufs OCI review)
