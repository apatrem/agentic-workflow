---
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
- metadata: `risk` (low|high), `mode` (low|medium|hard), `depends-on`, `parallel-safe`.

Default `mode: low`; promote to `medium` or `hard` only when the task's risk/ambiguity/value warrants it — justify in the task (ADR-0004).
Add any new contract files to the forbidden/protected list in `AGENTS.md`.

Output: committed `tasks/*.md` + frozen (red) tests. The human reviews and approves before `/agentic-workflow:run`.
