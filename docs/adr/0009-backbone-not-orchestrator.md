# ADR 0009 — The backbone is AGENTS.md + tests/CI + git/PR, not the orchestrator

**Status:** accepted (reframes 0006/0008, which centred on a bespoke harness)

## Context
The orchestrator is an execution convenience, not the source of truth. Two reference reviews and common practice agree: *"Git, tests, and diffs should be the source of truth,"* and *"boring around the model, aggressive around verification."*

## Decision
The load-bearing spine of every repo is **`AGENTS.md`** (cross-tool context) + a **deterministic gate enforced by CI required checks on protected `main`** + **small PRs**. grill-me (planning), code-review-graph/codegraph (navigation), and the orchestrator (execution) are *tools that plug into* that spine — not the spine.

## Consequences
- Vendor/tool choices (Composio, which CLIs) become swappable; the backbone is stable.
- Graph tools are treated as navigation, **not proof**.
- "Composio + grill-me + code-review as the backbone" is explicitly rejected as the wrong centre of gravity.
