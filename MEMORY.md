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

- **Living quickstart:** [`cl-stack/docs/QUICKSTART.md`](https://github.com/egao1980/cl-stack/blob/main/docs/QUICKSTART.md) — bootstrap cl-repository-client + current OCI pins + minimal HTTP/event. **Update the pin table + snippets in the same PR that publishes a user-facing feature.**

- **Package / project deps = cl-repository.** CI and local installs use `cl-repository-client` (`cl-repo:add-registry` + `cl-repo:ensure-system-dependencies` / `ensure-systems` / `load-system`) against `ghcr.io/egao1980/cl-systems`. **Bootstrap the client from OCI** — `oras pull ghcr.io/egao1980/cl-repository/cl-repository-client:<ver>` (current pin **`0.11.0`**; older mirror under `ghcr.io/egao1980/cl-systems/cl-repository-client` ≤0.6.6 — prefer the `cl-repository/` namespace). Extract + QL for *client* bootstrap deps only. Packager: `ghcr.io/egao1980/cl-repository/cl-repository-packager:0.10.0`. **Do not git-checkout `cl-repository` in consumer CI** — that checkout is only for developing cl-repository itself. No qlot / `ros install` / sibling git checkouts / hand-rolled `oras pull` of natives for *project* deps. Unpublished deps QL-fallback inside the client. **New first-party repos must ship `scripts/ci-install.lisp` + cl-repo CI from day one** — do not add `qlfile` as the project install story (qlot remains legacy on some older checkouts until migrated).
- **`ci-install.lisp` = thin `ensure-system-dependencies`.** Load client → `add-registry` `egao1980/cl-systems` → `(cl-repo:ensure-system-dependencies "<sut>" :also-tests t :with '(…ci-only…) :sources '(…))` → quit. Deps come from the SUT `.asd` (+ `/tests`); `:with` only for CI extras not in the asd (event backends, `cl-stack-ssl`, soft http2 libs). No hand-curated `ci-fetch`/`ci-ql` lists. Phase split: ensure installs without ASDF-load; `ci-test` loads + tests. Client order = OCI (GHCR packages published from GitHub) then QL.
- **No sibling checkouts (CI + install path).** Allowed `actions/checkout` in a consumer workflow: **only the repo under test**. Bootstrap `cl-repository-client` via **GHCR OCI** (above). Forbidden: checking out `cl-repository`, `http-protocol`, `event-protocol`, `event-backend-*`, `cl-stack-ssl`, or any other dep as a sibling path for ASDF. Deps come from **GHCR via cl-repo** (QL fallback only for unpublished). Workspace sibling clones for *local editing* are fine; never treat them as the CI/install dependency source.
- **Publish metadata = `.asd`.** `auto-package-spec` reads ASDF fields + `:properties (:cl-repo …)` (`:provides` / `:cffi-libraries` / `:overlays`). That is enough — no hand-written `package-spec` in repo scripts. Skill: **`cl-repository-ci`**.
- **Who publishes where (GHCR ACL):** Package write is tied to the **owning GitHub repo**. **First-party `egao1980/<repo>`** (http-protocol, backends, ws, encodings, cl-stack-*, …) → publish **from that repo** (`publish-checkout.yml` / native reusable workflow). Do **not** route owned first-party packages through `cl-stack-systems` (its `GITHUB_TOKEN` gets `write_package` denied). **`cl-stack-systems`** = **third-party / unmodified** imports only (`imports/<name>/qlfile` + shared `publish.yml`). Natives stay on the reusable native workflow in the owning repo.
- **Fork ↔ import exclusivity:** never both for the same upstream. Fork ⇒ delete `imports/<name>/` of upstream.
- **Native overlays:** resolve via `cffi:*foreign-library-directories*` + absolute preload (`cl-repo-init.lisp` / `ensure-*`). **Never** require `LD_LIBRARY_PATH` / `DYLD_LIBRARY_PATH` for correctness (Linux ignores mid-process `setenv`; see cl-repository `docs/requirements/native-deps.md`).
- **cffi OCI:** `ghcr.io/egao1980/cl-systems/cffi:0.24.1` (cl-stack-systems import; upstream asd has no `:version` — publish forces qlfile pin).

- Plan before acting on new projects or massive changes; use git to preserve initial state and track in a branch.
- Run tests before declaring done.
- Use feature branches in subproject repos.
- **Before deleting "dead" code** (unused params/vars/functions), check it isn't scaffolding for a planned-but-unimplemented feature — grep TODO/docs/requirements + `git log -S`. If planned: keep it and document the reserved intent (e.g. `;; TODO(<area>)`) rather than removing.
- When a skill proves wrong or incomplete during use, append the correction to `skills/<name>/STAGED.md` rather than editing SKILL.md in-flight.
- **PRs:** do **not** close open PRs silently (e.g. for conflicts or “superseded”). When asked to merge / clear the board: **fix conflicts, update the branch, and merge**. Close only if the user explicitly says to close/abandon, or the PR author asks to.
- **Upstream PR branches:** never `gh pr merge --delete-branch` (or otherwise delete) a branch that is the head of an **open upstream PR** (e.g. `egao1980/rove` `cursor/parametrize-3a7a` → fukamachi/rove#76). Delete only after upstream merges or the upstream PR is intentionally abandoned.
- **Never push or create PRs to `CommonLispNext/cl-repository`** — all work stays in **`egao1980/cl-repository`**. Rebase/merge against upstream locally, but push only to the fork.

## Project-specific notes

- **HTTP version design:** RFCs first (7301 ALPN, 9113 H2). CLOS split — **http-protocol** owns preference (`:auto`/`:http/1.1`/`:http/2`), ALPN offer/map, H2 header-field policy (`make-http2-request-headers`), `backend-http-versions`; **backends** own TLS ALPN, framing/HPACK (or OS H2), `response-http-version`. No framing in protocol; no ad-hoc Host/Connection on H2 wire.
- **http-protocol:** [`egao1980/http-protocol`](https://github.com/egao1980/http-protocol) — **urllib3/httpx layer** (not requests). Transport policy in protocol: `http-timeout`, `http-retry`, `http-proxy-config` (dexador#202 shape), `http-connection-pool` / `pooled-body-stream`. Wire bodies = streams/octets/strings/`http-file` only — **no FS**. Sync path = await on async engine (dexador = maintenance). Async: [`http-backend-async`](https://github.com/egao1980/http-backend-async) × libuv/libev; usocket; cl-stack-ssl WANT_*; `sleep* 0` next-tick. Live CE: `HTTP_ASYNC_LIVE=1`. Windows proxy auth / AUTOMATIC / NTLM SSO: [`http-backend-winhttp`](https://github.com/egao1980/http-backend-winhttp) (`WINHTTP_FLAG_ASYNC`, Gray streams, cancel); CI = cl-repo only (`windows-latest` + ubuntu stubs).
- **cl-stack-http:** [`egao1980/cl-stack-http`](https://github.com/egao1980/cl-stack-http) (nick `stack-http`) — **requests-like** layer over `http-protocol`: JSON (yason) + `:sexp` serdes, pathlib upload/download, Session, Digest/netrc, CLOS auth protocol + request hooks. OCI **0.1.6**. Typical pins: `http-protocol:0.3.0`, `cl-stack-pathlib:0.1.1`, backends async **0.2.0** / dexador·winhttp **0.1.2**.
- **Auth packages (Python-shaped):** [`cl-stack-oauth2`](https://github.com/egao1980/cl-stack-oauth2) **0.1.0** (scopes/grants/PKCE/401); [`cl-stack-jwt`](https://github.com/egao1980/cl-stack-jwt) **0.1.0** over jose (`cl-stack-systems` import → OCI `jose:0.1.0`).
- **ws-protocol:** [`egao1980/ws-protocol`](https://github.com/egao1980/ws-protocol) — wave-1 **done**; **0.2.2** = CLOS `:transport` + `feature-or-env-enabled-p` + `scripts/demo.lisp`. **winhttp 0.1.3** = H1 WS (`WINHTTP_WS_LIVE`). **async 0.2.4** = loop-native Extended CONNECT + `scripts/demo-ws.lisp`. Cookbook: `cl-stack/docs/cookbooks/websocket.md`.. QL fallback for unpublished WS stack (`websocket-driver`/`clack`/…) until `cl-stack-systems` imports land.

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


- **http-parity:** [`egao1980/http-parity`](https://github.com/egao1980/http-parity) — demo/CI canary for cl-stack-http vs requests/httpx. Default origin = local httpbin fixture (`HTTP_PARITY_FIXTURE=1`); prefer `:async` + libuv. Public httpbingo often 402s async TLS at Fly edge. Realistic app: `ros -l scripts/demo.lisp` (login → JSON catalog → download). Live CE+CD: `ros -l scripts/finance-demo.lisp` (Frankfurter + Fin-node; `HTTP_PARITY_FINANCE=1` for Rove). Pins: `http-protocol:0.2.3`, `cl-stack-http:0.1.6`, `http-backend-async:0.1.3`, `event-protocol:0.1.1`.
- **http-protocol 0.2.3:** `response-elapsed` / `response-bytes-downloaded` slots. 0.2.2 = multi-value `:params`/`:form-data` lists + NIL drop; 0.2.1 = `http-request-extras` + client `base-url` join.
- **rove fork:** [`egao1980/rove`](https://github.com/egao1980/rove) — `deftest-parametrize` (upstream [fukamachi/rove#76](https://github.com/fukamachi/rove/pull/76)); pin fork until merge. Design: `cl-stack/docs/ROVE-PARAMETRIZE.md`.
- **Cookbook:** [`cl-stack/docs/cookbooks/http-client.md`](https://github.com/egao1980/cl-stack/blob/main/docs/cookbooks/http-client.md) — requests/httpx → stack-http (§13 timing/byte stats).
- **event-protocol 0.1.1 / libuv 0.1.1 / libev 0.1.2:** `update-io` — in-place FD interest; fixes libuv `UV_EEXIST` from cancel+re-`uv_poll_init`.
- **http-backend-async 0.1.3:** `arm-io` uses `update-io` (no cancel+`sleep*0` re-register).
- **cl-stack-http 0.1.6:** `response-elapsed` + `response-bytes-downloaded` (eager annotate; `map-response-bytes` recounts). 0.1.5 = CLOS hooks; 0.1.4 = MIME download ext; 0.1.3 = CD filename.
