---
name: sbcl
description: >-
  SBCL: --disable-debugger, heap flags, compiler notes. Use when running SBCL
  directly or a process looks hung in the debugger.
---

# SBCL

Docs: [sbcl.org](https://www.sbcl.org/), manual: [sbcl.org/manual](https://www.sbcl.org/manual/).

## Interactive debugger — CRITICAL for non-interactive use

SBCL drops into an **interactive debugger** on unhandled conditions by default. In agent/CI/script contexts this makes the process **appear hung** (waiting for stdin input).

**Always disable the debugger for non-interactive execution:**

- CLI flag: `sbcl --disable-debugger` or `sbcl --non-interactive` (implies `--disable-debugger` + `--end-toplevel-options`).
- In Lisp: `(sb-ext:disable-debugger)` — causes unhandled conditions to print a backtrace and exit with non-zero status instead of entering the debugger.
- Via Roswell: `ros -e '...'` and `ros run -e '...' -q` typically handle this, but `ros run` alone opens an interactive REPL.

## Useful flags

- **`--dynamic-space-size <MB>`** — increase heap for large compilations (e.g. Lem build).
- **`--noinform`** — suppress startup banner.
- **`--no-userinit --no-sysinit`** — skip init files for clean environments.

## Compiler notes

- SBCL is verbose about optimization notes, style warnings, and undefined function/variable warnings. These are usually printed to `*error-output*` (stderr). In CI, pipe stderr to capture them.
- **`(declaim (optimize (speed 0) (safety 3) (debug 3)))`** for maximum debuggability; **(speed 3)** for production.
