---
name: cl-unit-testing
description: >-
  CL tests: Rove default, ASDF test-op, deftest-parametrize, egao1980/rove pin.
  Use when writing/running tests or choosing Rove vs FiveAM/Parachute.
---

# CL unit testing

Workspace default: **[Rove](https://github.com/fukamachi/rove)** (pin **[`egao1980/rove`](https://github.com/egao1980/rove)** until upstream merges parametrize — [fukamachi/rove#76](https://github.com/fukamachi/rove/pull/76)).  
OCI import: [`cl-stack-systems` `imports/rove`](https://github.com/egao1980/cl-stack-systems) → `ghcr.io/egao1980/cl-systems/rove`.

Match an **existing** runner in a subproject (FiveAM, Parachute, lisp-unit, …). Do not migrate frameworks casually.

Related: skill **[rove](../rove/SKILL.md)** (short alias) · design [cl-stack/docs/ROVE-PARAMETRIZE.md](https://github.com/egao1980/cl-stack/blob/main/docs/ROVE-PARAMETRIZE.md) · gaps [ROVE-GAPS.md](https://github.com/egao1980/cl-stack/blob/main/docs/ROVE-GAPS.md).

## Choose a runner

| Situation | Action |
|-----------|--------|
| New tests / new system | **Rove** |
| Repo already on FiveAM / Parachute / … | Keep that runner |
| Many vectors × one body (corpus, RFC tables) | Rove **`deftest-parametrize`** (fork pin) |

## ASDF layout

```lisp
;; my-lib.asd
:in-order-to ((test-op (test-op "my-lib/tests")))

(defsystem "my-lib/tests"
  :depends-on ("my-lib" "rove")
  :pathname "tests"
  :components ((:file "main"))
  :perform (test-op (o c) (symbol-call :rove :run c)))
```

Run: `(asdf:test-system :my-lib)` or `qlot exec ros -e '(asdf:test-system :my-lib)'`.

## Rove basics

```lisp
(defpackage #:my-lib/tests
  (:use #:cl #:rove #:my-lib))
(in-package #:my-lib/tests)

(deftest add-smoke
  (ok (= 3 (add 1 2)))
  (ng (add nil 1))
  (ok (signals (add :x 1) 'type-error)))

(testing "nested context"
  (ok t))
```

Useful: `ok` / `ng` / `signals` / `skip` / `setup` / `teardown` / `defhook` (`:before` / `:after`).

## Parametrize (data-driven)

Requires **egao1980/rove** (parametrize). Prefer this over copy-pasted `deftest`s for tables.

```lisp
(deftest-parametrize add
    ((a b expected)
     (1 2 3)
     (0 0 0)
     (-1 1 0))
  (ok (= (+ a b) expected)))
;; → ADD/0, ADD/1, ADD/2

(deftest-parametrize doubles
    ((n expected) :ids ("two" "four")
     (1 2)
     (2 4))
  (ok (= (* n 2) expected)))
;; → DOUBLES/TWO, DOUBLES/FOUR

(defparameter *cases* '((10 20 30) (1 1 2)))
(deftest-parametrize add-dyn
    ((a b expected) :rows *cases*)
  (ok (= (+ a b) expected)))
```

| Form | Meaning |
|------|---------|
| `(var*)` | bindings in body |
| row | list of values (or bare atom if one var) |
| `:ids` | name suffixes → `NAME/ID` (else `NAME/0`…) |
| `:rows` | load-time form → list of rows |

Each row is a normal `deftest` (hooks / reporters / `rove:run-test` work). Helper: `parametrize-test-name`.

**When to use:** corpus slices, RFC/vector tables, multi-backend × multi-input matrices.  
**When not:** one-off smoke tests; prefer a single `deftest`.

## Pinning rove

Until [fukamachi/rove#76](https://github.com/fukamachi/rove/pull/76) merges:

- **cl-repo / OCI:** `cl-stack-systems` import `rove` → `egao1980/rove` SHA (see `imports/rove/qlfile`)
- **qlot (legacy):** `github egao1980/rove` + ref
- **Local edit:** workspace `rove/` checkout — do not also import `fukamachi/rove` into cl-stack-systems

Bump the import SHA when the fork tip moves.

## CI / agent checks

- After substantive edits: run the project’s test system (ASDF `test-op` or `scripts/ci-test.lisp`).
- cl-mcp: `/load-and-test` or `run-tests` when the MCP server is available.
- Long compiles: log to a temp file; only tail on failure (always-on rule).

## Anti-patterns

- New FiveAM/Parachute in a greenfield egao1980 package without a reason
- Slurping huge corpora into one `deftest` instead of `deftest-parametrize`
- Pinning Quicklisp `rove` while using `deftest-parametrize` (symbol missing)
