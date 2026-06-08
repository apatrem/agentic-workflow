# ADR 0006 — Deterministic Workflow harness, official-CLI workers, PR as merge-and-handoff

**Status:** accepted

## Context
Control flow (loop, branch/worktree management, gate, merge decision) must be deterministic and
resumable. Judgment (synthesize, review) is the LLM's job. Putting control flow *in* an LLM (a
single session doing git plumbing in a loop) is non-deterministic, expensive, and not resumable.

The operator uses monthly subscriptions, not API keys. Vendor terms permit driving the **official
CLIs** headlessly under subscription (rate-limited); they prohibit extracting OAuth tokens into a
custom client. So workers are the official CLIs invoked as subprocesses.

## Decision
- **Substrate = the Claude Code Workflow mechanism**: deterministic JS control flow + `agent()`
  judgment steps, with resume, observability, structured outputs, and token budgets. (Bash scripts
  are the portable fallback if the loop must ever run outside Claude Code.)
- **Workers = official CLIs** (`claude -p`, `codex exec --sandbox workspace-write`, `cursor-agent`),
  each in its own worktree; never token extraction.
- **Merge target = a PR**, never `git push HEAD:main`. CI re-runs the gate in the canonical
  environment; auto-merge via `gh` only if the decision (ADR-0004) says go; otherwise the PR stays
  open, labeled `needs-human`, with reviewer notes. **The PR is both merge vehicle and human handoff.**
- **Branches ephemeral, worktree folders long-lived:** `agent/<app>/<task>`, `integrate/<task>`, deleted after.

## Consequences
- Resumable, observable, auditable; canonical-env gating (no laptop drift).
- Binding constraint becomes subscription rate limits → quota governance (ADR-0007).
- Cursor CLI is beta = the flakiest link; the harness degrades gracefully if a worker errors.
