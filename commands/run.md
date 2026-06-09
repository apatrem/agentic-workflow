---
description: Phase 3 — run a task via Superset (interactive); a human merges
argument-hint: "[tasks/<id>.md]"
---

# /agentic-workflow:run

The engine is **Superset** — an interactive macOS manager that runs each agent in its own git worktree
(ADR-0002 Update). It is *not* an automated harness: **you drive the loop, a human merges.** This command
preps and hands off.

1. **Pre-flight:** `main` clean + protected; the CLIs (`claude` / `codex` / `cursor-agent`) logged in on your
   subscription; `gh` authed; the task's `depends-on` already merged.
2. **Engine up:** open Superset. Confirm it launches the official CLIs on your **subscription login** (never
   API keys / token extraction — ADR-0002 constraint + caveat).
3. **Create the session** from `tasks/<id>.md` — Superset opens a fresh worktree. Pick the agent and run per
   the task's **`mode`** (ADR-0004):
   - **`low`** *(default)* — one implementer (**Cursor Composer**) + the gate + one adversarial reviewer.
   - **`medium`** — one implementer + the gate, then the dual review on the PR → `/agentic-workflow:review`.
   - **`hard`** — open **2–3 parallel sessions** on the **same** task with the agent overridden per lineage
     (claude / codex / cursor; bias each per `templates/ROLES.md`), then **smart-merge** the best attempts
     into one diff (Opus 4.8), then the medium dual review on that result (**hard ⊇ medium**).
4. Let each agent implement in its worktree and **run the gate** in-session. Review diffs in Superset; for
   `hard`, compare the parallel attempts side-by-side and synthesize the smallest correct diff — reward the
   smallest passing diff, not cleverness.
5. Push the chosen branch; open a PR via `gh` → CI re-runs the gate → review per tier (blockers only) → **a
   human merges**. **smart-merge ≠ auto-merge**; autonomous auto-merge is the separate advanced tier
   (ADR-0003 / 0008) and is **not served by an interactive engine**.
6. **Lessons → guardrails:** turn any recurring mistake into a test / lint rule / AGENTS.md line.
