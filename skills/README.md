# Workspace skills (Cursor)

Each subdirectory is a **skill**: a `SKILL.md` with YAML frontmatter (`name`, `description`) plus instructions. Cursor loads **project** skills from **`.cursor/skills/`** — this repo uses a **symlink** so skills live under **`.lisp-workspace/skills/`** and stay in the housekeeping Git repo.

## Adding a skill

1. Create `my-skill-name/SKILL.md` with `name` and `description` in frontmatter (same idea as `~/.cursor/skills-cursor/create-skill/SKILL.md` on your machine).
2. Put **what** and **when** in `description` so the agent can match tasks to skills.
3. Commit under `.lisp-workspace/`.

Personal skills (all projects): `~/.cursor/skills/`. Do **not** put project skills in `~/.cursor/skills-cursor/` (reserved).
