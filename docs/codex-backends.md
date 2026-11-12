# Codex backends on this machine

## Why two homes

Codex resolves *everything* from one directory, `CODEX_HOME` (default
`~/.codex`): `config.toml`, credentials, session history, skills, plugins, logs.
Give a process a different `CODEX_HOME` and it becomes a separate instance.

| Backend | Home | Model | Auth | Opened by |
| --- | --- | --- | --- | --- |
| Default | `~/.codex` | `gpt-6.1-terra` | ChatGPT sign-in | dock icon |
| OpenRouter | `~/.codex-openrouter` | `deepseek/deepseek-v4.1-flash` | `OPENROUTER_API_KEY` | `open-codex-openrouter` |

The default instance draws on the ChatGPT plan's limits; the OpenRouter instance
bills to the OpenRouter API key.

## How a second desktop window is possible

The Codex desktop app spawns a `codex` backend process and passes its environment
through, so `CODEX_HOME` selects the backend for that window. The app also holds
Electron's single-instance lock, so a second window needs its own profile:

```bash
open -n -a /Applications/ChatGPT.app \
     --env CODEX_HOME="$HOME/.codex-openrouter" \
     --args --user-data-dir="$HOME/Library/Application Support/Codex-OpenRouter"
```

Without `--user-data-dir` the second launch is forwarded to the window that is
already open. This was verified by inspecting the backend process environment:

```
pid 75697 -> CODEX_HOME=/Users/demianturner/.codex-openrouter
```

## Why the dock icon can drift onto OpenRouter

The desktop app writes the running session's model back into that session's
`CODEX_HOME/config.toml`. If an OpenRouter session runs in `~/.codex`, the app
saves `model_provider = "openrouter"` there and the dock icon starts opening
OpenRouter. Observed directly: `~/.codex/config.toml` was rewritten to
`deepseek/deepseek-v4.1-flash` while an OpenRouter session ran in the default
home.

Recovery:

```bash
open-codex-openrouter-setup      # reports the drift
cp ~/.codex/config.toml.DEFAULT ~/.codex/config.toml
```

Then run OpenRouter sessions only through `open-codex-openrouter`.

## OpenRouter authentication

`config.toml` declares a provider and an auth *command* rather than a stored
token:

```toml
[model_providers.openrouter]
name = "OpenRouter"
base_url = "https://openrouter.ai/api/v1"
wire_api = "responses"

[model_providers.openrouter.auth]
command = "sh"
args = [ "-c", "set -a; . \"${CODEX_HOME:-$HOME/.codex}/.env\"; set +a; printf '%s' \"$OPENROUTER_API_KEY\"" ]
```

Codex runs that command and reads the key from `.env`, so the key never sits in
`config.toml`. The `.env` is `chmod 600` and covered by `.gitignore`.

## Adding a third backend

```bash
mkdir -p ~/.codex-<name>
cp ~/.codex-openrouter/config.toml ~/.codex-<name>/config.toml
cp ~/.codex-openrouter/.env        ~/.codex-<name>/.env
```

Then copy the launcher with a new `CODEX_HOME` and `--user-data-dir`, and re-run
`./install.sh` so the skills are linked into the new home.
