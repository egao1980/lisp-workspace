#!/usr/bin/env bash
# Proves check-samples.sh accepts a matching program and rejects a wrong one.
set -euo pipefail

root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
check=$root/check-samples.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/ok"
cp -R "$root/fixture/." "$tmp/ok/"
( cd "$tmp/ok" && bash "$check" )

mkdir -p "$tmp/bad"
cp -R "$root/fixture/." "$tmp/bad/"
printf '%s\n' 'print(0)' > "$tmp/bad/solution.py"
set +e
( cd "$tmp/bad" && bash "$check" >"$tmp/bad.log" 2>&1 )
status=$?
set -e
if [ "$status" -eq 0 ]; then
    printf 'FAIL: broken solution was accepted\n' >&2
    cat "$tmp/bad.log" >&2
    exit 1
fi

mkdir -p "$tmp/empty/tests"
printf '%s\n' 'print(1)' > "$tmp/empty/solution.py"
set +e
( cd "$tmp/empty" && bash "$check" >"$tmp/empty.log" 2>&1 )
status=$?
set -e
if [ "$status" -eq 0 ]; then
    printf 'FAIL: missing samples were accepted\n' >&2
    exit 1
fi

printf 'checker ok\n'
