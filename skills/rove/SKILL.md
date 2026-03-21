---
name: rove
description: >-
  Rove: Common Lisp testing library (assertions, reporting, ASDF integration). Use when writing or running tests,
  adding test systems, or migrating tests — this workspace defaults to Rove unless a subproject already uses
  FiveAM, Parachute, etc.
---

# Rove

Repository: [fukamachi/rove](https://github.com/fukamachi/rove).

## Usage

- Add **`:rove`** (and often a test `:module` / `:components`) to your system’s **`.asd`** file per Rove’s README patterns.
- Run tests via ASDF: **`asdf:test-system`** on your test system, or **`rove`**-specific APIs as the project defines.
- Prefer matching **existing** test framework inside a subproject; use **Rove** for **new** test code when there is no prior choice ([`.lisp-workspace/AGENTS.md`](../AGENTS.md)).

## Integration

- Works with **Roswell**: e.g. **`qlot exec ros -e '(asdf:test-system :my-app/tests)'`** when the project uses qlot.
