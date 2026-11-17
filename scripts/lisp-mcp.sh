#!/usr/bin/env bash
# lisp-mcp, the workspace's Lisp MCP server (stdio by default).
#
#   lisp-mcp.sh [server args]   serve; --root defaults to $LISP_MCP_ROOT, $CLAUDE_PROJECT_DIR or $PWD
#   lisp-mcp.sh --build         install lisp-mcp from ghcr.io and write a fast-start executable
#   lisp-mcp.sh --which         print what would run
#
# Env: LISP_MCP_VERSION (OCI tag, default below), LISP_MCP_SOURCE=checkout (run the
# workspace checkouts: for developing lisp-mcp itself), LISP_MCP_BIN (executable path).
# The first start builds the executable (lisp-mcp and deps from ghcr.io over the
# cl-stack async HTTP backend) into ~/.cache/lisp-mcp/; bootstrap.sh does it ahead
# of time so the MCP client does not wait. Bump LISP_MCP_VERSION to upgrade.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd "$HERE/../.." && pwd)"
VERSION="${LISP_MCP_VERSION:-0.3.1}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/lisp-mcp"
BIN="${LISP_MCP_BIN:-$CACHE/lisp-mcp-$VERSION}"
SOURCE="${LISP_MCP_SOURCE:-oci}"
ROOT="${LISP_MCP_ROOT:-${CLAUDE_PROJECT_DIR:-$PWD}}"
export PATH="$HOME/.roswell/bin:$PATH"

launch() {  # launch ACTION [args...]
  local action="$1"; shift
  local joined="" a
  for a in "$@"; do joined+="${joined:+$'\x1f'}$a"; done
  LISP_MCP_ACTION="$action" LISP_MCP_SOURCE="$SOURCE" LISP_MCP_VERSION="$VERSION" \
    LISP_MCP_OUTPUT="$BIN" LISP_MCP_WORKSPACE="$WORKSPACE" LISP_MCP_ARGS="$joined" LISP_MCP_CACHE="$CACHE" \
    exec ros +Q run -- --dynamic-space-size 4096 --non-interactive --load "$HERE/lisp-mcp-launch.lisp"
}

case "${1:-}" in
  --build)
    [[ "$SOURCE" == oci ]] || { echo "lisp-mcp.sh --build uses the published package (unset LISP_MCP_SOURCE)" >&2; exit 2; }
    launch build ;;
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
    ( launch build ) 1>&2 || { echo "lisp-mcp: build failed; serving from the OCI cache" >&2; launch serve "${args[@]}"; }
  fi
  exec "$BIN" "${args[@]}"
fi
launch serve "${args[@]}"
