# agent-orchestrator

A reusable Claude Code plugin for **competitive multi-agent orchestration**.

> Git is the shared memory. Worktrees are the isolation layer. The orchestrator is the integrator. **Frozen tests are the judge.**

For each task: fan it out to three heterogeneous agents (Claude / Codex / Cursor) working independently in isolated worktrees, synthesize the best result, gate it on a frozen acceptance test suite plus an independent cross-lineage review, and either **auto-merge to `main`** or **flag a human** — deterministically.

## Why it exists

Running three agents on the same task surfaces genuinely different solutions (one wins on rigor, another on API design, another on minimalism). Best-of-N + an independent gate gets you higher quality than any single agent, *and* lets `main` move autonomously when — and only when — the evidence supports it.

## The exportability contract

**The engine is repo-agnostic. Everything repo-specific lives in one committed config file.**

| Travels with the plugin (improve once, every repo benefits) | Lives in each repo (committed) |
| --- | --- |
| the Workflow harness (`workflows/run-task.workflow.js`) | `orchestrator.config.ts` (gate cmd, protected paths, budgets, agents) |
| the agent role prompts (`templates/ROLES.md`) | `docs/adr/*`, `CONTEXT.md` (your contracts) |
| the auto-merge decision rule (in the harness) | `tasks/*.md` (your work, with frozen tests + `risk` + `mode`) |
| branch/worktree conventions, git rules | the frozen acceptance tests themselves |

Nothing engine-level is copy-pasted per repo, so there is no drift.

## Install

```bash
# one-time: make this a plugin source
cd ~/Documents/agent-orchestrator && git init && git add -A && git commit -m "init"

# in Claude Code, add it as a plugin (local path or pushed remote)
/plugin marketplace add ~/Documents/agent-orchestrator
/plugin install agent-orchestrator
```

## Use it in a repo

```text
/orchestrate:init        # scaffold orchestrator.config.ts, tasks/, and the git-rules block
/orchestrate:architect   # Phase 1 — grill-me → docs/adr/* + CONTEXT.md  (human signs off)
/orchestrate:plan        # Phase 2 — emit tasks/*.md with frozen tests, risk, mode  (human signs off)
/orchestrate:run         # Phase 3 — competitive loop → PR → auto-merge or needs-human
```

## Three phases

1. **Architect** (single agent + human) — establish the contracts (ADRs, domain language). *Never fanned out.*
2. **Plan** (single agent + human) — decompose into tasks, each with a **frozen acceptance test**, a `risk` tier, and a `mode`. The human sign-off here is the primary control point.
3. **Run** (competitive, autonomous) — the only phase that fans out and the only phase that touches `main`.

See [`docs/STRATEGY.md`](docs/STRATEGY.md) for the one-page model and [`docs/adr/`](docs/adr/) for the decisions and their rationale.

## Requirements

- Claude Code (host for the Workflow harness).
- Official CLIs installed + logged in on your subscriptions: `claude`, `codex`, `cursor-agent`. The harness invokes the **official** CLIs as subprocesses; it never extracts or reuses their auth tokens.
- `gh` CLI authenticated, for the PR + merge steps.
- A repo whose acceptance can be expressed as a runnable gate (build / lint / test / typecheck).
