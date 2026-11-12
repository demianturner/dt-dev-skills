#!/usr/bin/env bash
# Link every skill in this repo into $CODEX_HOME/skills, plus CLI helpers into
# ~/.local/bin. Idempotent: re-run after pulling to pick up changes.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${DT_BIN_DIR:-$HOME/.local/bin}"

# Codex discovers skills per CODEX_HOME, so every separate home needs its own
# links. Install into the primary home plus any sibling homes (e.g. the
# OpenRouter one at ~/.codex-openrouter) that already look like Codex homes.
primary_home="${CODEX_HOME:-$HOME/.codex}"
homes=("$primary_home")
if [[ -z "${DT_SKILLS_HOMES:-}" ]]; then
  for home in "$HOME"/.codex-*/; do
    [[ -d "$home" ]] || continue
    [[ -f "$home/config.toml" ]] || continue      # skip not-yet-configured dirs
    [[ "${home%/}" == "$primary_home" ]] && continue
    homes+=("${home%/}")
  done
else
  # shellcheck disable=SC2206
  homes+=(${DT_SKILLS_HOMES})
fi

mkdir -p "$BIN_DIR"

linked=0
link_script_binaries() {
  local skill="$1"
  [[ -d "$skill/scripts" ]] || return 0
  local script
  for script in "$skill"/scripts/*; do
    [[ -f "$script" ]] || continue
    chmod +x "$script"
    ln -sf "$script" "$BIN_DIR/$(basename "$script")"
    echo "             $(basename "$script") -> $BIN_DIR/$(basename "$script")"
  done
}

for home in "${homes[@]}"; do
  skills_dir="$home/skills"
  mkdir -p "$skills_dir"
  echo "Home: $home"
  for skill in "$REPO_DIR"/skills/*/; do
    [[ -f "$skill/SKILL.md" ]] || continue
    name="$(basename "$skill")"
    target="$skills_dir/$name"

    if [[ -L "$target" ]]; then
      current="$(readlink "$target")"
      if [[ "$current" == "${skill%/}" ]]; then
        echo "  ok       $name"
        link_script_binaries "$skill"
        continue
      fi
      rm "$target"
      echo "  relinked $name (was -> $current)"
    elif [[ -e "$target" ]]; then
      echo "  SKIPPED  $name — $target exists and is not a symlink (move it aside first)"
      continue
    fi

    ln -s "${skill%/}" "$target"
    echo "  linked   $name -> $target"
    linked=$((linked + 1))
    link_script_binaries "$skill"
  done
  echo
done

echo "Bin dir   : $BIN_DIR"
case ":$PATH:" in
  *":$BIN_DIR:"*) echo "PATH      : ok" ;;
  *) echo "PATH      : add this to ~/.zshrc ->  export PATH=\"$BIN_DIR:\$PATH\"" ;;
esac

if [[ $linked -eq 0 ]]; then
  echo
  echo "Nothing new to link. Skills are live from the repo."
fi
