#!/usr/bin/env bash
# Link agent config from .lisp-workspace into a workspace root.
#
# Source of truth (tool-neutral, in this repo):
#   AGENTS.md, CLAUDE.md, LESSONS_LEARNED.md, skills/<name>/SKILL.md, rules/<name>.md
#
# Generated at ROOT (gitignored there, re-run after adding a skill or rule):
#   AGENTS.md, LESSONS_LEARNED.md            -> .lisp-workspace/…
#   .claude/skills/<name>, .claude/rules/<name>.md   (Claude Code)
#   .cursor/skills, .cursor/rules/<name>.mdc         (Cursor)
#
# ROOT keeps its own tracked CLAUDE.md, .claude/settings.json and
# .cursor/environment.json; this script never touches real files.
#
# usage: link-agent-config.sh [ROOT]   (default: parent of .lisp-workspace)
set -euo pipefail

LW="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "${1:-${LW}/..}" && pwd)"
REL="${LW#"${ROOT}"/}"
if [[ "$REL" == "$LW" ]]; then
  echo "error: ${LW} is not inside ${ROOT}" >&2
  exit 1
fi

# link TARGET DEST: replace DEST only if it is a symlink (or absent).
link() {
  local target="$1" dest="$2"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    echo "error: ${dest} exists and is not a symlink; move it aside" >&2
    exit 1
  fi
  ln -sfn "$target" "$dest"
}

# prune DIR: drop dangling symlinks left by removed skills/rules.
prune() {
  local dir="$1" entry
  [[ -d "$dir" ]] || return 0
  for entry in "$dir"/* "$dir"/.[!.]*; do
    [[ -L "$entry" && ! -e "$entry" ]] && rm -f "$entry"
  done
  return 0
}

cd "$ROOT"

echo "==> Root docs"
for name in AGENTS.md LESSONS_LEARNED.md; do
  link "${REL}/${name}" "$name"
done

echo "==> Claude Code (.claude/skills, .claude/rules)"
# Per-entry symlinks: Claude Code documents symlinked skill dirs, not a
# symlinked .claude/skills itself.
mkdir -p .claude/skills .claude/rules
for d in "${LW}"/skills/*/; do
  d="${d%/}"
  [[ -f "${d}/SKILL.md" ]] || continue
  link "../../${REL}/skills/$(basename "$d")" ".claude/skills/$(basename "$d")"
done
for f in "${LW}"/rules/*.md; do
  [[ -f "$f" ]] || continue
  link "../../${REL}/rules/$(basename "$f")" ".claude/rules/$(basename "$f")"
done
prune .claude/skills
prune .claude/rules

echo "==> Cursor (.cursor/skills, .cursor/rules)"
mkdir -p .cursor
# Old layout linked whole dirs and mcp.json/commands; drop those symlinks.
for old in commands mcp.json rules; do
  [[ -L ".cursor/${old}" ]] && rm -f ".cursor/${old}"
done
link "../${REL}/skills" .cursor/skills
mkdir -p .cursor/rules
for f in "${LW}"/rules/*.md; do
  [[ -f "$f" ]] || continue
  link "../../${REL}/rules/$(basename "$f")" ".cursor/rules/$(basename "$f" .md).mdc"
done
prune .cursor/rules

echo "==> Agent config linked into ${ROOT}"
