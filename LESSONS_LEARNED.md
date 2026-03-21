# Lessons learned

Append-only log of **symptom → cause → fix** for this workspace.

## 2026-03 — `cl-protobufs` bootstrap and `egao1980` fork

- **Symptom:** `git clone https://github.com/egao1980/cl-protobufs.git` fails with `Repository not found` after `gh repo fork` exits non-zero.
- **Cause:** The fork under `egao1980` does not exist yet (fork creation failed, org permissions, or fork not created on GitHub).
- **Fix:** Ensure `gh auth status` succeeds; run `gh repo fork qitab/cl-protobufs --org egao1980` and confirm the repo appears on GitHub; then re-run `./.lisp-workspace/scripts/add-cl-project.sh qitab/cl-protobufs`. `add-cl-project.sh` checks `gh repo view egao1980/<name>` before cloning when the clone URL targets that org.

- **Symptom:** `gh repo fork … --org egao1980` returns HTTP 422: `egao1980` is the login for a user account (not an organization).
- **Cause:** GitHub’s `--org` flag is only for **organization** accounts.
- **Fix:** `add-cl-project.sh` compares `GITHUB_WORKSPACE_ORG` to `gh api user --jq .login`; if they match, it runs `gh repo fork` **without** `--org` so the fork lands under the user account.

## 2026-03 — MCP: quasi/cl-mcp + cl-mcp-server → cl-ai-project/cl-mcp

- **Context:** Workspace docs previously pointed at **quasi/cl-mcp** + **quasi/cl-mcp-server** (two repos, `run-server.lisp`).
- **Switch:** Canonical MCP server for this tree is **[cl-ai-project/cl-mcp](https://github.com/cl-ai-project/cl-mcp)** — single repo, **`MCP_PROJECT_ROOT`**, tools like **`repl-eval`** / **`inspect-object`** / **`load-system`**, stdio/TCP/HTTP, optional worker pool. Remove **`cl-mcp-server/`** wiring; use **`./.lisp-workspace/scripts/add-cl-project.sh cl-ai-project/cl-mcp`** (fork → **`egao1980/cl-mcp`**).

## 2026-03 — Same repo name, different owners (user vs org)

- **Symptom:** Confusion or wrong checkout — “we added **cl-mcp**” but tools/docs point at a different upstream than intended; or **`gh repo view cl-mcp`** is ambiguous / wrong repo.
- **Cause:** GitHub repo names are only unique **per owner**. Unrelated projects often share a name (e.g. **`quasi/cl-mcp`**, **`cl-ai-project/cl-mcp`**, **`egao1980/cl-mcp`**). Referring to “**cl-mcp**” without **`owner/`** does not identify a single repository.
- **Fix:** Always use full **`owner/repo`** in scripts, **`gh`**, **`add-cl-project.sh`** arguments, docs, and mental model. Set **`upstream`** remote to the **canonical** upstream you mean, not “whatever is called cl-mcp.” After a rename or switch, grep docs for the old **`owner/repo`** so nothing still points at the wrong fork.

## 2026-03 — ASDF source-registry.conf.d file format

- **Symptom:** `INVALID-SOURCE-REGISTRY` error at startup: `(:source-registry (:tree #P"/path/") :inherit-configuration)` in a `.conf` file under `source-registry.conf.d/`.
- **Cause:** Files inside `source-registry.conf.d/` must contain **bare directives** like `(:tree "/path/")`. ASDF wraps them in `(:source-registry ... :inherit-configuration)` automatically. Wrapping manually produces an invalid double-wrapped form. Also, `#P` pathname literals can confuse ASDF's reader — use plain strings.
- **Fix:** Changed `add-cl-project.sh` to emit `(:tree "/path/")` instead of `(:source-registry (:tree #P"/path/") :inherit-configuration)`.

## 2026-03 — cl-mcp requires eclector git HEAD (newer than Quicklisp dist)

- **Symptom:** `SB-PCL::FIND-METHOD-LENGTH-MISMATCH` loading `cl-mcp/src/cst.lisp`: `make-skipped-input-result` takes 4 args but cl-mcp defines a method with 5 specializers.
- **Cause:** cl-mcp's CST parser expects eclector git HEAD API where `make-skipped-input-result` takes `(client stream reason children source)` (5 args). Quicklisp dist eclector ships an older snapshot with 4-arg `(client stream reason source)`.
- **Fix:** Clone eclector HEAD into **both** Quicklisp `local-projects` directories: `~/quicklisp/local-projects/eclector-git` and symlink into `~/.roswell/lisp/quicklisp/local-projects/eclector-git`. Clear stale FASLs: `find ~/.cache/common-lisp -path '*eclector*' -name '*.fasl' -delete`.

## 2026-03 — `containerEnv` not available during devcontainer feature build

- **Symptom:** `ros: command not found` in `lem/install.sh` even though `containerEnv.PATH` in `roswell/devcontainer-feature.json` includes `/usr/local/roswell/current/bin`.
- **Cause:** `containerEnv` entries from `devcontainer-feature.json` are injected at **container runtime** (when the user opens the container), not during the **build phase** when `install.sh` scripts execute. Similarly, `updaterc` writes to `/etc/bash.bashrc` which has an early `return` guard for non-interactive shells, so PATH additions there are also invisible during build.
- **Fix:** Explicitly `export PATH="/usr/local/roswell/current/bin:${PATH}"` at the top of any downstream feature's `install.sh` that depends on Roswell binaries.

## 2026-03 — `sudo_if` PATH loss when running as non-root user

- **Symptom:** `qlot: command not found` when running `ros install qlot` as the `vscode` user via `su - "$USERNAME" -c "..."`, even though `qlot` is installed under `~vscode/.roswell/bin/`.
- **Cause:** `su -` resets the environment to the target user's login shell defaults. The Roswell bin directory (`~/.roswell/bin`) and the Roswell install path (`/usr/local/roswell/current/bin`) are not in the default PATH for that user during the build phase (see `containerEnv` lesson above).
- **Fix:** Inject the full PATH explicitly when invoking `su`:
  ```bash
  user_home=$(eval echo "~${USERNAME}")
  su - "$USERNAME" -c "PATH=\"/usr/local/roswell/current/bin:\$PATH:${user_home}/.roswell/bin\" $(printf '%q ' "$@")"
  ```
  Also use `printf '%q '` instead of `"$*"` to correctly handle arguments containing spaces.

## 2026-03 — Lem `.asd` requires `deploy` at ASDF parse time

- **Symptom:** `Component "deploy" not found, required by NIL` — `ros install lem-project/lem` fails during `.asd` parsing, before any compilation begins.
- **Cause:** `lem.asd` declares `:defsystem-depends-on ("deploy")`, which ASDF must resolve **before** the `defsystem` form is processed. The `qlot install --no-deps` that Lem's `.asd` runs inline only materializes git-sourced dependencies listed in the `qlfile`, not standard Quicklisp systems like `deploy`. Roswell's ASDF session during `ros install` doesn't see the reconfigured Quicklisp environment that qlot sets up.
- **Fix:** Pre-install `deploy` into the user's global Quicklisp before running `ros install`:
  ```bash
  ros -e '(ql:quickload :deploy :silent t)' -q
  ```
  This makes the system visible to ASDF at parse time regardless of qlot's state.

## 2026-03 — Lem `libwebview.so` missing runtime dependencies

- **Symptom:** `Unable to load foreign library (LIBWEBVIEW)` — CFFI fails to dlopen `libwebview.so.0.12.0` during Lem compilation.
- **Cause:** Lem's qlot dependency `lem-project/webview` ships prebuilt `.so` files for linux/arm64 and linux/x64, but these link against `libwebkitgtk-6.0.so.4`, `libgtk-4.so.1`, and related GLib/GObject libraries that are not installed in the base devcontainer image.
- **Fix:** Install system packages before `ros install lem-project/lem`:
  - **Debian/Ubuntu:** `libwebkitgtk-6.0-4 libgtk-4-1`
  - **RHEL/Fedora:** `webkit2gtk4.1 gtk4`
  - **Alpine:** `webkit2gtk-6.0 gtk4.0`

## 2026-03 — Cursor's `devcontainer` CLI wrapper vs standalone CLI

- **Symptom:** `Unknown arguments: workspace-folder, workspaceFolder` when running `devcontainer features test`.
- **Cause:** The system `devcontainer` binary provided by Cursor/VS Code is a wrapper that injects extra arguments not supported by the features test subcommand.
- **Fix:** Use the standalone `@devcontainers/cli` directly: `npx @devcontainers/cli features test ...` (or install globally via `npm install -g @devcontainers/cli`).

## 2026-03 — Shell quoting in `install.sh` scripts

- **Symptom:** Various subtle failures when feature option values contain spaces or special characters; unquoted `[ $VAR = … ]` tests fail with `[: too many arguments` on certain distros.
- **Cause:** Missing double-quotes around variable expansions in `[ ]` tests and function arguments. The original `sudo_if` used `"$*"` which concatenates all arguments into a single string, losing word boundaries.
- **Fix:** Quote all variable expansions in `[ ]` tests (e.g. `[ "${ID}" = "debian" ]`). In `sudo_if`, use `printf '%q ' "$@"` to properly shell-escape each argument before passing to `su -c`.
