# Task <id> — <short title>

<!-- Phase 2 emits one of these per task; a human signs off before any run. -->

## Goal
<One paragraph. What and why. No implementation prescription — that's the point of fanning out.>

## Acceptance criteria (FROZEN TESTS)
<!-- These MUST map to a runnable, committed test. If acceptance cannot be expressed
     as a test, the task is `risk: high` and is NOT auto-merge eligible. -->
- [ ] <criterion> → covered by `tests/<file>::<name>` (committed red before fan-out)
- [ ] <criterion> → covered by `tests/<file>::<name>`
- [ ] Existing gate stays green.

## Do not change
- <protected contract / file / API this task must not touch>

## Metadata
- `risk: low`            # low → auto-merge eligible; high → always human
- `mode: solo`           # solo (1 worker, default) | competitive (3 workers + synth + review)
- `depends-on: []`       # task ids that must be merged first (dependents skipped if a dep is unmerged)
- `parallel-safe: false` # true only if file set is disjoint from sibling tasks in the batch
