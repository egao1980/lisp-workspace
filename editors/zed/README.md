# cl-stack-code in Zed

[Zed](https://zed.dev) runs external agents over the [Agent Client Protocol](https://agentclientprotocol.com). `scripts/cl-stack-code.sh --acp` serves cl-stack-code that way (cl-stack-code 0.11.0 or later; the launcher pins 0.12.3). Zed then sends your prompts to cl-stack-code. cl-stack-code reads and writes files through Zed's buffers, runs `bash` in Zed's terminal and asks for approvals in Zed's permission dialog.

A recorded session: [cl-stack-demos `harness/zed-sample`](https://github.com/egao1980/cl-stack-demos/tree/main/harness/zed-sample).

## 1. Build the executable first

```bash
scripts/cl-stack-code.sh --build
```

Zed waits for the agent's `initialize` reply and shows "Loading…" until it comes. A built executable answers in about a second. The first build takes about two minutes, and Zed would time out during it. `bootstrap.sh` builds it too.

## 2. Add the agent server

Merge [`agent_servers.json`](agent_servers.json) into `~/.config/zed/settings.json` (Zed: `zed: open settings`), then fix the paths:

- `command`: the absolute path of `scripts/cl-stack-code.sh`. A symlink to it, such as `~/.local/bin/cl-stack-code`, works too.
- `args`: `--acp`, then any cl-stack-code flags. `--model openai` selects the OpenAI-compatible provider. For Anthropic, drop it and set `ANTHROPIC_API_KEY` in the environment instead.
- `env.PATH`: Zed starts the agent with this `PATH`. It must contain `cl-repo` (usually `~/.local/bin`) and `ros` (Roswell), because a session with `lispImage: spawn` starts its Lisp image through `cl-repo run`. Without `cl-repo`, the image cannot find the project's systems.
- `env.OPENAI_BASE_URL` and `env.OPENAI_MODEL`: the server and the model id. Look the id up with `curl $OPENAI_BASE_URL/models`.
- `env.OPENAI_TIMEOUT` (non-streamed calls, seconds) and `env.OPENAI_STREAM_IDLE_TIMEOUT` (the longest silence inside a stream) keep long turns of slow local models alive. A stream has no total limit.

## 3. The API key comes from the environment

Do not put the key in `settings.json`: it is easy to commit, share or show on screen. The agent inherits the environment Zed was started with, so export the key and start Zed from that shell:

```bash
export OPENAI_API_KEY=…          # or source a gitignored .env
zed --foreground ~/src/my-project   # Zed must not be running already
```

If Zed is already running, `zed` only opens a window in the running Zed, which has the old environment. Quit Zed first (cmd-Q). On macOS, Zed started from the Dock reads your login shell's environment, so an `export` in `~/.zprofile` works too.

## 4. Use it

1. Open the project folder in Zed. cl-stack-code takes its working directory from Zed's project root, and reads `AGENTS.md`, `.cl-stack-code/settings.json`, skills and rules from there.
2. Agent panel (cmd-?) → **+** → **cl-stack-code**.
3. Type the prompt. Plans, messages and tool calls stream into the thread. Edits show as diffs. Anything the project settings do not allow becomes a permission prompt.

Modes (`default`, `acceptEdits`, `bypassPermissions`, `plan`) are cl-stack-code's permission modes, in the mode menu of the thread.

## Troubleshooting

- **"Loading…" forever.** The executable is missing or stale, so the agent is building. Run `scripts/cl-stack-code.sh --build` in a terminal and try again.
- **401 / no key.** Zed was started without `OPENAI_API_KEY` in its environment (see 3).
- **`Component … not found` in the Lisp image.** `cl-repo` is not on `env.PATH`, or the project was never synced. Run `cl-repo sync` in the project once.
- **Logs.** Zed's command palette: `dev: open acp logs` shows every JSON-RPC message. The agent's stderr goes to Zed's log (`zed: open log`).
