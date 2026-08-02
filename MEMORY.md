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

- Plan before acting on new projects or massive changes; use git to preserve initial state and track in a branch.
- Run tests before declaring done.
- Use feature branches in subproject repos.
- **Before deleting "dead" code** (unused params/vars/functions), check it isn't scaffolding for a planned-but-unimplemented feature — grep TODO/docs/requirements + `git log -S`. If planned: keep it and document the reserved intent (e.g. `;; TODO(<area>)`) rather than removing.
- When a skill proves wrong or incomplete during use, append the correction to `skills/<name>/STAGED.md` rather than editing SKILL.md in-flight.
- **Never push or create PRs to `CommonLispNext/cl-repository`** — all work stays in **`egao1980/cl-repository`**. Rebase/merge against upstream locally, but push only to the fork.

## Project-specific notes

- `cl-mcp/` upstream is cl-ai-project (not quasi); fork is egao1980/cl-mcp.
- `features/` is the devcontainer features repo — not an ASDF library.
- **OCI publish + consumer test (cl-protobufs / grpc):** run **`act`** against `publish-oci.yml` with local registry + artifact server, then verify in a **roswell devcontainer** with **`cl-repository`** mounted and `host.docker.internal` to the registry. Full command pattern and pitfalls → **`.lisp-workspace/LESSONS_LEARNED.md`** (section *act + local OCI registry + devcontainer*).
- **cl-repository overlay keys:** platform specs support **`os` / `release` / `arch`** (not just `os` / `arch`). This means overlays can be keyed per distro release (e.g. `ubuntu-24.04/arm64` vs `ubuntu-26.04/arm64`) when native binaries are glibc-sensitive. Current workflows use bare `linux` / `darwin` — sufficient while building on the oldest supported LTS.
- **cl-stack-pathlib** (`egao1980/cl-stack-pathlib`, nick `stack-pathlib`): merged to `main` (PR #1). CLOS `path` + `filesystem` protocol (local/memory), pathlib-shaped facade, condition restarts (`create-parents`, `create-file`, `overwrite`, …). Tracking: `egao1980/cl-stack#40` (closed). SBCL collapses `:BACK` in pathnames — store `".."` as a string directory component.
- **Platform matrix:** **Windows is a primary target** (with linux/darwin) — not “later / stretch”. Overlay Done-when bars include `windows/amd64` (see `cl-stack/docs/overlays.md` Required row). Prefer `libuv` for anything that must run on Windows; libev/Woo/`lev` stay Unix-only second backends.
- **CFFI grovel policy:** Grovel **at overlay build time** (CI / Windows builder), ship `cffi-grovel-output` → `grovel-cache/`. Main packages may declare `grovel-file` for local-dev fallback, but consumers with cl-repository overlays must load **without** a C toolchain. Do not treat “no grovel on Windows” as a goal — treat “no grovel on consumer machines” as the goal.
- **cl-stack event-protocol:** app DX = **promises**; default **libuv** (Windows primary); second **libev** (Unix). **Separate GitHub repos per layer** (not colocated): `egao1980/event-protocol` (generics + shared conformance), `egao1980/event-backend-libuv`, `egao1980/event-backend-libev`. Grovel-at-overlay-build. Brief `cl-stack/docs/capabilities/event-protocol.md`.
- **event backends (scaffold merged):** libuv + libev repos on `main` with conformance CI. Remaining for `#16`/`#17`: OCI publish (`native-library` + `cffi-grovel-output`) + clean-container smoke. cl-repository reusable publish must support nested `lib/`+`grovel/` artifacts. `.asd` prefers `grovel-cache/grovel.cffi.lisp` when present (no CC).
