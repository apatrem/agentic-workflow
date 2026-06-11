# MODELS.md — agent model picks (living table)

**Last reviewed: 2026-06-11.** Revisit **often** — whenever a vendor ships a new tier or the leaderboards below move. This file is the **single source for which model runs which role**; the *durable principle* behind it (role-keyed cost ladder; reviewers cross-lineage **and** independent of the implementer; "difficult" → `hard`; `hard ⊇ medium`) lives in **`docs/adr/0004-effort-solo-default.md`** and rarely changes.

> **To swap a model, edit THIS file only.** `commands/run.md`, `commands/review.md`, `templates/ROLES.md`, and `docs/WORKFLOW.md` point here instead of naming models, so the policy churns in one place.

**Quality/price check — revisit these when picking models:**
- https://cursor.com/cursorbench
- https://deepswe.datacurve.ai/

## Roles × tiers (as of 2026-06-11)

| tier | implementer(s) | reviewer(s) — cross-lineage, independent of the implementer | synthesis / smart-merge |
|------|----------------|-------------------------------------------------------------|-------------------------|
| **low** | Composer 2.5 fast *(cursor)* | **GPT-5.5 @ High** *(codex)* — single | — |
| **medium** | Composer 2.5 fast *(cursor)* | **GPT-5.5 @ xHigh** *(codex)* + **Opus 4.8 @ xHigh** *(claude)* | — |
| **hard** | best-of-N: Composer 2.5 fast *(cursor)* + GPT-5.5 @ xHigh *(codex)* + Opus 4.8 @ xHigh *(claude)* | **GPT-5.5 @ xHigh** *(codex)* + **Opus 4.8 @ xHigh** *(claude)* + **Fable 5 @ High** *(claude)* | **Opus 4.8 @ xHigh** |

**Orchestrator** (drives `/run`, `/review`, synthesis, smart-merge) = **Claude Opus 4.8 [1M] @ High** (xHigh for the smart-merge step).

### Why these (the trade-offs)
- **Implementer is the cost lever** (it writes all the code, on every task) → cheap-fast **Composer 2.5** by default; a premium author shows up only inside `hard`'s best-of-N. **"Difficult" promotes a task to `hard`** — there is no separate "stronger single implementer" knob (ADR-0004).
- **Orchestrator / reviewers / synthesizer are low-volume and quality-critical** → premium, **reproducible** models. We dropped **Fable as the default** for its rate-limit fragility (a Fable reviewer stalled a PR mid-review), not to save tokens; Opus 4.8 [1M] is the reliable Claude-lineage premium.
- **Every reviewer is cross-lineage AND independent of the implementer.** With three lineages (cursor / codex / claude), the reviewer(s) are the lineage(s) the implementer didn't use.

### `hard` review — the third lens and graceful degradation
`hard`'s review = the **medium dual (GPT + Opus) plus Fable** as a third lens, so `hard ⊇ medium` holds by construction. **If Fable stalls or rate-limits, `hard` degrades to exactly the medium dual (GPT + Opus)** — no special fallback path. At `hard`, Opus also runs the smart-merge, so its review doubles as merge-validation; **Fable is the fully-independent lens** (it neither implemented nor synthesized).

> **Caveat — "independent of the implementer" cannot hold absolutely at `hard`.** The principle is stated as absolute (and holds cleanly at `low`/`medium`, where one cursor implementer leaves both other lineages free), but `hard`'s best-of-N spans **all three** lineages — so no reviewer can be independent of *every* implementer. Concretely: **Fable** is the one clean lens (it was not in the best-of-N and did not synthesize); **GPT** and **Opus** review code their own lineage also authored, so at `hard` they are cross-lineage *relative to each other* but not implementer-independent. The claude lineage deliberately splits implementer (Opus) from independent reviewer (Fable) to recover one clean lens; GPT has no such split.

### Effort & pinning mechanics
- **Claude** (orchestrator/reviewer/implementer/synth): CLI flags `--model <id> --effort <low|medium|high|xhigh|max>`. IDs: Opus 4.8 = `claude-opus-4-8` (1M context: `claude-opus-4-8[1M]`); Fable 5 = `claude-fable-5`.
- **codex (GPT-5.5):** effort is read from `~/.codex/config.toml` → `model_reasoning_effort` (global, not a per-call flag). Note the per-tier split — **High** at `low`, **xHigh** at `medium`/`hard` — means setting that value for the run, or accepting one pinned effort.
- **Cursor (Composer 2.5):** "fast" tier via `cursor-agent`.

## Potential future additions
- **Cursor Bugbot** (https://cursor.com/docs/bugbot) — automated PR bug pre-screen. **Not adopted (2026-06-11):** usage-based billing only, and CLI support is not yet shipped (today it is GitHub-app / Cursor-agent only). **Revisit when Bugbot lands in the Cursor CLI** — then reconsider as a cheap pre-flight lens. It would be **Cursor-lineage** (shares the Composer implementer's blind spots), so it could only ever be an advisory pre-screen (ADR-0008), a non-blocking check — never one of the independent cross-lineage reviewers.
