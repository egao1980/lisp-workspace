# Workspace requirements

Coordinate multiple **Common Lisp** ASDF systems: reproducible deps, **Roswell**, local ASDF registry. Qlot = legacy on unmigrated checkouts.

## Git

- Default org: `egao1980` (`GITHUB_WORKSPACE_ORG` overrides in scripts).
- **Unmodified third-party:** `egao1980/cl-stack-systems` import (`imports/<name>/qlfile`, `./scripts/add-import.sh owner/repo <ref>`) → `ghcr.io/egao1980/cl-systems`. Do not fork by default.
- **Patched / overlays / owned CI:** fork into `egao1980`, clone, set **`upstream`**. `gh repo fork` uses `--org` only when `egao1980` is a GitHub org; if it matches `gh api user`, fork without `--org`.
- **Fork ↔ import exclusivity:** never both. Fork ⇒ delete `imports/<name>/`. Import ⇒ no workspace fork.
- Original `egao1980` projects: clone directly.

## Deps / CI

Skill **[cl-repository-ci](../skills/cl-repository-ci/SKILL.md)**. Pins / ACL exceptions: [memory/ci.md](../memory/ci.md).

- Install path = `cl-repository-client` → `ghcr.io/egao1980/cl-systems`.
- Bootstrap client from OCI. Do **not** git-checkout `cl-repository` in consumer CI.
- Consumer CI may `actions/checkout` **only** the repo under test.
- New first-party: canned `test-system.yml` / `publish-source.yml` from day one (`uses:` literal `@main`). No copied `ci-*.lisp`. No `qlfile` as the install story. CI extras in `.asd` `:cl-repo :ci`.
- Publish metadata = `.asd` + `auto-package-spec`. First-party → owning-repo. Third-party → cl-stack-systems. Natives → reusable native workflow.

## Tooling

- **ASDF:** `50-lisp-workspace-<name>.conf` under `~/.config/common-lisp/source-registry.conf.d/` (`add-cl-project.sh`).
- **Qlot:** `qlot exec ros …` only where a project still has qlot.
- **Quicklisp `local-projects`:** `add-cl-project.sh --quicklisp` only when you want global `ql:quickload`.

## Testing / errors

- New tests: **Rove** unless the subproject already mandates another runner. Skill **cl-unit-testing**.
- First-party errors: conditions + restarts ([CLHS 9](http://www.lispworks.com/documentation/HyperSpec/Body/09_.htm)). Skill **cl-stack-conditions**.

## Specs

- Global goals here; per-repo specs stay in each repository.
- Durable prefs → **[MEMORY.md](../MEMORY.md)** (index) + **[memory/](../memory/)** (stack notes).
- Cursor config: **[`.cursor/`](../.cursor/)**; workspace root `.cursor` should symlink there. Skills: `.cursor/skills` → `../skills`.
- Devcontainer features: **[egao1980/features](https://github.com/egao1980/features)** sibling `../features/`.
- Lisp MCP: **[cl-ai-project/cl-mcp](https://github.com/cl-ai-project/cl-mcp)** in `cl-mcp/`; [cl-mcp.md](cl-mcp.md). Inspector: `npx @modelcontextprotocol/inspector`.
- Agent-wire RPC = `rpc-protocol-*`. No second JSON-RPC/gRPC stack inside protocol backends. See [memory/agent.md](../memory/agent.md).
