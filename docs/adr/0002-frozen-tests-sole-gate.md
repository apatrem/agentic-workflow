# ADR 0002 — Frozen acceptance tests are the sole auto-merge gate

**Status:** accepted

## Context
Auto-merge is only as safe as its judge. If the competing agents author the tests they are
judged by, the judge is captured — a weak agent ships weak tests that pass its own bug.

## Decision
Acceptance tests are authored in **Phase 2 and committed to `main` before any agent runs**.
They are **frozen**: agents may *add* tests but may not weaken or delete the frozen set; the
orchestrator verifies the frozen files are byte-intact before trusting a green result. The frozen
suite is the **only** thing that gates auto-merge; agent-added tests are informational signal.

**Corollary:** any task whose acceptance cannot be expressed as a runnable test is `risk: high`
and is **never** auto-merge eligible — it routes to a human by definition.

## Consequences
- Phase 2 is heavier (write real acceptance tests up front) — this is the price of autonomy.
- The judge is independent of the contestants, which is the precondition for everything downstream.
- "Looks right / opens cleanly" acceptance (e.g. a rendered document) is a human-review task.
