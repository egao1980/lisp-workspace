# Workspace memory

Durable **user instructions**. Read this at session start. **Update** when the user states a standing preference. Keep entries short; delete or supersede stale items.

Stack design / pins live in **`memory/*.md`** — open **only** the file that matches the task. Do not load all of them. Do not duplicate policy that already lives in [REQUIREMENTS.md](docs/REQUIREMENTS.md) or a skill — link.

---

## Preferences

- **Python touchpoints:** uv + ruff; line length 120; no black; modern typing (3.12+); optimize imports. **Not for CL repo scripts.**
- **CL project scripts = CL.** First-party CL repos dogfood cl-stack (`cl-stack-http` × `http-backend-async` × `event-backend-libuv`, pathlib, …). No Python/Node refresh/CI helpers for work the stack already covers. If a gold library exists only in another language, Lisp drives the sexp; freeze that dump rather than adding a second-language script.
- **Own stack first (explicit rule):** every first-party repo, script and tool uses cl-stack libraries wherever one exists (HTTP async × libuv, `cl-stack-ssl`, protocols/backends); a missing feature or bug goes into the stack, not around it. Also in [AGENTS.md](AGENTS.md).
- **Commit messages: no session ids / session URLs** (no `Claude-Session:` trailer). `Co-Authored-By:` only.
- **HTTP client in first-party consumers:** bind `http-backend-async` × `event-backend-libuv` (`http-backend-async:*event-backend-maker*` + `http-protocol:*http-backend*`; http-parity `with-parity` shape). Dexador is maintenance — do not default new tests/docs/examples to it. Goal is dogfooding so we find stack bugs. `cl-stack-http` `:auto` on Unix still falls to dexador — prefer explicit `:async`.
- **Documentation:** terse; no verbose boilerplate.
- **cl-stack features** (capability brief + existing ASDF test-op in the owning repo): skill **[team-solve](skills/team-solve/SKILL.md)** (`/team-solve`). Fresh agents talk only through `.team-solve/`; `check-feature.sh` is the verdict. Do not edit `tests/` or the brief.
- **CL errors = conditions + restarts.** First-party cl-stack uses CLHS 9 (not status-code returns, not Java exceptions). Skill **cl-stack-conditions**.
- **CL MCP:** first-party [egao1980/lisp-mcp](https://github.com/egao1980/lisp-mcp) (static + structural edit + Swank/Slynk image; skill **lisp-mcp-tooling**). [cl-ai-project/cl-mcp](https://github.com/cl-ai-project/cl-mcp) is the optional legacy server — never the quasi/cl-mcp stack.
- **GitHub repos:** always full `owner/repo` — never bare repo name when multiple owners share a name.
- **OCI / cl-repo for everything (explicit rule):** systems, tools and launchers resolve through cl-repo from GHCR. The cl-repository *client* itself is the OCI-installed tree (`setup-client.sh` → `CL_REPOSITORY_DEST`, default `~/.cl-repository-client`, run by `~/.local/bin/cl-repo`), loaded with `:ignore-inherited-configuration`. Never load it from the `cl-repository/` checkout. Unreleased client changes are tested through cl-repository CI and a release.
- **New first-party protocol / backend / parity = own `egao1980/<name>` the same day.** Workspace-only trees are not a system. No owning repo ⇒ no `publish-checkout.yml` ⇒ never on GHCR ⇒ consumers cannot `:depends-on` it in CI. Create with [scripts/create-first-party-repo.sh](scripts/create-first-party-repo.sh), push `main`, dispatch the first publish. Do not land `*-protocol` / `*-backend-*` / `*-parity` without that remote. New OCI-shipping products follow the same rule. **`egao1980/demiurge`:** replace the legacy tree with the new cl-stack core when shipping — do not keep a second product repo.

## Standing instructions

- **CCL diagnostics/smoke:** poll every 10–30s (do not block indefinitely) — runs hang or die quickly. FFI/port notes → [memory/runtime.md](memory/runtime.md).
- **No upstream PRs without explicit ask.** Fork/push to `egao1980/*` is fine; do **not** open PRs against third-party upstreams (e.g. `Clozure/ccl`) unless the user says to.
- **Living quickstart:** [`cl-stack/docs/QUICKSTART.md`](https://github.com/egao1980/cl-stack/blob/main/docs/QUICKSTART.md) — pin table + snippets in the **same PR** that publishes a user-facing feature.
- **New first-party `.asd`:** skill **[asdf](skills/asdf/SKILL.md)**. `:oci` is the implied dep source; omit `:cl-repo` unless overlays. Never `:sources (("foo" :oci))`.
- **CI / publish / OCI:** skill **[cl-repository-ci](skills/cl-repository-ci/SKILL.md)**. Pins, GHCR ACL, overlay keys → [memory/ci.md](memory/ci.md). Never `:ql` source pins; never sibling CI checkouts; never copy `ci-*.lisp`.
- Plan before new projects / massive changes; git branch first. Run tests before declaring done. Feature branches in subproject repos.
- **Before deleting "dead" code** (unused params/vars/functions), check it isn't scaffolding for a planned-but-unimplemented feature — grep TODO/docs/requirements + `git log -S`. If planned: keep it and document the reserved intent (e.g. `;; TODO(<area>)`).
- Skill wrong mid-task → append `skills/<name>/STAGED.md`; do not edit `SKILL.md` in-flight.
- **PRs = tracking / staging, not review.** No human review on `egao1980/*`. When CI is green (or no CI + mergeable): **merge immediately**, then **publish** if the repo ships OCI. Skill **pr-merge-publish**. Do **not** close open PRs silently (conflicts / “superseded”) — fix and merge. Close only if the user explicitly says to close/abandon, or the PR author asks to.
- **Rove:** consume **`egao1980/rove` via OCI** (`ghcr.io/egao1980/cl-systems/rove`). Ignore fukamachi/rove (and other Rove upstream) PRs unless the user asks. Do not merge `egao1980/rove` tracking PRs as part of a stack land unless asked.
- **Upstream PR branches:** never `gh pr merge --delete-branch` (or otherwise delete) a branch that is the head of an **open upstream PR**. Rove heads (leave them): `cursor/parametrize-3a7a` → fukamachi/rove#76; `cursor/upstream-marks-timeout-1979` → #77; `cursor/upstream-diffs-junit-1979` → #78; `cursor/upstream-fixtures-1979` → #79.
- **Retiring an unused checkout:** commit anything uncommitted and push unpushed branches/stashes to `archive/<name>` on its `egao1980` remote (verify the remote tip), then delete the local checkout (`remove-cl-project.sh --purge <name>`) and drop it from `repos.manifest`. Do not archive or delete the GitHub repo unless asked.
- **Never push or create PRs to `CommonLispNext/cl-repository`** — all work stays in **`egao1980/cl-repository`**. Rebase/merge against upstream locally; push only to the fork.

## Project notes (open one)

| File | Open when working on |
|------|----------------------|
| [memory/ci.md](memory/ci.md) | OCI pins, GHCR ACL, publish exceptions, overlay keys, act+local registry |
| [memory/http.md](memory/http.md) | http-protocol, cl-stack-http, encodings, ws, http-server, http-parity |
| [memory/agent.md](memory/agent.md) | llm, ai-agent, mcp/a2a/ag-ui/sse/rpc, blackboard, capability, log/telemetry |
| [memory/data.md](memory/data.md) | sql, crypto/secrets/jwt, io/serdes/schema/arrow/xml, unicode/i18n, mime, idna |
| [memory/runtime.md](memory/runtime.md) | event, process, CCL, ABCL, CFFI/grovel, pathlib, sockets, platform, demos |
