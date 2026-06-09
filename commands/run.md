---
description: Phase 3 — run a task via Superset (spawn workers in worktrees); a human merges
argument-hint: "[tasks/<id>.md]"
---

# /agentic-workflow:run

The engine is **Superset** (ADR-0002 Update) — a macOS app **and** a headless **CLI / SDK / MCP server**.
Each worker runs the chosen model in its own git worktree. Spawn **programmatically** (orchestrated, below) or
interactively in the GUI. It is not an auto-merge harness: **a human merges** by default.

1. **Pre-flight:** `main` clean + protected; the CLIs (`claude` / `codex` / `cursor-agent`) logged in on your
   subscription; `gh` authed; the task's `depends-on` already merged. Register the repo once:
   `superset projects create --name <repo> --local --clone <url>`.
2. **Spawn the worker(s)** per the task's **`mode`** (ADR-0004) — create a worktree, then spawn the agent with
   the right model:
   ```
   superset workspaces create --project prj_… --name <task> --branch agent/<tool>/<task> --local
   superset agents create --workspace ws_… --agent <model> --prompt "$(cat tasks/<id>.md)"
   ```
   - **`low`** *(default)* — one worker: `--agent cursor` (Cursor Composer) + the gate + one adversarial
     reviewer.
   - **`medium`** — one worker, then the dual review on the PR → `/agentic-workflow:review`.
   - **`hard`** — spawn **2–3 workspaces** on the **same** task, one per lineage (`--agent claude` / `codex` /
     `cursor`; bias each per `templates/ROLES.md`), then **smart-merge** the best into one diff (Opus 4.8),
     then the medium dual review (**hard ⊇ medium**).

   (Or do it in the GUI: `⌘N` new workspace → run the agent in its terminal.)
3. **Gate + review.** Run the gate in each worktree —
   `superset terminals create --workspace ws_… --command "<gate>"` — and review the diff (GUI `⌘L`, or open
   the worktree in your editor). For `hard`, compare attempts side-by-side and synthesize the smallest correct
   diff — reward the smallest passing diff, not cleverness.
4. Push the chosen branch; open a PR via `gh` → CI re-runs the gate → review per tier (blockers only) → **a
   human merges**. **smart-merge ≠ auto-merge**; autonomous auto-merge is the separate advanced tier
   (ADR-0003 / 0008).
5. **Lessons → guardrails:** turn any recurring mistake into a test / lint rule / AGENTS.md line.
