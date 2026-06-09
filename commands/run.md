---
description: Phase 3 — run a task via Superset (spawn workers in worktrees); a human merges
argument-hint: "[tasks/<id>.md]"
---

# /agentic-workflow:run

The engine is **Superset** (ADR-0002 Update) — a macOS app **and** a headless **CLI / SDK / MCP server**. Each
worker runs the chosen model in its own git worktree. **A human merges** by default (not an auto-merge harness).

> **Orchestrator interface — the exact spawn calls live in the engine, not here.** Drive Superset via its
> **MCP server** (preferred — an AI orchestrator gets self-describing spawn tools) or the `superset` CLI. The
> authoritative command/flag surface is `superset --help` / the MCP tool schemas; this repo records the
> *policy* (what to spawn, per tier), **not** the engine's API — it's external (ADR-0002 / 0007) and it
> changes. The commands below are **illustrative** (from docs.superset.sh, 2026-06 — verify against your
> installed version). Requires the CLI and/or MCP server set up; with only the desktop app, spawn in the GUI.

1. **Pre-flight:** `main` clean + protected; the CLIs (`claude` / `codex` / `cursor-agent`) logged in on your
   subscription; `gh` authed; the task's `depends-on` already merged.
2. **Spawn the worker(s)** per the task's **`mode`** (ADR-0004) — one worktree per worker, the right model per
   lineage:
   ```
   # illustrative — confirm exact commands via `superset --help` or the MCP tools
   superset workspaces create --project prj_… --name <task> --branch agent/<tool>/<task> --local
   superset agents create     --workspace ws_… --agent <model> --prompt "$(cat tasks/<id>.md)"
   ```
   - **`low`** *(default)* — one worker, lineage **cursor** (Cursor Composer) + the gate + one adversarial
     reviewer.
   - **`medium`** — one worker, then the dual review on the PR → `/agentic-workflow:review`.
   - **`hard`** — **2–3 workers on the same task, one per lineage** (claude / codex / cursor; bias each per
     `templates/ROLES.md`), then **smart-merge** the best into one diff (Opus 4.8), then the medium dual review
     (**hard ⊇ medium**).

   (GUI equivalent: `⌘N` new workspace → run the agent in its terminal.)
3. **Gate + review.** Run the gate in each worktree (illustratively
   `superset terminals create --workspace ws_… --command "<gate>"`, or in the worktree directly) and review the
   diff (GUI `⌘L`, or open the worktree in your editor). For `hard`, compare attempts side-by-side and
   synthesize the smallest correct diff — reward the smallest passing diff, not cleverness.
4. Push the chosen branch; open a PR via `gh` → CI re-runs the gate → review per tier (blockers only) → **a
   human merges**. **smart-merge ≠ auto-merge**; autonomous auto-merge is the separate advanced tier
   (ADR-0003 / 0008).
5. **Lessons → guardrails:** turn any recurring mistake into a test / lint rule / AGENTS.md line.
