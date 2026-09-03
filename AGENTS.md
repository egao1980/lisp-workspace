# Agent instructions

Act as a **senior Common Lisp** developer: idiomatic ASDF, packages, conditions.

## Load on demand

- **Skills:** `.lisp-workspace/skills/<name>/SKILL.md` — read the matching skill **before** specialized work. Personal (`~/.cursor/skills/`) apply across repos — do not duplicate here unless overriding. Mid-task fix → `skills/<name>/STAGED.md` (`/review-skill-improvements`). Index: [skills/README.md](skills/README.md).
- **MCP:** `cl-mcp/` = [cl-ai-project/cl-mcp](https://github.com/cl-ai-project/cl-mcp). Skill **cl-mcp-tooling**. Inspector: `npx @modelcontextprotocol/inspector`.
- **Commands:** `/load-and-test`, `/review-skill-improvements`.
- **Tests:** new tests = **Rove** ([`egao1980/rove`](https://github.com/egao1980/rove) for `deftest-parametrize`) unless the repo already picked a runner. Skill **cl-unit-testing**.
- **Errors:** conditions + restarts ([CLHS 9](http://www.lispworks.com/documentation/HyperSpec/Body/09_.htm)). Skill **cl-stack-conditions**.
- **CI / publish:** skill **cl-repository-ci**. Pins/ACL → [memory/ci.md](memory/ci.md).
- **Docs:** [MEMORY.md](MEMORY.md) (prefs + index) · [REQUIREMENTS.md](docs/REQUIREMENTS.md) (policy) · [LESSONS_LEARNED.md](LESSONS_LEARNED.md) (gotchas). Update MEMORY on durable user prefs — do not paste stack notes into this file.

## Always

- Types when they clarify (`declaim` / `declare` / `check-type`). Macros for real DSLs only. Match each subproject’s naming, ASDF, formatting, qlot — no alien style.
- Feature branches; milestone commits; remotes `github.com/egao1980/`. Unmodified third-party → `cl-stack-systems` import. Fork only for patches / owned CI / native overlays. **Exclusive:** fork ⇒ delete `imports/<name>/`; import ⇒ no workspace fork. Canonical `egao1980` repos: clone directly. Undo with git, not recall.
- Run tests/scripts after substantive edits. Docker for isolation. Web-search SBCL/ASDF quirks.
