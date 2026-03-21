#!/usr/bin/env bash
# Remove workspace wiring for a CL project: ASDF snippet, optional Quicklisp local-projects symlink.
# Does not delete the clone unless --purge.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WORKSPACE="${LISP_WORKSPACE:-$WORKSPACE_ROOT}"
ASDF_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/common-lisp/source-registry.conf.d"
ASDF_SNIPPET_PREFIX="50-lisp-workspace"

DO_QUICKLISP="0"
PURGE="0"

usage() {
  cat <<'EOF'
Usage: remove-cl-project.sh [options] <project-name>

Removes ~/.config/.../50-lisp-workspace-<project-name>.conf and optionally the
Quicklisp local-projects symlink. Does not remove the project directory unless --purge.

Options:
  --quicklisp       Also remove QUICKLISP_HOME/local-projects/<project-name> symlink
  --purge           Run rm -rf on WORKSPACE/<project-name> (destructive)
  --workspace PATH  Override LISP_WORKSPACE
  -h, --help        This help
EOF
}

die() { echo "remove-cl-project.sh: $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --quicklisp) DO_QUICKLISP="1"; shift ;;
    --purge) PURGE="1"; shift ;;
    --workspace) WORKSPACE="$(cd "${2:?}" && pwd)"; shift 2 ;;
    *) break ;;
  esac
done

[[ -d "${WORKSPACE}/.lisp-workspace" ]] || die "expected ${WORKSPACE}/.lisp-workspace (Lisp repo root with housekeeping)"

NAME="${1:-}"
[[ -n "$NAME" ]] || { usage; die "missing project name"; }

CONF="${ASDF_CONF_DIR}/${ASDF_SNIPPET_PREFIX}-${NAME}.conf"
if [[ -f "$CONF" ]]; then
  rm -f "$CONF"
  echo "Removed $CONF"
else
  echo "No ASDF snippet at $CONF (skipped)"
fi

if [[ "$DO_QUICKLISP" == "1" ]]; then
  qlhome="${QUICKLISP_HOME:-$HOME/quicklisp}"
  link="${qlhome}/local-projects/${NAME}"
  if [[ -L "$link" ]]; then
    rm -f "$link"
    echo "Removed symlink $link"
  else
    echo "No symlink at $link (skipped)"
  fi
fi

ROOT="${WORKSPACE}/${NAME}"
if [[ "$PURGE" == "1" ]]; then
  [[ -d "$ROOT" ]] || die "cannot --purge: not a directory: $ROOT"
  rm -rf "$ROOT"
  echo "Removed directory $ROOT"
else
  echo "Clone left in place: $ROOT (use --purge to delete)"
fi
