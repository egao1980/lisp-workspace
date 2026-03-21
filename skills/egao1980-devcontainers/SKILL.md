---
name: egao1980-devcontainers
description: >-
  Dev Container Features for Common Lisp: Roswell, Lem, qlot/Ultralisp options from egao1980/features. Use when
  authoring .devcontainer.json for CL projects, GHCR feature refs ghcr.io/egao1980/features/*, or working in this
  workspace’s features/ checkout.
---

# egao1980 Common Lisp Dev Container Features

Upstream repo: [egao1980/features](https://github.com/egao1980/features) (also cloned as **`features/`** at the workspace root next to `.lisp-workspace/`).

## Published features (see upstream README)

- **`ghcr.io/egao1980/features/roswell:1`** — Roswell, selectable Lisp (`installLisp` / `useLisp`), Quicklisp dist version, optional **Ultralisp**, **`installTools`** / **`toolsToInstall`** (defaults include **qlot**). Source: `features/src/roswell/`.
- **`ghcr.io/egao1980/features/lem:1`** — [Lem](https://lem-project.github.io/) editor; depends on Roswell + qlot path as documented in upstream README. Source: `features/src/lem/`.

## Minimal devcontainer.json pattern

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/egao1980/features/roswell:1": {
      "version": "latest"
    }
  }
}
```

## CLI

- Install CLI: **`npm install -g @devcontainers/cli`**
- **`devcontainer up --workspace-folder <dir>`**, **`devcontainer exec ...`** — see [features/README.md](../../../features/README.md) in this workspace.

## Editing features

- Feature metadata: **`features/src/*/devcontainer-feature.json`**, **`install.sh`** next to it — follow [containers.dev](https://containers.dev/) feature conventions and upstream CI in **`features/.github/workflows/`**.

## Build-time gotchas (learned the hard way)

- **`containerEnv`** from `devcontainer-feature.json` only applies at **container runtime**, not during `install.sh`. Downstream features must hardcode `export PATH=".../bin:${PATH}"`.
- **`${options.*}`** substitution is **not supported** inside `containerEnv` — it's a pending spec proposal. Use hardcoded defaults and emit `/etc/profile.d/*.sh` overrides if the path is customizable.
- **Lem feature** requires pre-installing the `deploy` Quicklisp system (`ros -e '(ql:quickload :deploy :silent t)' -q`) before `ros install lem-project/lem`, because Lem's `.asd` uses `:defsystem-depends-on ("deploy")`.
- **Lem feature** also needs `libwebkitgtk-6.0-4` and `libgtk-4-1` (Debian) for the bundled `libwebview.so` CFFI dependency.
- Use the standalone **`@devcontainers/cli`** (`npx @devcontainers/cli features test`) — Cursor/VS Code's wrapper `devcontainer` binary injects unsupported arguments.
- **Run CI locally** before pushing with **[act](../act-github-actions/SKILL.md)**: `act -j validate -W .github/workflows/validate.yml` for fast validation, add `--privileged` for Docker-in-Docker feature tests.
- **Lint install.sh** with **[ShellCheck](../shellcheck-configuration/SKILL.md)** before committing: `shellcheck features/src/*/install.sh`. See **[bash-defensive-patterns](../bash-defensive-patterns/SKILL.md)** for quoting, error handling, and `su -c` patterns.
