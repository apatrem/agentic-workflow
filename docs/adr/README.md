# Architecture Decision Records

The durable decision record for this plugin. Read top to bottom — each is self-contained.

> **These are the baseline — cite them `AW-NNNN` outside this repo** (e.g. `AW-0010` = remediation loop).
> Consuming repos adopt them **by reference, not by copy**: keep your own `docs/adr/` for domain decisions
> in your own number space, reference `AW-NNNN` where a baseline convention applies, and record
> `agentic-workflow-baseline: <pack version, e.g. v0.5.0>` (from `plugin.json` — a version, not an ADR
> ordinal, since baseline ADRs are amended in place) in your `AGENTS.md`. Never copy a baseline ADR file
> into a consuming repo (it drifts and burns your number space). Rationale: **AW-0007**.

| # | Decision |
|---|----------|
| [0001](0001-backbone.md) | The backbone is `AGENTS.md` + tests/CI + git/PR — not the orchestrator |
| [0002](0002-buy-engine-build-conventions.md) | Use an external engine (Composio → Superset, amended 2026-06); build only the conventions/policy |
| [0003](0003-human-merge-baseline.md) | Human-merge is the baseline; auto-merge is an earned, opt-in tier |
| [0004](0004-effort-solo-default.md) | Effort/review dial: three tiers (`low | medium | hard`), default `low`; prefer low, justify higher |
| [0005](0005-three-phases-human-signoff.md) | Three phases; humans gate planning; competition only in implementation |
| [0006](0006-fail-to-human-not-main.md) | Fail to human, never to `main`; sandboxed workers |
| [0007](0007-exportable-plugin.md) | Packaging: a plugin with a central engine; per-repo is decisions + config only |
| [0008](0008-advanced-auto-merge-tier.md) | Advanced tier (optional, **off by default**): the autonomous auto-merge engine |
| [0009](0009-package-manager-pnpm.md) | Package manager: pnpm via Corepack — default for new repos, optional for existing |
| [0010](0010-remediation-escalation-loop.md) | Post-review remediation & escalation loop: remediator = tier implementer; excess findings escalate a tier + re-review; cap 3 rounds → `needs-human` |
| [0011](0011-minimalism-lens-and-shortcut-markers.md) | Minimalism review lens + `SHORTCUT(…)` markers (imported from Ponytail's philosophy, not the plugin); advisory, reviewer-enforced, code-is-the-ledger |

**0001–0007 + 0009 + 0010 + 0011 are the baseline** every repo adopts. **0008 is the optional advanced tier** you graduate into per-repo (see 0003).
