# agentic-workflow

A reusable Claude Code plugin: the **conventions, planning, and decisions** for agentic coding — *not* an orchestration engine.

> Backbone: **`AGENTS.md` + a deterministic gate (CI) + git/PR isolation.**
> *LLMs propose. Tools verify. Git isolates. CI decides. Humans merge. Rules remember.*

The orchestration **engine** is an **external worktree manager** — currently **[Superset](https://github.com/superset-sh/superset)** (macOS app **plus** bundled CLI / SDK / MCP at `~/.superset/bin`). It's a *pluggable slot*: swap it for another manager (e.g. Claude Squad) in one line. **You drive the loop; a human merges.** This pack is the *operating manual + scaffolder* that sits on top. (See ADR-0002 for buy-the-engine / build-the-policy and the current pick.)

## What it gives you
- **`/agentic-workflow:init`** — scaffold the baseline conventions into any repo.
- **`/agentic-workflow:architect`** — Phase 1: grill-with-docs → ADRs + CONTEXT (grill-me when no domain model yet).
- **`/agentic-workflow:plan`** — Phase 2: tasks with acceptance tests, `risk`, `mode`.
- **`/agentic-workflow:run`** — Phase 3: drive Superset; human merges.
- **`/agentic-workflow:review`** — the `medium`-tier dual review on a PR (GPT-5.5 xhigh + Opus 4.8 ultrathink → synthesis).
- **`docs/adr/*`** — the decision record (the durable asset).
- **`docs/WORKFLOW.md`** — the one-page model.
- **`templates/`** — AGENTS.md, pre-commit, CLAUDE/.cursor, task template, agent biases.

## The exportability contract
**Engine = an external interactive manager (currently Superset). Policy/conventions = this plugin. Per-repo specifics = committed in the repo** (`AGENTS.md`, the gate, `tasks/`, ADRs). Nothing engine-level is copied per repo, so there is no drift — and the engine slot swaps without touching the conventions.

## Default posture
A per-task **effort/review dial — `mode: low | medium | hard`, default `low`** (prefer low, justify higher; ADR-0004). `low` = one implementer + deterministic gate + one adversarial reviewer. `medium` adds an independent dual review on every PR (GPT-5.5 xhigh + Opus 4.8 ultrathink, synthesized). `hard` adds competitive best-of-N + an Opus **smart-merge** (synthesize N attempts → one diff), then the medium dual review (**hard ⊇ medium**). **Humans merge** at every tier — **smart-merge ≠ auto-merge**; autonomous auto-merge is the separate, orthogonal opt-in tier you graduate into (ADR-0003/0008), not implied by `hard`.

## Requirements
Claude Code · the official CLIs logged in on your subs (`claude`, `codex`, `cursor-agent`) · `gh` · [Superset](https://github.com/superset-sh/superset/releases/latest) (macOS; CLI bundled in the app) for the engine.
