# Staged improvements for team-solve

## Pending

## Applied

- [2026-11-08] Run the verdict through cl-repo (from 2026-11-07). `check-feature.sh` runs `cl-repo test --system` when the client is on PATH; the fallback uses `ros +Q`. `TEAM_SOLVE_RUNNER=lisp` forces the fallback. `test-checker.sh` passes with both runners.

## Rejected
