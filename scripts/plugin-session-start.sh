#!/usr/bin/env bash
# SessionStart hook of the lisp-workspace Claude Code plugin.
#
# Plugins load no CLAUDE.md and no rules, so this prints the cl-stack
# conventions (plugin/context.md) and the path-scoped rules (rules/*.md, front
# matter stripped) as session context. It also reports what the toolchain is
# missing, and starts the lisp-mcp executable build in the background when
# Roswell and the cl-repo client are present but the executable is not built.
#
# A project that vendors this repo as .lisp-workspace (cl-workspace) already
# loads AGENTS.md and the rules through CLAUDE.md: then this prints nothing.
set -euo pipefail

root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
project="${CLAUDE_PROJECT_DIR:-$PWD}"

if [[ -d "$project/.lisp-workspace" ]]; then
  exit 0
fi

cat "$root/plugin/context.md"

for rule in "$root"/rules/*.md; do
  [[ -f "$rule" ]] || continue
  echo
  awk 'NR == 1 && /^---$/ { front = 1; next }
       front && /^---$/   { front = 0; next }
       !front' "$rule"
done

missing=()
export PATH="$HOME/.roswell/bin:$HOME/.local/bin:$PATH"
command -v ros >/dev/null 2>&1 || missing+=("Roswell (\`ros\`): https://roswell.github.io/ then \`ros install sbcl-bin\`")
client_dir="${CL_REPOSITORY_DEST:-$HOME/.cl-repository-client}"
if ! ls -d "$client_dir"/cl-oci-*/ >/dev/null 2>&1; then
  missing+=("the cl-repo client: \`curl -fsSL https://raw.githubusercontent.com/egao1980/cl-repository/main/install.sh | bash\` (needs oras and python3)")
fi

if (( ${#missing[@]} > 0 )); then
  echo
  echo "## Toolchain not ready"
  echo
  echo "lisp-mcp and \`cl-repo\` need these; tell the user before running Lisp commands:"
  for item in "${missing[@]}"; do
    echo "- $item"
  done
  exit 0
fi

# Build the fast-start lisp-mcp executable ahead of the first MCP start.
which="$("$root/scripts/lisp-mcp.sh" --which 2>/dev/null || true)"
if [[ "$which" == *"run --build"* ]]; then
  log="${TMPDIR:-/tmp}/lisp-mcp-build.log"
  nohup "$root/scripts/lisp-mcp.sh" --build >"$log" 2>&1 &
  echo
  echo "lisp-mcp is being built in the background (log: $log); its tools appear once it is ready (run \`/mcp\` to reconnect)."
fi
