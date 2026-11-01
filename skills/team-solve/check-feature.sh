#!/usr/bin/env bash
# Grade a cl-stack feature: sealed tests/ + brief, then asdf:test-system.
# A nonzero exit is preserved by the verify step.
set -euo pipefail

root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo=$(pwd)
task=${TEAM_SOLVE_TASK:-$repo/.team-solve/task.md}
mode=${1:-run}

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

[ -f "$task" ] || fail "no $task"

frontmatter() {
    awk -v key="$1" '
        NR == 1 && $0 != "---" { exit 1 }
        NR > 1 && $0 == "---" { exit 0 }
        NR > 1 && index($0, key ":") == 1 {
            sub("^" key ":[[:space:]]*", "")
            print
            exit 0
        }
    ' "$task"
}

system=$(frontmatter system || true)
test_system=$(frontmatter test-system || true)
brief=$(frontmatter brief || true)
[ -n "$system" ] || fail "task.md frontmatter needs system"
[ -n "$test_system" ] || fail "task.md frontmatter needs test-system"

case "$brief" in
    "" ) ;;
    /*) ;;
    *) brief=$repo/$brief ;;
esac
if [ -n "$brief" ] && [ ! -f "$brief" ]; then
    fail "brief not found: $brief"
fi

if command -v shasum >/dev/null 2>&1; then
    hash_line() { shasum -a 256 "$1"; }
    hash_stream() { shasum -a 256 | awk '{print $1}'; }
else
    hash_line() { sha256sum "$1"; }
    hash_stream() { sha256sum | awk '{print $1}'; }
fi

digest() {
    {
        hash_line "$task"
        if [ -n "$brief" ]; then
            hash_line "$brief"
        fi
        if [ -d "$repo/tests" ]; then
            find "$repo/tests" -type f -print | sort | while IFS= read -r file; do
                hash_line "$file"
            done
        fi
    } | hash_stream
}

seal=$repo/.team-solve/contract.sha256
current=$(digest)

if [ "$mode" = "--seal" ]; then
    printf '%s\n' "$current" > "$seal"
    printf 'SEAL %s\n' "$current"
    exit 0
fi

[ "$mode" = "run" ] || fail "unknown mode $mode"
[ -f "$seal" ] || fail "contract not sealed"
sealed=$(tr -d '[:space:]' < "$seal")
[ "$current" = "$sealed" ] || fail "contract changed (tests/, task.md, or brief)"

export TEAM_SOLVE_REPO=$repo
export TEAM_SOLVE_SYSTEM=$system
export TEAM_SOLVE_TEST_SYSTEM=$test_system

set +e
if command -v sbcl >/dev/null 2>&1; then
    sbcl --noinform --disable-debugger --non-interactive --load "$root/run-test.lisp"
else
    ros -e '(setf *debugger-hook* (lambda (c h) (declare (ignore h)) (format *error-output* "UNHANDLED: ~A~%" c) (uiop:quit 1)))' \
        -l "$root/run-test.lisp"
fi
status=$?
set -e
if [ "$status" -eq 0 ]; then
    printf 'PASS %s\n' "$system"
else
    printf 'FAIL %s: test-op exit %s\n' "$system" "$status"
fi
exit "$status"
