---
name: docker-devcontainers
description: >-
  Docker / Compose / Dev Containers spec. Use when authoring Dockerfiles or
  .devcontainer.json, or debugging mounts — not Lisp-specific.
---

# Docker and Dev Containers

## Authoritative references

- **Docker:** [docs.docker.com](https://docs.docker.com/) — Engine, Dockerfile reference, Compose, best practices.
- **Dev Containers:** [containers.dev](https://containers.dev/) — specification, Features, templates.
- **Spec repo:** [devcontainers/spec](https://github.com/devcontainers/spec) (JSON schemas, feature metadata).

## Cursor / Agent Skills ecosystem

- **Cursor docs:** [Agent Skills](https://www.cursor.com/docs/context/skills) — `.cursor/skills/`, `SKILL.md` format, optional `scripts/` / `references/` / `assets/`.
- **Open standard:** [agentskills.io](https://agentskills.io/) — portable skill packages across tools.
- **Example community collections** (inspect for patterns; verify before copying): [Snowflake-Labs/agent-skills](https://github.com/Snowflake-Labs/agent-skills), community “docker” skill writeups (e.g. SkillMD.ai docker skill guides — third-party, not official Docker Inc.).

## Practices

- Prefer **multi-stage** builds for smaller runtime images; pin base image digests when reproducibility matters.
- **Devcontainer Features** publish to OCI registries (e.g. `ghcr.io/...`); validate with **`@devcontainers/cli`** locally when possible.

## Feature authoring pitfalls

- **`containerEnv`** in `devcontainer-feature.json` sets env vars at **container runtime** only. Feature `install.sh` scripts execute during the **build phase** and do not see these variables. Hardcode necessary PATH exports in `install.sh`.
- **`${options.*}`** substitution works in `install.sh` (as shell vars), `entrypoint`, and `onCreateCommand`, but is **not yet supported** in `containerEnv` — it's a pending spec proposal ([devcontainers/spec#62](https://github.com/devcontainers/spec/issues/62)).
- **`su -` resets the environment.** When running commands as a non-root user in `install.sh`, explicitly inject PATH and other required env vars into the `su -c` command string.
- **Shell quoting:** use `printf '%q ' "$@"` to properly escape arguments for `su -c`; `"$*"` concatenates and loses word boundaries.
