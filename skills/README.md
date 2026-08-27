# Workspace skills (Cursor)

Each subdirectory is a **skill**: a `SKILL.md` with YAML frontmatter (`name`, `description`) plus instructions. Cursor loads **project** skills from **`.cursor/skills/`**. Skills live only under **`.lisp-workspace/skills/`**; **`.lisp-workspace/.cursor/skills`** is a symlink **`../skills`** so there is a single tree (no duplicate or broken chain when root **`.cursor`** points here).

## Adding a skill

1. Create `my-skill-name/SKILL.md` with `name` and `description` in frontmatter (same idea as `~/.cursor/skills-cursor/create-skill/SKILL.md` on your machine).
2. Put **what** and **when** in `description` so the agent can match tasks to skills.
3. Commit under `.lisp-workspace/`.

Personal skills (all projects): `~/.cursor/skills/`. Do **not** put project skills in `~/.cursor/skills-cursor/` (reserved).

## Cursor discovery

From the **workspace root** (the directory that contains `.lisp-workspace/`):

```bash
ln -sfn .lisp-workspace/.cursor .cursor
```

**`.lisp-workspace/.cursor/skills` → `../skills`** is committed in this repo — do not replace it with a direct `.cursor/skills` → `.lisp-workspace/skills` link at the root (that would skip the bundled rules/commands/mcp.json).

Recreate the root **`.cursor`** symlink after clone if Cursor does not see project rules/skills.

## Skill improvement staging

Skills improve over time. When an agent (or user) discovers a correction, a better pattern, or a missing detail while using a skill, it should be **staged** rather than editing the `SKILL.md` directly in the middle of unrelated work.

### How it works

1. **Append** to `skills/<skill-name>/STAGED.md` with an entry under `## Pending`:
   ```markdown
   - [2026-03-21] Brief description of the improvement
     - Source: user correction / lesson learned / agent observation
     - Proposed change: what to add or change in SKILL.md
   ```
2. **Review** periodically via the `/review-skill-improvements` command (`.cursor/commands/`). The review reads each `STAGED.md` alongside its `SKILL.md` and proposes apply/reject for each item.
3. **Applied** items move to `## Applied` with date; **rejected** items move to `## Rejected` with reason.

### Creating a STAGED.md

If the file doesn't exist yet, create it with this template:

```markdown
# Staged improvements for <skill-name>

Pending corrections, additions, and refinements discovered during use.

## Pending

## Applied

## Rejected
```

### When to stage vs. edit directly

- **Stage** when you notice an issue mid-task but the task is about something else.
- **Edit directly** when the user explicitly asks to update the skill, or you're doing a dedicated skill maintenance pass.

## Skill index (this workspace)

| Skill | Focus |
|-------|--------|
| [add-cl-project](add-cl-project/SKILL.md) | Clone + fork + ASDF wiring script |
| [asdf](asdf/SKILL.md) | ASDF systems, source registry, operations |
| [cl-mcp-tooling](cl-mcp-tooling/SKILL.md) | **`cl-mcp/`** — cl-ai-project MCP server; Inspector |
| [common-lisp-workspace](common-lisp-workspace/SKILL.md) | Whole-tree conventions |
| [docker-devcontainers](docker-devcontainers/SKILL.md) | Docker + Dev Containers spec and credible refs |
| [egao1980-devcontainers](egao1980-devcontainers/SKILL.md) | **`features/`** — GHCR features for Roswell / Lem |
| [qlot](qlot/SKILL.md) | qlfile, `qlot exec`, project-local deps |
| [cl-repository-ci](cl-repository-ci/SKILL.md) | cl-repo CI + cl-stack-systems publish (no custom publish scripts) |
| [cl-stack-conditions](cl-stack-conditions/SKILL.md) | CLHS 9 conditions + restarts for first-party cl-stack |
| [cl-unit-testing](cl-unit-testing/SKILL.md) | Rove default, `deftest-parametrize`, pins |
| [rove](rove/SKILL.md) | Rove quick ref → cl-unit-testing |
| [roswell](roswell/SKILL.md) | `ros` CLI, implementations, scripting |
