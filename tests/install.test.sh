#!/usr/bin/env bash
# Frozen test for T-002 — bin/install.sh symlinks EVERY skill into all three shared roots,
# idempotently, converting pre-existing diverged real files AND real directories into symlinks;
# and the `setup` skill exists with the exact shim body.
# Hardened (codex review PR#12): enumerates every skills/*/ (not just grill-me); covers the
# real-directory collision (ln -sfn into an existing dir is a footgun); asserts the setup skill.
# install.sh MUST derive its repo root from its own path and resolve target dirs from $HOME.
set -uo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO/tests/lib.sh"
echo "== install.test: bin/install.sh symlinks every skill into ~/.agents|.codex|.claude/skills =="

have_file "$REPO/bin/install.sh"
if [ ! -f "$REPO/bin/install.sh" ]; then echo "  (install.sh missing — rest skipped)"; exit $fails; fi

SBX="$(mktemp -d)"; trap 'rm -rf "$SBX"' EXIT
# diverged pre-existing copies that must be REPLACED by symlinks:
mkdir -p "$SBX/.agents/skills/grill-me"; echo "stale" > "$SBX/.agents/skills/grill-me/SKILL.md"  # real DIRECTORY
mkdir -p "$SBX/.codex/skills";           echo "stale" > "$SBX/.codex/skills/grill-me"             # real FILE

HOME="$SBX" bash "$REPO/bin/install.sh" >/dev/null 2>&1 && ok "install.sh ran (exit 0)" || no "install.sh failed"

# every skill present in the repo must be linked into every root, pointing at the repo
for d in "$REPO"/skills/*/; do
  name="$(basename "$d")"
  for root in .agents/skills .codex/skills .claude/skills; do
    link="$SBX/$root/$name"
    [ -L "$link" ] && ok "symlink: $root/$name" || no "missing symlink: $root/$name"
    [ "$(readlink "$link" 2>/dev/null)" = "$REPO/skills/$name" ] && ok "$root/$name -> repo" || no "$root/$name wrong target"
  done
done

# the diverged real DIR and real FILE were both converted
[ -L "$SBX/.agents/skills/grill-me" ] && ok "diverged real DIRECTORY converted to symlink" || no "real directory not converted (ln -sfn footgun?)"
[ -L "$SBX/.codex/skills/grill-me" ]  && ok "diverged real FILE converted to symlink"      || no "real file not converted"

# idempotent: second run exits 0 and keeps links intact
HOME="$SBX" bash "$REPO/bin/install.sh" >/dev/null 2>&1 && ok "re-run idempotent (exit 0)" || no "re-run failed"
[ "$(readlink "$SBX/.agents/skills/grill-me" 2>/dev/null)" = "$REPO/skills/grill-me" ] && ok "idempotent: link still correct" || no "idempotent: link broken"

# the setup skill (T-002 acceptance) — frontmatter + exact body
python3 "$REPO/tests/skillmeta.py" "$REPO/skills/setup/SKILL.md" setup >/dev/null 2>&1 && ok "skills/setup: valid frontmatter" || no "skills/setup missing/invalid"
sb="$(bash "$REPO/tests/body_of.sh" "$REPO/skills/setup/SKILL.md" 2>/dev/null)"
[ "$sb" = "Run \`bin/install.sh\`." ] && ok "skills/setup body == 'Run \`bin/install.sh\`.'" || no "skills/setup body wrong (got: '${sb:0:48}')"

exit $fails
