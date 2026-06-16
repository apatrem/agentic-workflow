<!-- Optional block — paste into the target repo's CLAUDE.md and AGENTS.md. Superset + PR model (AW-0002 Update). -->

# Multi-agent git rules

- Never merge or rebase `main`. Never force-push `main`.
- Worker agents work ONLY in their assigned worktree; never read or edit a sibling worktree.
- Worker agents commit locally; they do not push unless the operator explicitly asks (Phase 3 finalize).
- Ship via PR only — `main` moves only after the frozen gate passes in CI on that PR.
- Never modify the frozen acceptance tests, the gate, CI config, or dependencies
  (see forbidden/protected in AGENTS.md) — those route to a human by definition.
- Never extract or reuse another tool's auth token; the engine drives the official CLIs as subprocesses only.

# Branch & worktree convention

```
agent/<lineage>/<task-id>   # one per worker, ephemeral (Superset workspace branch)
```

Long-lived worktree *folders*, ephemeral per-task *branches*. Delete branches after merge.
