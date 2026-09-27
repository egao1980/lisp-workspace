---
name: spec-mbt-conformance
description: >-
  Model-based conformance for cl-stack CLOS protocols: replay Quint/Apalache ITF traces (`quint run --mbt`)
  against a real implementation via `spec-protocol/mbt` (`mbt-driver`, `mbt-init/apply/observe/compare`,
  `replay-trace`). Use when writing an `mbt-driver`, mapping ITF values to Lisp, freezing trace fixtures,
  or hunting spec/RFC deviations in an implementation. DSL: spec-dsl. Quint itself: quint-modeling.
---

# MBT conformance (`spec-protocol/mbt`)

Trace = oracle. `quint run --mbt` records which action fired (`mbt::actionTaken`) and its `nondet` picks (`mbt::nondetPicks`); the driver applies the same action to the system under test (SUT) and compares observed state with the trace state. Divergence = bug in model, mapping, or implementation — decide which before fixing.

## Driver

```lisp
(defclass journal-driver (spec-protocol.mbt:mbt-driver) ())

(defmethod mbt-init ((d journal-driver) state)          ; state = itf-state 0
  (let ((j (make-in-memory-journal))) (list j (make-durable-task :id "t"))))

(defmethod mbt-apply ((d journal-driver) sut action picks state)
  (destructuring-bind (journal task) sut
    (alexandria:switch (action :test #'string=)
      ("start"      (with-durable-task (task journal)))
      ("recordStep" (with-durable-task (task journal)
                      (with-durable-step ((cdr (assoc "name" picks :test #'string=))) t)))
      ("complete"   (complete-task task))
      (t (error 'spec-error :message (format nil "unmapped action ~A" action))))))

(defmethod mbt-observe ((d journal-driver) sut)         ; alist itf-var → lisp value
  (destructuring-bind (journal task) sut
    `(("status"  . ,(status->variant (durable-task-status task)))
      ("journal" . ,(map 'vector #'event->variant (journal-events journal task))))))

(replay-trace (make-instance 'journal-driver) (spec-protocol.itf:read-itf #p"spec/fixtures/journal-1.itf.json"))
```

`picks` = alist `("name" . lisp-value)` with `None` picks dropped. `mbt-compare` defaults to `itf-equal` after `itf-value->lisp`; specialise per variable when the SUT exposes less (e.g. compare only event tags).

## ITF ↔ Lisp

| ITF | Lisp (`spec-protocol.itf`) | Notes |
|-----|-----|-------|
| `{"#bigint": "3"}` | `3` | |
| `"s"` / `true` / `false` | `"s"` / `t` / `nil` | |
| `[…]` (List) | vector | ordered |
| `{"#set": …}` | `itf-set` | order-insensitive `itf-equal` |
| `{"#map": [[k v]…]}` | `itf-map` (alist) | composite keys allowed |
| `{"#tup": …}` | `itf-tuple` | |
| `{"tag": "Busy", "value": …}` | `itf-variant` | nullary = `value` empty tuple |
| record `{f: v}` | `equal` hash-table string→value | |

Keywords ↔ variants: `:half-closed-local` ↔ `HalfClosedLocal` via `spec-protocol:spec-name` — do not hand-roll a second mangler.

## Workflow

1. Model the **spec** (RFC section / design doc), invariants named after it. Skill **quint-modeling**.
2. `simulate … :mbt t :n-traces 3 :seed N` → freeze traces as `spec/fixtures/*.itf.json` (plus `--seed` in the test name).
3. Driver: init → apply → observe. Add domain assertions after each step where the model cannot see (e.g. crash-replay: copy journal, fresh task, `replay-journal`, status equal).
4. Rove: replay frozen traces (no Node needed); when `quint-available-p`, also emit → typecheck → simulate → replay fresh traces.
5. Divergence triage: `spec-conformance-divergence` carries `step-index action variable expected actual`. `continue` skips the variable, `abort-trace` stops. Classify: model wrong → fix `defspec`; mapping wrong → fix driver; impl wrong → file it, add the trace as a regression fixture, do **not** bend the model to the code.

## RFC as oracle

Prefer protocols with an external spec (HTTP/2 RFC 9113 §5.1 stream states + §6.9 flow control, WebSocket RFC 6455 close/fragmentation) over self-designed ones: the model transcribes the RFC, so a passing replay is evidence about the implementation, not just self-consistency. Drive in-process (connection pairs, frame injection) — no sockets in conformance tests.

## Anti-patterns

- Observing via the same code path you are testing (read state through a second, independent accessor when possible)
- Weakening `mbt-compare` to make a red trace green
- Traces without `--mbt` (no `actionTaken` ⇒ nothing to apply)
- Mapping by trace **index** instead of `mbt::actionTaken`
- Network I/O or sleeps inside `mbt-apply`
