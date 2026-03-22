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
- **Fix:** Install system packages before `ros install lem-project/lem`. The prebuilt `libwebview.so` links against different WebKit libraries per architecture:
  - **x64:** `libwebkit2gtk-4.1.so.0` (GTK3 WebKit) — install `libwebkit2gtk-4.1-0`
  - **arm64:** `libwebkitgtk-6.0.so.4` (GTK4 WebKit) — install `libwebkitgtk-6.0-4 libgtk-4-1`
  - Install both on Debian/Ubuntu to cover either arch. Requires Ubuntu 22.04+ (focal lacks both).
  - **Alpine** does not package either library — lem cannot build with webview support on Alpine.

## 2026-03 — Cursor's `devcontainer` CLI wrapper vs standalone CLI

- **Symptom:** `Unknown arguments: workspace-folder, workspaceFolder` when running `devcontainer features test`.
- **Cause:** The system `devcontainer` binary provided by Cursor/VS Code is a wrapper that injects extra arguments not supported by the features test subcommand.
- **Fix:** Use the standalone `@devcontainers/cli` directly: `npx @devcontainers/cli features test ...` (or install globally via `npm install -g @devcontainers/cli`).

## 2026-03 — Shell quoting in `install.sh` scripts

- **Symptom:** Various subtle failures when feature option values contain spaces or special characters; unquoted `[ $VAR = … ]` tests fail with `[: too many arguments` on certain distros.
- **Cause:** Missing double-quotes around variable expansions in `[ ]` tests and function arguments. The original `sudo_if` used `"$*"` which concatenates all arguments into a single string, losing word boundaries.
- **Fix:** Quote all variable expansions in `[ ]` tests (e.g. `[ "${ID}" = "debian" ]`). In `sudo_if`, use `printf '%q ' "$@"` to properly shell-escape each argument before passing to `su -c`.

## 2026-03 — `devcontainer features test` `-s` flag does not exist

- **Symptom:** `Unknown argument: s` — all test-roswell and test-lem CI jobs fail immediately.
- **Cause:** The `-s` (scenario) flag was assumed from older docs or examples, but `@devcontainers/cli` uses `--filter` to select a specific scenario by name.
- **Fix:** Replace `-s ${{ matrix.scenario }}` with `--filter ${{ matrix.scenario }}` in CI workflows.

## 2026-03 — Token waste from verbose command output

- **Symptom:** Agent burns thousands of tokens reading qlot/roswell/SBCL compilation output, ANSI escape sequences, and progress bars that carry no diagnostic value.
- **Cause:** Long-running commands (`ros install`, `qlot install`, `apt-get install`, SBCL compilation) produce massive stdout/stderr that the model reads in full when piped directly.
- **Fix:** Redirect output of long-running commands to a temp file, then only read the tail on failure:
  ```bash
  ros install lem-project/lem > /tmp/lem-install.log 2>&1 || { tail -50 /tmp/lem-install.log; exit 1; }
  ```
  Or use `| tail -N` to cap output. For progress-style output with ANSI escapes, pipe through `cat` or redirect to file to avoid terminal noise. Only inspect the full log when debugging a failure.

## 2026-03 — `act` cannot run `devcontainer features test` (DinD bind mount failure)

- **Symptom:** `docker: Error response from daemon: invalid mount config for type "bind": bind source path does not exist: /tmp/devcontainercli/container-features-test/...`
- **Cause:** `devcontainer features test` creates temp files inside the act container, then runs `docker run --mount` referencing those paths. The host Docker daemon (shared via socket) can't access paths inside the act container. `--privileged`, `--bind`, and `--container-daemon-socket -` do not solve this — it's a fundamental Docker-out-of-Docker limitation.
- **Fix:** Run `npx @devcontainers/cli features test` directly on the host instead of through act. act *can* run the `validate` job (JSON schema checks, no container launches). For scenario tests, use the CLI directly:
  ```bash
  npx @devcontainers/cli features test -f roswell --skip-autogenerated --filter roswell_ubuntu .
  ```

## 2026-03 — `oras-project/setup-oras@v1` version pin (act + arm64)

- **Symptom:** `Error: official ORAS CLI releases does not contain version 1.3.1` when `with: version: 1.3.1` is set.
- **Cause:** The action ships a **frozen JSON manifest** of allowed ORAS versions. Newer tags (e.g. v1.3.1) are not in that list until the action is updated.
- **Symptom (earlier):** `Unexpected HTTP response: 404` downloading `oras_1.3.0_linux_arm64.tar.gz` under `act --container-architecture linux/arm64`.
- **Cause:** Transient GitHub/CDN issues or flaky default URL fetch; not a reason to drop `oras` from workflows that `oras pull` the packager image and `oras manifest fetch` for verify.
- **Fix:** Pin to a version **present in the bundled manifest** with `linux_arm64`, e.g. **`1.2.3`**, until `setup-oras` releases a tag that lists newer ORAS versions. Keep `oras` for bootstrap + verify; Lisp still publishes via `cl-repository-packager`.

## 2026-03 — `act` + local OCI registry + devcontainer (cl-protobufs / grpc)

End-to-end: build/publish packages with **nektos/act** to a **local registry**, then install/load in a **features-based devcontainer** (Roswell) using **cl-repository-client** — same flow we used to validate `linux/arm64` overlays and bundled gRPC C++ deps.

**Registry (host):** e.g. Docker `registry:2` mapped to **`localhost:5050`** (container name often `cl-oci-test-registry`). From other containers use **`host.docker.internal:5050`**.

**act (publish workflow):**

- **`workflow_dispatch`** inputs: `registry=host.docker.internal:5050`, `version=<tag>` (empty registry → workflow defaults to ghcr).
- **`--artifact-server-path /tmp/act-artifacts`** — required: `upload-artifact` / `download-artifact` need the local artifact server or act fails (`ACTIONS_RUNTIME_TOKEN`).
- **`--container-architecture linux/arm64`** on Apple Silicon to match **`linux/arm64`** matrix builds.
- **Runner map:** `-P ubuntu-latest=catthehacker/ubuntu:act-latest` and `-P ubuntu-24.04-arm64=catthehacker/ubuntu:act-latest`.
- **Single matrix slice:** `--matrix os:linux --matrix arch:arm64` so act does not try to run **macos** jobs.
- **Namespace:** `--env GITHUB_REPOSITORY_OWNER=egao1980` so publish targets **`egao1980/cl-systems/...`** (matches `github.repository_owner` in CI).
- **Logs:** redirect act stdout/stderr to **`/tmp/act-*.log`**; tail on failure (workspace policy).

**Template (adjust paths/versions):**

```bash
rm -rf /tmp/act-artifacts && mkdir -p /tmp/act-artifacts
cd cl-protobufs  # or grpc
act workflow_dispatch \
  --input version=2.1 \
  --input registry=host.docker.internal:5050 \
  --container-architecture linux/arm64 \
  -P ubuntu-latest=catthehacker/ubuntu:act-latest \
  -P ubuntu-24.04-arm64=catthehacker/ubuntu:act-latest \
  --matrix os:linux --matrix arch:arm64 \
  -W .github/workflows/publish-oci.yml \
  --env GITHUB_REPOSITORY_OWNER=egao1980 \
  --artifact-server-path /tmp/act-artifacts \
  > /tmp/act-cl-protobufs.log 2>&1 || { tail -50 /tmp/act-cl-protobufs.log; exit 1; }
```

Run **cl-protobufs** first if **grpc** depends on that OCI version; then **grpc** with its `--input version=...`.

**Devcontainer consumer test:**

- **Image + feature:** e.g. `mcr.microsoft.com/devcontainers/base:ubuntu` + **`ghcr.io/egao1980/features/roswell:1`**.
- **Mount `cl-repository` read-only**; set **`CL_SOURCE_REGISTRY`** to **`(:source-registry (:directory #p"/workspace/cl-repository/") :inherit-configuration)`** — **not** `:tree`, or ASDF may find **cl-protobufs under `.qlot/local-projects`** and ignore the OCI install / pregenerated overlay.
- **`runArgs`:** `"--add-host=host.docker.internal:host-gateway"` so the container reaches the host registry.
- **Test Lisp:** `(cl-repository-client/quickload:add-registry "http://host.docker.internal:5050" :namespace "egao1980/cl-systems")`, then **`cl-repository-client/quickload:load-system`** with pinned **`cl-protobufs`** / **`grpc`** versions; optional protobuf round-trip + **`(find-package :grpc)`** checks.
- **Bundled grpc:** with **Makefile `$ORIGIN` / bundle script** + overlay, **`LD_LIBRARY_PATH`** / Homebrew grpc on the consumer image should **not** be required for load.

**Failures we hit:**

- **Homebrew inside act:** transient **GitHub 500** on `brew` clone — retry act.
- **ORAS:** see section *`oras-project/setup-oras@v1` version pin* — use **`1.2.3`** in workflow `with.version` for act **arm64** until the action’s bundled manifest updates.

## 2026-03 — cl-repository overlay platform keys: `os` / `release` / `arch`

- **Fact:** cl-repository's `overlay-spec` and `.asd` `:platform` entries support **three** keys: **`os`**, **`release`**, and **`arch`** — not just `os`/`arch`.
- **Implication:** you can ship separate overlays per distro release (e.g. `linux` + `24.04` + `arm64` vs `linux` + `26.04` + `arm64`) when native libraries link against different glibc / system lib versions.
- **Current practice:** our `publish-oci.yml` workflows use bare `linux`/`darwin` + `arch` without `release`, which is fine as long as we build on the oldest supported LTS (24.04) — forward glibc compat covers newer releases. If we ever need release-specific binaries (e.g. linking against a system lib that changed ABI between releases), add `release` to the matrix and the overlay spec.
