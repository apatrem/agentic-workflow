---
description: Run the `medium` dual review on a PR — GPT-5.5 (xhigh) + Opus 4.8 (ultrathink), then synthesize
argument-hint: "[<pr-number-or-url>]"
---

# /agentic-workflow:review

The **medium**-tier review (ADR-0004): an independent, **cross-lineage dual review** of a PR. Two
reviewers of different lineage each post a PR comment; the orchestrator then synthesizes both into one
verdict. This is also the review that runs on a `hard` task's synthesized result (`hard` ⊇ `medium`).
Veto is **blockers-only**; nits are advisory. **This does not merge** — a human merges by default (ADR-0003).

> Reviewer models/effort are **pinned** so the review is reproducible. **Use `--agent` explicitly:** a
> plain `ao spawn` runs as the repo's `worker.agent` (often `cursor`), so the Claude reviewer **must**
> pass `--agent claude-code`, and the GPT reviewer **must** pass `--agent codex`.

1. **Pre-flight:** the PR's CI gate is **green** (don't pay tokens to review red code — WORKFLOW.md);
   `gh` authed; the CLIs (`claude` / `codex`) logged in; engine up (`ao start`). Note the PR number/URL.

2. **Reviewer A — GPT-5.5 @ xhigh (Codex lineage):**
   ```
   ao spawn --agent codex --task "Review PR <pr>. Read AGENTS.md + the task's acceptance criteria.
     Adversarial, blockers-only (correctness / security / spec-violation / regression); ≤10 ranked
     findings; nits clearly marked advisory. Post your review as a PR comment prefixed
     '### Review — GPT-5.5 (codex, xhigh)' via: gh pr comment <pr> --body-file <file>.
     Then run: ao report ready_for_review."
   ```
   Effort is pinned in `~/.codex/config.toml` → `model_reasoning_effort = "xhigh"` (Codex reads its
   effort from there, not a flag — confirm it before spawning).

3. **Reviewer B — Opus 4.8 @ extra-high (Claude lineage):**
   ```
   ao spawn --agent claude-code --task "ultrathink. Review PR <pr>. Read AGENTS.md + the task's
     acceptance criteria. Adversarial, blockers-only (correctness / security / spec-violation /
     regression); ≤10 ranked findings; nits clearly marked advisory. Post your review as a PR comment
     prefixed '### Review — Claude Opus 4.8 (claude-code, ultrathink)' via:
     gh pr comment <pr> --body-file <file>. Then run: ao report ready_for_review."
   ```
   The leading `ultrathink` is what pins Claude to extra-high reasoning. **`--agent claude-code` is
   mandatory** — without it the spawn runs as `worker.agent` (e.g. cursor), not Opus.

4. **Synthesize (orchestrator).** Once both `ready_for_review` reports are in and both PR comments are
   posted, read both and produce one **synthesis** comment prefixed `### Dual-review synthesis`:
   - **Agreements** — blockers both reviewers raised (highest priority).
   - **Disagreements** — raised by one only; adjudicate (keep if a real blocker, else mark advisory).
   - **Deduped, severity-ranked punch-list** — blockers first, then advisory nits.
   - **Verdict:** *blockers present → changes required* (the only veto), else *no blocker → advisory only*.

5. **Hand back to the human.** The synthesis informs the author and the human merger; **the human
   merges** (ADR-0003). Auto-merge is the separate advanced tier (ADR-0008) — not triggered here.

> For a `hard` task: run `/agentic-workflow:run` to do the competitive best-of-N + Opus smart-merge
> (synthesize N attempts → one diff), open the PR, **then run this command** on that PR.
