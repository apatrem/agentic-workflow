#!/usr/bin/env bash
# The gate for this repo: run every tests/*.test.sh; exit non-zero if any fail.
# Wire this into CI (T-003). Frozen tests are committed RED before implementation.
set -uo pipefail
cd "$(dirname "$0")/.."
rc=0
for t in tests/*.test.sh; do
  echo "### $t"
  bash "$t" || rc=1
done
[ $rc -eq 0 ] && echo "GATE: green" || echo "GATE: RED"
exit $rc
