# ADR 0001 — Competitive best-of-N, not collaborative split

**Status:** accepted

## Context
With several capable, *heterogeneous* agents (Claude, Codex, Cursor), two orchestration
shapes exist: collaborative (split one task across agents, integrate all) or competitive
(all solve the same task, keep the best). Heterogeneity is only valuable when approaches
diverge — i.e. competitively. A real run (the "M1" milestone) confirmed the three produce
meaningfully different solutions: one won on rigor, another on API design, another on size.

## Decision
The default model is **competitive best-of-N**: N agents implement the same task in isolated
worktrees; the orchestrator selects/synthesizes one. Effort is a per-task dial (`mode`, ADR-0007),
not a global constant — `solo` for the bulk, `competitive` for high-uncertainty/high-value tasks.

## Consequences
- Diversity is leveraged; merge is "pick/synthesize one," with low cross-task conflict.
- Cost is ~N× per competitive task — hence the `mode` dial and quota governance (ADR-0007).
- Collaborative split is explicitly rejected as the default: three contracts with nothing to
  integrate them against, and it wastes the vendor diversity.
