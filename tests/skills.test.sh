#!/usr/bin/env bash
# Frozen test for T-001 — phase commands converted to SKILL.md skills + thin slash shims.
set -uo pipefail
cd "$(dirname "$0")/.."
source tests/lib.sh
echo "== skills.test: phase commands -> skills + thin Claude shims =="

# A marker phrase unique-ish to each command's body; must land in the SKILL, not the shim.
markers="architect:grill-with-docs plan:frozen run:Superset review:Dual-review init:Scaffold"

for pair in $markers; do
  name="${pair%%:*}"; marker="${pair#*:}"
  # 1. the skill exists with valid frontmatter
  have_dir "skills/$name"
  have_file "skills/$name/SKILL.md"
  grep_q "skills/$name/SKILL.md" "^name:[[:space:]]*$name[[:space:]]*$" "skills/$name frontmatter: name: $name"
  grep_q "skills/$name/SKILL.md" "^description:[[:space:]]*[^[:space:]]" "skills/$name frontmatter: has description"
  # 2. the body actually landed in the skill
  grep_q "skills/$name/SKILL.md" "$marker" "skills/$name carries body marker ($marker)"
  # 3. the command is now a thin shim that invokes the skill
  have_file "commands/$name.md"
  grep_q "commands/$name.md" "Use the .?${name}.? skill" "commands/$name.md is a thin shim -> $name skill"
  # 4. no prompt duplication: the body marker must NOT remain in the shim
  ngrep_q "commands/$name.md" "$marker" "commands/$name.md has no duplicated body ($marker absent)"
  # 5. the shim is actually thin
  n=$(wc -l < "commands/$name.md" 2>/dev/null || echo 999)
  [ "$n" -le 8 ] && ok "commands/$name.md is thin ($n lines)" || no "commands/$name.md too long ($n lines) — not a shim"
done

exit $fails
