# dt-dev-skills

Various skills I've been working on.

## Skills

- **dt-codex-openrouter** — opens a second Codex desktop window running on the
  OpenRouter API backend, while the normal Codex app (dock icon) stays on its
  default OpenAI config. 
  
  Handles the one-off `CODEX_HOME` setup and the
  diagnosing of a dock icon that has drifted onto OpenRouter.

## Install

```bash
git clone https://github.com/demianturner/dt-dev-skills.git
cd dt-dev-skills
./install.sh
```

`install.sh` symlinks every `skills/*` folder into `$CODEX_HOME/skills` (default
`~/.codex/skills`) so Codex discovers them, and links each skill's `scripts/*`
into `~/.local/bin`. It also covers sibling homes such as
`~/.codex-openrouter`, because Codex reads skills per `CODEX_HOME`. Re-run after
pulling to pick up new skills.

Skills are linked, not copied, so edits in the repo are live. To remove one:

```bash
rm "$CODEX_HOME/skills/<skill-name>"
```

## Layout

```
skills/<skill-name>/
  SKILL.md          required; front matter has name + description
  scripts/          optional executables, linked into ~/.local/bin
  assets/           optional templates the skill copies
install.sh
```

## Notes

- The dock icon always reads `~/.codex`. A Codex session run on OpenRouter *in
  that home* makes the app save OpenRouter into its config, which repoints the
  icon. This repo avoids that by keeping OpenRouter in `~/.codex-openrouter`.
- Secrets live in each home's `.env` (`chmod 600`), never in `config.toml`.

## Other Skills
- [https://github.com/demianturner/swift-skills]()
- [https://github.com/demianturner/minknote-skills]()

## License

MIT — see [LICENSE](LICENSE).
