# Agent biases (for competitive / manual best-of-N)

Give each agent a slightly different bias so they don't converge on the same mistake. All implement the **same** task, each in its own worktree, commit locally, and never push/merge.

- **claude** — the cleanest, most readable implementation.
- **codex** — the most test-driven (red → green; cover each acceptance criterion).
- **cursor** — the smallest diff (fewest files/lines; no new abstractions).

Shared rules: smallest correct change; don't touch protected paths or the frozen tests (you may *add* tests); run the gate before finishing.

> Worker orchestration is handled by Composio (ADR-0002). This file is *guidance*, not harness wiring.
