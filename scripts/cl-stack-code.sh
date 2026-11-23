#!/usr/bin/env bash
# cl-stack-code, the cl-stack coding agent (egao1980/cl-stack-code), as a fast-start executable.
#
#   cl-stack-code.sh [args]       run it: interactive, or -p "PROMPT" headless; args pass through
#   cl-stack-code.sh --acp [args] serve the Agent Client Protocol for editors (needs >= 0.11.0)
#   cl-stack-code.sh --build      install cl-stack-code from ghcr.io and write the executable
#   cl-stack-code.sh --which      print the executable path (building it when missing)
#
# Env: CL_STACK_CODE_VERSION (OCI tag, default below), CL_STACK_CODE_BIN (executable path).
# The first run builds the executable (cl-stack-code and deps from ghcr.io through the
# cl-repository client) into ~/.cache/cl-stack-code/; bootstrap.sh does it ahead of time.
# The executable's name carries the version and the Lisp, so bumping VERSION or
# upgrading SBCL builds a new one. Needs Roswell (ros) and the cl-repository client
# (~/.cl-repository-client). Build output goes to stderr only.
# Runs started at once share one build: one builds under a lock into a temporary
# file and renames it; the others wait for it. A copy of this script on its own
# (downloaded) fetches its build driver, cl-stack-code-launch.lisp, from egao1980/lisp-workspace.
set -euo pipefail

SELF="${BASH_SOURCE[0]}"
while [[ -L "$SELF" ]]; do  # a symlink (e.g. ~/.local/bin/cl-stack-code): find the script
  link="$(readlink "$SELF")"; [[ "$link" == /* ]] || link="$(dirname "$SELF")/$link"; SELF="$link"
done
HERE="$(cd "$(dirname "$SELF")" && pwd)"
LAUNCH_URL="https://raw.githubusercontent.com/egao1980/lisp-workspace/main/scripts/cl-stack-code-launch.lisp"
VERSION="${CL_STACK_CODE_VERSION:-0.13.2}"
ACP_MIN="0.11.0"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/cl-stack-code"
export PATH="$HOME/.roswell/bin:$PATH"

die() { echo "cl-stack-code: $*" >&2; exit 2; }

ros_config() {  # ros_config KEY: a Roswell setting, read from its config file.
  # No Lisp starts on the way to an existing executable: `ros config show` runs
  # an SBCL, and one an editor starts can inherit a Mach exception port that
  # takes its traps, so it spins (Zed on macOS, cl-stack-code#43).
  local f="${ROSWELL_HOME:-$HOME/.roswell}/config" v=""
  [[ -f "$f" ]] && v="$(awk -F'\t' -v k="$1" '$1 == k { print $3; exit }' "$f")"
  if [[ -z "$v" ]] && command -v ros >/dev/null 2>&1; then
    v="$(ros config show "$1" 2>/dev/null || true)"
  fi
  echo "$v"
}

lisp_key() {  # the Roswell default Lisp and its version, e.g. sbcl-bin-2.4.11
  local impl ver
  impl="$(ros_config default.lisp)"
  impl="${impl:-sbcl-bin}"
  ver="$(ros_config "$impl.version")"
  echo "${impl}-${ver:-unknown}"
}

if [[ -n "${CL_STACK_CODE_BIN:-}" ]]; then BIN="$CL_STACK_CODE_BIN"
else BIN="$CACHE/cl-stack-code-$VERSION-$(lisp_key)"; fi
NATIVES="$BIN.natives"

stale() {  # true when $BIN is missing or a foreign library it reopens is gone; $1 = quiet
  [[ -x "$BIN" ]] || return 0
  [[ -f "$NATIVES" ]] || return 1
  local lib
  while IFS= read -r lib; do
    # -L: macOS system frameworks are symlinks into the dyld cache
    [[ -z "$lib" || -e "$lib" || -L "$lib" ]] || { [[ -n "${1:-}" ]] || echo "cl-stack-code: $lib is gone; rebuilding" >&2; return 0; }
  done <"$NATIVES"
  return 1
}

launch_file() {  # the build driver: beside this script, else (a downloaded script) fetched once
  local f="$HERE/cl-stack-code-launch.lisp"
  if [[ ! -f "$f" ]]; then
    f="$CACHE/cl-stack-code-launch.lisp"
    if [[ ! -f "$f" ]]; then
      mkdir -p "$CACHE"
      curl -fsSL "$LAUNCH_URL" -o "$f.tmp.$$" && mv -f "$f.tmp.$$" "$f" \
        || { rm -f "$f.tmp.$$"; die "cannot download $LAUNCH_URL"; }
    fi
  fi
  echo "$f"
}

launch_build() {  # write $1
  command -v ros >/dev/null 2>&1 || die "needs Roswell (ros) on PATH: https://roswell.github.io"
  local driver; driver="$(launch_file)"
  [[ -d "${CL_REPOSITORY_DEST:-$HOME/.cl-repository-client}" ]] \
    || die "needs the cl-repository client: curl -fsSL https://raw.githubusercontent.com/egao1980/cl-repository/main/install.sh | bash"
  # two images: install (with the cl-repository client), then dump (without
  # it, so cl-stack-code never runs on the client's older copies)
  local phase
  for phase in install dump; do
    CL_STACK_CODE_PHASE="$phase" CL_STACK_CODE_REGISTRY="$1.registry" \
      CL_STACK_CODE_VERSION="$VERSION" CL_STACK_CODE_OUTPUT="$1" CL_STACK_CODE_CACHE="$CACHE" \
      CL_STACK_CODE_NATIVES="$1.natives" \
      ros +Q run -- --dynamic-space-size 4096 --non-interactive --no-userinit \
        --load "$driver" 1>&2 || { rm -f "$1.registry"; return 1; }
  done
  rm -f "$1.registry"
}

build() {  # build $BIN once: under a lock, into a temporary file, then renamed
  local lock="$BIN.lock" tmp="$BIN.tmp.$$"
  mkdir -p "$(dirname "$BIN")"
  until mkdir "$lock" 2>/dev/null; do
    # a stale lock (a build killed mid-way) is older than half an hour
    if [[ -n "$(find "$lock" -maxdepth 0 -mmin +30 2>/dev/null)" ]]; then rmdir "$lock" 2>/dev/null || true; continue; fi
    echo "cl-stack-code: waiting for another build of $BIN" >&2
    sleep 3
  done
  local status=0
  if stale quiet || [[ "${FORCE_BUILD:-0}" == 1 ]]; then
    echo "cl-stack-code: building $BIN (cl-stack-code $VERSION from ghcr.io; later starts are instant)" >&2
    if launch_build "$tmp"; then
      mv -f "$tmp" "$BIN"
      if [[ -f "$tmp.natives" ]]; then mv -f "$tmp.natives" "$NATIVES"; else rm -f "$NATIVES"; fi
      # older executables (other versions or Lisps) are dead weight
      if [[ -z "${CL_STACK_CODE_BIN:-}" ]]; then
        find "$CACHE" -maxdepth 1 -name 'cl-stack-code-*' ! -name "$(basename "$BIN")" \
          ! -name "$(basename "$BIN").*" ! -name '*.lock' -exec rm -f {} + 2>/dev/null || true
      fi
    else
      status=$?
      echo "cl-stack-code: build failed (exit $status)" >&2
    fi
    rm -f "$tmp" "$tmp.natives"
  fi
  rmdir "$lock" 2>/dev/null || true
  return $status
}

version_ge() {  # version_ge A B: A >= B (dotted numbers)
  [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -t. -k1,1n -k2,2n -k3,3n | head -1)" == "$2" ]]
}

case "${1:-}" in
  --build)
    FORCE_BUILD=1 build; exit $? ;;
  --which)
    if stale; then build; fi
    echo "$BIN"; exit 0 ;;
  --acp)
    version_ge "$VERSION" "$ACP_MIN" \
      || die "--acp (editors over the Agent Client Protocol) needs cl-stack-code >= $ACP_MIN; this launcher pins $VERSION (set CL_STACK_CODE_VERSION when $ACP_MIN is published)" ;;
esac

if stale; then build; fi
exec "$BIN" "$@"
