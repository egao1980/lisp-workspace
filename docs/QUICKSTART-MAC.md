# cl-protobufs + grpc на macOS (Apple Silicon) — памятка

Установка и использование `cl-protobufs` и `grpc` как OCI-пакетов через [cl-repository](https://github.com/egao1980/cl-repository).
Компилятор C++ и Homebrew-зависимости **не нужны** — нативные библиотеки и прегенерированные .lisp уже внутри пакета.

## Зависимости

| Что | Установка |
|-----|-----------|
| [Roswell](https://roswell.github.io/) | `brew install roswell` |
| SBCL | `ros install sbcl-bin` |
| [Quicklisp](https://www.quicklisp.org/) | `ros install quicklisp` (или вручную) |

## Версии пакетов

| Пакет | Реестр | Тег |
|-------|--------|-----|
| [cl-repository](https://github.com/egao1980/cl-repository) (клиент) | [v0.9.0](https://github.com/egao1980/cl-repository/releases/tag/v0.9.0) | — |
| [cl-protobufs](https://github.com/egao1980/cl-protobufs) | `ghcr.io/egao1980/cl-systems/cl-protobufs` | `2.1` |
| [grpc](https://github.com/egao1980/grpc) | `ghcr.io/egao1980/cl-systems/grpc` | `0.11` |

Платформы с оверлеями: **linux/amd64**, **linux/arm64**, **darwin/arm64**.

## Быстрый старт

```lisp
;; 1. Загрузить клиент cl-repository (через Quicklisp или ASDF)
(ql:quickload "cl-repository-client")

;; 2. Подключить реестр
(cl-repo:add-registry "https://ghcr.io" :namespace "egao1980/cl-systems")

;; 3. Установить и загрузить
(cl-repo:load-system "cl-protobufs" :version "2.1")
(cl-repo:load-system "grpc" :version "0.11")
```

`cl-repo:load-system` сам скачает пакет, выберет оверлей под текущую ОС/архитектуру, установит зависимости и вызовет `asdf:load-system`.

## Без cl-repository (голый oras)

```bash
brew install oras
DEST=~/.local/share/cl-systems
mkdir -p "$DEST"

# cl-protobufs (darwin/arm64 overlay)
oras pull --platform darwin/arm64 \
  ghcr.io/egao1980/cl-systems/cl-protobufs:2.1 -o /tmp/cl-pb/
for f in /tmp/cl-pb/*.tar.gz; do tar xzf "$f" -C "$DEST/"; done

# grpc
oras pull --platform darwin/arm64 \
  ghcr.io/egao1980/cl-systems/grpc:0.11 -o /tmp/grpc/
for f in /tmp/grpc/*.tar.gz; do tar xzf "$f" -C "$DEST/"; done
```

Затем в SBCL:

```lisp
(asdf:initialize-source-registry
  '(:source-registry
    (:tree (:home ".local/share/cl-systems/"))
    :inherit-configuration))
(asdf:load-system "grpc")
```

## Что внутри оверлея

- **cl-protobufs**: `protoc`, `protoc-gen-cl-pb` (нативные бинарники) + прегенерированные `.lisp` для well-known-types → не нужен `cmake`/`protobuf` на машине
- **grpc**: `grpc.dylib`/`grpc.so` + зависимые `libgrpc*.dylib` (бандл) → не нужен `brew install grpc`, `LD_LIBRARY_PATH` / `DYLD_LIBRARY_PATH` не требуется (rpath `$ORIGIN` / `@loader_path`)

## Ссылки

- [README cl-repository](https://github.com/egao1980/cl-repository#readme) — полная документация (CLI, lockfile, OCICL-совместимость, CI)
- [README cl-protobufs](https://github.com/egao1980/cl-protobufs#readme) — Protocol Buffers для Common Lisp
- [README grpc](https://github.com/egao1980/grpc#readme) — gRPC-обёртка
- Devcontainer-фича Roswell: [egao1980/features](https://github.com/egao1980/features)
- Подробности сборки и ошибки: [LESSONS_LEARNED.md](../LESSONS_LEARNED.md)
