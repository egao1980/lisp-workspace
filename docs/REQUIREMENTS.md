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

- **Install path = cl-repository.** Project deps come from **`ghcr.io/egao1980/cl-systems`** via `cl-repository-client`.
- **Bootstrap client from OCI.** Prefer `oras pull ghcr.io/egao1980/cl-repository/cl-repository-client:<ver>` (+ QL for the client’s own deps). Packager: `ghcr.io/egao1980/cl-repository/cl-repository-packager`. Do **not** git-checkout `cl-repository` in consumer CI (git clone only when developing that repo).
- **No sibling checkouts for deps.** Consumer CI may `actions/checkout` **only** the repo under test. Do **not** checkout `cl-repository`, `http-protocol`, `event-protocol`, … as sibling paths to satisfy ASDF. Local multi-repo clones are for editing; CI/install must not depend on them.
- **New first-party repos:** canned `test-system.yml` / `publish-source.yml` from day one (`@main`, literal ref — GH rejects expressions in `uses:`). Do not copy `ci-install.lisp` / `ci-test.lisp` / `publish-checkout.lisp`. CI extras in `.asd` `:cl-repo :ci`; hooks in `scripts/ci/` only if needed. Do not add `qlfile` as the project install story (qlot = legacy on unmigrated checkouts). `publish-source.yml@main` verified 2026-08-25 (`schema-protocol:0.1.0`).
- **Publish metadata = `.asd`.** Packaging is `auto-package-spec` from ASDF (`:version` / `:depends-on` / `:properties (:cl-repo …)`). Do **not** maintain a parallel `package-spec` in publish scripts. First-party source-only → owning-repo `publish-source.yml`. Third-party → cl-stack-systems import. Natives → cl-repository reusable native publish, still from `.asd` `:cl-repo` overlays. Skill: **[cl-repository-ci](../skills/cl-repository-ci/SKILL.md)**.

## Tooling

- **ASDF:** per-project `50-lisp-workspace-<name>.conf` under `~/.config/common-lisp/source-registry.conf.d/` (from `.lisp-workspace/scripts/add-cl-project.sh`).
- **Qlot:** legacy on unmigrated checkouts; prefer canned cl-repository GH Actions for new work. Use `qlot exec ros …` only where a project still has qlot.
- **Quicklisp `local-projects`:** optional; use `add-cl-project.sh --quicklisp` only when you want global `ql:quickload` without qlot.

## Testing

- Prefer **Rove** for **new** test code unless a subproject already mandates another framework.

## Specs

- **Global** goals and constraints live in this file; **per-repo** specs stay in each repository.
- **Durable user preferences** (standing instructions, tool defaults) belong in **[MEMORY.md](../MEMORY.md)** so agents can load them without mixing into formal requirements.
- **Cursor project config** lives in **[`.cursor/`](../.cursor/)** inside this repo; workspace root **`.cursor`** should symlink there. **`.cursor/skills` → `../skills`** so Cursor discovers **[skills/](../skills/)** without duplicating the tree.
- **Devcontainer features** for CL are maintained in **[egao1980/features](https://github.com/egao1980/features)**; this workspace keeps a sibling clone at **`../features/`** (relative to `.lisp-workspace/`) for reference and edits.
- **MCP for Lisp:** **[cl-ai-project/cl-mcp](https://github.com/cl-ai-project/cl-mcp)** in sibling dir **`cl-mcp/`**; see **[cl-mcp.md](cl-mcp.md)**. Use MCP Inspector (`npx @modelcontextprotocol/inspector`) when debugging stdio servers.
- **Agent-wire (MCP / A2A / AG-UI):** RPC is **`rpc-protocol-*`** (`rpc-protocol` modes + `rpc-protocol-json` / `rpc-protocol-grpc` codecs + `rpc-backend-*` transports). No second JSON-RPC/gRPC stack inside protocol backends. See **MEMORY.md**.
