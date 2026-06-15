#!/usr/bin/env bash
# Frozen test for T-003 — plugin.json registers every skill by EXACT path (no dupes); every SKILL.md
# has a valid leading frontmatter block; shims resolve to real skills; CI actually runs the gate;
# README documents the install. Hardened (codex review PR#12): exact ./skills/<dir> path parity with
# duplicate detection; frontmatter validated as a leading block; CI checked as a real run step.
set -uo pipefail
cd "$(dirname "$0")/.."
source tests/lib.sh
echo "== packaging.test: plugin.json parity + frontmatter + shim<->skill + CI step + README =="

# 1. plugin.json .skills == the exact set of ./skills/<dir> paths, with no duplicates
if python3 - <<'PY'
import json, os, sys
d = json.load(open(".claude-plugin/plugin.json"))
entries = [e.rstrip("/") for e in d.get("skills", [])]
dups = sorted({e for e in entries if entries.count(e) > 1})
listed = set(entries)
present = {"./skills/" + n for n in os.listdir("skills") if os.path.isdir(os.path.join("skills", n))}
miss, extra = sorted(present - listed), sorted(listed - present)
if dups:  print("duplicate entries:", dups)
if miss:  print("missing from plugin.json:", miss)
if extra: print("listed but no such dir:", extra)
sys.exit(1 if (dups or miss or extra) else 0)
PY
then ok "plugin.json .skills == ./skills/<dir> set (exact paths, no dupes)"; else no "plugin.json skills parity/dupe failure"; fi

# 2. every SKILL.md: valid LEADING frontmatter, name==folder, non-empty description
for d in skills/*/; do
  n="$(basename "$d")"
  python3 tests/skillmeta.py "${d}SKILL.md" "$n" >/dev/null 2>&1 && ok "frontmatter ok: $n" || no "frontmatter invalid: $n"
done

# 3. every command shim resolves to an existing skill (exact shim body)
for f in commands/*.md; do
  base="$(basename "$f" .md)"
  if [ "$(bash tests/body_of.sh "$f" 2>/dev/null)" = "Use the \`$base\` skill." ]; then
    [ -d "skills/$base" ] && ok "shim $base -> skills/$base" || no "shim $base -> MISSING skills/$base"
  fi
done

# 4. the phase skills + setup are registered (end-state; red until T-001/T-002/T-003 land)
for n in architect plan run review init setup; do
  grep_q ".claude-plugin/plugin.json" "skills/$n\"" "plugin.json registers skills/$n"
done

# 5. CI runs the gate — a non-comment step that invokes `bash tests/run.sh`
if python3 - <<'PY'
import sys
try:
    lines = open(".github/workflows/validate-templates.yml").read().split("\n")
except FileNotFoundError:
    print("no CI workflow"); sys.exit(1)
hit = any(("tests/run.sh" in l) and (not l.lstrip().startswith("#"))
          and ("bash" in l or l.lstrip().startswith(("run:", "- run:"))) for l in lines)
sys.exit(0 if hit else 1)
PY
then ok "CI workflow runs 'bash tests/run.sh' (enabled step)"; else no "CI does not invoke the gate"; fi

# 6. README documents the per-seat install
grep_q "README.md" "bin/install.sh" "README documents bin/install.sh"

exit $fails
