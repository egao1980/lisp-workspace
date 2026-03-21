---
name: docker-devcontainers
description: >-
  Docker images, Dockerfiles, Compose, and Dev Containers (devcontainer.json, Features, lifecycle). Use when
  containerizing apps, authoring .devcontainer.json, debugging mount/network issues, or comparing community skill
  patterns — not Lisp-specific by itself.
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
