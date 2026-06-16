#!/usr/bin/env bash
# Guard the governance claims that the docs PRs (#16/#17 + the codex-remediation) introduced — things the
# packaging/snapshot tests don't cover (codex review nit). Two mechanical invariants:
#   1. Exported/consumer-facing artifacts (templates/ + skills/) cite the baseline as AW-NNNN, never bare
#      ADR-NNNN — bare names are ambiguous once scaffolded/run inside a consuming repo (AW-0007 / AW-0002b).
#   2. The risk floor (AW-0004 refinement 3) is actually wired into the executable skills that act on it
#      (skills/plan assigns mode, skills/run spawns) — not just asserted in the ADRs.
# This repo's OWN decision record (docs/adr/*) is intentionally exempt from (1): there, bare ADR-NNNN means
# "this repo's NNNN" and is correct.
set -uo pipefail
cd "$(dirname "$0")/.."
source tests/lib.sh
echo "== namespace.test: AW- namespace in exported artifacts + risk-floor wired into skills =="

# 1. No bare ADR-NNNN in templates/ or skills/ (must be AW-NNNN). Report offenders with file:line.
offenders="$(grep -rnoE 'ADR-[0-9]{4}' templates/ skills/ 2>/dev/null)"
if [ -z "$offenders" ]; then
  ok "no bare ADR-NNNN in templates/ or skills/ (all baseline refs use AW-NNNN)"
else
  no "bare ADR-NNNN found in exported artifacts (use AW-NNNN):"
  echo "$offenders" | sed 's/^/      /'
fi

# 2. The risk floor is named in the skills that enforce it (not only in the ADRs/templates).
grep_q "skills/plan/SKILL.md" "risk floor"        "skills/plan applies the risk floor when assigning mode"
grep_q "skills/run/SKILL.md"  "risk floor"        "skills/run enforces the risk floor before spawning"
# and it cites the canonical source by AW number
grep_q "skills/plan/SKILL.md" "AW-0004"           "skills/plan cites AW-0004 for the floor"
grep_q "skills/run/SKILL.md"  "AW-0004"           "skills/run cites AW-0004 for the floor"

exit $fails
