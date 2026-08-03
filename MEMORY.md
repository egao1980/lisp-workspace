# Workspace memory

Durable **user instructions and preferences** for this Lisp workspace (similar in spirit to Claude Code's project memory). **Agents should read this file** when starting work here and **edit it** when the user states a preference that should persist across sessions.

Keep entries **short and actionable**. Remove or supersede items that go stale.

---

## How to use

- **User:** add bullets under the sections below, or tell the agent to record something here.
- **Agent:** after the user gives a standing instruction (tool choice, style, workflow, "always…", "never…"), add or update a line here and commit in `.lisp-workspace/` when appropriate.

---

## Preferences

- **Python touchpoints:** uv + ruff; line length 120; no black; modern typing (3.12+); optimize imports.
- **Documentation:** terse; no verbose boilerplate.
- **CL MCP:** use [cl-ai-project/cl-mcp](https://github.com/cl-ai-project/cl-mcp), not the quasi/cl-mcp stack.
- **GitHub repos:** always use full `owner/repo` — never bare repo name when multiple owners share a name.

## Standing instructions

- **Package / project deps = cl-repository.** CI and local installs use `cl-repository-client` (`cl-repo:add-registry` + `cl-repo:load-system` / lockfile restore) against `ghcr.io/egao1980/cl-systems`. **Bootstrap the client from OCI** — `oras pull ghcr.io/egao1980/cl-repository/cl-repository-client:<ver>` (current pin **`0.10.0`** / `latest`; older mirror under `ghcr.io/egao1980/cl-systems/cl-repository-client` ≤0.6.6 — prefer the `cl-repository/` namespace). Extract + QL for *client* bootstrap deps only. Packager: `ghcr.io/egao1980/cl-repository/cl-repository-packager:0.10.0`. **Do not git-checkout `cl-repository` in consumer CI** — that checkout is only for developing cl-repository itself. No qlot / `ros install` / sibling git checkouts / hand-rolled `oras pull` of natives for *project* deps. Unpublished imports may temporarily QL-fallback via cl-repo/`ci-ensure-ql` until published into `cl-stack-systems`. **New first-party repos must ship `scripts/ci-install.lisp` + cl-repo CI from day one** — do not add `qlfile` as the project install story (qlot remains legacy on some older checkouts until migrated).
- **No sibling checkouts (CI + install path).** Allowed `actions/checkout` in a consumer workflow: **only the repo under test**. Bootstrap `cl-repository-client` via **GHCR OCI** (above). Forbidden: checking out `cl-repository`, `http-protocol`, `event-protocol`, `event-backend-*`, `cl-stack-ssl`, or any other dep as a sibling path for ASDF. Deps come from **GHCR via cl-repo** (QL fallback only for unpublished). Workspace sibling clones for *local editing* are fine; never treat them as the CI/install dependency source.
- **Unforked third-party deps:** add to **[`egao1980/cl-stack-systems`](https://github.com/egao1980/cl-stack-systems)** (`imports/<name>/qlfile`) for OCI republish into `ghcr.io/egao1980/cl-systems`. Fork/checkout only when patching or shipping native overlays. One import dir per upstream pin (CI matrix isolation). Seeded set: see `cl-stack-systems/imports/IMPORTS.md` (chipz/salza2, mime/quri/idna support libs, cffi, cl+ssl, …).
- **Fork ↔ import exclusivity:** never both. Fork ⇒ delete `cl-stack-systems/imports/<name>/`. Import ⇒ no workspace fork of that lib.
- **Native overlays:** resolve via `cffi:*foreign-library-directories*` + absolute preload (`cl-repo-init.lisp` / `ensure-*`). **Never** require `LD_LIBRARY_PATH` / `DYLD_LIBRARY_PATH` for correctness (Linux ignores mid-process `setenv`; see cl-repository `docs/requirements/native-deps.md`).
- **cffi OCI:** `ghcr.io/egao1980/cl-systems/cffi:0.24.1` (cl-stack-systems import; upstream asd has no `:version` — publish forces qlfile pin).

- Plan before acting on new projects or massive changes; use git to preserve initial state and track in a branch.
- Run tests before declaring done.
- Use feature branches in subproject repos.
- **Before deleting "dead" code** (unused params/vars/functions), check it isn't scaffolding for a planned-but-unimplemented feature — grep TODO/docs/requirements + `git log -S`. If planned: keep it and document the reserved intent (e.g. `;; TODO(<area>)`) rather than removing.
- When a skill proves wrong or incomplete during use, append the correction to `skills/<name>/STAGED.md` rather than editing SKILL.md in-flight.
- **Never push or create PRs to `CommonLispNext/cl-repository`** — all work stays in **`egao1980/cl-repository`**. Rebase/merge against upstream locally, but push only to the fork.

## Project-specific notes

- **http-protocol:** [`egao1980/http-protocol`](https://github.com/egao1980/http-protocol) — **urllib3/httpx layer** (not requests). Transport policy in protocol: `http-timeout`, `http-retry`, `http-proxy-config` (dexador#202 shape), `http-connection-pool` / `pooled-body-stream`. Wire bodies = streams/octets/strings/`http-file` only — **no FS**. Sync path = await on async engine (dexador = maintenance). Async: [`http-backend-async`](https://github.com/egao1980/http-backend-async) × libuv/libev; usocket; cl-stack-ssl WANT_*; `sleep* 0` next-tick. Live CE: `HTTP_ASYNC_LIVE=1`. Windows proxy auth / AUTOMATIC / NTLM SSO: [`http-backend-winhttp`](https://github.com/egao1980/http-backend-winhttp) (`WINHTTP_FLAG_ASYNC`, Gray streams, cancel); CI = cl-repo only (`windows-latest` + ubuntu stubs).
- **cl-stack-http:** [`egao1980/cl-stack-http`](https://github.com/egao1980/cl-stack-http) (nick `stack-http`) — **requests-like** layer over `http-protocol`: JSON (yason) + `:sexp` serdes, pathlib upload/download (`path-http-file` / `download` / `upload`), `with-session`, platform backend select (`:auto`/`:dexador`/`:async`/`:winhttp` via `ensure-http-backend`). Pins: `http-protocol:0.2.0`, `cl-stack-pathlib:0.1.1`, backends `0.1.1`.
- **ws-protocol:** [`egao1980/ws-protocol`](https://github.com/egao1980/ws-protocol) — wave-1 **done** (`cl-stack#4` closed): cleartext + WSS/`cl-stack-ssl` + hub corpus `tests/corpus/ws/echo-frames/`. cl-repo CI (`scripts/ci-*.lisp`). QL fallback only for unpublished WS stack (`websocket-driver`/`clack`/…) until `cl-stack-systems` imports land.

- **MIME:** pin fork [`egao1980/cl-mime`](https://github.com/egao1980/cl-mime) of [`40ants/cl-mime`](https://github.com/40ants/cl-mime) (hanshuebner lineage) for MIME parse/print + CTE (`decode-content`/`encode-content` = base64/qp/7bit). OCI: `ghcr.io/egao1980/cl-systems/cl-mime:0.5.1` (source-only). **Not** HTTP `Content-Encoding` (gzip/br/zstd) — that stays chipz/salza2 + cl-stack-brotli/zstd.

- `cl-mcp/` upstream is cl-ai-project (not quasi); fork is egao1980/cl-mcp.
- `features/` is the devcontainer features repo — not an ASDF library.
- **OCI publish + consumer test (cl-protobufs / grpc):** run **`act`** against `publish-oci.yml` with local registry + artifact server, then verify in a **roswell devcontainer** with **`cl-repository`** mounted and `host.docker.internal` to the registry. Full command pattern and pitfalls → **`.lisp-workspace/LESSONS_LEARNED.md`** (section *act + local OCI registry + devcontainer*).
- **cl-repository overlay keys:** platform specs support **`os` / `release` / `arch`** (not just `os` / `arch`). This means overlays can be keyed per distro release (e.g. `ubuntu-24.04/arm64` vs `ubuntu-26.04/arm64`) when native binaries are glibc-sensitive. Current workflows use bare `linux` / `darwin` — sufficient while building on the oldest supported LTS.
- **cl-stack-pathlib** (`egao1980/cl-stack-pathlib`, nick `stack-pathlib`): merged to `main` (PR #1). CLOS `path` + `filesystem` protocol (local/memory), pathlib-shaped facade, condition restarts (`create-parents`, `create-file`, `overwrite`, …). Tracking: `egao1980/cl-stack#40` (closed). SBCL collapses `:BACK` in pathnames — store `".."` as a string directory component.
- **Sockets:** prefer portable **usocket** over SBCL `sb-bsd-sockets`; skip **iolib** for Windows-primary code (Unix-only).
- **Platform matrix:** **Windows is a primary target** (with linux/darwin) — not “later / stretch”. Overlay Done-when bars include `windows/amd64` (see `cl-stack/docs/overlays.md` Required row). Prefer `libuv` for anything that must run on Windows; libev/Woo/`lev` stay Unix-only second backends.
- **CFFI grovel policy:** Grovel **at overlay build time** (CI / Windows builder), ship `cffi-grovel-output` → `grovel-cache/`. Main packages may declare `grovel-file` for local-dev fallback, but consumers with cl-repository overlays must load **without** a C toolchain. Do not treat “no grovel on Windows” as a goal — treat “no grovel on consumer machines” as the goal.
- **cl-stack event-protocol:** app DX = **promises**; default **libuv** (Windows primary); second **libev** (Unix). **Separate GitHub repos per layer** (not colocated): `egao1980/event-protocol` (generics + shared conformance), `egao1980/event-backend-libuv`, `egao1980/event-backend-libev`. Grovel-at-overlay-build. Brief `cl-stack/docs/capabilities/event-protocol.md`.
- **IDNA / URI pins:** [`egao1980/cl-idna`](https://github.com/egao1980/cl-idna) (IDNA2008 / UTS #46) — not `antifuchs/idna`. OCI: `ghcr.io/egao1980/cl-systems/cl-idna:0.1.0`. Fork [`egao1980/quri`](https://github.com/egao1980/quri) `0.7.1` → `cl-idna:to-ascii`; OCI `ghcr.io/egao1980/cl-systems/quri:0.7.1`. **No upstream PR to fukamachi/quri** until `cl-idna` is on Quicklisp.
- **HTTP Content-Encoding (wave-1):** gzip/deflate (**chipz**/**salza2**) + **br** + **zstd**. Overlays: [`cl-stack-brotli`](https://github.com/egao1980/cl-stack-brotli) Brotli **v1.2.0** → `ghcr.io/egao1980/cl-systems/cl-stack-brotli:1.2.0`; [`cl-stack-zstd`](https://github.com/egao1980/cl-stack-zstd) Zstd **v1.5.7** → `ghcr.io/egao1980/cl-systems/cl-stack-zstd:1.5.7` (linux/amd64+arm64, darwin/arm64, windows/amd64). Brief: `cl-stack/docs/capabilities/http-protocol.md`.
