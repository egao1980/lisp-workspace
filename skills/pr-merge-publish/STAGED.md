# Staged improvements: pr-merge-publish

Reviewed by `/review-skill-improvements`; not yet part of SKILL.md.

## Gate the publish on the merge state, not on the commands' exit codes (2026-11-24)

**What happened:** a scripted chain ran `gh pr ready N; … gh pr merge N --merge; gh pr view N --json state -q .state && gh workflow run publish-checkout.yml`. `gh pr ready` failed with a transient GraphQL error ("Something went wrong while executing your query"), so the PR stayed a draft. `gh pr merge` then failed ("Pull Request is still a draft"). `gh pr view` still exited 0 (printing `OPEN`), so the publish ran from the unchanged default branch and re-pushed the previous version's tag.

**Rule:**
- Compare the state explicitly: `[ "$(gh pr view N -R owner/repo --json state -q .state)" = MERGED ] || exit 1`, and only then `gh workflow run`.
- After `gh pr ready`, confirm `isDraft` is `false` (retry once on a GraphQL error).
- After publishing, check the run log for the expected tag: `gh run view ID --log | grep -o "Published …:<version>"`. A publish of the old version means the merge didn't land.
