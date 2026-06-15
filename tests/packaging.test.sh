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

# 1. plugin.json .skills is an ARRAY OF STRINGS equal to the exact set of ./skills/<dir> (no dupes)
if python3 - <<'PY'
import json, os, sys
d = json.load(open(".claude-plugin/plugin.json"))
sk = d.get("skills")
if not isinstance(sk, list):
    print("plugin.json .skills is not a JSON array:", type(sk).__name__); sys.exit(1)
if not all(isinstance(e, str) for e in sk):
    print("plugin.json .skills has a non-string entry"); sys.exit(1)
entries = [e.rstrip("/") for e in sk]
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

# 5. CI runs the gate — an ENABLED step that actually INVOKES `tests/run.sh` at command position
#    (not in a comment, not echoed, not under a falsy `if:`).
if ruby -ryaml -e '
  begin; y = YAML.safe_load(File.read(".github/workflows/validate-templates.yml"), aliases: true)
  rescue; exit 1; end
  falsy = lambda do |c|
    s = c.to_s.gsub(/\$\{\{|\}\}/, "").strip.downcase
    !s.empty? && (%w[false 0 no off].include?(s) || s.include?("false"))
  end
  found = false
  (y["jobs"] || {}).each_value do |job|
    next unless job.is_a?(Hash)
    (job["steps"] || []).each do |s|
      next unless s.is_a?(Hash) && s["run"]
      next if falsy.call(s["if"])
      s["run"].to_s.each_line do |ln|
        l = ln.strip
        next if l.start_with?("#")                                  # comment line
        found = true if l =~ %r{\A(bash\s+)?(\./)?tests/run\.sh(\s|\z)}  # invoked at line start
      end
    end
  end
  exit(found ? 0 : 1)
' 2>/dev/null
then ok "CI invokes tests/run.sh at command position in an enabled step"; else no "CI does not actually invoke the gate"; fi

# 6. README documents the per-seat install
grep_q "README.md" "bin/install.sh" "README documents bin/install.sh"

exit $fails
