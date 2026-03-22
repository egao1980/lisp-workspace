# OCI-пакеты cl-protobufs / grpc — памятка (macOS, Apple Silicon)

## Репозитории и версии

| Пакет | Репо | Релиз |
|-------|------|-------|
| cl-repository | [egao1980/cl-repository](https://github.com/egao1980/cl-repository) | [v0.9.0](https://github.com/egao1980/cl-repository/releases/tag/v0.9.0) |
| cl-protobufs | [egao1980/cl-protobufs](https://github.com/egao1980/cl-protobufs) | [v2.1.0](https://github.com/egao1980/cl-protobufs/releases/tag/v2.1.0) |
| grpc | [egao1980/grpc](https://github.com/egao1980/grpc) | [v0.1.0](https://github.com/egao1980/grpc/releases/tag/v0.1.0) |

Платформы в матрице сборки: **linux/amd64**, **linux/arm64**, **darwin/arm64**.

## Зависимости

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (для локального реестра и `act`)
- [nektos/act](https://github.com/nektos/act) — `brew install act`
- [oras](https://oras.land/) — `brew install oras`
- [Roswell](https://roswell.github.io/) — `brew install roswell`
- SBCL — `ros install sbcl-bin`

## Быстрый старт

### 1. Локальный OCI-реестр

```bash
docker run -d -p 5050:5000 --name cl-oci-test-registry registry:2
```

### 2. Сборка и публикация (act)

```bash
rm -rf /tmp/act-artifacts && mkdir -p /tmp/act-artifacts

cd cl-protobufs   # сначала cl-protobufs, потом grpc
act workflow_dispatch \
  --input version=2.1 \
  --input registry=host.docker.internal:5050 \
  --container-architecture linux/arm64 \
  -P ubuntu-latest=catthehacker/ubuntu:act-latest \
  -P ubuntu-24.04-arm64=catthehacker/ubuntu:act-latest \
  --matrix os:linux --matrix arch:arm64 \
  -W .github/workflows/publish-oci.yml \
  --env GITHUB_REPOSITORY_OWNER=egao1980 \
  --artifact-server-path /tmp/act-artifacts \
  > /tmp/act-publish.log 2>&1 || { tail -50 /tmp/act-publish.log; exit 1; }
```

Для **grpc** — то же, `--input version=0.11`.

### 3. Проверка в devcontainer

Минимальный `devcontainer.json`:

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": { "ghcr.io/egao1980/features/roswell:1": {} },
  "runArgs": ["--add-host=host.docker.internal:host-gateway"]
}
```

Внутри контейнера (SBCL):

```lisp
(cl-repository-client/quickload:add-registry
  "http://host.docker.internal:5050" :namespace "egao1980/cl-systems")
(cl-repository-client/quickload:load-system "cl-protobufs" :version "2.1")
(cl-repository-client/quickload:load-system "grpc" :version "0.11")
```

## Подробности

- Полный разбор ошибок и рецепты: [LESSONS_LEARNED.md](../LESSONS_LEARNED.md) (секции «act + local OCI registry + devcontainer», «oras version pin»)
- Overlay-ключи `os`/`release`/`arch`: там же, секция «cl-repository overlay platform keys»
- Настройка ASDF: используйте `:directory` (не `:tree`) для монтирования cl-repository — см. LESSONS_LEARNED
- Devcontainer-фичи Roswell/Lem: [egao1980/features](https://github.com/egao1980/features)
- cl-mcp (MCP-сервер для Lisp): [docs/cl-mcp.md](cl-mcp.md)
