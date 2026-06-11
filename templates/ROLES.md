# Agent biases (for `hard` competitive best-of-N)

Give each agent a slightly different bias so they don't converge on the same mistake. Both implement the **same** task, each in its own worktree, commit locally, and never push/merge.

> **Solo default:** the routine ~90% path (`mode: low`) runs one implementer — the **Cursor Composer** agent by default, the agent you select for the session in Superset (ADR-0002 Update, ADR-0004). The biases below apply only to **`hard`** competitive best-of-N, where you override the agent per lineage.

`hard` runs best-of-N over **two authoring lineages** — **codex** and **cursor** — each with a distinct bias:

- **codex** — the most test-driven (red → green; cover each acceptance criterion).
- **cursor** — the smallest diff (fewest files/lines; no new abstractions).

> **claude does *not* author at `hard`.** It is **held out of authoring and synthesis** so it can be the *structurally-clean* independent reviewer (Opus) — the ADR-0004 independence invariant. The smart-merge is run by **codex**, not claude. (Lineage→model assignment lives in **`docs/MODELS.md`**; this file is *bias* guidance only, not model pins.)

Shared rules: smallest correct change; don't touch protected paths or the frozen tests (you may *add* tests); run the gate before finishing.

> Worker orchestration is handled by Superset (ADR-0002 Update). This file is *guidance*, not harness wiring.
