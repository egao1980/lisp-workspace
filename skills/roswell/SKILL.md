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

## Interactive debugger (CRITICAL for agents)

- SBCL (and most CL implementations) drop into an **interactive debugger** on unhandled conditions by default. When running CL code from shell scripts or agent tool calls, this causes the process to **appear hung** — it's waiting for debugger input on stdin.
- **Always** use `--disable-debugger` (SBCL) or `--non-interactive` (Roswell) when running Lisp non-interactively. Roswell's `-e` and script modes typically handle this, but `ros run` does not.
- For SBCL directly: `sbcl --disable-debugger --load script.lisp` or `sbcl --non-interactive --load script.lisp`.
- In Lisp code you can also set `(sb-ext:disable-debugger)` or wrap with `handler-case` / `handler-bind` to avoid the debugger on errors.

## Devcontainer / non-interactive shell pitfalls

- **`containerEnv`** entries in `devcontainer-feature.json` apply at **runtime**, not during the **build phase** (`install.sh`). Downstream features that need `ros` must explicitly `export PATH="/usr/local/roswell/current/bin:${PATH}"`.
- **`updaterc`** writes PATH additions to `/etc/bash.bashrc`, which guards with `return` for non-interactive shells. Build-phase scripts and `su -c` commands do not source it.
- When running Roswell commands as a non-root user via `su -`, explicitly inject both the Roswell install path and the user's `~/.roswell/bin` into PATH:
  ```bash
  su - "$USERNAME" -c "PATH=\"/usr/local/roswell/current/bin:\$PATH:${user_home}/.roswell/bin\" $(printf '%q ' "$@")"
  ```
- **`ros follow-dependency=t install <repo>`** resolves ASDF deps after loading the `.asd`. It does **not** help if the `.asd` itself fails to parse (e.g. due to `:defsystem-depends-on` on an unavailable system).

## Policy

- Read [Policy on how Roswell affects your system](https://roswell.github.io/Policy-on-how-Roswell-affects-or-manipulates-your-system.html) when advising install scope.
