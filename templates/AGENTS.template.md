# AGENTS.md — <project>

## Overview
<what this repo is, in 2–3 sentences>

## Commands
- **Package manager:** pnpm via Corepack (`corepack enable`); install with `pnpm install --frozen-lockfile`. Commit `pnpm-lock.yaml` only — not `package-lock.json` / `yarn.lock`. (Default for Node repos — ADR-0009.)
- **Gate (one command):** `<pnpm run build && pnpm run lint && pnpm test && pnpm run validate>`  ← the bar; CI runs exactly this
- Install / dev / format: <…>

## Coding rules
- **Smallest correct change, via the ladder:** needed at all? → stdlib → platform feature → already-installed dep → one line → minimal code. No unrequested abstractions; no new dependencies without justification.
- **Minimalism has a floor** — never cut: input validation at trust boundaries, error handling that prevents data loss, security, accessibility. Reject invalid input; never auto-"fix" it — fail loudly.
- **Mark deliberate corners** with `// SHORTCUT(<ceiling>): <upgrade path>` — e.g. `// SHORTCUT(O(n²) scan): ok <1k rows; add an index if it grows`. The reviewer enforces this; `grep -rn 'SHORTCUT('` is the running ledger (ADR-0011).
- Preserve public APIs / contracts unless the task explicitly allows it.
- Add or update tests for behaviour changes.

## Forbidden / protected — route to a human
- <the gate, CI config, lockfiles/deps, migrations, auth, schema/contracts, brand, secrets>

## Workflow
- Work in your own worktree on `agent/<tool>/<task>`; **never commit to `main`** (protected — PR + green CI).
- Small PRs (< 300 lines routine; split/stack larger).
- **Effort/review tier** per task: `mode: low | medium | hard` (default `low`; prefer low, justify higher — ADR-0004). `medium`/`hard` add an independent cross-lineage dual review on the PR; `hard` also runs competitive best-of-N + a smart-merge first. (Which model runs each role/tier: `docs/MODELS.md`.)
- Ship via PR → review per tier (blockers only) → **a human merges** (smart-merge ≠ auto-merge; ADR-0003).

## Review checklist
- Correctness · security · test coverage · backward-compat. **Minimalism (advisory):** over-engineering delete-list; deliberate corners marked `SHORTCUT(…)` (ADR-0011).

## Lessons → guardrails
- Every recurring mistake becomes a test, a lint rule, or a line here — never just a mental note.
