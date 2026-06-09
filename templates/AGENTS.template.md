# AGENTS.md — <project>

## Overview
<what this repo is, in 2–3 sentences>

## Commands
- **Package manager:** pnpm via Corepack (`corepack enable`); install with `pnpm install --frozen-lockfile`. Commit `pnpm-lock.yaml` only — not `package-lock.json` / `yarn.lock`. (Node repos.)
- **Gate (one command):** `<pnpm run build && pnpm run lint && pnpm test && pnpm run validate>`  ← the bar; CI runs exactly this
- Install / dev / format: <…>

## Coding rules
- Smallest correct change. No new dependencies without justification.
- Preserve public APIs / contracts unless the task explicitly allows it.
- Add or update tests for behaviour changes. Reject invalid input; never auto-"fix" it.

## Forbidden / protected — route to a human
- <the gate, CI config, lockfiles/deps, migrations, auth, schema/contracts, brand, secrets>

## Workflow
- Work in your own worktree on `agent/<tool>/<task>`; **never commit to `main`** (protected — PR + green CI).
- Small PRs (< 300 lines routine; split/stack larger).
- **Effort/review tier** per task: `mode: low | medium | hard` (default `low`; prefer low, justify higher — ADR-0004). `medium`/`hard` add an independent dual review on the PR; `hard` also runs competitive best-of-N + an Opus smart-merge first.
- Ship via PR → review per tier (blockers only) → **a human merges** (smart-merge ≠ auto-merge; ADR-0003).

## Review checklist
- Correctness · security · test coverage · backward-compat · unnecessary complexity.

## Lessons → guardrails
- Every recurring mistake becomes a test, a lint rule, or a line here — never just a mental note.
