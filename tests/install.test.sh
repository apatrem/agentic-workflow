#!/usr/bin/env bash
# Frozen test for T-002 — bin/install.sh symlinks EVERY skill into all three shared roots,
# idempotently, converting pre-existing diverged real files AND real directories into symlinks;
# the `setup` skill exists with the exact shim body.
# Hardened (codex review PR#12, rounds 1-2): every skill is re-verified after BOTH runs (so a
# non-idempotent installer that drops other links on run 2 can't pass); real-dir + real-file
# collisions both covered; setup validated via a real YAML parse.
# install.sh MUST derive its repo root from its own path and resolve target dirs from $HOME.
set -uo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO/tests/lib.sh"
echo "== install.test: bin/install.sh symlinks every skill into ~/.agents|.codex|.claude/skills =="

have_file "$REPO/bin/install.sh"
if [ ! -f "$REPO/bin/install.sh" ]; then echo "  (install.sh missing — rest skipped)"; exit $fails; fi

SBX="$(mktemp -d)"; trap 'rm -rf "$SBX"' EXIT

check_all_links() { # $1 = label — assert EVERY skill is symlinked into EVERY root, pointing at the repo
  for d in "$REPO"/skills/*/; do
    name="$(basename "$d")"
    for root in .agents/skills .codex/skills .claude/skills; do
      link="$SBX/$root/$name"
      if [ -L "$link" ] && [ "$(readlink "$link" 2>/dev/null)" = "$REPO/skills/$name" ]; then
        ok "$1: $root/$name -> repo"
      else no "$1: $root/$name missing or wrong target"; fi
    done
  done
}

# diverged pre-existing copies that must be REPLACED by symlinks:
mkdir -p "$SBX/.agents/skills/grill-me"; echo "stale" > "$SBX/.agents/skills/grill-me/SKILL.md"  # real DIRECTORY
mkdir -p "$SBX/.codex/skills";           echo "stale" > "$SBX/.codex/skills/grill-me"             # real FILE

HOME="$SBX" bash "$REPO/bin/install.sh" >/dev/null 2>&1 && ok "install.sh ran (exit 0)" || no "install.sh failed"
check_all_links "after run1"
[ -L "$SBX/.agents/skills/grill-me" ] && ok "diverged real DIRECTORY converted to symlink" || no "real directory not converted (ln -sfn footgun?)"
[ -L "$SBX/.codex/skills/grill-me" ]  && ok "diverged real FILE converted to symlink"      || no "real file not converted"

# idempotent: a second run exits 0 AND every link (not just one) is still correct
HOME="$SBX" bash "$REPO/bin/install.sh" >/dev/null 2>&1 && ok "re-run idempotent (exit 0)" || no "re-run failed"
check_all_links "after run2"

# the setup skill (T-002 acceptance) — real-YAML frontmatter + exact body
ruby "$REPO/tests/skillmeta.rb" "$REPO/skills/setup/SKILL.md" setup >/dev/null 2>&1 && ok "skills/setup: valid frontmatter" || no "skills/setup missing/invalid"
sb="$(bash "$REPO/tests/body_of.sh" "$REPO/skills/setup/SKILL.md" 2>/dev/null)"
[ "$sb" = "Run \`bin/install.sh\`." ] && ok "skills/setup body == 'Run \`bin/install.sh\`.'" || no "skills/setup body wrong (got: '${sb:0:48}')"

exit $fails
