#!/usr/bin/env bash
# Frozen test for T-003 — plugin.json registers every skill by EXACT path (no dupes); every SKILL.md
# has valid YAML frontmatter; shims resolve to real skills; CI actually runs the gate as an enabled
# step; README documents the install. Hardened (codex review PR#12, rounds 1-2): the CI check parses
# the workflow YAML and requires an ENABLED `run:` step invoking `bash tests/run.sh` (not a comment,
# `name:`, or `if: false` step); frontmatter via real YAML parse (tests/skillmeta.rb).
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

# 2. every SKILL.md: valid YAML frontmatter, name==folder, non-empty description
for d in skills/*/; do
  n="$(basename "$d")"
  ruby tests/skillmeta.rb "${d}SKILL.md" "$n" >/dev/null 2>&1 && ok "frontmatter ok: $n" || no "frontmatter invalid: $n"
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

# 5. CI runs the gate — parse the workflow and require an ENABLED run step invoking `bash tests/run.sh`
if ruby -ryaml -e '
  begin; y = YAML.safe_load(File.read(".github/workflows/validate-templates.yml"), aliases: true)
  rescue; exit 1; end
  found = false
  (y["jobs"] || {}).each_value do |job|
    (job["steps"] || []).each do |s|
      next unless s.is_a?(Hash) && s["run"].to_s.include?("tests/run.sh")
      next if s["if"].to_s.downcase.include?("false")   # skip disabled steps
      found = true
    end
  end
  exit(found ? 0 : 1)
' 2>/dev/null
then ok "CI workflow has an enabled step running 'bash tests/run.sh'"; else no "CI does not run the gate in an enabled step"; fi

# 6. README documents the per-seat install
grep_q "README.md" "bin/install.sh" "README documents bin/install.sh"

exit $fails
