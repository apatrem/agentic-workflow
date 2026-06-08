# ADR 0008 — Exportable plugin + per-repo config; rollout ladder

**Status:** accepted

## Context
The strategy must be reusable across repos. Anything copy-pasted per repo drifts and you lose the
ability to fix the engine once for everyone.

## Decision
**Packaging:** ship as a **Claude Code plugin** (engine, versioned centrally) driven by a single
committed **`orchestrator.config.ts`** per repo. Engine = harness + role prompts + decision rule +
conventions + the four `/agentic-workflow:*` commands + a scaffolder. Per-repo = config + ADRs/CONTEXT +
tasks + the frozen tests. **Zero engine code copied per repo → no drift.** (Not a template repo, not
copied scripts, not a standalone CLI — those undermine central improvement or contradict ADR-0006.)

**Rollout ladder:** earn the right to touch `main`. **Narrow → Widen → Unattended.**
1. *Narrow:* auto-merge only the safest slice (`solo` · `risk: low` · additive/non-protected · tiny diff).
2. *Widen:* raise the diff budget, enable `competitive` auto-merge, open the non-protected path set.
3. *Unattended:* overnight queue; wake to merged low-risk PRs + a `needs-human` pile.

Non-negotiables: squash-merge + an `auto-merged` label for easy bulk rollback; **ratchet back and
tighten the gate if a bad change ever lands.**

> Note: the optional **Shadow** stage (auto-merge globally off while you validate the *judge*) was
> skipped by operator choice. Mitigation: keep Narrow extra-tight and hand-verify its first merged batch.

## Consequences
- One engine improves everywhere; repos stay independent and auditable.
- Trust in autonomy grows on evidence, not assumption.
