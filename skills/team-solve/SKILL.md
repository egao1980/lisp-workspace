---
name: team-solve
description: >-
  Use when a problem directory has task.md plus paired tests/N.in and
  tests/N.out, or when the user runs /team-solve. Fresh agents, an on-disk
  ledger, and check-samples.sh is the verdict.
---

# team-solve

Cursor host for the [memdoor team-solve steps](https://github.com/guregodevo/memdoor/tree/main/examples/workflows/team-solve/steps) (Apache-2.0). `steps/*.yaml` prompts are verbatim. Memdoor is not required.

Not for Common Lisp repo work, refactors, or reviews.

## Coordinator

Dispatch and run the two shell steps. Do not plan, ideate, solve, review, or repair. Do not edit `task.md`, `tests/`, `plan.md`, `notes.md`, `solution.py`, or `review.md`.

Problem directory needs `task.md` and at least one `tests/*.in` with a matching `.out`. The program is `solution.py` (Python 3 stdlib, stdin to stdout).

Refuse to start if any of these already exist there: `plan.md`, `notes.md`, `solution.py`, `review.md`, `test-output.log`, `test-status.txt`, `final-test-output.log`. Copy the problem to a clean directory.

Run id: `team-solve-YYYYMMDDHHMMSS`. Replace `{{.partition}}` in the plan prompt with that id. Nowhere else.

Each agent step is one fresh subagent (Cursor Task, `subagent_type` `generalPurpose`). Do not `resume`. The task text is the step `prompt` plus these two lines and nothing else:

```
Problem directory: <absolute path>
Read and write files only in that directory.
```

Do not add hints, earlier replies, or your own plan. Workers must not spawn agents. `ideate-a` and `ideate-b` go out together, in one message, after `plan` has finished.

`max_retries: 1` is one re-dispatch of that step when its files are missing. It is not a second repair.

## Order

| step | kind | after | done when |
| --- | --- | --- | --- |
| `plan` | agent | — | `plan.md` and `notes.md` exist; `<!-- proposal-a -->` and `<!-- proposal-b -->` each occur once |
| `ideate-a`, `ideate-b` | agents, parallel | plan | proposal text sits immediately before its own marker; the other marker is untouched |
| `solve` | agent | both ideators | `solution.py` exists and the solver decision is in `notes.md` |
| `test` | command | solve | `test-status.txt` and `test-output.log` exist. A nonzero status does not stop the run |
| `review` | agent | test | `review.md` exists |
| `repair` | agent | review | exactly one pass, including when the status is 0 |
| `verify` | command | repair | this exit status is the workflow result |

## Commands

Run from the problem directory. Checker is this skill's `check-samples.sh`. Ignore the `check=` paths inside `test.yaml` and `verify.yaml`; those are Memdoor install paths. The script is the same file.

Test, and keep going:

```bash
bash "$CHECK" > test-output.log 2>&1
result=$?
printf '%s\n' "$result" > test-status.txt
cat test-output.log
printf 'Initial sample-test exit status: %s\n' "$result"
```

Verify. Do not repair again if this fails. Report the log.

```bash
bash "$CHECK" > final-test-output.log 2>&1
result=$?
cat final-test-output.log
exit "$result"
```

`$CHECK` is `.lisp-workspace/skills/team-solve/check-samples.sh` from the workspace root, or the absolute path of the copy next to this file.

A model saying done is not success. `verify` exit 0 is success.

## Checker

`bash .lisp-workspace/skills/team-solve/test-checker.sh` from the workspace root. Fixture is a one-integer double, not a benchmark problem.
