#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd -P)"

realpath() {
  python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

path_in_repo() {
  local resolved="$1"
  [ "$resolved" = "$REPO_REAL" ] && return 0
  case "$resolved" in
    "$REPO_REAL"/*) return 0 ;;
  esac
  return 1
}

REPO_REAL="$(realpath "$REPO")"

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
  source_real="$(realpath "$source")"

  for root in "${roots[@]}"; do
    dest="$root/$name"
    dest_real="$(realpath "$dest")"

    if [ "$dest_real" = "$source_real" ]; then
      continue
    fi

    if path_in_repo "$dest_real"; then
      echo "warning: skipping $dest (resolves inside repo at $dest_real)" >&2
      continue
    fi

    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
      rm -rf "$dest"
    fi
    ln -sfn "$source" "$dest"
  done
done
