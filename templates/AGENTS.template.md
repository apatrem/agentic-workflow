# AGENTS.md — <project>

## Overview
<what this repo is, in 2–3 sentences>

## Commands
- **Gate (one command):** `<build && lint && test && typecheck>`  ← the bar; CI runs exactly this
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
- Ship via PR → sparse review (blockers only) → **a human merges**.

## Review checklist
- Correctness · security · test coverage · backward-compat · unnecessary complexity.

## Lessons → guardrails
- Every recurring mistake becomes a test, a lint rule, or a line here — never just a mental note.
