#!/usr/bin/env bash
# Frozen test for T-002 — bin/install.sh symlinks skills/* into the shared global dirs,
# idempotently, and converts a pre-existing diverged real copy into a symlink.
# install.sh MUST resolve target dirs from $HOME (so this can sandbox it) and point links
# at the repo's absolute skills/<name>.
set -uo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO/tests/lib.sh"
echo "== install.test: bin/install.sh symlinks into ~/.agents|.codex|.claude/skills =="

have_file "$REPO/bin/install.sh"
if [ ! -f "$REPO/bin/install.sh" ]; then echo "  (install.sh missing — rest skipped)"; exit $fails; fi

SBX="$(mktemp -d)"; trap 'rm -rf "$SBX"' EXIT
# seed a diverged REAL copy that must be replaced by a symlink
mkdir -p "$SBX/.agents/skills/grill-me"; echo "stale divergent copy" > "$SBX/.agents/skills/grill-me/SKILL.md"

if HOME="$SBX" bash "$REPO/bin/install.sh" >/dev/null 2>&1; then ok "install.sh ran (exit 0)"; else no "install.sh failed (exit non-zero)"; fi

for base in .agents/skills .codex/skills .claude/skills; do
  link="$SBX/$base/grill-me"
  [ -L "$link" ] && ok "symlink present: $base/grill-me" || no "expected symlink: $base/grill-me"
  [ "$(readlink "$link" 2>/dev/null)" = "$REPO/skills/grill-me" ] && ok "$base/grill-me -> repo skills" || no "$base/grill-me not pointing at \$REPO/skills/grill-me"
done

# idempotent: a second run must not error and must keep the links
if HOME="$SBX" bash "$REPO/bin/install.sh" >/dev/null 2>&1; then ok "re-run is idempotent (exit 0)"; else no "re-run failed"; fi
[ -L "$SBX/.agents/skills/grill-me" ] && ok "diverged real copy converted to symlink" || no "diverged real copy not converted"

exit $fails
