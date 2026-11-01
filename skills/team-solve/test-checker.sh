#!/usr/bin/env bash
# Proves check-feature.sh accepts a passing test-op, rejects a failing one,
# and rejects a tampered tests/ tree.
set -euo pipefail

root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
check=$root/check-feature.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

copy_fixture() {
    local dest=$1
    mkdir -p "$dest"
    tar -C "$root/fixture" -cf - . | tar -C "$dest" -xf -
}

copy_fixture "$tmp/ok"
( cd "$tmp/ok" && bash "$check" --seal && bash "$check" )

copy_fixture "$tmp/bad"
cat > "$tmp/bad/src/feature.lisp" <<'EOF'
(defpackage #:team-solve-fixture
  (:use #:cl)
  (:export #:*feature-ok*))
(in-package #:team-solve-fixture)

(defvar *feature-ok* nil)
EOF
( cd "$tmp/bad" && bash "$check" --seal )
set +e
( cd "$tmp/bad" && bash "$check" >"$tmp/bad.log" 2>&1 )
status=$?
set -e
if [ "$status" -eq 0 ]; then
    printf 'FAIL: broken feature was accepted\n' >&2
    cat "$tmp/bad.log" >&2
    exit 1
fi

copy_fixture "$tmp/tamper"
( cd "$tmp/tamper" && bash "$check" --seal )
printf '\n' >> "$tmp/tamper/tests/tests.lisp"
set +e
( cd "$tmp/tamper" && bash "$check" >"$tmp/tamper.log" 2>&1 )
status=$?
set -e
if [ "$status" -eq 0 ]; then
    printf 'FAIL: tampered tests were accepted\n' >&2
    cat "$tmp/tamper.log" >&2
    exit 1
fi
if ! grep -q 'contract changed' "$tmp/tamper.log"; then
    printf 'FAIL: tamper did not report contract changed\n' >&2
    cat "$tmp/tamper.log" >&2
    exit 1
fi

copy_fixture "$tmp/noseal"
set +e
( cd "$tmp/noseal" && bash "$check" >"$tmp/noseal.log" 2>&1 )
status=$?
set -e
if [ "$status" -eq 0 ]; then
    printf 'FAIL: unsealed contract was accepted\n' >&2
    exit 1
fi

printf 'checker ok\n'
