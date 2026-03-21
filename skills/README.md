# Workspace skills (Cursor)

Each subdirectory is a **skill**: a `SKILL.md` with YAML frontmatter (`name`, `description`) plus instructions. Cursor loads **project** skills from **`.cursor/skills/`** — this repo uses a **symlink** so skills live under **`.lisp-workspace/skills/`** and stay in the housekeeping Git repo.

## Adding a skill

1. Create `my-skill-name/SKILL.md` with `name` and `description` in frontmatter (same idea as `~/.cursor/skills-cursor/create-skill/SKILL.md` on your machine).
2. Put **what** and **when** in `description` so the agent can match tasks to skills.
3. Commit under `.lisp-workspace/`.

Personal skills (all projects): `~/.cursor/skills/`. Do **not** put project skills in `~/.cursor/skills-cursor/` (reserved).

## Cursor discovery

From the **workspace root** (the directory that contains `.lisp-workspace/`):

```bash
mkdir -p .cursor && ln -sfn .lisp-workspace/skills .cursor/skills
```

Recreate this symlink after clone if **`.cursor/skills`** is missing so Cursor loads project skills.

## Skill index (this workspace)

| Skill | Focus |
|-------|--------|
| [add-cl-project](add-cl-project/SKILL.md) | Clone + fork + ASDF wiring script |
| [asdf](asdf/SKILL.md) | ASDF systems, source registry, operations |
| [common-lisp-workspace](common-lisp-workspace/SKILL.md) | Whole-tree conventions |
| [docker-devcontainers](docker-devcontainers/SKILL.md) | Docker + Dev Containers spec and credible refs |
| [egao1980-devcontainers](egao1980-devcontainers/SKILL.md) | **`features/`** — GHCR features for Roswell / Lem |
| [qlot](qlot/SKILL.md) | qlfile, `qlot exec`, project-local deps |
| [rove](rove/SKILL.md) | Rove testing |
| [roswell](roswell/SKILL.md) | `ros` CLI, implementations, scripting |
