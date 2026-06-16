#!/usr/bin/env bash
# Repo-hygiene guards (T-1): AW-0007 invites adoption by reference, which is legally blocked without an
# explicit license. Assert the LICENSE exists and is MIT, and that both manifests declare it — so the
# legal gap can't silently reopen.
set -uo pipefail
cd "$(dirname "$0")/.."
source tests/lib.sh
echo "== repo.test: LICENSE present (MIT) + manifests declare it =="

have_file LICENSE
grep_q LICENSE "^MIT License" "LICENSE is MIT"
grep_q LICENSE "Pierre Supau" "LICENSE names the copyright holder"

for m in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
  if python3 -c "import json,sys; sys.exit(0 if json.load(open('$m')).get('license')=='MIT' else 1)" 2>/dev/null; then
    ok "$m declares \"license\": \"MIT\""
  else
    no "$m missing \"license\": \"MIT\""
  fi
done

exit $fails
