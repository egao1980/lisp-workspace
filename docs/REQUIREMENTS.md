# Workspace requirements

## Purpose

Coordinate multiple **Common Lisp** codebases (ASDF systems) that depend on each other — with reproducible deps (**qlot** where used), **Roswell** for implementations, and **pure ASDF** source registry entries for local checkouts.

## Git policy

- **Default GitHub org for this workspace:** `egao1980` (`GITHUB_WORKSPACE_ORG` overrides in scripts).
- **Third-party libraries:** fork into `egao1980`, clone the fork, add **`upstream`** to the canonical repo. The script runs **`gh repo fork`**; use **`--org`** only when `egao1980` is a **GitHub organization** (`gh api orgs/egao1980`). If `egao1980` is a **user** login matching `gh api user`, fork runs **without** `--org`.
- **Original projects** already living under `egao1980`: clone `egao1980/<repo>` directly.

## Tooling

- **ASDF:** per-project `50-lisp-workspace-<name>.conf` under `~/.config/common-lisp/source-registry.conf.d/` (from `.lisp-workspace/scripts/add-cl-project.sh`).
- **Qlot:** project-local; use `qlot exec ros …` from a project root when that project uses qlot.
- **Quicklisp `local-projects`:** optional; use `add-cl-project.sh --quicklisp` only when you want global `ql:quickload` without qlot.

## Testing

- Prefer **Rove** for **new** test code unless a subproject already mandates another framework.

## Specs

- **Global** goals and constraints live in this file; **per-repo** specs stay in each repository.
- **Durable user preferences** (standing instructions, tool defaults) belong in **[MEMORY.md](../MEMORY.md)** so agents can load them without mixing into formal requirements.
- **Cursor project skills** live in **[skills/](../skills/)**; the workspace uses **`.cursor/skills` → `.lisp-workspace/skills`** so Cursor discovers them while the source stays in this Git repo.
- **Devcontainer features** for CL are maintained in **[egao1980/features](https://github.com/egao1980/features)**; this workspace keeps a sibling clone at **`../features/`** (relative to `.lisp-workspace/`) for reference and edits.
- **MCP for Lisp:** **[cl-mcp](https://github.com/quasi/cl-mcp)** + **[cl-mcp-server](https://github.com/quasi/cl-mcp-server)** live in sibling dirs **`cl-mcp/`** and **`cl-mcp-server/`**; see **[cl-mcp.md](cl-mcp.md)**. Use MCP Inspector (`npx @modelcontextprotocol/inspector`) when debugging stdio servers.
