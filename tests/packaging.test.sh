#!/usr/bin/env bash
# Frozen test for T-003 — plugin.json lists every skill; command shims point at real
# skills; every SKILL.md has valid frontmatter; CI runs the gate; README has install docs.
set -uo pipefail
cd "$(dirname "$0")/.."
source tests/lib.sh
echo "== packaging.test: plugin.json parity + shim<->skill + frontmatter + CI + README =="

# 1. plugin.json .skills == the set of skills/ dirs (parity, no missing/extra)
if python3 - <<'PY'
import json, os, sys
d = json.load(open(".claude-plugin/plugin.json"))
listed = {os.path.basename(p.rstrip("/")) for p in d.get("skills", [])}
present = {n for n in os.listdir("skills") if os.path.isdir(os.path.join("skills", n))}
miss, extra = present - listed, listed - present
if miss:  print("missing from plugin.json:", sorted(miss))
if extra: print("listed but absent:", sorted(extra))
sys.exit(1 if (miss or extra) else 0)
PY
then ok "plugin.json .skills == skills/ dirs"; else no "plugin.json skills list mismatches skills/"; fi

# 2. the phase skills + setup are actually listed (end-state, red until T-001/T-003 land)
for n in architect plan run review init setup; do
  grep_q ".claude-plugin/plugin.json" "skills/$n([\"/]|$)" "plugin.json lists skills/$n"
done

# 3. every command shim points at an existing skill
for f in commands/*.md; do
  base="$(basename "$f" .md)"
  if grep -qiE "Use the .?${base}.? skill" "$f" 2>/dev/null; then
    [ -d "skills/$base" ] && ok "shim $base -> skills/$base" || no "shim $base -> MISSING skills/$base"
  fi
done

# 4. every SKILL.md: name matches folder + has a description
for d in skills/*/; do
  n="$(basename "$d")"
  grep_q "${d}SKILL.md" "^name:[[:space:]]*$n[[:space:]]*$" "skills/$n frontmatter name==$n"
  grep_q "${d}SKILL.md" "^description:[[:space:]]*[^[:space:]]" "skills/$n has description"
done

# 5. CI runs the gate (tests/run.sh wired into the workflow)
grep_q ".github/workflows/validate-templates.yml" "tests/run.sh|tests/.*\.test\.sh" "CI workflow runs the bash gate"

# 6. README documents the per-seat install (mentions bin/install.sh)
grep_q "README.md" "bin/install.sh" "README documents bin/install.sh install"

exit $fails
