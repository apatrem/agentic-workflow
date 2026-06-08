---
description: Phase 3 — run the competitive best-of-N loop for one task or the queue
argument-hint: "[tasks/<id>.md | --all]"
---

# /orchestrate:run

Phase 3 — the only phase that fans out and the only phase that touches `main`.

1. Load `orchestrator.config.ts` and the target task(s). With `--all`, order the queue by
   `depends-on` (sequential by default; batch only `parallel-safe` tasks with disjoint file sets).
2. Pre-flight: `main` worktree clean; required CLIs logged in; `gh` authenticated; the task's
   `depends-on` are all merged (else skip with a note).
3. For each task, invoke the harness `workflows/run-task.workflow.js` (via the Workflow tool),
   passing `args = { config, task }`. The harness runs: setup → workers → pre-screen → synthesize →
   gate → review → **decision (code)** → PR (auto-merge or `needs-human`).
4. Honor the failure/quota policy (ADR-0007): degrade on worker exhaustion, **pause the queue on
   synthesizer exhaustion**, repair-once before escalating, skip downstream dependents of unmerged tasks.
5. Report per task: outcome (`auto-merged` | `needs-human`), reasons, PR link. Never merge anything
   that didn't pass the code-computed decision.

Rollout: until you've widened past **Narrow**, keep `risk: low` + small diffs + additive paths, and
hand-verify the first auto-merged batch.
