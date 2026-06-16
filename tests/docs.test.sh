#!/usr/bin/env bash
# Docs-drift guards (T-2): lock in the consistency fixes the 2026-06-16 reviews flagged, so they can't
# silently regress —
#   (a) the headline framing must stay cross-CLI (AW-0007), not "a reusable Claude Code plugin";
#   (b) skill bodies must not hardcode model VERSIONS — those live only in docs/MODELS.md (single source).
set -uo pipefail
cd "$(dirname "$0")/.."
source tests/lib.sh
echo "== docs.test: cross-CLI framing (AW-0007) + model single-source =="

# (a) README carries the cross-CLI framing (names Codex AND Cursor) and doesn't lead Claude-only.
grep_q README.md "Codex" "README names Codex (cross-CLI framing)"
grep_q README.md "Cursor" "README names Cursor (cross-CLI framing)"
if head -4 README.md | grep -qiE '^a reusable claude code plugin'; then
  no "README headline reframes Claude-only (regresses AW-0007)"
else
  ok "README headline is not the old Claude-only framing"
fi
grep_q .claude-plugin/marketplace.json "Codex|Cursor|portable" "marketplace.json description carries cross-CLI framing"

# (b) No hardcoded model versions anywhere under skills/ (drift surface — docs/MODELS.md is the single source).
hits="$(grep -rnoE 'GPT-5\.[0-9]|Opus 4\.[0-9]|Fable [0-9]|Sonnet 4\.[0-9]|claude-opus-4-[0-9]|claude-fable-[0-9]' skills/ 2>/dev/null)"
if [ -z "$hits" ]; then
  ok "no hardcoded model versions in skills/ (single source = docs/MODELS.md)"
else
  no "hardcoded model version in skills/ (move to docs/MODELS.md):"
  echo "$hits" | sed 's/^/      /'
fi

exit $fails
