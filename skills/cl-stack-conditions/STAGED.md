# Staged improvements for cl-stack-conditions

Pending corrections, additions, and refinements discovered during use.

## Pending

- [2026-08-26] restart-case keyword body after :report
  - Source: agent observation (ai-agent-protocol loop.lisp COMPILE-FILE unmatched close paren)
  - Proposed change: In Restarts, note that after `:report` / `:interactive` / `:test`, a **keyword body form** (`:skip`, `:continue`, `:retry`) is parsed as another restart-case option and swallows the next clause. Wrap keyword results: `(progn :skip)`. Same trap as CLHS `restart-case` option grammar. Replacing `:skip` with `(progn :skip)` steals one trailing `)` unless you add a close. A leftover extra `)` on a deeply nested `restart-case` is a real READ error (`unmatched close parenthesis`), distinct from the option-grammar trap.

- [2026-08-26] domain restart names are package-qualified
  - Source: agent observation (`No restart MCP-PROTOCOL/TESTS::PROVIDE-INPUT`; Rove `SKIP` vs domain `skip`)
  - Proposed change: Tests section — CLHS functions (`use-value`, `continue`, `abort`) are package-independent. Domain restarts (`skip`, `provide-input`, `approve`, `retry`) are interned in the protocol package; from a test package use `invoke-*` sugar or `protocol::name`. Never `(invoke-restart 'skip)` under Rove (hits `rove:skip`).

## Applied

## Rejected
