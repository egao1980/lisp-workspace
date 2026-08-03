# Workspace requirements

## Purpose

Coordinate multiple **Common Lisp** codebases (ASDF systems) that depend on each other — with reproducible deps (**qlot** where used), **Roswell** for implementations, and **pure ASDF** source registry entries for local checkouts.

## Git policy

- **Default GitHub org for this workspace:** `egao1980` (`GITHUB_WORKSPACE_ORG` overrides in scripts).
- **Third-party libraries (unmodified):** do **not** fork by default. Add an import unit to **[`egao1980/cl-stack-systems`](https://github.com/egao1980/cl-stack-systems)** — `imports/<name>/qlfile` with a pinned `github`/`git` line — so CI publishes a source-only package into **`ghcr.io/egao1980/cl-systems`**. One qlfile per upstream pin (isolation); use `./scripts/add-import.sh owner/repo <ref>`.
- **Third-party libraries (patched / overlays / owned CI):** fork into `egao1980`, clone the fork, add **`upstream`** to the canonical repo. The script runs **`gh repo fork`**; use **`--org`** only when `egao1980` is a **GitHub organization** (`gh api orgs/egao1980`). If `egao1980` is a **user** login matching `gh api user`, fork runs **without** `--org`.
- **Fork ↔ import exclusivity:** never keep both. Forking a library ⇒ remove `cl-stack-systems/imports/<name>/`. Adding an import ⇒ no workspace fork/checkout of that upstream (drop any existing fork from the workflow).
- **Original projects** already living under `egao1980`: clone `egao1980/<repo>` directly.

## Dependencies and CI

- **Install path = cl-repository.** Project deps come from **`ghcr.io/egao1980/cl-systems`** via `cl-repository-client`. Only **cl-repository** itself is checked out raw (client bootstrap + QL for *its* deps).
- **No sibling checkouts for deps.** CI may `actions/checkout` **(1)** the repo under test and **(2)** `egao1980/cl-repository` → `.cl-repository`. Do **not** checkout other workspace projects (`http-protocol`, `event-protocol`, …) as sibling paths to satisfy ASDF. Local multi-repo clones are for editing; CI/install must not depend on them.
- **New first-party repos:** ship `scripts/ci-install.lisp` + `scripts/ci-test.lisp` and cl-repo CI from day one. Do not add `qlfile` as the project install story (qlot = legacy on unmigrated checkouts).

## Tooling

- **ASDF:** per-project `50-lisp-workspace-<name>.conf` under `~/.config/common-lisp/source-registry.conf.d/` (from `.lisp-workspace/scripts/add-cl-project.sh`).
- **Qlot:** legacy on unmigrated checkouts; prefer cl-repository CI scripts for new work. Use `qlot exec ros …` only where a project still has qlot.
- **Quicklisp `local-projects`:** optional; use `add-cl-project.sh --quicklisp` only when you want global `ql:quickload` without qlot.

## Testing

- Prefer **Rove** for **new** test code unless a subproject already mandates another framework.

## Specs

- **Global** goals and constraints live in this file; **per-repo** specs stay in each repository.
- **Durable user preferences** (standing instructions, tool defaults) belong in **[MEMORY.md](../MEMORY.md)** so agents can load them without mixing into formal requirements.
- **Cursor project config** lives in **[`.cursor/`](../.cursor/)** inside this repo; workspace root **`.cursor`** should symlink there. **`.cursor/skills` → `../skills`** so Cursor discovers **[skills/](../skills/)** without duplicating the tree.
- **Devcontainer features** for CL are maintained in **[egao1980/features](https://github.com/egao1980/features)**; this workspace keeps a sibling clone at **`../features/`** (relative to `.lisp-workspace/`) for reference and edits.
- **MCP for Lisp:** **[cl-ai-project/cl-mcp](https://github.com/cl-ai-project/cl-mcp)** in sibling dir **`cl-mcp/`**; see **[cl-mcp.md](cl-mcp.md)**. Use MCP Inspector (`npx @modelcontextprotocol/inspector`) when debugging stdio servers.
