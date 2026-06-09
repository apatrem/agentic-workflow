---
description: Phase 3 — run a task via Superset (spawn workers in worktrees); a human merges
argument-hint: "[tasks/<id>.md]"
---

# /agentic-workflow:run

The engine is **Superset** (ADR-0002 Update) — a macOS app **and** a headless **CLI / SDK / MCP server**. Each
worker runs the chosen model in its own git worktree. **A human merges** by default (not an auto-merge harness).

> **Orchestrator interface — exact spawn calls live in the engine, not here.** Drive Superset via its **MCP
> server** (preferred — self-describing spawn tools) or the bundled **`superset` CLI** (`~/.superset/bin/superset`;
> add `~/.superset/bin` to `PATH`, or use a Superset terminal where it is already on `PATH`). The authoritative
> command/flag surface is `superset --help` / the MCP tool schemas; this repo records the *policy* (what to
> spawn, per tier), **not** the engine's API — external (ADR-0002 / 0007) and versioned. Commands below verified
> against **superset v0.2.19** — re-check on upgrade.

1. **Pre-flight:** `main` clean + protected; the agent CLIs (`claude` / `codex` / `cursor-agent`) logged in on
   your subscription; `gh` authed; the task's `depends-on` already merged. Register the repo once:
   `superset projects create --local --clone <url>` (returns a `prj_…` id).
2. **Spawn the worker(s)** per the task's **`mode`** (ADR-0004) — each gets its own worktree + the right model.
   Create-and-spawn in one call:
   ```
   # verified against superset v0.2.19 — confirm with `superset --help`
   superset workspaces create --local --project prj_… --name <task> \
     --branch agent/<lineage>/<task> --agent <lineage> --prompt "$(cat tasks/<id>.md)"
   # add --quiet for just the workspace id (scripting); --base-branch defaults to the project default
   ```
   - **`low`** *(default)* — one worker, lineage **cursor** (Cursor Composer) + the gate + one adversarial reviewer.
   - **`medium`** — one worker, then the dual review on the PR → `/agentic-workflow:review`.
   - **`hard`** — repeat the spawn **2–3×** on the **same** task, one per lineage (`--agent claude` / `codex` /
     `cursor`; bias each per `templates/ROLES.md`), then **smart-merge** the best into one diff (Opus 4.8), then
     the medium dual review (**hard ⊇ medium**).

   (GUI equivalent: `⌘N` new workspace → run the agent in its terminal.)
3. **Gate + inspect.** Run the gate in each worktree —
   `superset terminals create --workspace <ws> --command "<gate>"` — and review the diff (GUI `⌘L`, or open the
   worktree in your editor). For `hard`, compare attempts side-by-side and synthesize the smallest correct diff —
   reward the smallest passing diff, not cleverness.
4. Push the chosen branch; open a PR via `gh` → CI re-runs the gate. Once CI is green, review per tier
   (blockers only):
   - **`low`** — one **adversarial reviewer** (≤10 ranked findings): spawn via
     `superset agents create --workspace <ws> --agent claude --prompt "Review PR <pr> …"` (or review the diff
     yourself) and post as a PR comment; nits are advisory.
   - **`medium`** / post-**`hard`** smart-merge — run `/agentic-workflow:review` on the PR (dual
     cross-lineage review).
   Then **a human merges**. **smart-merge ≠ auto-merge**; autonomous auto-merge is the separate advanced
   tier (ADR-0003 / 0008).
5. **Lessons → guardrails:** turn any recurring mistake into a test / lint rule / AGENTS.md line.
