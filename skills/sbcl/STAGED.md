# Staged improvements for sbcl

Pending corrections, additions, and refinements discovered during use.

## Pending

## Applied

- [2026-10-22] `ros -e` does not disable the debugger (from 2026-07-02) → SKILL (+ roswell skill line fixed). Re-verified: `ros -e '(error "boom")'` and a missing `ql:quickload` both stop at `0]`; exit 0 after stdin EOF.
- [2026-10-22] Roswell Quicklisp in plain `sbcl` breaks (from 2026-07-02) → SKILL; first-`-e` hook guidance merged into the item above.

## Rejected
- `(directory (merge-pathnames #p"*" dir))` only matches files with **no type/extension** on SBCL (`#p"*"` has `:type nil`). To list all files in a directory use `uiop:directory-files` (or `uiop:*wild-file-for-directory*`). Bit us in the grpc OCI publish pipeline: `grpc.so` never matched, so native overlays were published empty. (2026-07-02, grpc/cl-protobufs OCI review)
