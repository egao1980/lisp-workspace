#!/usr/bin/env bash
# Add a Common Lisp project: fork third-party repos into GITHUB_WORKSPACE_ORG via gh (built-in),
# clone, upstream remote, ASDF source-registry snippet, optional qlot / Quicklisp local-projects.
set -euo pipefail

ORG="${GITHUB_WORKSPACE_ORG:-egao1980}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WORKSPACE="${LISP_WORKSPACE:-$WORKSPACE_ROOT}"
ASDF_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/common-lisp/source-registry.conf.d"
ASDF_SNIPPET_PREFIX="50-lisp-workspace"

NO_FORK="0"
UPSTREAM_URL=""
DO_QLOT="0"
DO_QUICKLISP="0"
SKIP_CLONE="0"
CLONE_URL=""
FORK_SLUG=""

usage() {
  sed -n '1,80p' <<'EOF'
Usage: add-cl-project.sh [options] [<repo>] [target-dir]

Clone a GitHub repo into the Lisp workspace and register it with ASDF (and optionally
Quicklisp local-projects).

<repo> may be omitted when --fork OWNER/REPO is set (same as passing OWNER/REPO as <repo>).

<repo> may be:
  - short name "foo"  -> clone https://github.com/<org>/foo.git (no fork step)
  - full https or git@ URL
  - owner/repo (e.g. qitab/cl-protobufs) -> runs gh repo fork into <org>, then clones <org>/<basename>

Options:
  --org NAME          GitHub org/user for default short-name clones (default: egao1980)
  --fork OWNER/REPO   Same as passing OWNER/REPO as <repo>; fork then clone
  --no-fork           Skip gh repo fork (assume github.com/<org>/<name> already exists)
  --upstream URL      After clone: git remote add upstream <URL> (default when using upstream/repo: https://github.com/OWNER/REPO.git)
  --qlot              If qlfile or qlot.conf exists, run qlot install
  --quicklisp         Symlink into QUICKLISP_HOME/local-projects and ql:register-local-projects via ros
  --skip-clone        Only write ASDF (and optional ql/qlot steps); target-dir must exist under workspace
  --workspace PATH    Override LISP_WORKSPACE (default: repo root containing .lisp-workspace/)

Environment:
  LISP_WORKSPACE, GITHUB_WORKSPACE_ORG, QUICKLISP_HOME (default ~/quicklisp), XDG_CONFIG_HOME

Examples:
  add-cl-project.sh --fork qitab/cl-protobufs
  add-cl-project.sh qitab/cl-protobufs
  add-cl-project.sh https://github.com/egao1980/my-lib.git
  add-cl-project.sh my-lib
EOF
}

die() { echo "add-cl-project.sh: $*" >&2; exit 1; }

require_cmd() { command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --org) ORG="${2:?}"; shift 2 ;;
    --fork) FORK_SLUG="${2:?}"; shift 2 ;;
    --no-fork) NO_FORK="1"; shift ;;
    --upstream) UPSTREAM_URL="${2:?}"; shift 2 ;;
    --qlot) DO_QLOT="1"; shift ;;
    --quicklisp) DO_QUICKLISP="1"; shift ;;
    --skip-clone) SKIP_CLONE="1"; shift ;;
    --workspace) WORKSPACE="$(cd "${2:?}" && pwd)"; shift 2 ;;
    --) shift; break ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      break
      ;;
  esac
done

[[ -d "${WORKSPACE}/.lisp-workspace" ]] || die "expected ${WORKSPACE}/.lisp-workspace (Lisp repo root with housekeeping)"

REPO_SPEC="${1:-}"
TARGET_DIR="${2:-}"

if [[ -n "$FORK_SLUG" && -n "$REPO_SPEC" && "$FORK_SLUG" != "$REPO_SPEC" ]]; then
  die "use either --fork $FORK_SLUG alone or pass the same owner/repo as <repo>, not both differing"
fi
if [[ -n "$FORK_SLUG" && -z "$REPO_SPEC" ]]; then
  REPO_SPEC="$FORK_SLUG"
fi
if [[ -z "$REPO_SPEC" ]]; then
  usage
  die "missing <repo> (or use --fork OWNER/REPO without repeating it)"
fi

infer_name_from_url() {
  local url="$1"
  url="${url%.git}"
  basename "$url"
}

NAME=""
# Derive clone URL and directory name from REPO_SPEC
if [[ "$REPO_SPEC" =~ ^(https?://|git@) ]]; then
  CLONE_URL="$REPO_SPEC"
  NAME="$(infer_name_from_url "$REPO_SPEC")"
elif [[ "$REPO_SPEC" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  NAME="${REPO_SPEC##*/}"
  local_owner="${REPO_SPEC%%/*}"
  CLONE_URL="https://github.com/${ORG}/${NAME}.git"
  if [[ "$local_owner" == "$ORG" ]]; then
    # already canonical under this org (e.g. egao1980/myproject) — no fork
    FORK_SLUG=""
  else
    FORK_SLUG="$REPO_SPEC"
    if [[ -z "$UPSTREAM_URL" ]]; then
      UPSTREAM_URL="https://github.com/${REPO_SPEC}.git"
    fi
  fi
elif [[ "$REPO_SPEC" =~ ^[A-Za-z0-9_.-]+$ ]]; then
  NAME="$REPO_SPEC"
  CLONE_URL="https://github.com/${ORG}/${NAME}.git"
else
  die "unrecognized repo spec: $REPO_SPEC"
fi

DEST_NAME="${TARGET_DIR:-$NAME}"
CLONE_PATH="${WORKSPACE}/${DEST_NAME}"

fork_exists_on_github() {
  gh repo view "${ORG}/${NAME}" >/dev/null 2>&1
}

# Core fork step for third-party owner/repo: create github.com/<org>/<name> from upstream.
run_gh_fork_into_org() {
  [[ -n "$FORK_SLUG" ]] || return 0
  [[ "$NO_FORK" == "1" ]] && {
    echo "Skipping gh repo fork (--no-fork); ensure ${ORG}/${NAME} exists on GitHub."
    return 0
  }
  require_cmd gh
  gh auth status >/dev/null 2>&1 || die "gh is not authenticated; run: gh auth login"

  if fork_exists_on_github; then
    echo "Fork already present: https://github.com/${ORG}/${NAME}"
    return 0
  fi

  echo "Forking ${FORK_SLUG} -> ${ORG}/${NAME} (gh repo fork)..."
  # --org is only for GitHub organizations. If ORG is your user login, fork without --org (fork lands under that user).
  local gh_login fork_ok=0
  gh_login="$(gh api user --jq .login 2>/dev/null || true)"
  if [[ -n "$gh_login" && "$ORG" == "$gh_login" ]]; then
    gh repo fork "$FORK_SLUG" && fork_ok=1
  else
    gh repo fork "$FORK_SLUG" --org "$ORG" && fork_ok=1
  fi
  if [[ "$fork_ok" -eq 1 ]]; then
    echo "gh repo fork finished."
    return 0
  fi

  # Fork may have raced or been created earlier; accept if the repo is visible now.
  if fork_exists_on_github; then
    echo "Fork is available at https://github.com/${ORG}/${NAME} (created earlier or by another process)."
    return 0
  fi

  die "gh repo fork failed and ${ORG}/${NAME} is still missing. If ${ORG} is a user, log in as that user (gh auth login) or set GITHUB_WORKSPACE_ORG to match gh api user --jq .login. For a real GitHub org, use --org with org admin rights."
}

verify_github_repo_exists() {
  command -v gh >/dev/null 2>&1 || return 0
  gh auth status >/dev/null 2>&1 || return 0
  case "$CLONE_URL" in
    "https://github.com/${ORG}/${NAME}.git"|"https://github.com/${ORG}/${NAME}") ;;
    *) return 0 ;;
  esac
  if gh repo view "${ORG}/${NAME}" >/dev/null 2>&1; then
    return 0
  fi
  die "GitHub repo ${ORG}/${NAME} not found after fork step. Check gh auth and org ${ORG}."
}

write_asdf_snippet() {
  local tree_path="$1"
  local conf_path="${ASDF_CONF_DIR}/${ASDF_SNIPPET_PREFIX}-${DEST_NAME}.conf"
  mkdir -p "$ASDF_CONF_DIR"
  # Files in conf.d/ contain bare directives (ASDF wraps them automatically).
  cat >"$conf_path" <<EOF
;; Added by add-cl-project.sh — tree for ${DEST_NAME}
(:tree "${tree_path}/")
EOF
  echo "Wrote ASDF config: $conf_path"
}

add_upstream_remote() {
  [[ -n "$UPSTREAM_URL" ]] || return 0
  git -C "$CLONE_PATH" remote get-url upstream >/dev/null 2>&1 && {
    echo "Remote 'upstream' already set"
    return 0
  }
  git -C "$CLONE_PATH" remote add upstream "$UPSTREAM_URL"
  echo "Added git remote upstream -> $UPSTREAM_URL"
  git -C "$CLONE_PATH" fetch upstream 2>/dev/null || true
}

run_qlot() {
  [[ "$DO_QLOT" == "1" ]] || return 0
  if [[ ! -f "$CLONE_PATH/qlfile" && ! -f "$CLONE_PATH/qlot.conf" ]]; then
    echo "No qlfile or qlot.conf in $CLONE_PATH; skipping qlot"
    return 0
  fi
  command -v qlot >/dev/null 2>&1 || die "qlot not on PATH (install or drop --qlot)"
  (cd "$CLONE_PATH" && qlot install)
}

run_quicklisp() {
  [[ "$DO_QUICKLISP" == "1" ]] || return 0
  local qlhome="${QUICKLISP_HOME:-$HOME/quicklisp}"
  local lp="${qlhome}/local-projects"
  mkdir -p "$lp"
  local abs
  abs="$(cd "$CLONE_PATH" && pwd)"
  ln -sfn "$abs" "${lp}/${DEST_NAME}"
  echo "Symlinked ${lp}/${DEST_NAME} -> $abs"
  require_cmd ros
  ros -q -e '(ql:register-local-projects)'
  echo "Ran ql:register-local-projects"
}

if [[ "$SKIP_CLONE" == "1" ]]; then
  [[ -d "$CLONE_PATH" ]] || die "--skip-clone but directory missing: $CLONE_PATH"
else
  run_gh_fork_into_org
  verify_github_repo_exists
  if [[ -d "$CLONE_PATH" ]]; then
    die "target already exists: $CLONE_PATH (remove it or use --skip-clone)"
  fi
  echo "Cloning $CLONE_URL -> $CLONE_PATH"
  git clone "$CLONE_URL" "$CLONE_PATH" || die "git clone failed. If the repo is missing under ${ORG}, create it (e.g. gh repo fork … --org ${ORG}) or use --no-fork if the clone URL is elsewhere."
fi

TREE_PATH="$(cd "$CLONE_PATH" && pwd)"
write_asdf_snippet "$TREE_PATH"
add_upstream_remote
run_qlot
run_quicklisp

echo "Done. Project root: $CLONE_PATH"
