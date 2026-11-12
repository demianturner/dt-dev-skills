---
name: dt-codex-openrouter
description: "Open a second Codex desktop window running on the OpenRouter API backend, leaving the normal Codex app on its default OpenAI config. Use when the user says 'spin up OpenRouter codex', 'open the OpenRouter Codex', 'launch a Codex instance on OpenRouter', 'switch this session to OpenRouter', or wants a Codex agent on a model their ChatGPT plan does not cover. Also covers the one-off CODEX_HOME setup and diagnosing why the dock icon changed backend."
metadata:
  short-description: "Second Codex desktop window on OpenRouter; dock icon stays default."
---

# dt-codex-openrouter

Opens an extra **Codex desktop window** that runs on the OpenRouter API backend,
while the normal Codex app (dock icon) keeps using its default OpenAI config.

## Do this

```bash
open-codex-openrouter                 # open the OpenRouter window
open-codex-openrouter --check         # verify config/state, launch nothing
open-codex-openrouter --project ~/path/to/project
open-codex-openrouter --new           # force an additional window
```

Then confirm from the window itself that the model reads as the OpenRouter model
(e.g. `DeepSeek: DeepSeek V4.1 Flash`) and that the app shows no sign-in wall.
`--check` prints both backends, their homes, and their models.

Launching a GUI app is the one step a shell cannot fully verify. After running
the command, look at the window and tell the user what model it shows.

## How it works

Codex reads *everything* from one directory, `CODEX_HOME` (default `~/.codex`):
`config.toml`, credentials, sessions, history. Two facts make a second desktop
window possible:

1. The desktop app spawns a `codex` backend process and passes its environment
   through, so `CODEX_HOME` decides which config that window uses.
2. The app holds a single-instance lock, so a second window needs its own
   Electron profile via `--user-data-dir`.

So the launcher runs:

```bash
open -n -a /Applications/ChatGPT.app \
     --env CODEX_HOME="$HOME/.codex-openrouter" \
     --args --user-data-dir="$HOME/Library/Application Support/Codex-OpenRouter"
```

| | Default (dock icon) | OpenRouter window |
| --- | --- | --- |
| `CODEX_HOME` | `~/.codex` | `~/.codex-openrouter` |
| Model | `gpt-6.1-terra` | `deepseek/deepseek-v4.1-flash` |
| Auth | ChatGPT sign-in | `OPENROUTER_API_KEY` in `.env` |
| Sessions | default history | separate history |

The two windows run at the same time and do not interfere.

## One-off setup

Already done on this machine. Re-run any time; it is idempotent and backs up
before changing anything:

```bash
open-codex-openrouter-setup                 # create the OpenRouter home if missing
open-codex-openrouter-setup --force-config  # rewrite its config.toml from the template
```

It writes `~/.codex-openrouter/config.toml` and a `chmod 600` `.env`, links both
scripts into `~/.local/bin`, and warns if the default home has drifted onto
OpenRouter.

## Where the files live

The skill is the source of truth; `~/.local/bin` holds symlinks.

| Repo file | Installed at |
| --- | --- |
| `assets/openrouter.config.toml` | `~/.codex-openrouter/config.toml` |
| `assets/env.template` | `~/.codex-openrouter/.env` (`OPENROUTER_API_KEY=...`) |
| `scripts/open-codex-openrouter` | `~/.local/bin/open-codex-openrouter` |

To change the model, edit `model` in `~/.codex-openrouter/config.toml` (ids from
<https://openrouter.ai/models>) or run `/model` inside the OpenRouter window.
The provider must keep `wire_api = "responses"`.

## If the dock icon starts opening on OpenRouter

The desktop app saves the model of the session you are running back into that
session's `CODEX_HOME/config.toml`. Running an OpenRouter session *in the default
home* therefore repoints the dock icon — the usual cause of this problem.

Fix it and keep OpenRouter in its own home:

```bash
open-codex-openrouter-setup    # reports the drift
cp ~/.codex/config.toml.DEFAULT ~/.codex/config.toml
```

Then run OpenRouter sessions only through `open-codex-openrouter`, never by
changing the default home.

## Notes

- OpenRouter windows keep separate sessions; they do not appear in the default
  window's history. That is expected.
- Needs a GUI login session; `open` does nothing useful over plain SSH.
- If the window opens but shows the wrong model, run `--check` and compare the
  reported homes against the table above.
