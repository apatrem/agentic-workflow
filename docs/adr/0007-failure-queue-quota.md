# ADR 0007 — Failure, queue, and quota semantics

**Status:** accepted

## Context
An unattended loop is undefined without explicit behavior for errors, exhaustion, and ordering.
Governing principle: **fail to human, never to main.** The worst outcome of a bad night is a review
pile, never a broken `main`.

## Decision
**Failure**
- Worker errors / no diff → proceed with whoever succeeded (≥1 candidate). Zero → `needs-human`.
- Synthesis fails the gate, or reviewer raises a blocker → **repair once** (feed the failure back),
  then `needs-human`.
- CI is source of truth; one auto-rerun for flake.

**Quota (subscriptions are rate-limited)**
- Per-task **`mode: solo | competitive`**, default **`solo`**; Phase 2 promotes to `competitive`.
- **Worker** rate-limited → degrade and continue. **Reviewer** rate-limited → that task `needs-human`.
  **Synthesizer (Opus)** rate-limited → **pause the queue at a resumable checkpoint** (every later
  task would fail identically) and notify.
- Near the daily token budget, auto-downgrade remaining `competitive` tasks to `solo`.

**Queue**
- **Sequential** by default (each task starts from the new `main`). Opt-in parallel only for
  `parallel-safe` tasks with disjoint file sets.
- A human-flag does **not** halt the queue, but **downstream dependents of an unmerged task are skipped**.

**Sandbox:** workers run with no network, no secrets, no push — safety and a runaway-token backstop.

## Consequences
- The loop self-propels overnight and degrades into open PRs, not failures.
- Quota is a first-class, governed resource.
