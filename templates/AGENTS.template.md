# AGENTS.md — <project>

<!-- agentic-workflow-baseline: <pack version this repo is pinned to, e.g. v0.3.7 — from the pack's plugin.json> -->
<!-- Baseline conventions are adopted BY REFERENCE: cite them `AW-NNNN` (AW-0007); this repo's own
     docs/adr/ is for domain decisions in its own number space. Never copy a baseline ADR file in.
     The stamp is a pack VERSION, not an ADR ordinal — baseline ADRs are amended in place, so only a
     version/commit pins which text you adopted. "Are we current?" = compare to the pack's plugin.json. -->

## Overview
<what this repo is, in 2–3 sentences>

## Commands
- **Package manager:** pnpm via Corepack (`corepack enable`); install with `pnpm install --frozen-lockfile`. Commit `pnpm-lock.yaml` only — not `package-lock.json` / `yarn.lock`. (Default for Node repos — AW-0009.)
- **Gate (one command):** `<pnpm run build && pnpm run lint && pnpm test && pnpm run validate>`  ← the bar; CI runs exactly this
- Install / dev / format: <…>

## Coding rules
- **Smallest correct change, via the ladder:** needed at all? → stdlib → platform feature → already-installed dep → one line → minimal code. No unrequested abstractions; no new dependencies without justification.
- **Minimalism has a floor** — never cut: input validation at trust boundaries, error handling that prevents data loss, security, accessibility. Reject invalid input; never auto-"fix" it — fail loudly.
- **Mark deliberate corners** with `// SHORTCUT(<ceiling>): <upgrade path>` — e.g. `// SHORTCUT(O(n²) scan): ok <1k rows; add an index if it grows`. The reviewer enforces this; `grep -rn 'SHORTCUT('` is the running ledger (AW-0011).
- Preserve public APIs / contracts unless the task explicitly allows it.
- Add or update tests for behaviour changes.

## Forbidden / protected — route to a human
- <the gate, CI config, lockfiles/deps, migrations, auth, schema/contracts, brand, secrets>
- A worker does **not** change these autonomously — stop and escalate to a human, who decides *whether* it happens. If a human scopes such a change into a task, the **risk floor** below sets *at what tier* it runs.

## Workflow
- Work in your own worktree on `agent/<tool>/<task>`; **never commit to `main`** (protected — PR + green CI).
- Small PRs (< 300 lines routine; split/stack larger).
- **Effort/review tier** per task: `mode: low | medium | hard` (default `low`; prefer low, justify higher — AW-0004). `medium`/`hard` add an independent cross-lineage dual review on the PR; `hard` also runs competitive best-of-N + a smart-merge first. (Which model runs each role/tier: `docs/MODELS.md`.)
- **`mode` is a floor, not a ceiling:** once a destructive-or-protected change *is* in a task's scope — destructive fs ops (`rm -rf`/bulk in-place rewrites) the task inherently performs, a *Forbidden / protected* item a human has explicitly scoped in, or a **governance / decision-record change** (this repo's `docs/adr/*`, `CONTEXT.md`, or `AGENTS.md` conventions — not routine prose) — that task runs at **≥ `medium`** regardless of the declared mode (AW-0004, refinement 3). The route-to-human gate above decides *whether*; this floor decides *at what tier*. They are sequential, not in conflict.
- Ship via PR → review per tier (blockers only) → **a human merges** (smart-merge ≠ auto-merge; AW-0003).

## Review checklist
- Correctness · security · test coverage · backward-compat. **Minimalism (advisory):** over-engineering delete-list; deliberate corners marked `SHORTCUT(…)` (AW-0011).

## Lessons → guardrails
- Every recurring mistake becomes a test, a lint rule, or a line here — never just a mental note.
