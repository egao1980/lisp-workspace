#!/usr/bin/env bash
# lisp-mcp, the workspace's Lisp MCP server (stdio by default).
#
#   lisp-mcp.sh [server args]   serve; --root defaults to $LISP_MCP_ROOT, $CLAUDE_PROJECT_DIR or $PWD;
#                               other args pass through (e.g. --tools code | --tools image)
#   lisp-mcp.sh --build         install lisp-mcp from ghcr.io and write a fast-start executable
#   lisp-mcp.sh --which         print what would run
#
# Env: LISP_MCP_VERSION (OCI tag, default below), LISP_MCP_SOURCE=checkout (run the
# workspace checkouts: for developing lisp-mcp itself), LISP_MCP_BIN (executable path).
# The first start builds the executable (lisp-mcp and deps from ghcr.io over the
# cl-stack async HTTP backend) into ~/.cache/lisp-mcp/; bootstrap.sh does it ahead
# of time so the MCP client does not wait. Bump LISP_MCP_VERSION to upgrade.
# Several servers (lisp-code, lisp-image) may start at once: one builds under a
# lock into a temporary file and renames it; the others wait for it.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd "$HERE/../.." && pwd)"
VERSION="${LISP_MCP_VERSION:-0.7.5}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/lisp-mcp"
BIN="${LISP_MCP_BIN:-$CACHE/lisp-mcp-$VERSION}"
SOURCE="${LISP_MCP_SOURCE:-oci}"
ROOT="${LISP_MCP_ROOT:-${CLAUDE_PROJECT_DIR:-$PWD}}"
export PATH="$HOME/.roswell/bin:$PATH"

launch() {  # launch ACTION [args...]; ACTION build writes $OUTPUT (default $BIN)
  local action="$1"; shift
  local joined="" a
  for a in "$@"; do joined+="${joined:+$'\x1f'}$a"; done
  LISP_MCP_ACTION="$action" LISP_MCP_SOURCE="$SOURCE" LISP_MCP_VERSION="$VERSION" \
    LISP_MCP_OUTPUT="${OUTPUT:-$BIN}" LISP_MCP_WORKSPACE="$WORKSPACE" LISP_MCP_ARGS="$joined" LISP_MCP_CACHE="$CACHE" \
    exec ros +Q run -- --dynamic-space-size 4096 --non-interactive --load "$HERE/lisp-mcp-launch.lisp"
}

build() {  # build $BIN once: under a lock, into a temporary file, then renamed
  local lock="$BIN.lock" tmp="$BIN.tmp.$$"
  mkdir -p "$(dirname "$BIN")"
  until mkdir "$lock" 2>/dev/null; do
    # a stale lock (a build killed mid-way) is older than half an hour
    if [[ -n "$(find "$lock" -maxdepth 0 -mmin +30 2>/dev/null)" ]]; then rmdir "$lock" 2>/dev/null || true; continue; fi
    echo "lisp-mcp: waiting for another build of $BIN" >&2
    sleep 3
  done
  local status=0
  if [[ ! -x "$BIN" || "${FORCE_BUILD:-0}" == 1 ]]; then
    ( OUTPUT="$tmp" launch build ) && mv -f "$tmp" "$BIN" || status=$?
    rm -f "$tmp"
  fi
  rmdir "$lock" 2>/dev/null || true
  return $status
}

case "${1:-}" in
  --build)
    [[ "$SOURCE" == oci ]] || { echo "lisp-mcp.sh --build uses the published package (unset LISP_MCP_SOURCE)" >&2; exit 2; }
    FORCE_BUILD=1 build; exit $? ;;
  --which)
    if [[ "$SOURCE" == checkout ]]; then echo "checkouts under $WORKSPACE"
    elif [[ -x "$BIN" ]]; then echo "$BIN"
    else echo "ghcr.io/egao1980/cl-systems/lisp-mcp:$VERSION (loaded on each start; run --build)"; fi
    exit 0 ;;
esac

args=("$@")
has_root=0
for a in "${args[@]+"${args[@]}"}"; do [[ "$a" == --root ]] && has_root=1; done
[[ $has_root == 1 ]] || args+=(--root "$ROOT")

if [[ "$SOURCE" != checkout ]]; then
  if [[ ! -x "$BIN" ]]; then
    # First start: install from ghcr.io and dump the executable. stdout is the
    # MCP channel, so the build talks on stderr only.
    echo "lisp-mcp: building $BIN (first start; later starts are instant)" >&2
    build 1>&2 || { echo "lisp-mcp: build failed; serving from the OCI cache" >&2; launch serve "${args[@]}"; }
  fi
  exec "$BIN" "${args[@]}"
fi
launch serve "${args[@]}"
