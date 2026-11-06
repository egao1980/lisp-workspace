@AGENTS.md

## Claude Code

- **Skills** load from `.claude/skills/` (per-skill symlinks into `skills/`, made by `scripts/link-agent-config.sh`). After adding a skill or rule, re-run `./scripts/bootstrap.sh --links-only` at the workspace root.
- **Rules** in `rules/*.md` load through `.claude/rules/` when a matching file is read or edited (`paths:` frontmatter).
- **Subagents:** where a skill says "fresh subagent" (e.g. **team-solve**), use the Agent tool with `general-purpose`, one new agent per step, never resumed.
- **Cloud sessions** (claude.ai/code): start them against `egao1980/cl-workspace`. Its `.claude/settings.json` SessionStart hook inits this submodule and links config when `CLAUDE_CODE_REMOTE=true`. The VM toolchain (Roswell, SBCL, gh) comes from the environment setup script — see the cl-workspace README.
- **Memory:** durable workspace prefs go in [MEMORY.md](MEMORY.md) (shared by all agents), not only in Claude's per-user auto memory.
