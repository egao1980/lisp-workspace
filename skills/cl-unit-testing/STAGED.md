# Staged improvements for cl-unit-testing

## Pending

- [2026-11-24] rove 0.11.1 (egao1980/rove#7) changed `deftest-parametrize :rows FORM`: the values are now bound as values. Before, they were spliced in as code and evaluated a second time. Literal (inline) rows are unchanged, and their elements are still forms (`'(1 2)`). A contract that worked around the old behaviour (a `quoted-rows` helper, or `(list 'quote v)` wrapping) now passes `(QUOTE v)` through. It fails in CI, which resolves an unpinned `"rove"` to the newest version, while a local `cl-repo.lock` can still hold 0.11.0. Hit on a contract branch on 2026-11-24 (green locally, red on all three OSes). Proposal for the skill:
  - pin `(:version "rove" "0.11.1")` in every tests system;
  - say in the `:rows` row of the table that values are bound, not evaluated;
  - never quote `:rows` values.
## Applied

## Rejected
