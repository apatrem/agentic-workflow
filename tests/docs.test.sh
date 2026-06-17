#!/usr/bin/env bash
# Docs-drift guards (T-2): lock in the consistency fixes the 2026-06-16/17 reviews flagged, so they can't
# silently regress —
#   (a) the headline framing must stay cross-CLI (AW-0007), not "a reusable Claude Code plugin";
#   (b) skill bodies must not hardcode model VERSIONS — those live only in docs/MODELS.md (single source);
#   (c) the architect skill's "spike" reference must carry its definition (no dangling term — 2026-06-17 review).
set -uo pipefail
cd "$(dirname "$0")/.."
source tests/lib.sh
echo "== docs.test: cross-CLI framing (AW-0007) + model single-source + spike defined =="

# (a) README carries the cross-CLI framing (names Codex AND Cursor) and doesn't lead Claude-only.
grep_q README.md "Codex" "README names Codex (cross-CLI framing)"
grep_q README.md "Cursor" "README names Cursor (cross-CLI framing)"
if head -4 README.md | grep -qiE '^a reusable claude code plugin'; then
  no "README headline reframes Claude-only (regresses AW-0007)"
else
  ok "README headline is not the old Claude-only framing"
fi
grep_q .claude-plugin/marketplace.json "Codex" "marketplace.json names Codex (cross-CLI framing)"
grep_q .claude-plugin/marketplace.json "Cursor" "marketplace.json names Cursor (cross-CLI framing)"

# (b) No hardcoded model versions anywhere under skills/ (drift surface — docs/MODELS.md is the single source).
#     Broad — matches bare 'GPT-5'/'Opus 4' too, not just dotted minor versions.
hits="$(grep -rnoE 'GPT-?5|Opus 4|Fable [0-9]|Sonnet 4|claude-opus|claude-fable' skills/ 2>/dev/null)"
if [ -z "$hits" ]; then
  ok "no hardcoded model versions in skills/ (single source = docs/MODELS.md)"
else
  no "hardcoded model version in skills/ (move to docs/MODELS.md):"
  echo "$hits" | sed 's/^/      /'
fi

# (c) The architect skill tells the human to "spike a throwaway prototype" for high-fidelity questions. If it
#     references a spike, it MUST also DEFINE one here — a dangling term with no definition was the gap the
#     2026-06-17 review flagged. The frozen-body fixture locks the whole body byte-for-byte; this guards the
#     SEMANTIC invariant a legitimate re-freeze of that fixture could still drop. Keyed on the definition's
#     distinctive phrasing ("spike" alone also appears in the reference).
if grep -qiE '\bspike\b' skills/architect/SKILL.md 2>/dev/null; then
  grep_q skills/architect/SKILL.md "discard the code"   "architect defines 'spike' (throwaway, discard) where it references one"
  grep_q skills/architect/SKILL.md "never merge a spike" "architect: spike definition says don't merge a spike"
fi

exit $fails
