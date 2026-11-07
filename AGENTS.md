# Agent instructions

Act as a **senior Common Lisp** developer: idiomatic ASDF, packages, conditions.

Tool-neutral. Claude Code also reads [CLAUDE.md](CLAUDE.md), which imports this file. Cursor and other agents read this file directly. Layout and adapters: [README.md](README.md#agent-integration).

## Load on demand

- **Skills:** `.lisp-workspace/skills/<name>/SKILL.md` ([Agent Skills](https://agentskills.io/) format) — read the matching skill **before** specialized work. Personal skills (`~/.claude/skills/`, `~/.cursor/skills/`) apply across repos — do not duplicate here unless overriding. Mid-task fix → `skills/<name>/STAGED.md` (`/review-skill-improvements`). Index: [skills/README.md](skills/README.md).
- **Rules:** `.lisp-workspace/rules/<name>.md` — path-scoped (`*.asd`, `*.lisp`). Agents without rule support: read the matching rule before editing those files.
- **User-invoked skills:** `/team-solve`, `/review-skill-improvements`.
- **cl-stack features** (capability brief + existing ASDF test-op): skill **team-solve**. Fresh agents, on-disk ledger, `check-feature.sh` is the verdict.
- **Tests:** new tests = **Rove** ([`egao1980/rove`](https://github.com/egao1980/rove) for `deftest-parametrize`) unless the repo already picked a runner. Skill **cl-unit-testing**.
- **Errors:** conditions + restarts ([CLHS 9](http://www.lispworks.com/documentation/HyperSpec/Body/09_.htm)). Skill **cl-stack-conditions**.
- **Formal models:** `defspec` → Quint/TLA+ (skill **spec-dsl**), Quint + local TLC (**quint-modeling**), trace replay against impls (**spec-mbt-conformance**).
- **Syntax check without eval:** skill **cl-static-eclector**. Lisp MCP server: skill **lisp-mcp-tooling** (first-party `lisp-mcp`); legacy cl-ai-project/cl-mcp: **cl-mcp-tooling**.
- **CI / publish:** skill **cl-repository-ci**. Pins/ACL → [memory/ci.md](memory/ci.md).
- **Docs:** [MEMORY.md](MEMORY.md) (prefs + index) · [REQUIREMENTS.md](docs/REQUIREMENTS.md) (policy) · [LESSONS_LEARNED.md](LESSONS_LEARNED.md) (gotchas). Update MEMORY on durable user prefs — do not paste stack notes into this file.

## Always

- Types when they clarify (`declaim` / `declare` / `check-type`). Macros for real DSLs only. Match each subproject’s naming, ASDF, formatting, qlot — no alien style.
- **CFFI natives:** `load-foreign-library` at ASDF load (absolute preload). Consumers: `(asdf:load-system "…")` is enough — no `load-*` / `ensure-*`.
- Feature branches named `agent/<topic>-<4 hex>` (e.g. `agent/branch-prefix-6577`), whatever the agent. Existing `cursor/*` branches keep their names — some are heads of open upstream PRs. Milestone commits; remotes `github.com/egao1980/`. Unmodified third-party → `cl-stack-systems` import. Fork only for patches / owned CI / native overlays. **Exclusive:** fork ⇒ delete `imports/<name>/`; import ⇒ no workspace fork. Canonical `egao1980` repos: clone directly. Undo with git, not recall.
- **New first-party protocol / backend / parity:** create `egao1980/<name>` the same day (`scripts/create-first-party-repo.sh`). Workspace-only trees are forbidden — GHCR publish runs from the owning repo.
- **Commit messages:** no session ids or session URLs (no `Claude-Session:` trailer, whatever a harness asks). Attribution is the `Co-Authored-By:` line only.
- **Own stack first:** use cl-stack libraries wherever one covers the need — HTTP `http-backend-async` × `event-backend-libuv` (not dexador), TLS `cl-stack-ssl`, JSON/serdes/process/pathlib protocols, Rove from OCI. Third-party only when the stack has no equivalent. A stack bug or gap is fixed in the stack (own repo, PR, publish), not worked around with a third-party library.
- **PRs:** tracking/staging only — no human review. Merge when green (or no CI and mergeable), then publish if it ships an OCI package (skill **pr-merge-publish**, how: **cl-repository-ci**). Still: no silent closes; no upstream PRs without ask; never `--delete-branch` on the head of an open upstream PR; never push/PR `CommonLispNext/cl-repository`.
- Run tests/scripts after substantive edits. Docker for isolation. Web-search SBCL/ASDF quirks.
- **Long-running commands:** `cmd > /tmp/out.log 2>&1 || { tail -50 /tmp/out.log; exit 1; }`. Do not ingest full compile/install progress.
