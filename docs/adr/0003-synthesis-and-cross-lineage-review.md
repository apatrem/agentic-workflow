# ADR 0003 — Strongest author synthesizes; an independent cross-lineage agent reviews

**Status:** accepted

## Context
For best quality we allow the orchestrator to synthesize a final implementation (possibly novel),
not just pick a branch. But synthesized code is the *least*-corroborated code in the pipeline —
no second agent saw it — yet it is what ships. Tests are necessary, not sufficient. So a synthesis
step must be paired with an independent reviewer, and the pairing is load-bearing.

Two axes are often conflated: who *authors* (quality is created here) vs who *gates* (last line of
defense). A reviewer can only catch bugs it is capable of understanding; a cheap reviewer on
sophisticated novel code is a rubber stamp — the most dangerous state.

## Decision
- **Synthesizer = the strongest author: Opus 4.8 (xhigh)**, judging candidates blind to author.
- **Reviewer = a strong, *cross-lineage* skeptic: Codex (high)** — different lineage from the
  synthesizer, so it can actually refute rather than rubber-stamp. Same-lineage self-review is the
  weaker fallback only.
- **Pre-screen = Cursor Composer** (fast/cheap) — kills obvious breakage before the expensive steps.
- Reviewer veto is **blockers-only** (correctness/security/spec-violation/regression); nits are
  non-blocking follow-ups, or it would route everything to a human and kill latitude.

## Consequences
- Highest-quality path is available *and* gated. Cost is +1 review per synthesis.
- If the cross-lineage reviewer is unavailable (e.g. rate-limited), that task routes to a human.
