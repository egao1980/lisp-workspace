---
name: spec-mbt-conformance
description: >-
  Model-based conformance for cl-stack protocols: replay Quint/Apalache ITF traces (`quint run --mbt`)
  against an implementation via `spec-protocol.mbt` (`clos-driver` for defspec classes; `mbt-driver`
  with `mbt-init/apply/observe/compare` for anything else; `replay-trace`). Use when replaying traces,
  writing a driver, freezing trace fixtures, or triaging a divergence. DSL: spec-dsl. Quint: quint-modeling.
---

# MBT conformance (`spec-protocol.mbt`)

Trace = oracle. `quint run --mbt` records the action fired (`mbt::actionTaken`) and its `nondet` picks (`mbt::nondetPicks`); the driver applies the same action to the system under test (SUT) and compares observed state with the trace state. Divergence = bug in model, mapping, or implementation — decide which before fixing.

## Free for any `defspec`: `clos-driver`

```lisp
(spec-protocol.mbt:replay-traces (spec-protocol.mbt:make-clos-driver 'bank)
                                 (result-traces (simulate 'bank :seed 1 :n-traces 3)))
```

`mbt-init` = `make-instance` of the generated class (consts from `:instance`, or `:consts` alist) with vars set from ITF state 0; `mbt-apply` = the action generic with picks in parameter order (`spec-action-disabled` → `continue`); `mbt-observe` = `spec-state-alist`. This is the self-test that the CLOS and Quint projections agree, and the regression harness once real code builds on the generated core.

## Hand-written driver (SUT not built on defspec)

```lisp
(defclass journal-driver (spec-protocol.mbt:mbt-driver) ())
(defmethod mbt-init ((d journal-driver) state)                 ; state = itf-state 0
  (list (make-in-memory-journal) (make-durable-task :id "t")))
(defmethod mbt-apply ((d journal-driver) sut action picks state)
  (destructuring-bind (journal task) sut
    (cond ((string= action "recordStep")
           (with-durable-task (task journal) (with-durable-step ((cdr (assoc :name picks))) t)))
          ((string= action "complete") (complete-task task))
          (t (error 'spec-error :message (format nil "unmapped action ~a" action))))))
(defmethod mbt-observe ((d journal-driver) sut)                ; alist "itfVar" . lisp value
  (destructuring-bind (journal task) sut
    `(("status" . ,(durable-task-status task))                 ; keyword = nullary variant
      ("journal" . ,(apply #'make-seq (mapcar #'event->variant (journal-events journal task)))))))
```

`picks` = alist `(:name . value)` (None dropped, Some unwrapped). `mbt-compare` defaults to `spec-equal`; specialise per variable when the SUT exposes less. `replay-trace driver trace &key variables check-initial` → `(values sut :ok|:aborted)`; variables not in `mbt-observe` are ignored.

## ITF ↔ Lisp (`spec-protocol.itf`)

| ITF | Lisp |
|-----|------|
| `{"#bigint": "3"}` / `"s"` / `true` `false` | `3` / `"s"` / `t` `nil` |
| `[…]` / `{"#set": …}` / `{"#map": [[k v]…]}` / `{"#tup": …}` | `fset2:seq` / `fset2:set` / `fset2:map` / list |
| `{"tag": "Busy", "value": v}` / `{"tag": "Idle", "value": {"#tup": []}}` | `(:busy . v)` / `:idle` |
| record `{f: v}` | canonical keyword plist (`rec`) |
| `BankTest::Bank::x`, `mbt::actionTaken` | keyed by last segment: `"x"`, `state-action-taken` |

`read-itf` / `parse-itf` / `write-itf` (freeze), `state-value` (string or symbol), `state-variables`, `state-nondet-picks`, `itf-equal`. Labels/fields go through `demangle-name`, so `HalfClosedLocal` ↔ `:half-closed-local`.

## Workflow

1. Model the **spec** (RFC section / design doc) as a `defspec`; invariants named after it. Skill **quint-modeling**.
2. `(simulate spec :seed N :n-traces 3)` → `write-itf` into `tests/fixtures/`; keep one trace from a deliberately broken variant.
3. Rove: `clos-driver` on frozen traces (no Node); when `(quint-available-p)`, emit → typecheck → simulate → replay fresh traces. Divergence must be detected on the broken fixture.
4. For a foreign SUT: driver as above; add domain assertions the model cannot see (e.g. crash-replay: copy journal, fresh task, `replay-journal`, status equal).
5. Triage: `spec-conformance-divergence` carries `divergence-step-index action variable expected actual`. `continue` skips the variable, `abort-trace` stops the trace. Model wrong → fix `defspec`; mapping wrong → fix driver; impl wrong → file it, keep the trace as a regression fixture, do **not** bend the model to the code.

## RFC as oracle

Prefer protocols with an external spec (HTTP/2 RFC 9113 §5.1 stream states + §6.9 flow control, WebSocket RFC 6455 close/fragmentation) over self-designed ones: the model transcribes the RFC, so a passing replay is evidence about the implementation, not just self-consistency. Drive in-process (connection pairs, frame injection) — no sockets in conformance tests.

## Anti-patterns

- Observing via the code path under test (read state through an independent accessor)
- Weakening `mbt-compare` to make a red trace green
- Traces without `--mbt` (no `actionTaken` ⇒ `spec-error`)
- Mapping by trace **index** instead of `mbt::actionTaken`
- Network I/O or sleeps inside `mbt-apply`
