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

## 2026-08 — Install-GhaRunner.ps1 path must include owner

- **Symptom:** Docs claim one Windows runner install per `owner/repo`, but a second install for a same-named repo under another owner hits the same folder / conflicts.
- **Cause:** `$Dir = Join-Path $Root $name` and runner name `windows-amd64-$name` dropped `$owner`.
- **Fix:** Install under `<Root>\<owner>\<repo>` and name runners `windows-amd64-<owner>-<repo>` (hash-shortened if over GitHub’s 64-char name limit).

## 2026-08 — Install-GhaRunner.ps1 must not drop the service before payload is ready

- **Symptom:** Version upgrade / reinstall can leave a previously online runner with no Windows service if extract/copy/`config.cmd` fails mid-flight.
- **Cause:** `svc.cmd uninstall` ran before staging succeeded; install tree was wiped before `Copy-Item` finished.
- **Fix:** Extract+validate into TEMP first; stop/uninstall only after staging is ready; overlay binaries in place (no wipe-before-copy); on failure after uninstall, attempt `svc.cmd install`/`start`. Also use `Invoke-WebRequest -UseBasicParsing` for PS 5.1/Server Core.

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

## 2026-03 — OCI consumer test: `publish-oci.yml` (act) vs `test-oci-local.sh`

End-to-end test: `act` builds cl-protobufs & grpc → local registry → devcontainer → `cl-repository-client/quickload:load-system`.

**What works (reference):** The `scripts/test-oci-local.sh` scripts in cl-protobufs / grpc. They use **relative** paths in overlay `overlay-spec :files` (e.g. `("lib/linux-amd64/grpc.so" . "grpc.so")`) and only package the wrapper `.so`, not the full bundle. The packager correctly builds `native/grpc.so` in the overlay tarball. Consumer gets `native/` in CFFI search dirs via `cl-repo-init.lisp` — works without `LD_LIBRARY_PATH`.

**What broke:** `publish-oci.yml` run via `act`. Three issues, all in the CI workflow — **not** in `cl-repository-client`:

### 1. Empty overlay tarball (grpc `publish-oci.yml`)

- The `publish.lisp` heredoc in the workflow collects overlay files via `(directory ...)` which returns **absolute** paths. `overlay-spec :files` alist gets `("/full/path/lib/linux-arm64/grpc.so" . "grpc.so")`. The packager's layer builder resolves relative to `:source-dir` and can't find the file at that absolute path → empty tarball.
- **Meanwhile**, `lib/linux-arm64/` exists inside the source tree (created by the "Arrange overlay" step), so the source tarball includes all `.so` files.
- **Fix:** Use relative paths in overlay `:files` (match `test-oci-local.sh`), or fix the layer builder to handle absolute paths.

### 2. Missing soname symlinks (`bundle-grpc-native-deps.sh`)

- The bundle script uses `realpath` → `basename`, copying e.g. `libgrpc.so.52.0.0`. The soname links (`libgrpc.so.52`) are not created. `grpc.so` has `NEEDED: libgrpc.so.52` + `RUNPATH: $ORIGIN` → `not found`.
- **Fix:** Add `ldconfig -n "$destdir"` at the end, or manually create soname symlinks.
- **Note:** `test-oci-local.sh` doesn't hit this because it only ships `grpc.so` (wrapper), relying on system grpc libs. Full self-contained bundle is the `publish-oci.yml` goal.

### 3. `latest` tag → 0 files (cl-repository-client)

- Pulling `cl-protobufs:latest` (as transitive dep) extracts 0 files. Explicit `:version "2.1.0"` works (176 files).
- **Likely cause:** `compute-strip-prefix` gets version `"latest"` → strip prefix `"cl-protobufs-latest/"` → doesn't match tarball entries `"cl-protobufs-2.1.0/"` → all entries skipped.
- **Workaround:** Always pass explicit `:version` to `load-system`.

## 2026-03 — cl-repository: push only to fork, never to upstream

- **Symptom:** PR conflict resolution and force-push could accidentally target `CommonLispNext/cl-repository` (upstream) instead of `egao1980/cl-repository` (fork).
- **Cause:** `origin` and `upstream` remotes both exist; `gh pr view` defaults to the upstream repo when the PR is on `CommonLispNext`. Easy to conflate the two when rebasing.
- **Fix:** Always push to `origin` (`egao1980/cl-repository`). Never push or create PRs directly on `CommonLispNext/cl-repository`. When SSH keys aren't configured, temporarily switch to HTTPS (`git remote set-url`) for fetch/push, then restore SSH URLs afterward.

### ASDF source-registry conflict (devcontainer test setup)

- `post-create.sh` registers all workspace subdirs in ASDF. Must remove `50-lisp-workspace-cl-protobufs.conf` and `50-lisp-workspace-grpc.conf` before OCI consumer tests, or use `(:directory "/workspaces/lisp/cl-repository/")` (not `:tree`).

## 2026-06 — cl-repository: structured `cffi-libraries` + finishing the native-deps init hook

Implemented the per-library `cffi-libraries` metadata the spec always described (`name -> {define-foreign-library, canary, search-path}`) and wired `generate-init-file` to consume it. Findings from the work + the live integration run:

- **Author form stays backward-compatible.** `:cffi-libraries ("libfoo")` (bare name list) still works everywhere; the richer form is `("libfoo" :define-foreign-library "pkg::libfoo" :canary "foo_init" :search-path "lib/")`. Normalization to a canonical alist `(NAME . PLIST)` happens **inside `make-cl-system-config`** (idempotent), so every caller — packager, repackager, JSON deserialize — stores the same shape. Keep `package-spec-cffi-libraries` as the **raw author value** so existing asdf-plugin tests don't break; normalize only at config-build time.
- **Init files load BEFORE `asdf:load-system`** (`load-system-init-files` runs in quickload phase 3, before the system loads). So the system's own `define-foreign-library` symbol does **not** exist at init time — the only actionable field is `search-path` (push onto `cffi:*foreign-library-directories*`). `define-foreign-library`/`canary` are recorded as comments for the canary pattern, not executed. Per `native-deps.md` this is correct: the prebuilt lib loads transparently once the search dir is registered. Don't try to `load-foreign-library` by name at init time — it's load-order-wrong and platform-fragile.
- **yason quirk:** a plain CL list serializes as a JSON **array**, not an object. The old code wrote `cffi-libraries` as the raw list (→ `["libfoo"]`), mismatching the spec's object form. New `serialize-cffi-libraries`/`deserialize-cffi-libraries` use a hash-table for the object form; deserialize still accepts the legacy array (yason parses JSON arrays as **lists** by default, not vectors) for old blobs.

### Local integration run (Docker registry `localhost:5050`)

- Start: `docker run -d --name oci-registry -p 5050:5000 registry:2`; verify `curl -fsS http://localhost:5050/v2/` returns `{}`.
- Run: `qlot exec sbcl --non-interactive` loading the 5 `.asd`s then `(asdf:test-system "cl-repository-integration-tests")`. **All passed** (~9 s after warm fasl cache).
- The relevant E2E test `install-and-load-native-overlay` exercises the changed path exactly: publish → install → `generate-init-file` → **`cffi:load-foreign-library` of the bundled `libcalc.dylib` + call into C** (returns version 1.0.0). Green. Confirms backward compat of the simple `("libcalc")` form through the full publish/install/load cycle.
- **Gotcha:** rove's end summary prints `All 1 test passed` for the integration system even though dozens of `deftest`s ran — it counts the package run, not assertions. Don't trust the count; grep the log for `✗`/`fail` to confirm (there were none). Native overlay tests need a working `cc` (they compile `libcalc` on the fly).

### `ocicl-compat` CI flake — transient read race in upstream ocicl

- **Symptom:** `ocicl-compat` job fails intermittently. Same commit content / same ocicl version (2.16.14) / same registry pass on re-run with no change.
- **Two distinct log lines, only one is fatal:**
  - `Error getting bearer token ... "404 page not found" ... not of type (VECTOR (UNSIGNED-BYTE 8))` — **benign noise present on every run** (passing too). ocicl probes `/token` on the no-auth `registry:2`, gets 404, falls back to anonymous.
  - `error downloading ... ; end of file on STRING-INPUT-STREAM from "{\"schema..."` — **the real, intermittent failure.** ocicl hits EOF parsing an otherwise-complete `200 OK` (correct `Content-Length`). Not registry readiness (`Registry ready` logged, 200s served) — a race in ocicl's Drakma/`Connection: close` HTTP read path.
- **Fix:** bounded retry around `ocicl install` in `tests/integration/test-ocicl-compat.sh` via `with_retries` helper, configurable through `OCICL_INSTALL_RETRIES` (default 3) and `OCICL_INSTALL_RETRY_DELAY` (default 3s). A genuine failure still exits 1 after N attempts (no masking). Pinning the ocicl version does **not** help — the race occurs within a single version.

### Code review 2026-07-02 — cl-repository + features hardening

- **`loop ... do (return X)` values get discarded when the loop is a non-final form.** `version-utils:compare-segments` computed segment differences in a loop, `return`ed -1/1 from it — then fell through to the length-based `cond`, throwing the result away. Net effect: `version<` was NIL for all same-segment-count versions ("1" < "2" → NIL), so `select-preferred-version` order was accidental and the SAT solver's "latest version" pick was alphabetical. Fixed by `(or (loop ...) fallback)`. Lesson: when a `loop` communicates via `return`, its value must be *used*; unit-test comparison predicates directly, not just through their consumers.
- **Rove counts packages, not deftests** (again — see integration note above). `× 1 of 11 tests failed` names the suite; grep the log for the failing `deftest` name.
- **Tar extraction must reject `..`/absolute/`~`-prefixed names** — `merge-pathnames` on SBCL expands `~/...` to HOME, so a hostile tar entry name is a traversal vector even without `..`. Also reject wildcard chars (`*?[`) — they build wild pathnames and `with-open-file` misbehaves.
- **OCI pulls need explicit digest checks**: descriptors carry digest+size, but `pull-blob` returns whatever the registry sends. Verify size + `verify-digest` on every config/layer blob at install time (`pull-verified-blob`).
- **devcontainer template boilerplate carries bugs**: the upstream `find_version_from_git_tags` "two-part version" check is `grep -o "." | wc -l` — counts *characters*, not dots, so exact pins still resolved via `git ls-remote`. Also `set -e` only (no `-u`/`pipefail`), unquoted expansions, and `curl -sSL` without `-f` (saves HTML error pages as tarballs).
- **Feature options are attacker-ish input**: `installPath` was interpolated into `/etc/profile.d`/rc files unvalidated (shell injection as root at build time). Validate option charsets before interpolation (`^/[A-Za-z0-9._/-]+$` etc.).

## 2026-07-02 — grpc / cl-protobufs OCI packaging review

- **SBCL `(directory #p"*")` skips files that have a type** (`grpc.so`, `libfoo.dylib`): `#p"*"` has `:type nil`, so only extensionless files match. Use `uiop:directory-files` to enumerate a directory — the grpc publish workflow shipped *empty* native overlays because of this. Also `(error ...)` when the collected file list is empty; silent empty layers pass CI.
- **Homebrew binaries are not portable artifacts.** brew's `protoc` links versioned brew dylibs by absolute path (`libprotoc.34.0.0.dylib`) — breaks off-machine *and* on the same machine after `brew upgrade`. Linuxbrew binaries are worse: their ELF interpreter is `/home/linuxbrew/.linuxbrew/lib/ld.so`. Ship the official static `protoc` release zip (`protoc-<v>-<platform>.zip`, links only libSystem/libc++) and bundle locally-built tools' brewish deps next to them.
- **Bundling recipe** (see `cl-protobufs/scripts/bundle-protoc-plugin.sh`): copy deps under their *referenced* name (ldd soname / `@rpath/NAME`), not the realpath basename — dyld/ld.so look up the load-command name. Linux: `patchelf --force-rpath --set-rpath '$ORIGIN'` (legacy DT_RPATH is inherited by transitive lookups; DT_RUNPATH is not). Darwin: resolve `@rpath/` deps against the referencing lib's dir + brew lib dir, rewrite to `@loader_path/`, then `codesign --force -s -` — install_name_tool invalidates ad-hoc signatures and arm64 kills unsigned code at exec/dlopen.
- **Verify native bundles by *running* them in a clean container** (`ubuntu:24.04`, no brew): `protoc --version`, plugin with empty stdin (protoc plugins exit 0 on empty CodeGeneratorRequest), then a real codegen. `ls`/`otool` checks alone miss interpreter and signature problems.
- **Prefer-bundled-tool logic needs a runtime probe**: if the overlay's binary doesn't exec (foreign arch, missing deps), fall back to PATH lookup instead of shadowing a working system tool (`find-protobuf-tool` in `cl-protobufs/asdf.lisp`).
- **GitHub arm64 hosted runner label is `ubuntu-24.04-arm`**, not `ubuntu-24.04-arm64`. The wrong label queues forever (or fails); act won't catch it.

### First real CI publish runs (workflow_dispatch, 2.0-rc1 / 0.9-rc1) — three more failure modes

- **`build-package` tars the *entire* source-dir into the source layer.** Overlay files staged inside the checkout (`native-artifacts/`, `lib/`, `generated/`) get swept into every published source tarball — ~80 bundled dylibs per platform in the "source" layer. Stage overlays under `$RUNNER_TEMP` (CI) or a `/tmp` dir (local scripts) and pass the root to publish.lisp via env var. `.gitignore` does not help; the packager doesn't consult it.
- **`split-tar-name` (packager) crashed on 101-155 char entry names**: the ustar split scan started at `(char name (min (length name) 155))` — one past the end for names in that range. Exactly what deep staged artifact paths produced. Fixed in cl-repository (start at `(1- (length name))`; unsplittable names now signal instead of silently truncating to 100 chars). Boundary-test anything that splits fixed-size header fields.
- **GHCR: the shared `<namespace>/catalog` package is writable only by the repo whose workflow created it.** Other repos' `GITHUB_TOKEN`s get 403 pushing catalog referrers *after* the package published fine. Packager now warns instead of dying; publishing repos can pass `:skip-catalog t` (or grant repo access in the package's Actions settings).
- **Pre-existing red CI is not your red CI, but check**: cl-protobufs ABCL-Tests has failed since 2026-03 (`COMPILE-CONSTANT unhandled case HASH-TABLE` — ABCL can't dump hash-table literals in some upstream file); grpc SBCL/CCL tests crash in `grpc_cq_begin_op` because the workflow builds gRPC C++ from *upstream master* at test time — version drift, unrelated to packaging changes. Verify by finding the same failure on the base branch / previous runs.

## 2026-08-03 — cl-repo CI on Windows / multi-phase OpenSSL

- **`http-protocol` OCI must ship `tests/`** if consumers depend on `http-protocol/conformance`. Staging only `src/` makes encoding CI fail with missing `tests/conformance/package.lisp` even though the `.asd` declares the secondary system.
- **Never ASDF-load / `ql:quickload` mid-flight while still pulling from GHCR via dexador/cl+ssl.** Loading OCI `cffi` (or event-backend deps) invalidates `CL+SSL::PEM-PASSWORD-CALLBACK` → later pulls fail with `Undefined callback`. Phase 1 = install-to-disk only; load in a fresh image after overlay OpenSSL is on the loader path.
- **`cl-stack-ssl` cl-repo-init rewires CFFI** — install it last in the fetch phase (or only load init in the test image). Installing it early + `load-system-init-files` also breaks subsequent HTTPS.
- **Windows SBCL NB connect**: WSAEWOULDBLOCK (10035) often surfaces as `EINTR (...could not be completed immediately.)`. Treat that (and `INTERRUPTED-ERROR`) as connect-in-progress / would-block, not hard failure.
- **OCI `cl-unicode:0.1.6` lacks `idna-mapping`** (QL tip has it). Until republished from a newer pin, force `("cl-unicode" :ql)` via cl-repo `:sources`.

## 2026-08-03 — New first-party repos: cl-repository CI, not qlot

- **Symptom:** `ws-protocol` (wave-1, brand-new) shipped `qlfile` + `qlot exec` CI while MEMORY already required cl-repository for project deps. WSS/#35 CI then fought qlot (`CL_SOURCE_REGISTRY` rewritten; nested `qlot exec` → `Component "dexador" not found` for qlot itself).
- **Cause:** Muscle memory from older checkouts / REQUIREMENTS still mentioning qlot; “new repo” scaffold copied the qlot path instead of `http-backend-dexador`/`async`’s `scripts/ci-install.lisp` + cl-repo client.
- **Fix:**
  - New first-party systems ship **`scripts/ci-install.lisp` + `scripts/ci-test.lisp`** and checkout `egao1980/cl-repository` in CI from day one. Do **not** add `qlfile` as the install story.
  - Unpublished deps (e.g. `websocket-driver` / `clack` not yet in `cl-stack-systems/imports/`) → temporary **QL fallback inside `ci-install`**, then import+publish to `ghcr.io/egao1980/cl-systems`.
  - Overlay natives (`cl-stack-ssl`): still stage `native/` onto the **process loader path before SBCL starts** (Linux ignores mid-process `LD_LIBRARY_PATH`); Lisp package itself via `cl-repo:install-system`, install **last**, load only in the test phase.
  - Local docs should point at the CI-shaped cl-repo flow, not `qlot install`.
- **Also:** Rove `(skip …)` does **not** abort the `deftest` — gate with `if`/`return-from`, or the “skipped” body still runs (e.g. spawned a WSS child after `skip`).
- **Also:** Hunchentoot/Clack SSL + cl+ssl teardown can SIGSEGV on `clack:stop` / image exit (esp. darwin). WSS smoke: run assertions then `sb-ext:exit :code 0 :abort t` (child process), don’t destroy SSL acceptor threads in-process.

- **`cl-base64:latest` on GHCR:** `oras repo tags` may list `latest` while `oras pull …:latest` / cl-repo install get HTTP 404 `MANIFEST_UNKNOWN`. Pin explicit `3.1` (same class of bug as `cl-protobufs:latest` → 0 files). Prefer explicit OCI versions in `ci-install`.

- **cl-repo CI two-phase + QL fallback:** Phase-1 `ql:quickload` does **not** make systems visible to a fresh Phase-2 SBCL via ASDF alone. Re-`ql:quickload` the unpublished stack in `ci-test.lisp` (or install into cl-systems). Do all OCI `install-system` calls **before** any QL load that pulls cffi/cl+ssl.

## 2026-08-04 — http-backend-async#12: Windows recv -1-as-unsigned; libev cross-thread stop

- **Windows SBCL `socket-receive` can leak `recv()`'s `-1` (WSAEWOULDBLOCK) as an unsigned count** (`4294967295`) instead of signaling. Feeding that "count" to the parser produced `INVALID-VERSION` from stale buffer bytes — only on pooled keep-alive reuse, where `adopt-pooled`'s manual `on-io` tick reads before data arrives. Guard **both** `socket-recv-octets` and `socket-send-octets`: any count outside `[0, len]` = would-block (NIL). Diagnose this class by embedding `n` + raw bytes in the parse-error message.
- **libev `ev_break` is only valid inside `ev_run` callbacks.** Calling `stop` from a worker thread (e.g. a body-stream slurper) is silently lost: loop sits in `select()` forever with only the ref'd async watcher. Symptom set: `test-want-stream-body` hangs; `sample` shows main in `ev_run → select_poll`, worker already exited. Fix in event-backend-libev 0.1.1: off-loop `stop` routes through `wake-call` (ev_async_send). libuv "works" only because `uv_stop`'s flag persists and any later event wakes the loop — same latent race, consider the same treatment.
- **Windows case-insensitive env in tests:** `(setf (uiop:getenv "http_proxy") …)` then unsetting `HTTP_PROXY` clears the value just set. Apply env bindings unset-first, then set.
- **Debug loop that worked:** repro locally (`rove:run-test` in 30x loop; libev hang reproduced on macOS), `sample <pid>` for stacks, print-trace the await/stop sequence, and only then burn CI rounds — with byte-capture diagnostics so one Windows run answers "what did the parser see".

## 2026-08 — http-server-protocol publish / Woo CI

- **ASDF secondary systems need their own `.asd` files.** Defining `http-server-backend-*` inside `http-server-protocol.asd` made `cl-repo:ensure-system-dependencies` fail with “system not findable” even with `CL_SOURCE_REGISTRY=$(pwd)//:`. Mirror `json-protocol` (`json-backend-*.asd`).
- **`workflow_dispatch` empty `version` is truthy in CL.** `(or (uiop:getenv "PKG_VERSION") asd-version)` returns `""` and publishes OCI tag `:` → GHCR 404. Treat blank string as missing before falling back to `.asd` `:version`.
- **Woo CI + babel:** client bootstrap QL-loads babel (NIL fillers); GHCR `babel:latest` uses `0` → `sb-ext:defconstant-uneql` during woo load. Prefer `:sources '(("babel" :ql) …)` for Woo job and wrap load in `(handler-bind ((sb-ext:defconstant-uneql #'continue)) …)`.

## 2026-08-07 — cl-stack#165: ensure-system-dependencies + :ql drops OCI packages

- **Symptom:** `(cl-repo:ensure-system-dependencies …)` prints `tomlet not found in any registry` while `(cl-repo:load-system "tomlet" :version "0.1.0")` succeeds.
- **Cause:** `compute-install-plan` ran OCI SAT for every missing name. With `:sources '(("tomlet" :ql))` (OCI-only package forced to QL), `oci-allowed-p` is false → SAT errors → `dependency-resolution-error` handler **only logged** and neither queued QL nor fell through to direct OCI (unlike the generic `error` handler). tomlet is not on Quicklisp.
- **Fix:** cl-repository — `:ql`-only → QL accumulator; resolution-error → direct OCI if allowed else QL. Demos — remove `("tomlet" :ql)` from `local-install.lisp`.
- **Rule:** never put OCI-only pins in `:sources … :ql`. Prefer default `:any` or explicit `:oci`.

## 2026-08 — ECL local smoke (multi-impl #42)

- **Symptom:** Agents hang or fail immediately on Homebrew ECL.
- **Cause:** (1) `asdf:…` at read time before `(require :asdf)`; (2) interactive debugger without `--nodebug`; (3) brew ECL ships ASDF 3.1.8.11.
- **Fix:** `--load` scripts; `(require :asdf)` first; `ecl --norc --nodebug -q`; `*debugger-hook*` → `si:quit`. Crypto/secrets Rove suites pass on ECL 26.5.5 with QL + `load-asd`.
- **Also:** `'(("x" :ql), ("y" :ql))` → `Comma not inside a backquote` — strip commas from `:sources` (same footgun as crypto CI earlier).

## ABCL + cl-repository OCI (2026-08-07)

- **chipz:** ABCL is not in chipz’s Gray-streams feature list → `make-decompressing-stream` errors. Fix: `chipz:decompress` buffer API in `cl-repository-client/installer` (`gunzip-octets`).
- **JNA:** CFFI on ABCL needs `jna` + `jna-platform` on `CLASSPATH` (else `Class not found: com.sun.jna.Pointer`). Java 21+: `--enable-native-access=ALL-UNNAMED` and `--add-opens=java.base/java.io=ALL-UNNAMED`.
- **Symptom without buffer gunzip:** `ensure-system-installed` logs `not in ghcr.io (make-decompressing-stream…)` and silently skips first-party deps → later `System "…" not found` at test time.

## 2026-08-07 — event-protocol/conformance secondary OCI shadows primary

- **Symptom:** CI installs `event-protocol:0.1.2` then still pulls `event-protocol/conformance:0.1.1` and ASDF loads **0.1.1** (ABCL dies on bare `sb-unix:` in old `asyncio-io.lisp`).
- **Cause:** Older publish listed `event-protocol/conformance` in `:provides`, creating a separate GHCR package. Later “protocol-only” publish omitted that provide, so the stale secondary stayed preferred when resolving the subsystem name.
- **Fix:** Republish primary with `provides = (event-protocol event-protocol/conformance)` (not `*/tests`). Optionally `ensure-systems` the primary + `configure-asdf-source-registry` before `ensure-system-dependencies` so the subsystem is already findable.
- **Rule:** If backends depend on a subsystem name as an ASDF system, keep that name in OCI `:provides` whenever you bump the primary — or delete the orphan secondary package.

## 2026-08-07 — gh pr merge + workflow scope

- OAuth `GITHUB_TOKEN` without `workflow` scope refuses `gh pr merge` when the PR touches `.github/workflows/*`.
- **Workaround:** merge locally (`git merge` / ff onto `main`) and `git push origin main` (SSH).

## 2026-08-08 — CCL Darwin arm64 ObjC "N-word heisenbug" was tagged pointers

Symptom: `#/substringWithRange:` on short NSStrings (`"abcdef"`) failed ~half the time with `TYPE-ERROR` (Foreign Pointer ≠ objc-object); long strings were fine. Looked like NSRange/N-word FFI.

Root cause: Apple arm64 ObjC **tagged pointers** (bit 63 set). `tagged-objc-instance-p` still used the **x86_64** low-nibble test, so many tagged NSStrings were treated as heap objects → `safe-get-ptr` on a non-address → `recognize-objc-object` failed. Process-stable because the same short string → same tagged bit pattern.

Fix: arm64 branch of `tagged-objc-instance-p` (MSB + split basic/extended tag). N-word expand (x8664-style `%%get-unsigned-longlong`) still useful but was not the flake.

Require OBJC-SUPPORT still SIGBUS/SIGSEGV flaky (~30%) — separate issue.

## CCL darwinarm64 NXArgv paref (2026-08-08)

- **Symptom:** intermittent SIGSEGV in `os_unfair_lock_lock` during `(require "OBJC-SUPPORT")` / Cocoa `dlopen`; fault address often `cs_area.high+0x4c10`.
- **Cause:** `objc-runtime.lisp` cleared argv with `(paref (%get-ptr NXArgv) (:* :char) 1)` — that indexes **bytes**, smashing `argv[0]` mid-pointer. Correct element type for `char**` is `(:* (:* :char))` (see `library/jni.lisp`).
- **Fix:** use `(:* (:* :char))` + `(%null-ptr)`.

## 2026-08 — CCL local smoke (multi-impl #42)

- **Symptom:** `ros install ccl` / `ros install ccl-bin` fail or refuse on Apple Silicon.
- **Cause:** Roswell target is **`ccl-bin`** (not `ccl`). Install script hard-errors on `uname-m = arm64`. Upstream CCL 1.13 has **no darwin/arm64** port.
- **Fix:** Local probe = Clozure `ccl-1.13-darwinx86.tar.gz` under Rosetta (`arch -x86_64 ./dx86cl64 --no-init --batch`). CI = `ros install ccl-bin` on **ubuntu-latest (amd64)** only. Crypto/secrets Rove suites pass on CCL 1.13; PBKDF2 is very slow under Rosetta (~2 min/verify).

## 2026-08 — CLISP MT unusable on clean Ubuntu (multi-impl #42)

- **Symptom:** Cannot smoke Ironclad/crypto on CLISP in CI-shaped Linux.
- **Cause:** (1) Ubuntu/Homebrew CLISP ship without `:mt` → bordeaux-threads rejects. (2) Building 2.49.92 with `--with-threads=POSIX_THREADS` in clean `ubuntu:24.04`: **arm64** `interpreted.mem` bootstrap **hangs** (0% CPU); **amd64** bootstrap **SIGSEGV** in GC (`Fault address = 0xa8`). Configure help: threads “highly experimental”. Wrong flag `POSIX` (need `POSIX_THREADS`); aarch64 also needs `-DNO_GENERATIONAL_GC` (no fast spinlocks) before you even reach the hang.
- **Fix / policy:** No `test-clisp` job. Track in `cl-stack/docs/multi-impl.md`. Do not `continue-on-error` apt clisp.

## 2026-08-13 — Stack review: default branches, jzon vectors, CRLF, publish version stamping

- **GitHub default branch left on a merged `cursor/*` branch is a time bomb.** `sql-query` default sat on `cursor/sql-query-dsl-3a7a` (33 behind main) after the PR merged; every `actions/checkout` without `ref:` (sql-orm `_deps`), publish-checkout matrix entries, and "browse the repo" views got stale code — sql-orm main went red with `no class named DROP-TYPE-STATEMENT`. After merging a PR from a branch that is the repo default, reset the default to `main` before deleting anything. Same cleanup found ~330 stale merged `cursor/*` branches across the stack (squash-merged branches show "ahead" in compare — check merged PRs by head ref, not just `compare.ahead_by`).
- **json-protocol arrays are vectors — consumers written in the yason era break via `:latest`.** cl-stack-http 0.1.8 switched `response-json` to json-protocol/jzon (arrays → vectors, `:null`); http-parity's demo `mapcar` TYPE-ERRORed only when CI moved to client `:latest` and silently picked up the new stack. Use sequence ops (`map 'list …`) on parsed JSON arrays; grep for `mapcar`/`dolist` over `response-json` results when migrating.
- **`read-line` keeps the `#\Return` of CRLF records.** sql-query-csv keywordized a header as `:|CITY^M|` on Windows (git autocrlf) — right-trim `#\Return` at the record level per RFC 4180; don't rely on `.gitattributes`.
- **Rove `:perform (test-op … (symbol-call :rove :run c))` swallows failures.** `rove:run` returns a boolean; without `(unless … (error …))` failing tests keep `asdf:test-system` (and CI) green. cl-stack-pathlib/brotli/zstd all had this.
- **Publish version overrides must land before `build-package`.** cl-stack-systems `imports/<name>/version` was applied to the spec *after* the packager built the tarball/config/annotations — `cl-unicode:0.1.7` shipped a `cl-unicode-0.1.6/` tarball with `version: 0.1.6` annotations (tag was the only 0.1.7). The client still extracts (strip prefix comes from the config blob) but installs under the wrong version dir and `:latest`-anchor reads the stale annotation. Fixed by building the spec, forcing the version, then `build-package` (cl-stack-systems#24/#25); packager-side `:version` parameter proposed in cl-stack#174.
- **QL cl-unicode is also too old for IDNA.** The Quicklisp dist predates edicl/cl-unicode#22, so `("cl-unicode" :ql)` pins never provided `idna-mapping` — they only worked where a sibling checkout shadowed them. OCI `cl-unicode:0.1.7` (edicl master) is the fix; pins removed from http-protocol, http-encoding-*, cl-stack-demos.
