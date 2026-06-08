# Orchestration strategy (one page)

## Pipeline (per task, Phase 3)

```
align main ─▶ fan out (3 worktrees) ─▶ pre-screen ─▶ synthesize ─▶ GATE ─▶ review ─▶ DECIDE ─▶ PR
                 claude · codex · cursor   (Cursor)    (Opus)    frozen    (Codex)    (code)    │
                 each commits locally                            tests              blockers?   ├─ auto-merge (squash)
                 never push/merge                                                                └─ needs-human (labeled PR)
```

## Roles (best author + independent gate)

| Step | Who | Job |
| --- | --- | --- |
| Worker ×3 | Claude (cleanest), Codex (most test-driven), Cursor (smallest diff) | implement the same task independently in an isolated worktree; commit locally |
| Pre-screen | Cursor Composer (fast/cheap) | kill obviously-broken candidates before spending expensive steps |
| Synthesize | **Opus 4.8 (xhigh)** | build the best final implementation from the candidates (blind to author) |
| Review / gate | **Codex (high)** — *cross-lineage* | adversarial review of the synthesis; **blockers-only** veto |

The synthesizer is the strongest *author* (quality is created here); the reviewer is a strong, *different-lineage* skeptic (so it can actually refute the synthesizer, not rubber-stamp it).

## The auto-merge decision is **code**, never an LLM call

Auto-merge **iff all hold**, else open a `needs-human` PR:

1. **Frozen acceptance gate green** — the suite committed *before* agents ran; agents may add tests, never weaken frozen ones (orchestrator verifies byte-intact).
2. **Reviewer returns no blocker** — blockers = correctness / security / spec-violation / likely regression. Nits are follow-ups, not blockers.
3. **No protected path touched** — contracts + the gate itself (see config).
4. **Within diff budget** — runaway detector.
5. **`risk: low`** — `risk: high` tasks always route to human.

The LLM produces *structured findings*; plain code computes the merge boolean. The one dangerous action (moving `main`) sits behind logic the model can't talk past.

## Two dials

- **`risk: low | high`** — output gate (auto vs human).
- **`mode: solo | competitive`** — input effort. **Default `solo`** (one worker); Phase 2 promotes to `competitive` only for high-uncertainty / high-value tasks. Three workers + synth + review is ~5 agent-runs — reserve it.

## Failure & queue — *fail to human, never to main*

- Worker fails → proceed with whoever succeeded (≥1 candidate). Zero candidates → needs-human.
- Synthesis fails gate, or reviewer raises a blocker → **repair once**, then needs-human.
- CI is source of truth; one auto-rerun for flake.
- **Synthesizer (Opus) rate-limited** → pause the queue at a resumable checkpoint (every later task would fail too). **Worker rate-limited** → degrade and continue.
- Queue is **sequential** (each task starts from the new `main`); opt-in parallel only for declared-independent tasks. A human-flag doesn't halt the queue, but **downstream dependents of an unmerged task are skipped**.

## Merge target

Always a **PR**, never `git push HEAD:main`. CI re-runs the gate in the canonical environment; auto-merge via `gh` if the decision says go; otherwise the PR stays open, labeled `needs-human`, with the reviewer's notes in the body. The PR is both the merge vehicle and the human-handoff artifact.

## Rollout ladder

**Narrow → Widen → Unattended.** Start auto-merge on the safest slice only (`solo` · `risk: low` · additive/non-protected · tiny diff), hand-verify the first merged batch, then widen the budget + enable `competitive` auto-merge + open the path set, then run the unattended queue. Ratchet back and tighten the gate if a bad change ever lands. (We skipped the optional Shadow stage, so verify Narrow's first batch especially closely.)

## Workers run sandboxed

`codex exec --sandbox workspace-write`, no network, no `.env`/secrets, no push — safety *and* a runaway-token backstop.
