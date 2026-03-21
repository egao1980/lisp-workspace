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

## Pitfalls

- **`qlot install --no-deps`** only materializes dependencies declared in the `qlfile` (typically git repos, local paths, custom dists). It does **not** install standard Quicklisp/Ultralisp systems — those must already be available in the Quicklisp environment or be installed separately.
- Some projects (e.g. Lem) run `qlot install --no-deps` from top-level forms inside their `.asd` file. If the `.asd` also uses `:defsystem-depends-on` on a Quicklisp-only system, that system must be pre-installed before ASDF attempts to parse the `.asd`.
- **`qlot exec`** sets up the project-local environment so that ASDF sees `.qlot/` paths. However, combining `qlot exec ros install <repo>` can be fragile — Roswell's internal install mechanism may not fully inherit qlot's reconfigured Quicklisp client.
