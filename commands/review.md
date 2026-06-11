---
description: Run the `medium` dual review on a PR — two cross-lineage reviewers (current models in docs/MODELS.md), then synthesize
argument-hint: "[<pr-number-or-url>]"
---

# /agentic-workflow:review

The **medium**-tier review (ADR-0004): an independent, **cross-lineage dual review** of a PR. Two
reviewers of different lineage each post a PR comment; the orchestrator then synthesizes both into one
verdict. This is also the review that runs on a `hard` task's synthesized result (`hard` ⊇ `medium`).
Veto is **blockers-only**; nits are advisory. **This does not merge** — a human merges by default (ADR-0003).

> Reviewer models/effort are **pinned** so the review is reproducible — **current picks live in
> `docs/MODELS.md`** (single source; this command names today's defaults inline but `MODELS.md` wins).
> Run each reviewer as its **own lineage** — open a review session in Superset (or run the CLI directly) with
> **Codex** for Reviewer A and **Claude** for Reviewer B; don't let either run as the session's default agent
> (e.g. cursor). Each reviewer must also be **independent of the implementer's lineage**.

1. **Pre-flight:** the PR's CI gate is **green** (don't pay tokens to review red code — WORKFLOW.md);
   `gh` authed; the CLIs (`claude` / `codex`) logged in on subscription. Note the PR number/URL.

2. **Reviewer A — GPT-5.5 @ xhigh (Codex lineage).** Spawn it —
   `superset agents create --workspace ws_… --agent codex --prompt` (or run `codex` directly) — with:
   ```
   Review PR <pr>. Read AGENTS.md + the task's acceptance criteria. Adversarial, blockers-only
   (correctness / security / spec-violation / regression); ≤10 ranked findings; nits clearly marked
   advisory. Post your review as a PR comment prefixed '### Review — GPT-5.5 (codex, xhigh)' via:
   gh pr comment <pr> --body-file <file>.
   ```
   Effort is pinned in `~/.codex/config.toml` → `model_reasoning_effort = "xhigh"` (Codex reads its effort
   from there, not a flag — confirm it before running).

3. **Reviewer B — Claude Opus 4.8 @ effort `xhigh` (Claude lineage)** *(today's pick — see `docs/MODELS.md`)*. Spawn it —
   `superset agents create --workspace ws_… --agent claude --prompt` (or run
   `claude --model claude-opus-4-8 --effort xhigh` directly) — with:
   ```
   Review PR <pr>. Read AGENTS.md + the task's acceptance criteria. Adversarial, blockers-only
   (correctness / security / spec-violation / regression); ≤10 ranked findings; nits clearly marked
   advisory. Post your review as a PR comment prefixed
   '### Review — Claude Opus 4.8 (claude-code, xhigh)' via: gh pr comment <pr> --body-file <file>.
   ```
   Model/effort are pinned by **CLI flags** — `--model claude-opus-4-8 --effort xhigh` (valid efforts:
   `low|medium|high|xhigh|max`; verify with `claude --help`). A Superset preset is one stored command — if
   yours can't carry these flags for this role, run the CLI directly.

   > **On `hard` tasks (`hard ⊇ medium`):** add a **third** independent lens after the GPT + Opus pair —
   > **Fable 5 @ high** (`--model claude-fable-5 --effort high`), prefix `### Review — Claude Fable 5 (claude-code, effort high)`.
   > If Fable stalls/rate-limits, `hard` degrades to exactly this GPT + Opus dual — no separate fallback. (`docs/MODELS.md`.)

4. **Synthesize (orchestrator).** Once both PR comments are posted, read both and produce one **synthesis**
   comment prefixed `### Dual-review synthesis`:
   - **Agreements** — blockers both reviewers raised (highest priority).
   - **Disagreements** — raised by one only; adjudicate (keep if a real blocker, else mark advisory).
   - **Deduped, severity-ranked punch-list** — blockers first, then advisory nits.
   - **Verdict:** *blockers present → changes required* (the only veto), else *no blocker → advisory only*.

5. **Hand back to the human.** The synthesis informs the author and the human merger; **the human merges**
   (ADR-0003). Auto-merge is the separate advanced tier (ADR-0008) — not triggered here.

> For a `hard` task: run `/agentic-workflow:run` to do the competitive best-of-N + smart-merge (synthesizer
> in `docs/MODELS.md`), open the PR, **then run this command** on that PR (and add the third `hard` lens above).
