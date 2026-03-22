Review and apply staged skill improvements.

Scan all `STAGED.md` files under `.lisp-workspace/skills/*/`:

1. For each skill that has a `STAGED.md` with pending items:
   - Read the current `SKILL.md` alongside `STAGED.md`.
   - For each pending item, evaluate whether it should be:
     - **Applied**: incorporate the change into `SKILL.md` and move the item to the `## Applied` section of `STAGED.md` with today's date.
     - **Rejected**: move to the `## Rejected` section with a brief reason.
     - **Kept pending**: leave it if more context is needed — explain why.
   - Show the user a summary of proposed changes per skill before applying.
2. After all skills are reviewed, commit the changes in `.lisp-workspace/`.
3. Report what was applied, rejected, and still pending.
