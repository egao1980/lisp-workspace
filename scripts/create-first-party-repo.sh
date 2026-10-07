#!/usr/bin/env bash
# Create egao1980/<name> from an existing workspace tree and push main.
# First-party protocols / backends / parity MUST have an owning repo the same day
# the tree is created. Workspace-only trees never reach GHCR.
set -euo pipefail

ORG="${GITHUB_WORKSPACE_ORG:-egao1980}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WORKSPACE="${LISP_WORKSPACE:-$WORKSPACE_ROOT}"

usage() {
  cat <<'EOF'
Usage: create-first-party-repo.sh <name> [description]

Create github.com/<org>/<name> from the workspace tree <name>/ (or push if the
repo already exists). Inits git, commits if needed, registers ASDF.

<name> is the directory and GitHub repo (e.g. task-protocol).

Environment:
  LISP_WORKSPACE, GITHUB_WORKSPACE_ORG (default: egao1980)
EOF
}

die() { echo "create-first-party-repo.sh: $*" >&2; exit 1; }

require_cmd() { command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"; }

if [[ $# -lt 1 || "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  [[ $# -ge 1 ]] || exit 1
  exit 0
fi

NAME="$1"
DESCRIPTION="${2:-}"
DIR="${WORKSPACE}/${NAME}"

[[ "$NAME" =~ ^[A-Za-z0-9_.-]+$ ]] || die "bad name: $NAME"
[[ -d "$DIR" ]] || die "missing workspace tree: $DIR"
require_cmd git
require_cmd gh
gh auth status >/dev/null 2>&1 || die "gh is not authenticated; run: gh auth login"

asd=""
for candidate in "${DIR}/${NAME}.asd" "${DIR}"/*.asd; do
  if [[ -f "$candidate" ]]; then
    asd="$candidate"
    break
  fi
done
[[ -n "$asd" ]] || die "no .asd in $DIR"

if [[ -z "$DESCRIPTION" ]]; then
  DESCRIPTION="$(python3 -c "
import re, pathlib, sys
text = pathlib.Path(sys.argv[1]).read_text()
m = re.search(r':description\\s+\"([^\"]+)\"', text)
print(m.group(1) if m else '')
" "$asd")"
fi
if [[ -z "$DESCRIPTION" ]]; then
  DESCRIPTION="CLOS ${NAME} for cl-stack"
fi

if [[ ! -d "${DIR}/.git" ]]; then
  git -C "$DIR" init -b main
fi

# Local artifacts that `git add -A` below would otherwise commit (cl-repo.lock
# and the OCI cache are per-machine; fasls are per-implementation).
ensure_ignored() {
  local gitignore="${DIR}/.gitignore" pattern
  for pattern in "$@"; do
    if ! grep -qxF -- "$pattern" "$gitignore" 2>/dev/null; then
      echo "$pattern" >> "$gitignore"
    fi
  done
}
ensure_ignored "cl-repo.lock" ".cl-repository/" ".qlot/" "*.fasl" "*.dx64fsl" "*.lx64fsl" "*.wx64fsl" ".DS_Store"

if ! git -C "$DIR" rev-parse --verify HEAD >/dev/null 2>&1; then
  git -C "$DIR" add -A
  git -C "$DIR" status --porcelain | grep -q . || die "nothing to commit in $DIR"
  git -C "$DIR" commit -m "Initial import of ${NAME}."
elif [[ -n "$(git -C "$DIR" status --porcelain)" ]]; then
  git -C "$DIR" add -A
  git -C "$DIR" commit -m "Sync workspace tree for ${NAME}."
fi

slug="${ORG}/${NAME}"
if gh repo view "$slug" >/dev/null 2>&1; then
  echo "Repo already present: https://github.com/${slug}"
  if git -C "$DIR" remote get-url origin >/dev/null 2>&1; then
    git -C "$DIR" remote set-url origin "git@github.com:${slug}.git"
  else
    git -C "$DIR" remote add origin "git@github.com:${slug}.git"
  fi
  git -C "$DIR" push -u origin HEAD
else
  echo "Creating https://github.com/${slug}"
  gh repo create "$slug" --public --description "$DESCRIPTION" --source="$DIR" --remote=origin --push
fi

# Register ASDF even when the tree already existed (--skip-clone).
"${SCRIPT_DIR}/add-cl-project.sh" --skip-clone --no-fork "$NAME"

echo "Owning repo: https://github.com/${slug}"
echo "Next: gh workflow run publish-checkout.yml -R ${slug}"
