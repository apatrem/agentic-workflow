# ADR 0011 — Buy the orchestration engine (Composio); build only the conventions/policy

**Status:** accepted (amends 0006 — the substrate is Composio, not a bespoke Workflow harness)

## Context
The orchestration plumbing (worktrees, running agents, opening PRs) is commoditised and more mature off-the-shelf than anything we would maintain. Our differentiator is the *policy/conventions*, not a from-scratch runner. Constraint: subscription CLIs, no API keys.

## Decision
Use **Composio (`@aoagents/ao`)** as the engine — it drives the official Claude/Codex/Cursor CLIs on subscription auth, isolates worktrees, and opens PRs. This pack ships only the **conventions, planning (grill-me), task template, and ADRs**, and is renamed **`agentic-workflow`** (the old name `agent-orchestrator` collided with Composio's repo). The bespoke `run-task.workflow.js` harness and `orchestrator.config.ts` are removed.

## Consequences
- Composio is fleet-first; competitive best-of-N is **manual** (same task, agent overridden) — acceptable, since best-of-N is the ~10% case.
- Composio's `approved-and-green` is its own gate; our frozen-test / protected-path policy (0002/0004) is the layer we add only when graduating to the advanced auto-merge tier (0010).
- If Composio is ever dropped, the backbone (0009) and these conventions are unaffected.
