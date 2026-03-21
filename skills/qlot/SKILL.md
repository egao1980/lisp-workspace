---
name: qlot
description: >-
  Qlot: project-local Common Lisp dependency installer (qlfile, lockfile, isolated Quicklisp dist under .qlot/).
  Use when adding deps without polluting global Quicklisp, running commands in a locked environment, CI with qlot,
  or debugging .qlot paths.
---

# Qlot

Repository: [fukamachi/qlot](https://github.com/fukamachi/qlot).

## Workflow

- **`qlot init`** — create **`qlfile`** (and often **`qlot.conf`**) in the project root.
- **`qlot install`** — materialize dependencies under **`.qlot/`** (do not commit large `.qlot` trees unless your policy says so).
- **`qlot update`** — refresh according to `qlfile` / lock.
- **`qlot exec <command>`** — run with project-local environment (e.g. **`qlot exec ros -e '(asdf:test-system :my-system)'`**).

## qlfile

- Declares dist sources: Quicklisp, Ultralisp, git, local path, etc. — match what upstream documents for your stack.

## Relation to Roswell / ASDF

- **Roswell** remains the Lisp launcher; **qlot** wraps execution so the right dist is visible.
- **ASDF** loads systems from paths visible in that process — qlot keeps deps consistent per project.
