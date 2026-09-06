# Event / process / CCL / natives / platform

## Event / process / executors

- **cl-stack event-protocol:** app DX = **promises**; default **libuv** (Windows primary); second **libev** (Unix). **Separate GitHub repos per layer** (not colocated): `egao1980/event-protocol` (generics + shared conformance), `egao1980/event-backend-libuv`, `egao1980/event-backend-libev`. Grovel-at-overlay-build. Brief `cl-stack/docs/capabilities/event-protocol.md`. **`submit` yes, pool protocol no. Protocol has no BT.** Hop-off + hop-back is one GF; `:executor` is a function of one thunk (or `NIL` → backend default). Shared BT pools: [`cl-stack-executors`](https://github.com/egao1980/cl-stack-executors) — backends *may* plug that in. Do not add `event-pool` / `worker-protocol`.
- **event-protocol 0.2.0:** `wake-call` + `submit`. No `bordeaux-threads` on the protocol. Pin ≥0.2.0 for hop-off. Backends: libuv **0.1.2**, libev **0.1.3**, nio **0.1.2**. Executors lib **0.1.0**.
- **event-protocol 0.1.1 / libuv 0.1.1 / libev 0.1.2:** `update-io` — in-place FD interest; fixes libuv `UV_EEXIST` from cancel+re-`uv_poll_init`.
- **ABCL JVM backends (wave-1):** [`event-backend-nio`](https://github.com/egao1980/event-backend-nio) OCI **0.1.2** (NIO `Selector`; `run` binds `*event-loop*`); [`http-backend-java`](https://github.com/egao1980/http-backend-java) OCI **0.1.0** (`java.net.http` + WS scaffold). Prefer NIO over libuv on ABCL. Pin [`event-protocol`](https://github.com/egao1980/event-protocol) **≥0.2.0** for `submit` / 3-arg `wake-call`.

## CCL

- **CCL Darwin/arm64 FFI:** may study SBCL (and Apple AAPCS64 / libffi) for **ABI behavior** (≤16B in GPRs, HFA→FPRs, Darwin variadic-on-stack). **Do not copy SBCL (or other impl) source** — reimplement in CCL idioms (`expand-ff-call`, `arm642-aapcs64-*`, vinsns). Prefer aligning with CCL’s own x8664 paths when they already match the ABI.
- **CCL Apple Silicon:** fork [`egao1980/ccl`](https://github.com/egao1980/ccl) of [`Clozure/ccl`](https://github.com/Clozure/ccl); work on `cursor/darwin-arm64-8969` based on upstream `arm64` (Linux/arm64 already boots). Kernel `darm64cl` links natively; boot image / MAP_JIT / Mach exceptions still open. Host for cross-compile: Rosetta `ccl-bin/1.13` (Roswell rejects arm64; shim `dcl`→`dx86cl64`).

## Pathlib / sockets / platform / CFFI

- **cl-stack-pathlib** (`egao1980/cl-stack-pathlib`, nick `stack-pathlib`) **0.2.2**: ZIP inflate/archive via [`compression-protocol`](https://github.com/egao1980/compression-protocol). CLOS `path` + `filesystem` protocol (local/memory/zip), pathlib-shaped facade, condition restarts (`create-parents`, `create-file`, `overwrite`, …). Tracking: `egao1980/cl-stack#40` (closed). SBCL collapses `:BACK` in pathnames — store `".."` as a string directory component.
- **Sockets:** prefer portable **usocket** over SBCL `sb-bsd-sockets`; skip **iolib** for Windows-primary code (Unix-only).
- **Platform matrix:** **Windows is a primary target** (with linux/darwin) — not “later / stretch”. Overlay Done-when bars include `windows/amd64` (see `cl-stack/docs/overlays.md` Required row). Prefer `libuv` for anything that must run on Windows; libev/Woo/`lev` stay Unix-only second backends.
- **CFFI grovel policy:** Grovel **at overlay build time** (CI / Windows builder), ship `cffi-grovel-output` → `grovel-cache/`. Main packages may declare `grovel-file` for local-dev fallback, but consumers with cl-repository overlays must load **without** a C toolchain. Do not treat “no grovel on Windows” as a goal — treat “no grovel on consumer machines” as the goal.
- **http2 (zellerin) fork:** [`egao1980/http2`](https://github.com/egao1980/http2) **2.1.1**. `http2/server` / `http2/server/threaded` no longer depend on `http2/openssl` (Homebrew-only grovel + `poll.h`). Threaded TLS uses cl+ssl + ALPN select. Poll/openssl stay opt-in. Not a `cl-stack-systems` import (patched).

## Workspace / demos / tests

- `cl-mcp/` upstream is cl-ai-project (not quasi); fork is egao1980/cl-mcp.
- `features/` is the devcontainer features repo — not an ASDF library.
- **cl-stack-demos:** [`egao1980/cl-stack-demos`](https://github.com/egao1980/cl-stack-demos) — 15 Python→CL mini-apps from real GH projects (`SOURCES.md`). Showcase / bug / gap finder; no workarounds. Run: `uv run python scripts/run_all.py` + `ros -l scripts/bootstrap.lisp -l scripts/run-all.lisp`. cl-unicode comes from OCI **0.1.7** (edicl master with `idna-mapping`; cl-stack#164 closed) — no sibling checkout, no `("cl-unicode" :ql)` pins (the QL dist also predates the IDNA merge).
- **rove fork:** [`egao1980/rove`](https://github.com/egao1980/rove) — `deftest-parametrize` (upstream [fukamachi/rove#76](https://github.com/fukamachi/rove/pull/76)); pin fork until merge. Design: `cl-stack/docs/ROVE-PARAMETRIZE.md`.
