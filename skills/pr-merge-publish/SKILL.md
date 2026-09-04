---
name: pr-merge-publish
description: >-
  Merge egao1980 PRs when CI is green; no human review. PRs are tracking/staging.
  Then run OCI publish. Use when a PR is open, checks finish, or the user
  mentions merge / land / publish.
---

# Merge when green, then publish

`egao1980/*` PRs are **not** a review queue. They exist so GitHub/CI/agents can track and stage a change. Do **not** wait for a human approve.

## When a PR exists

1. Keep it mergeable: rebase/merge the base, fix conflicts, push. Do not close for “superseded” / conflicts.
2. Wait until required checks are **green**. No checks configured + `MERGEABLE` = green.
3. Mark ready if it is still draft.
4. **Merge** (`gh pr merge <n> --merge` unless the repo standardizes on squash). Do **not** wait to be asked.
5. **Publish** if this repo ships to `ghcr.io/egao1980/cl-systems` (below). Skip publish for docs-only / workspace-only (`lisp-workspace`, `cl-workspace` manifest, skills, MEMORY).

Failed CI → fix and push; do not merge red.

## Merge commands

```bash
gh pr view <n> --json state,isDraft,mergeable,mergeStateStatus,statusCheckRollup
gh pr merge <n> --merge
```

`--delete-branch` only for a throwaway `egao1980` head that is **not** also the head of an **open upstream** PR. Never delete `egao1980/rove` `cursor/parametrize-*` while fukamachi/rove#76 is open.

## Publish (after merge)

Skill **[cl-repository-ci](../cl-repository-ci/SKILL.md)** is the contract. Trigger from the **owning** repo:

```bash
# source-only first-party (thin wrapper around publish-source.yml)
gh workflow run publish-checkout.yml -R egao1980/<repo> -f version=<asd-version>
# or omit -f version to use .asd :version

# natives — owning repo reusable workflow
gh workflow run publish-oci.yml -R egao1980/<repo>   # name varies; use the repo's native publish workflow
```

Third-party / unmodified → `cl-stack-systems` `publish.yml` (`-f import=<name>`), not a first-party proxy job.

User-facing feature → update `cl-stack/docs/QUICKSTART.md` pins in the **same** change set.

## Exceptions (do not auto-merge / auto-publish)

- Third-party **upstream** PRs — do not open or merge unless the user asks.
- `CommonLispNext/cl-repository` — never push or PR.
- Red or pending **required** checks.
- User said close/abandon, or the PR author asked to close.
