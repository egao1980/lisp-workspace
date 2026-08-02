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
- **cl-stack-pathlib** (`egao1980/cl-stack-pathlib`, nick `stack-pathlib`): merged to `main` (PR #1). CLOS `path` + `filesystem` protocol (local/memory), pathlib-shaped facade, condition restarts (`create-parents`, `create-file`, `overwrite`, …). Tracking: `egao1980/cl-stack#40`. SBCL collapses `:BACK` in pathnames — store `".."` as a string directory component.
