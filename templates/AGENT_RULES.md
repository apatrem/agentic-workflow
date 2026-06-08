<!-- Paste this block into the target repo's CLAUDE.md and AGENTS.md. -->

# Multi-agent git rules

- Never push unless explicitly acting as the orchestrator's finalize step.
- Never merge or rebase `main`. Never force-push `main`.
- Worker agents work ONLY in their assigned worktree; never read or edit a sibling worktree.
- Worker agents commit their final changes locally; they do not push.
- Integration happens only on `integrate/<task-id>`, only by the orchestrator.
- `main` may move only after the frozen gate passes (in CI, on a PR).
- Never modify the frozen acceptance tests, the gate, CI config, or dependencies
  (see `protectedPaths`) — those route to a human by definition.
- Never extract or reuse another tool's auth token; the harness drives the
  official CLIs as subprocesses only.

# Branch & worktree convention

```
agent/<app>/<task-id>     # one per worker, ephemeral
integrate/<task-id>       # orchestrator's synthesis branch, ephemeral
```

Long-lived worktree *folders*, ephemeral per-task *branches*. Delete branches after integration.
