---
name: roswell
description: >-
  Roswell (ros): Common Lisp implementation manager, launcher, Quicklisp integration, and scripting.
  Use when installing SBCL/CCL, running `ros run`, `ros install`, Roswell scripts (.ros), CI setup, or debugging
  PATH / ~/.roswell issues.
---

# Roswell

Official docs: [roswell.github.io](https://roswell.github.io/), repo [roswell/roswell](https://github.com/roswell/roswell).

## Commands (essentials)

- **`ros run`** — start REPL with default implementation (`ros use` selects default).
- **`ros install sbcl-bin`** / **`ros install sbcl/1.2.0`** — install Lisp implementations.
- **`ros use sbcl/…`** — switch default implementation.
- **`ros install qlot`** or **`ros install fukamachi/qlot`** — install CLI tools from Quicklisp/GitHub.
- **`ros help options`** — includes **`-Q` / `--no-quicklisp`** when you need ASDF without loading Quicklisp.
- **`ros init`** — scaffold a `.ros` script ([scripting tutorial](https://roswell.github.io/Roswell-as-a-Scripting-Environment.html)).

## Integration

- Roswell typically wires **Quicklisp** for library installs; this workspace often prefers **qlot** per project (`qlot exec ros …`).
- **`ros list`** / **`ros config`** — inspect what is installed.

## Policy

- Read [Policy on how Roswell affects your system](https://roswell.github.io/Policy-on-how-Roswell-affects-or-manipulates-your-system.html) when advising install scope.
