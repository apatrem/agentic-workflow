---
name: plan
description: Phase 2 — decompose into tasks with frozen tests, risk, and mode
---

# /agentic-workflow:plan

Single agent + human. Turn the ADRs/CONTEXT into runnable tasks. The human sign-off here is the
**primary control point** — nothing fans out until these are approved.

For each task, emit `tasks/<id>-<slug>.md` from `templates/task.template.md` with:
- a clear **Goal** (no implementation prescription),
- **Acceptance criteria mapped to frozen tests** — write the tests, commit them **red**, before any
  fan-out. If acceptance can't be a test, mark `risk: high` (never auto-merge eligible),
- **Do not change** (protected contracts this task must respect),
- metadata: `risk` (low|high), `mode` (low|medium|hard), `depends-on`, `parallel-safe` (yes|no).

**Flag parallelizable work explicitly.** For every task, set `parallel-safe` against the rest of the
plan: `yes` iff its file set is disjoint from the other pending tasks' and it shares no contract with
them (its `depends-on` still gates *when* it starts). `/agentic-workflow:run` fans out `parallel-safe`
tasks concurrently — an unset or timid flag serializes work for free; an over-eager one causes merge
conflicts. When two tasks collide only on one file, consider re-splitting so they don't.

Default `mode: low`; promote to `medium` or `hard` only when the task's risk/ambiguity/value warrants it — justify in the task (AW-0004).
**Apply the risk floor when assigning `mode`:** if a task's *Files likely involved* / acceptance touch destructive-or-protected surface that a human has scoped in (destructive fs ops like `rm -rf`/bulk in-place rewrites, the gate/CI, lockfiles/deps, migrations, auth, public APIs), set it to **≥ `medium`** regardless of the default and note *"escalated by risk floor"* (AW-0004 refinement 3). The route-to-human gate decides *whether* such a change happens; this floor decides *at what tier* once it's authorized.
Add any new contract files to the forbidden/protected list in `AGENTS.md`.

Output: committed `tasks/*.md` + frozen (red) tests. The human reviews and approves before `/agentic-workflow:run`.
