# Workspace skills (Cursor)

Each subdirectory is a **skill**: `SKILL.md` with YAML frontmatter (`name`, `description`) plus instructions.
Cursor loads project skills from **`.cursor/skills/`**. Skills live only under **`.lisp-workspace/skills/`**;
**`.lisp-workspace/.cursor/skills`** → **`../skills`**.

## Adding

1. `my-skill-name/SKILL.md` with `name` + `description` (what **and** when).
2. Keep `SKILL.md` short; put examples in `reference.md` / `examples.md` (one level deep).
3. Commit under `.lisp-workspace/`.

Personal: `~/.cursor/skills/`. Never `~/.cursor/skills-cursor/` (reserved).

## Discovery

From the **workspace root**:

```bash
ln -sfn .lisp-workspace/.cursor .cursor
```

Do **not** replace `.lisp-workspace/.cursor/skills` with a root-level shortcut that skips rules/commands/mcp.json.
Recreate the root `.cursor` symlink after clone if Cursor misses project rules/skills.

## Staging

Mid-task correction → append `skills/<name>/STAGED.md` under `## Pending` (do not edit `SKILL.md` in-flight).
Review with `/review-skill-improvements`. Applied → `## Applied`; rejected → `## Rejected`.

New `STAGED.md`:

```markdown
# Staged improvements for <skill-name>

## Pending

## Applied

## Rejected
```

Entry shape:

```markdown
- [YYYY-MM-DD] Brief description
  - Source: user correction / lesson learned / agent observation
  - Proposed change: what to add or change in SKILL.md
```

**Stage** mid-unrelated-task. **Edit directly** when the user asks or this is a dedicated skill pass.

## Index

| Skill | Focus |
|-------|--------|
| [act-github-actions](act-github-actions/SKILL.md) | Local GH Actions via Docker |
| [add-cl-project](add-cl-project/SKILL.md) | Clone + fork + ASDF wiring |
| [asdf](asdf/SKILL.md) | New `.asd` shape, ASDF registry |
| [bash-defensive-patterns](bash-defensive-patterns/SKILL.md) | Production Bash / install.sh |
| [cl-mcp-tooling](cl-mcp-tooling/SKILL.md) | `cl-mcp/` MCP server + Inspector |
| [cl-static-eclector](cl-static-eclector/SKILL.md) | Eclector CST read; no eval |
| [cl-repository-ci](cl-repository-ci/SKILL.md) | cl-repo CI + cl-stack-systems publish |
| [cl-stack-conditions](cl-stack-conditions/SKILL.md) | CLHS 9 conditions + restarts |
| [cl-unit-testing](cl-unit-testing/SKILL.md) | Rove default, `deftest-parametrize` |
| [common-lisp-workspace](common-lisp-workspace/SKILL.md) | Tree conventions (router) |
| [docker-devcontainers](docker-devcontainers/SKILL.md) | Docker + Dev Containers spec |
| [egao1980-devcontainers](egao1980-devcontainers/SKILL.md) | `features/` GHCR Roswell / Lem |
| [pr-merge-publish](pr-merge-publish/SKILL.md) | Merge when CI green; then OCI publish |
| [qlot](qlot/SKILL.md) | qlfile, `qlot exec` (legacy) |
| [quint-modeling](quint-modeling/SKILL.md) | Quint language + CLI, invariants, ITF, local TLC |
| [rove](rove/SKILL.md) | Rove quick ref → cl-unit-testing |
| [roswell](roswell/SKILL.md) | `ros` CLI, implementations |
| [sbcl](sbcl/SKILL.md) | SBCL debugger / flags |
| [shellcheck-configuration](shellcheck-configuration/SKILL.md) | Lint `install.sh` / CI shell |
| [spec-dsl](spec-dsl/SKILL.md) | `defspec` → Quint/TLA+ (`spec-protocol` + `spec-backend-quint`) |
| [spec-mbt-conformance](spec-mbt-conformance/SKILL.md) | Replay ITF traces against CLOS impls (`mbt-driver`) |
| [team-solve](team-solve/SKILL.md) | Fresh-agent ledger for a cl-stack feature; ASDF test-op is the verdict |
