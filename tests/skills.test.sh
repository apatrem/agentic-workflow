#!/usr/bin/env bash
# Frozen test for T-001 — phase commands become SKILL.md skills; commands become EXACT thin shims.
# Hardened (codex review PR#12): freezes each command body as a fixture and compares the moved skill
# body byte-for-byte (no loss/edit/duplication); asserts the shim payload exactly; validates a real
# leading frontmatter block (not a loose whole-file grep).
set -uo pipefail
cd "$(dirname "$0")/.."
source tests/lib.sh
echo "== skills.test: phase commands -> skills (body frozen) + exact thin shims =="

for name in architect plan run review init; do
  # 1. skill has a valid LEADING frontmatter block: name==<name> + non-empty description
  if python3 tests/skillmeta.py "skills/$name/SKILL.md" "$name" >/dev/null 2>&1; then
    ok "skills/$name: valid leading frontmatter (name==$name, has description)"
  else no "skills/$name: invalid/missing frontmatter"; fi

  # 2. the command body moved into the skill BYTE-FOR-BYTE (frozen fixture)
  if [ -f "skills/$name/SKILL.md" ] && diff -q <(bash tests/body_of.sh "skills/$name/SKILL.md") "tests/fixtures/$name.body" >/dev/null 2>&1; then
    ok "skills/$name: body == frozen command body (no loss/edit/dup)"
  else no "skills/$name: body differs from frozen fixture tests/fixtures/$name.body"; fi

  # 3. the command is now EXACTLY the thin shim payload (nothing else)
  shim="$(bash tests/body_of.sh "commands/$name.md" 2>/dev/null)"
  expected="Use the \`$name\` skill."
  if [ "$shim" = "$expected" ]; then ok "commands/$name.md: body == exact shim ($expected)"
  else no "commands/$name.md: body != exact shim (got: '${shim:0:48}')"; fi

  # 4. the shim keeps a description frontmatter so /agentic-workflow:$name still registers
  if awk 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit} f&&/^description:[[:space:]]*[^[:space:]]/{ok=1} END{exit !ok}' "commands/$name.md" 2>/dev/null; then
    ok "commands/$name.md: keeps description frontmatter"
  else no "commands/$name.md: missing description frontmatter"; fi
done

exit $fails
