---
description: Phase 3 — run a task via the Composio engine (ao); a human merges
argument-hint: "[tasks/<id>.md]"
---

# /agentic-workflow:run

The engine is **Composio (`ao`)**, not a bespoke harness (ADR-0011). This command preps and hands off.

1. **Pre-flight:** `main` clean + protected; the CLIs (`claude` / `codex` / `cursor-agent`) logged in; `gh` authed; the task's `depends-on` already merged.
2. **Engine up:** `ao start` (dashboard on :3000). Confirm `agent-orchestrator.yaml` — its `agent` and the gate in `agentRules` match this repo.
3. **Create the task** in the dashboard from `tasks/<id>.md`. Default **solo** (`mode: solo`). For a hard / ambiguous / risky task (`mode: competitive`), run the **same** task 2–3× with the agent overridden (claude / codex / cursor) — that is Composio's manual best-of-N; bias each per `templates/ROLES.md`.
4. Let each agent work in its worktree and run the gate. Compare diffs; pick the winner (or cherry-pick) — reward the smallest passing diff, not cleverness.
5. Open a PR → CI runs the gate → **sparse review** (blockers only) → **a human merges**. Autonomous auto-merge is the advanced tier (ADR-0010), not the default.
6. **Lessons → guardrails:** turn any recurring mistake into a test / lint rule / AGENTS.md line.
