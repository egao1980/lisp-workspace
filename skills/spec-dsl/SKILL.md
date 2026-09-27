---
name: spec-dsl
description: >-
  cl-stack formal-spec DSL: `spec-protocol` (`defspec` sexp front-end, CLOS AST, driver generics,
  ITF traces) + `spec-backend-quint` (emit .qnt, drive quint typecheck/run/test/verify/compile).
  Use when writing a `defspec`, emitting Quint or TLA+ from Lisp, adding a spec backend, or wiring
  golden `.qnt` / ITF fixtures into Rove. Quint language itself: quint-modeling. Replay: spec-mbt-conformance.
---

# spec-dsl (`spec-protocol` + `spec-backend-quint`)

**One `defspec` = CLOS protocol + formal spec.** The form expands to a class (vars = slots, consts = initargs), generics + methods (actions), `deftype`s (sum types), `check-invariants`, **and** registers the AST that `spec-backend-quint` emits as `.qnt`. Do not write a model beside the code; the model is the code's core.

Protocol/backend split like the rest of cl-stack: `spec-protocol` (nickname `stack-spec`) owns the DSL, AST, CLOS projection (`spec-protocol/clos`, `spec-protocol/runtime`), conditions, driver generics, ITF and MBT; `spec-backend-quint` emits `.qnt` and shells out to `quint` via `process-protocol`. TLA+ text comes from `(compile-spec m :target :tlaplus)`; a native TLC backend is future work.

```lisp
(asdf:load-system "spec-backend-quint")          ; also sets *spec-backend*
(asdf:load-system "process-backend-uiop") (asdf:load-system "json-backend-jzon")
(spec-protocol:emit (spec-protocol:find-spec 'bank))
(spec-protocol:simulate (find-spec 'bank) :invariants '(no-negatives) :max-steps 15 :seed 1 :mbt t)
```

## `defspec` shape

```lisp
(defspec task-journal (:module "TaskJournal")
  (const steps (set str))
  (type status (| :new :running :waiting :completed :failed :canceled))   ; keywords = nullary variants
  (type event (| task-started (step-completed str) timer-set timer-fired task-completed (task-failed str)))
  (var status status) (var journal (list event)) (var pending-timers int)
  (pure-def replay (j) (foldl j :new (lambda (s e) (match e ((task-started) :running) (_ s)))))
  (action init (all (assign status :new) (assign journal (list)) (assign pending-timers 0)))
  (action record-step (name)
    (all (= status :running) (not (in name (recorded journal)))
         (assign journal (append journal (step-completed name)))))
  (action step (nondet (n (one-of steps)) (any (start) (record-step n) (complete))))
  (invariant status-matches-replay (= (replay journal) status))
  (run happy-path (then init (start) (record-step "a") (complete))))
```

Decl heads: `const var type import pure-val pure-def val def action temporal invariant run assume`. `invariant` = `val` tagged so drivers can enumerate it. `:as "Literal"` on any decl overrides the emitted name.

## CLOS projection

- Action body: non-`assign` forms are guards → `spec-action-disabled` (`continue` = no-op) when false; `assign`s are **simultaneous** (all RHS in pre-state, then `setf`). `*check-invariants*` runs `check-invariants` after each action (on in tests) → `spec-invariant-violation`.
- Values: nullary variant = keyword, payload = `(label . value)`; record = keyword plist; tuple = list; list = vector; set = `spec-set`; map = `equal` hash-table. Ops from `spec-protocol/runtime` (`map-get`, `map-put`, `set-in-p`, …) — same names the emitter maps.
- `(:spec-only …)` for `step` / `nondet` / `any` / `temporal` / `run` / `(:raw …)`; using them in a plain action is a macroexpansion `spec-parse-error`.
- Header `:class :superclasses :accessor-prefix :package` shape the generated names; existing protocols inherit the class as a mixin or hold it as a delegate.
- `spec-state-alist` exposes vars for MBT; `clos-driver` replays any `--mbt` trace against the generated class with no mapping code — every `defspec` gets that self-test.

Specs with `const`s declare an instance in the header — `(:module "Bank" :instance ("BankTest" (accounts (set "a" "b"))))` — which emits a second module importing `Bank(accounts = …).*`, hosts the `run`s, and becomes the default `--main`. `run-tests` passes an explicit `--match` built from the spec's run names (quint's default only matches `*Test`). `simulate` always passes `--max-samples` (a `--seed` alone caps samples at 1). ITF var names come back namespaced (`BankTest::Bank::balances`); `spec-name` matches on the last segment.

## Forms → Quint

| Lisp | Quint |
|------|-------|
| `(+ a b)` `(= a b)` `(/= a b)` `(and a b)` `(or a b)` `(not a)` `(implies a b)` `(iff a b)` | infix / `not(a)` / `a.implies(b)` / `a.iff(b)` (nested binaries always parenthesised) |
| `(union a b)` `(in x s)` `(size s)` `(get m k)` `(put m k v)` `(set-by m k f)` `(keys m)` `(values m)` `(append l x)` `(foldl l init f)` `(forall s f)` `(exists s f)` `(one-of s)` `(to a b)` `(then a b)` `(reps n f)` `(expect r p)` | method style `a.union(b)` … |
| `(assign x e)` | `x' = e` |
| `(all …)` `(any …)` | `all { … }` / `any { … }` |
| `(nondet (v (one-of s)) body)` | `nondet v = s.oneOf()` newline body |
| `(if c a b)` `(let ((v e)) body)` `(lambda (x y) body)` | `if (c) a else b` / `val v = e` / `((x, y) => body)` |
| `(match e ((busy n) body) ((idle) body) (_ body))` | `match e { \| Busy(n) => … \| Idle => … \| _ => … }` |
| `(set …)` `(list …)` `(tuple …)` `(rec (a 1) (b 2))` `(field r a)` `(map-of ((k s) v))` | `Set(…)` `[…]` `(…)` `{a: 1, b: 2}` `r.a` `s.mapBy(k => v)` |
| `true` `false` ints strings | literals — never `t` / `nil` |
| `(:raw "text")` | verbatim escape hatch; last resort |

Types: `int str bool`, `(set T)` `(list T)` `(map K V)` `(tuple …)` `(rec (f T) …)`, `(| variants…)`, named types by symbol.

Names mangle deterministically: kebab → `camelCase` for vars/consts/ops/params/fields, `PascalCase` for types and variant labels. `spec-name` maps back from ITF variable names; `backend-name` lets a backend override.

## Driver

`*spec-backend*` + facades `emit typecheck simulate verify run-tests compile-spec` over generics `backend-emit backend-typecheck backend-simulate backend-verify backend-run-tests backend-compile`. `verify` takes `:checker` (`:tlc` local explicit-state, `:apalache` default upstream). All return `spec-result` (`status` `:ok :violation :error :skipped`, `seed`, `errors`, `traces` of `itf-trace`, `stdout` `stderr`). `check` signals `spec-invariant-violation` (restart `continue`) on `:violation`.

Conditions (`spec-error` root): `spec-parse-error` (`use-value`), `spec-emit-error`, `spec-tool-missing-error`, `spec-tool-error`, `spec-typecheck-error`, `spec-invariant-violation`, `spec-conformance-divergence` (`continue` / `abort-trace`). Skill **cl-stack-conditions** applies.

## Fixtures + tests (Rove)

- Golden emit: `tests/fixtures/<spec>.qnt` compared string-equal to `(emit spec)`; diff, do not regenerate blindly.
- Frozen traces: `quint run --mbt --seed N --out-itf` output committed as `*.itf.json`; replay in CI without Node (skill **spec-mbt-conformance**).
- Quint-gated: `(unless (spec-backend-quint:quint-available-p) (skip "quint not installed"))`. `verify` (`:checker :tlc` / `:apalache`) gated on `(java-available-p)` (`JAVA_HOME` = Homebrew `openjdk`, `TLA2TOOLS` = Toolbox jar, see **quint-modeling**).
- Record the quint version in README; bump fixtures when emit changes, never edit them by hand.

## Where a model lives

Model + driver for protocol `foo` = subsystem `foo/spec` (pathname `spec/`, deps `spec-protocol` `spec-protocol/mbt`), tests in `foo/tests`, `:cl-repo (:ci (:with ("foo/spec")))`. Shared examples (bank, journal) live in `spec-protocol/examples`. Not in `*-parity` (those are interop canaries).

## Anti-patterns

- Hand-editing emitted `.qnt` or fixtures
- `t`/`nil` in expressions (ambiguous with empty list)
- `(:raw …)` for anything the forms table covers — extend the table instead
- Modelling the Lisp code's quirks rather than the spec/RFC; the conformance run is where quirks surface
- Tests that require Node/quint to pass
