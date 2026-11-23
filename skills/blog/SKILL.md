---
name: blog
description: >-
  Publish a note or post on egao1980/cl-blog (https://egao1980.github.io/cl-blog/):
  write posts/YYYY-MM-DD-slug.md (or .org) from the user's text or from the
  conversation, open a PR, merge it when the site build is green; master
  deploys to GitHub Pages. Use when the user asks to blog, post or publish a
  note / TIL / write-up, or runs /blog.
---

# Publish a blog note

Repo **`egao1980/cl-blog`**, default branch **`master`**, checkout `cl-blog/` at the workspace root. Post format, fields and URL rules: its [README](https://github.com/egao1980/cl-blog#writing-a-post). The generator is a cl-stack system in the same repo. PRs follow **pr-merge-publish**: no human review, so merge when green.

## Steps

1. **Checkout.** If `cl-blog/` is missing (as in a cloud session), clone it: `gh repo clone egao1980/cl-blog cl-blog`. Then `git -C cl-blog checkout -q master && git -C cl-blog pull -q --ff-only`.
2. **Write** `cl-blog/posts/$(date -u +%F)-<slug>.md`. Use `.org` (`#+TITLE`/`#+DATE`/`#+FILETAGS`) when the user writes Org or asks for it.
   - Slug: short, lowercase, hyphens. It must not collide with another post's slug.
   - Front matter: `title`, `date` (`date -u +'%F %H:%M'`), `tags`. Reuse existing tags (`grep -h '^tags:' cl-blog/posts/*.md`).
   - From a conversation: write a self-contained note (problem, what worked, code, links), not a transcript. Keep the user's voice and their terms.
   - For a long post, put `<!--more-->` (org: `#+more`) after the opening paragraph.
   - Images go in `cl-blog/static/images/` and are linked as `images/<file>`.
   - Public site: no secrets, tokens, e-mail addresses or private-repo details.
3. **Confirm** the text with the user before publishing, unless they said to publish as is. Use `draft: true` to stage a post without showing it.
4. **Preview** (local, optional): `cl-blog/bin/build > /tmp/blog-build.log 2>&1 || tail -40 /tmp/blog-build.log`, then open `cl-blog/_site/posts/<slug>.html`. Without `cl-repo` (cloud), skip this step: the PR build checks the post.
5. **PR:** create branch `agent/note-<slug>-<4 hex>` and commit `Post: <title>` (`Co-Authored-By` only). Push, then `gh pr create -R egao1980/cl-blog --base master`.
6. **Merge when green:** `gh pr checks <n> -R egao1980/cl-blog --watch`, then `gh pr merge <n> -R egao1980/cl-blog --merge --delete-branch`. If the build is red, read `gh run view <id> -R egao1980/cl-blog --log-failed`. It is usually the front matter (`invalid-post` names the file and reason); fix it and push.
7. **Deploy:** the `site` workflow on master runs `deploy`. Watch it (`gh run watch`), then give the user `https://egao1980.github.io/cl-blog/posts/<slug>.html`.

To edit or unpublish, use the same flow: change or delete the file. Never push to master directly.
