# Lessons learned

Append-only log of **symptom → cause → fix** for this workspace.

## 2026-03 — `cl-protobufs` bootstrap and `egao1980` fork

- **Symptom:** `git clone https://github.com/egao1980/cl-protobufs.git` fails with `Repository not found` after `gh repo fork` exits non-zero.
- **Cause:** The fork under `egao1980` does not exist yet (fork creation failed, org permissions, or fork not created on GitHub).
- **Fix:** Ensure `gh auth status` succeeds; run `gh repo fork qitab/cl-protobufs --org egao1980` and confirm the repo appears on GitHub; then re-run `./.lisp-workspace/scripts/add-cl-project.sh qitab/cl-protobufs`. `add-cl-project.sh` checks `gh repo view egao1980/<name>` before cloning when the clone URL targets that org.

- **Symptom:** `gh repo fork … --org egao1980` returns HTTP 422: `egao1980` is the login for a user account (not an organization).
- **Cause:** GitHub’s `--org` flag is only for **organization** accounts.
- **Fix:** `add-cl-project.sh` compares `GITHUB_WORKSPACE_ORG` to `gh api user --jq .login`; if they match, it runs `gh repo fork` **without** `--org` so the fork lands under the user account.

## 2026-03 — MCP: quasi/cl-mcp + cl-mcp-server → cl-ai-project/cl-mcp

- **Context:** Workspace docs previously pointed at **quasi/cl-mcp** + **quasi/cl-mcp-server** (two repos, `run-server.lisp`).
- **Switch:** Canonical MCP server for this tree is **[cl-ai-project/cl-mcp](https://github.com/cl-ai-project/cl-mcp)** — single repo, **`MCP_PROJECT_ROOT`**, tools like **`repl-eval`** / **`inspect-object`** / **`load-system`**, stdio/TCP/HTTP, optional worker pool. Remove **`cl-mcp-server/`** wiring; use **`./.lisp-workspace/scripts/add-cl-project.sh cl-ai-project/cl-mcp`** (fork → **`egao1980/cl-mcp`**).

## 2026-03 — Same repo name, different owners (user vs org)

- **Symptom:** Confusion or wrong checkout — “we added **cl-mcp**” but tools/docs point at a different upstream than intended; or **`gh repo view cl-mcp`** is ambiguous / wrong repo.
- **Cause:** GitHub repo names are only unique **per owner**. Unrelated projects often share a name (e.g. **`quasi/cl-mcp`**, **`cl-ai-project/cl-mcp`**, **`egao1980/cl-mcp`**). Referring to “**cl-mcp**” without **`owner/`** does not identify a single repository.
- **Fix:** Always use full **`owner/repo`** in scripts, **`gh`**, **`add-cl-project.sh`** arguments, docs, and mental model. Set **`upstream`** remote to the **canonical** upstream you mean, not “whatever is called cl-mcp.” After a rename or switch, grep docs for the old **`owner/repo`** so nothing still points at the wrong fork.

## 2026-03 — ASDF source-registry.conf.d file format

- **Symptom:** `INVALID-SOURCE-REGISTRY` error at startup: `(:source-registry (:tree #P"/path/") :inherit-configuration)` in a `.conf` file under `source-registry.conf.d/`.
- **Cause:** Files inside `source-registry.conf.d/` must contain **bare directives** like `(:tree "/path/")`. ASDF wraps them in `(:source-registry ... :inherit-configuration)` automatically. Wrapping manually produces an invalid double-wrapped form. Also, `#P` pathname literals can confuse ASDF's reader — use plain strings.
- **Fix:** Changed `add-cl-project.sh` to emit `(:tree "/path/")` instead of `(:source-registry (:tree #P"/path/") :inherit-configuration)`.

## 2026-03 — cl-mcp requires eclector git HEAD (newer than Quicklisp dist)

- **Symptom:** `SB-PCL::FIND-METHOD-LENGTH-MISMATCH` loading `cl-mcp/src/cst.lisp`: `make-skipped-input-result` takes 4 args but cl-mcp defines a method with 5 specializers.
- **Cause:** cl-mcp's CST parser expects eclector git HEAD API where `make-skipped-input-result` takes `(client stream reason children source)` (5 args). Quicklisp dist eclector ships an older snapshot with 4-arg `(client stream reason source)`.
- **Fix:** Clone eclector HEAD into **both** Quicklisp `local-projects` directories: `~/quicklisp/local-projects/eclector-git` and symlink into `~/.roswell/lisp/quicklisp/local-projects/eclector-git`. Clear stale FASLs: `find ~/.cache/common-lisp -path '*eclector*' -name '*.fasl' -delete`.
