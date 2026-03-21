---
name: act-github-actions
description: >-
  act: run GitHub Actions workflows locally via Docker. Use when testing CI workflows before pushing, debugging
  workflow failures offline, or validating GH Actions changes without burning CI minutes.
---

# act — Run GitHub Actions locally

Repo: [nektos/act](https://github.com/nektos/act). Install: `brew install act` (macOS) or see [install docs](https://nektosact.com/installation/).

## Quick reference

```bash
# List available jobs
act -l

# Run all workflows triggered by push
act push

# Run a specific job
act -j validate

# Run a specific workflow file
act -W .github/workflows/validate.yml

# Dry-run (parse and plan, no execution)
act -n push
```

## Selecting runner images

act maps `runs-on: ubuntu-latest` to Docker images. The default micro image is very minimal; most devcontainer feature workflows need a larger image:

```bash
# Medium image (recommended balance of size vs completeness)
act push -P ubuntu-latest=catthehacker/ubuntu:act-latest

# Full image (~12GB, closest to GitHub-hosted runners)
act push -P ubuntu-latest=catthehacker/ubuntu:full-latest
```

Set defaults in `~/.actrc`:
```
-P ubuntu-latest=catthehacker/ubuntu:act-latest
-P ubuntu-22.04=catthehacker/ubuntu:act-22.04
```

## Passing secrets and variables

```bash
# From env
act push -s GITHUB_TOKEN="$(gh auth token)"

# From file
act push --secret-file .secrets

# Env vars
act push --env-file .env
```

## Devcontainer features testing with act

The `devcontainer features test` command needs Docker-in-Docker. act runs inside Docker, so this requires privileged mode:

```bash
act push -j test-roswell -P ubuntu-latest=catthehacker/ubuntu:act-latest --privileged
```

**Known limitations for devcontainer feature testing:**
- DinD may need `--privileged` and Docker socket mounting.
- Feature tests that build containers are slower locally than on GitHub runners.
- `devcontainers/action@v1` (used for validation) works fine under act.
- Some feature tests may fail under act due to missing systemd or cgroup differences — if a test passes on GitHub but fails locally, check the runner image compatibility.

## Common workflow: egao1980/features

```bash
cd features/

# Validate devcontainer-feature.json (fast, no Docker builds)
act -j validate -W .github/workflows/validate.yml

# Test a specific roswell scenario
act -j test-roswell -W .github/workflows/validate.yml --privileged \
    -P ubuntu-latest=catthehacker/ubuntu:act-latest

# Test lem scenarios
act -j test-lem -W .github/workflows/validate.yml --privileged \
    -P ubuntu-latest=catthehacker/ubuntu:act-latest

# Test the older test.yaml matrix
act -j test-scenarios -W .github/workflows/test.yaml --privileged \
    -P ubuntu-latest=catthehacker/ubuntu:act-latest
```

## Troubleshooting

- **`Error: Cannot connect to the Docker daemon`** — ensure Docker/OrbStack is running.
- **Slow first run** — act pulls the runner image on first use; subsequent runs use cache.
- **`action not allowed`** — act doesn't enforce `allowed_actions` permissions. If it works locally but not on GitHub, check the repo's Actions permissions (Settings → Actions → General).
- **Matrix jobs** — act runs all matrix combinations by default. Use `--matrix scenario:roswell_ubuntu` to run a single combination.
- **`-s` flag does not exist** on `devcontainer features test` — use `--filter <scenario_name>` to run a specific scenario. This was a CI bug we hit.

## Integration with gh CLI

```bash
# Check remote CI status
gh run list --repo egao1980/features --limit 5
gh run view <run-id> --repo egao1980/features --log

# Trigger workflow manually (requires workflow_dispatch trigger)
gh workflow run validate.yml --repo egao1980/features --ref fix/cleanup-and-modernize

# Watch a running workflow
gh run watch <run-id> --repo egao1980/features
```
