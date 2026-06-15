#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

roots=(
  "$HOME/.agents/skills"
  "$HOME/.codex/skills"
  "$HOME/.claude/skills"
)

for root in "${roots[@]}"; do
  mkdir -p "$root"
done

for skill_dir in "$REPO"/skills/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  source="$REPO/skills/$name"

  for root in "${roots[@]}"; do
    dest="$root/$name"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
      rm -rf "$dest"
    fi
    ln -sfn "$source" "$dest"
  done
done
