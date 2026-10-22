# Staged improvements for cl-stack-conditions

Pending corrections, additions, and refinements discovered during use.

## Pending

## Applied

- [2026-10-22] Domain restart names are package-qualified (from 2026-08-26) → Tests. Verified: `rove` exports `skip`; `mcp-protocol` exports `invoke-provide-input`, not `provide-input`.
- [2026-10-22] Worker-thread policy is not drain-thread `handler-bind` (from 2026-08-27) → Handlers.

## Rejected

- [2026-10-22] restart-case keyword body after `:report` (from 2026-08-26) — wrong: only `:report` / `:interactive` / `:test` are options (CLHS). SBCL 2.6.5: `(skip () :report "Skip" :skip)` returns `:SKIP`. The original failure was a stray `)` (READ error), not option grammar.
