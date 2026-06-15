#!/usr/bin/env bash
# Frozen test for T-001 — phase commands become SKILL.md skills; commands become EXACT thin shims.
# Hardened (codex review PR#12, rounds 1-2): body frozen as a fixture and compared byte-for-byte with
# NO H1-stripping (so a sneaked leading `# …` can't pass); shim body compared exactly; frontmatter
# validated by a real YAML parse (tests/skillmeta.rb).
set -uo pipefail
cd "$(dirname "$0")/.."
source tests/lib.sh
echo "== skills.test: phase commands -> skills (body frozen) + exact thin shims =="

for name in architect plan run review init; do
  # 1. skill frontmatter parses as YAML with name==<name> + non-empty description
  if ruby tests/skillmeta.rb "skills/$name/SKILL.md" "$name" >/dev/null 2>&1; then
    ok "skills/$name: valid frontmatter (name==$name, non-empty description)"
  else no "skills/$name: invalid/missing frontmatter"; fi

  # 2. the command body moved into the skill BYTE-FOR-BYTE (frozen fixture, nothing dropped)
  if [ -f "skills/$name/SKILL.md" ] && diff -q <(bash tests/body_of.sh "skills/$name/SKILL.md") "tests/fixtures/$name.body" >/dev/null 2>&1; then
    ok "skills/$name: body == frozen command body (no loss/edit/dup)"
  else no "skills/$name: body differs from tests/fixtures/$name.body"; fi

  # 3. the command body is EXACTLY the thin shim payload — no H1, no extra lines
  shim="$(bash tests/body_of.sh "commands/$name.md" 2>/dev/null)"
  expected="Use the \`$name\` skill."
  if [ "$shim" = "$expected" ]; then ok "commands/$name.md: body == exact shim ($expected)"
  else no "commands/$name.md: body != exact shim (got: '${shim:0:48}')"; fi

  # 4. the shim keeps a description in its frontmatter so /agentic-workflow:$name still registers
  if awk 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit} f&&/^description:[[:space:]]*[^[:space:]]/{ok=1} END{exit !ok}' "commands/$name.md" 2>/dev/null; then
    ok "commands/$name.md: keeps description frontmatter"
  else no "commands/$name.md: missing description frontmatter"; fi
done

exit $fails
