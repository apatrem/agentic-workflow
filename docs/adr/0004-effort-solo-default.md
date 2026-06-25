# ADR 0004 — Effort/review dial: three tiers (`mode: low | medium | hard`), default `low`

**Status:** accepted — supersedes the original two-point dial (`mode: solo | competitive`)

> **Update (2026-06-15) — the declared `mode` is a *floor*, and risk can raise it.** The author's
> `mode` sets a minimum, not a ceiling: once a **destructive-or-protected change is in a task's scope**, that
> task runs at **≥ `medium`** regardless of what the frontmatter declares.
>
> **This does not contradict `AGENTS.md`'s "Forbidden / protected — route to a human."** The two are
> *sequential*, governing different questions: the route-to-human gate decides **whether** a protected change
> happens at all (a worker never does it autonomously — a human authorizes it); this floor decides **at what
> tier** it runs *once authorized*. A worker is never told both "stop" and "proceed" — it stops; if a human
> scopes the change in, the resulting task is ≥ `medium`. The floor's own trigger is **destructive work a task
> legitimately performs**, which is *not* limited to the route-to-human list — most often it's a destructive
> filesystem op in a perfectly in-scope task (the `rm -rf` installer below):
> - **destructive filesystem ops** — `rm -rf`, bulk in-place rewrites, symlink/dir replacement *(the common
>   case — usually in-scope, not routed to a human)*
> - a **protected** item (gate/CI, lockfiles or a dependency *added/removed/version-changed* — not a metadata
>   touch, migrations/schema/data-shape, auth/secrets, public API/contract) **that a human has scoped into the
>   task** *(having passed the route-to-human gate, it still can't run `low`)*
> - **governance / decision-record surface** — the **decision record and conventions themselves**: `docs/adr/*`,
>   `CONTEXT.md`, the `AGENTS.md` conventions, and (for this pack) its own `skills/`/`templates/`. This includes
>   **`docs/MODELS.md`'s role→model/tier *assignments*** — a model swap changes how *every* task runs, so the
>   assignment change is governance; the table is otherwise designed to churn, so routine maintenance (benchmark
>   links, the *Last reviewed* date, leaderboard prose) stays `low`. *Why:* these
>   are high-blast-radius — they change how *every* task is run — and have repeatedly shipped **incoherent when
>   authored solo and merged fast** (this session alone, three cross-lineage review rounds caught real
>   contradictions in solo-authored amendments that green tests missed). A cross-lineage review *before* merge
>   is the cheapest guard. Governance edits are usually made **directly** (no `tasks/*.md`, so no `mode` field) —
>   "`medium`" here means *ship via PR with the cross-lineage dual review before a human merges*. **Boundary:**
>   only the decision record / conventions count — routine prose (typos, examples, comments, a feature README)
>   is **not** governance and stays `low`.
>
> The planner/orchestrator checks the task's *files-likely-involved* + acceptance against this at plan and at
> run-start; on intersection it **bumps the tier** (low→medium; medium→hard if the change is also large or
> ambiguous) and records *"escalated by risk floor"* in the task and PR. **Why:** a real run authored an
> installer at `low` that did `rm -rf` (T-002); the single low reviewer happened to catch the data-loss bug,
> but the tier was mislabeled — destructive surface is medium-risk *by nature*, and the right tier shouldn't
> depend on the author noticing. This makes the escalation **structural**, not a matter of judgement, and it
> composes with the post-review remediation/escalation loop (AW-0010), which escalates *after* findings; this
> escalates *before*, on surface. See refinement 3 below.

> **Update (2026-06-11) — model picks moved to a living table; Fable-first retired.** Supersedes the
> 2026-06-10 Fable-first update below. The *specific model→role→tier picks* now live in **`docs/MODELS.md`**
> (a dated table, revisited often against cursor.com/cursorbench + deepswe.datacurve.ai). This ADR keeps only
> the durable **principle**:
> - **Role-keyed cost ladder.** The **implementer** is the cost lever (cheap-fast by default; a premium
>   author appears only inside `hard`'s best-of-N). Orchestrator, reviewers, and synthesizer are low-volume
>   and quality-critical → premium, **reproducible** models. **Fable is no longer the default** — dropped for
>   rate-limit fragility (a Fable reviewer stalled a PR mid-review), not to save tokens.
>   *The deeper "why": judgment work — grilling, planning, review, synthesis — is **parametric-knowledge**
>   (it leans on the model's trained priors and creative challenge) → premium; implementation is
>   **contextual-knowledge** (the spec is already rich) → cheap. (External corroboration: Pocock's
>   grill-me/grill-with-docs analysis, aihero.dev — which independently arrives at "frontier model for
>   grilling, cheaper model for implementation.") The Phase-1 grilling/architect model row is in `docs/MODELS.md`.*
> - **Reviewers are cross-lineage *and* independent of the implementer** (not just reviewer-vs-reviewer). With
>   three lineages, the reviewer(s) are the lineage(s) the implementer didn't use.
> - **`hard` guarantees ≥1 structurally-clean lens** *(added 2026-06-11; see below)* — at least one
>   reviewer whose **lineage neither authored nor synthesized**. Because a 3-lineage best-of-N would leave
>   no clean lineage, **`hard` caps best-of-N at two lineages and reserves the third entirely for review**.
>   This holds *by construction* and survives the loss of any optional extra lens — unlike a guarantee that
>   leans on one specific model staying available. The cost is one fewer competing author. Concrete lineage
>   assignment + why the synthesizer can't be the clean lineage: **`docs/MODELS.md`**.
> - **"Difficult" promotes to `hard`** — no separate "stronger single implementer" knob; a task worth a
>   premium author is worth the `hard` best-of-N.
> - **`hard ⊇ medium` preserved** — `hard`'s review is still a cross-lineage dual (at least the medium
>   scrutiny), now with the guarantee that one lens is structurally clean; an optional extra lens may be
>   added and may degrade away without breaking the guarantee.
> Concrete current models are in **`docs/MODELS.md`**; the prose below points there rather than naming models.

> **Update (2026-06-10 — SUPERSEDED by the 2026-06-11 update above) — Claude-lineage model policy: Fable-first, pinned by CLI flags.** All
> Claude-lineage roles now run **Claude Fable 5**, pinned per spawn via
> `claude --model claude-fable-5 --effort <level>` (the `ultrathink` prompt-prefix trick is retired —
> effort is a first-class CLI flag, valid values `low|medium|high|xhigh|max`). Effort scales with the
> role's stakes: `low`-tier adversarial reviewer @ **medium**; `medium`-tier dual-review Reviewer B and
> `hard`'s claude implementer @ **high**; the `hard` smart-merge synthesizer @ **xhigh**. **Fallback:**
> if Fable is unavailable/rate-limited, use the **latest Opus (≥4.8) at `high`–`xhigh`** and record the
> actual model in the review comment. The decision text below is updated in place to match.

## Context
With several capable, *heterogeneous* agents (Claude, Codex, Cursor), two orchestration shapes
exist: collaborative (split one task across agents, integrate) or competitive (all solve the same
task, keep the best). Heterogeneity only pays when approaches diverge — i.e. competitively; a real
run confirmed the three produce meaningfully different solutions (one won on rigor, another on API
design, another on size). But running N agents on *every* task costs ~N× and is wasted on routine work.

**External evidence for the design (directional, not load-bearing).** Merouani et al., *Agentic
Auto-Scheduling: An Experimental Study of LLM-Guided Loop Optimization* (COMPILOT, PACT 2025;
[arXiv:2511.00592](https://arxiv.org/abs/2511.00592)) ran off-the-shelf LLMs in a closed loop with a compiler
and independently lands on three things this ADR (and AW-0001/0010) already bet on:
- **best-of-N beats single-run** — geomean speedup **3.54× at best-of-5 vs 2.66× single-run** — the empirical
  shape of `hard`'s competitive best-of-N: independent attempts diverge, and keeping the best wins.
- **model choice materially affects outcomes** — across **eight** models the top performers were close,
  **reasoning- and coding-specialized models did *not* consistently win**, and per-model failure distributions
  differed widely (runnable-proposal rates spanned ~15%–40%). The paper studies *which single model* you pick,
  not *mixing* models — so this is direct evidence that the model matters, and only an **analogy** (ours, not
  the paper's) for why we run reviewers **cross-lineage**: the paper never tested mixed- vs same-lineage
  best-of-N or anything about review.
- **the verifier carries the loop** — for the primary model (gemini-2.0-flash) only **~36% of proposals were
  runnable** (~31% invalid, ~33% illegal; other models ranged lower, e.g. codestral ~15% runnable). The loop
  worked *because a deterministic two-stage check caught the rest* — a compiler-independent **response parser**
  rejects invalid proposals, the **compiler's legality check** rejects illegal ones. The model proposes; the
  tooling decides — exactly *"LLMs propose, tools verify"* (AW-0001) and why review is blockers-gated on a
  green gate, never a substitute for it. (Their RQ10 also found an **analyze-before-acting** step measurably
  helped — our plan-/grill-before-code, AW-0005.)

**Caveat — read the *direction*, not the magnitudes.** It's a different domain (compiler loop scheduling, not
software change authoring) and the study used **2024–early-2025 models** (gemini-2.0-flash, gemma3, gpt-4o,
llama3.3, o3-mini, qwq, qwen2.5-coder, codestral-2501 — several released early 2025). The absolute numbers are
already stale relative to 2026 and don't transfer; the **qualitative findings** — best-of-N > single,
model-choice-matters, verifier-carries-the-loop — are what corroborate the design. The cross-lineage-reviewer
link is our inference, not a result the paper reports.

The original dial had two points (`solo | competitive`). In practice there is a useful middle: keep a
single implementer, but spend extra **review** assurance on a change that is risky but not worth a
full competitive author-off. So the dial really moves **two axes at once** — *authoring depth* (how
many lineages implement) and *review rigor* (how hard the result is scrutinised) — and we bundle both
into one named tier so a task author turns a single knob.

## Decision
Effort is a **per-task dial, `mode: low | medium | hard`, default `low`**, set in the task
frontmatter (`tasks/*.md`), defaulting to `low`. It is a cost↔assurance
ladder; the rule is **prefer `low`, justify higher** — promote a task only when its risk/ambiguity/value
warrants the extra spend, and say why in the task.

The two axes bundled into the one dial:

| `mode` | Authoring depth | Review rigor |
|--------|-----------------|--------------|
| **low** *(default)* | 1 implementer | deterministic gate + **1 adversarial reviewer** |
| **medium** | 1 implementer | deterministic gate + an independent **dual review** on every PR |
| **hard** | **competitive best-of-N** over **2 lineages** → **smart-merge** into one diff | the **medium** cross-lineage dual review, run on the synthesized result, with **≥1 structurally-clean lens** |

The declared `mode` is a **floor**: a destructive-or-protected change *in a task's scope* forces **≥ medium** regardless — sequential with, not contradicting, the route-to-human gate (refinement 3 + the 2026-06-15 Update).

- **low (default)** — today's baseline: one implementer + the deterministic gate + one adversarial
  reviewer. The routine ~90% path.
- **medium** — one implementer + gate, then a **dual review on every PR**: two independent reviewers of
  **different lineage**, each independent of the implementer, each post a PR comment (current models in
  **`docs/MODELS.md`**).

  The orchestrator then **synthesizes both** into one verdict: agreements, disagreements, and a
  deduped, severity-ranked punch-list. **Veto is blockers-only** (correctness / security /
  spec-violation / regression); nits are advisory follow-ups. Mechanics live in `skills/review/SKILL.md`.
- **hard** — competitive best-of-N over **two lineages**: agents implement the **same** task in isolated
  worktrees, then a **smart-merge** synthesizer grafts the best of the attempts into one diff — and **then
  the cross-lineage dual review runs on that synthesized result**, with the guarantee that **one lens is
  structurally clean** (its lineage neither authored nor synthesized). The third lineage is held out of
  authoring/synthesis precisely to *be* that clean lens; the synthesizer therefore runs on an authoring
  lineage, not the clean one (current assignment + rationale in **`docs/MODELS.md`**; this is how
  `hard ⊇ medium` *and* the independence invariant both hold).

### Refinements (load-bearing — do not drop)
1. **`hard` ⊇ `medium`, with a structurally-clean lens.** The synthesized winner of a `hard` run still gets
   a **cross-lineage dual review** — at least the **medium** scrutiny — and the invariant adds that **≥1
   reviewer is fully independent** (lineage neither authored nor synthesized). A `hard` task must never
   receive *less* scrutiny than a `medium` one; smart-merge adds an authoring step on top of medium's
   review, it does not replace it. (Achieved by capping best-of-N at two lineages — `docs/MODELS.md`.)
2. **smart-merge ≠ auto-merge.** "Smart merge" means *synthesizing N attempts into one best diff* — an
   **authoring** step. The PR **merge** stays **human by default** (ADR-0003). Bypassing the human
   merge gate is the **separate, opt-in advanced tier** (ADR-0008), **orthogonal** to this effort dial.
   Choosing `mode: hard` does **not** imply auto-merge.
3. **`mode` is a floor; risk raises it.** *(added 2026-06-15 — see Update above)* The declared tier is a
   **minimum the author sets**, never a ceiling. Once a destructive-or-protected change is *in a task's
   scope* (`rm -rf`/bulk in-place rewrites; a route-to-human item — gate/CI, lockfiles/deps,
   migrations/schema, auth/secrets, public API/contracts — that a human has scoped in; **or a governance /
   decision-record change** — `docs/adr/*`, `CONTEXT.md`, `docs/MODELS.md` role assignments, the
   conventions/skills/templates themselves), the
   task is forced to **≥ `medium`** — *"prefer low, justify higher"* still holds, but some surfaces remove the
   option of staying low. (Routine prose stays `low`; only the decision record / conventions are governance.)
   This is **sequential with** `AGENTS.md`'s route-to-human gate (whether vs at-what-tier; see Update), not in
   conflict with it. Distinct from AW-0010: that loop escalates *reactively* on excess findings; this escalates
   *proactively* on the surface the diff touches.

**Collaborative split is still rejected:** three contracts with nothing to integrate them against, and
it wastes the vendor diversity.

## Consequences
- Cost tracks value on a real ladder: cheap routine work at `low`; extra *review* assurance at
  `medium` without paying for N authors; full author-off + dual review at `hard`.
- One knob, two axes: a task author picks a tier instead of reasoning about authoring and review
  separately.
- The effort dial and the auto-merge tier (ADR-0008) are independent: any tier can run under the
  human-merge baseline (ADR-0003) or, once a repo has earned it, under auto-merge.
- Under Superset, `hard`'s best-of-N runs as N parallel sessions and the dual review runs the reviewer
  CLIs (see `skills/review/SKILL.md` for the pinned models/effort); a human still merges by default.
