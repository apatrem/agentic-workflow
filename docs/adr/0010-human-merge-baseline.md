# ADR 0010 — Human-merge is the baseline; autonomous auto-merge is an earned, opt-in tier

**Status:** accepted (amends 0004, and the rollout in 0008)

## Context
AI review detects only ~**15–31%** of human-flagged issues (SWE-PRBench), and agent PRs can look clean while hiding redundancy/debt (GitHub guidance). Full auto-merge also adds machinery that conflicts with "keep it simple."

## Decision
Baseline for every repo: **protected `main` + required CI + PR + human merge.** The code-computed auto-merge engine (0004/0007) is **demoted to an ADVANCED tier**, switched on per-repo only after real CI required-checks and a Narrow→Widen rollout.

Effort default is **`mode: solo`** (one implementer + gate + one adversarial reviewer); competitive best-of-N is reserved for hard / ambiguous / risky tasks (~10%).

## Consequences
- The default is simpler and safer; nothing from the auto-merge design is discarded, only deferred.
- AI review is an assistant (blockers-only, sparse), never a merge authority.
