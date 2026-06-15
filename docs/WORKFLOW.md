# Agentic coding workflow (one page)

**Backbone (every repo):** `AGENTS.md` (cross-tool source of truth) + a deterministic gate (build/lint/test/typecheck) enforced by **CI required checks** on a **protected main** + small **PRs**.
*LLMs propose. Tools verify. Git isolates. CI decides. Humans merge. Rules remember.*

## The loop
idea → **`/agentic-workflow:architect`** (grill-with-docs → ADRs + `CONTEXT.md`; human signs each ADR) → **`/agentic-workflow:plan`** (`tasks/T-xxx.md` + frozen red tests, each flagged `parallel-safe` or not; human sign-off) → *(codegraph maps blast radius)* → **`/agentic-workflow:run`** (implement in an isolated worktree; `parallel-safe` tasks fan out concurrently) → gate green → small PR → review per tier (blockers only; `medium`/`hard` add the dual review) → **human merges** → recurring mistake → a test/lint/rule.

## Effort/review dial — `mode: low | medium | hard` (default `low`; prefer low, justify higher)
One dial, two axes (authoring depth × review rigor); set per task, default `low` (ADR-0004).
- **low** *(default, ~90%)* — 1 implementer + deterministic gate + 1 adversarial reviewer (a lineage independent of the implementer).
- **medium** — 1 implementer + gate + an independent **dual review** on every PR: two cross-lineage reviewers, each independent of the implementer, each posts a PR comment; orchestrator synthesizes (agreements / disagreements / deduped severity-ranked punch-list). Blockers-only veto. → `/agentic-workflow:review`.
- **hard** — competitive best-of-N over **two lineages** → **smart-merge** (synthesizer grafts the best attempts into one diff) → **then the cross-lineage dual review** on that result, guaranteeing **≥1 structurally-clean lens** (the third lineage is held out of authoring/synthesis to *be* that lens) (**hard ⊇ medium**; the invariant is ADR-0004).

**Remediation loop (ADR-0010):** review blockers → the **tier's implementer** (the *remediator*) fixes the punch-list → **targeted re-verify** by default; if findings are excessive (count ≥ the tier's *N*, `systemic`, or the fix ballooned) **escalate one tier + a full re-review** (`medium→hard` keeps the diff as a best-of-N seed). Capped at **3 review rounds** → else **`needs-human`** (ADR-0006).

**Model policy:** which model runs each role/tier is a **living table — `docs/MODELS.md`** (the single source; revisit often against cursor.com/cursorbench + deepswe.datacurve.ai). The *durable principle* — role-keyed cost ladder, reviewers cross-lineage **and** independent of the implementer, "difficult"→`hard` — is **ADR-0004**.

**smart-merge ≠ auto-merge:** smart-merge synthesizes N attempts into one diff; the PR **merge stays human** by default (ADR-0003). Auto-merge is the separate, orthogonal advanced tier (ADR-0008) — `hard` does *not* imply it.

## Tiers — add complexity only when a trigger fires
- **Baseline (always):** AGENTS.md, thin CLAUDE.md/.cursor rules, task template, the gate + CI required check + protected main, pre-commit, **pnpm via Corepack for new Node repos (ADR-0009)**, the rituals below. *Recommended:* codegraph + code-review-graph (navigation, **not proof**).
- **Deferred (add when…):** Semgrep/CodeQL (security/scale) · ast-grep (codemods) · stacked PRs (large changes) · SonarQube/CodeRabbit (team) · [SkillSpector](https://github.com/NVIDIA/SkillSpector) (vet a third-party skill/plugin before adopting it — the automatable form of the hand-inspection we did for Ponytail).
- **Advanced (earned, opt-in per repo):** autonomous auto-merge — only after real CI required-checks + a Narrow→Widen rollout. Until then, **humans merge.**

## Engine
Orchestration (worktree sessions, run agents, review diffs) = **Superset** (ADR-0002 Update) — a macOS app *and* a headless **CLI / SDK / MCP server** driving your subscription CLIs (bundled at `~/.superset/bin/superset`). This pack does not implement an engine. Spawn workers interactively (GUI) **or** programmatically — `superset workspaces create … --agent <lineage> --prompt <task>` puts each worker with the right model in its own worktree (see `/agentic-workflow:run`; re-check `superset --help` on upgrade); use `superset agents create --workspace …` to run agents in an *existing* workspace (e.g. PR reviewers). **A human merges** by default. `hard`'s best-of-N = N spawned agents across lineages; `medium`/`hard`'s dual review spawns the reviewer CLIs (pinned models — see `/agentic-workflow:review`). The engine is a *pluggable slot* — swap in another manager (e.g. Claude Squad) in one line.

## Rituals
1. **Grill before code** — ambiguity dies in Phase 1 (`/agentic-workflow:architect`), not in the PR.
2. **Deterministic gate before any AI review** — don't pay tokens to review red code.
3. **Small-PR budget** — routine < 300 lines; split/stack larger; separate mechanical from behavioural.
4. **Sparse review** — blockers only, ≤10 findings, ranked. AI review is an assistant, not a merge authority (it catches ~15–31% of issues).
5. **Lessons → guardrails** — every recurring mistake becomes a test / lint / Semgrep / AGENTS.md rule.
6. **Prune after merge** — GitHub auto-deletes the remote head branch on merge; locally run `git fetch --prune` then delete branches marked `: gone]` (`git branch -vv`) so nothing goes stale. Mechanism + why squash needs this: `ORCHESTRATOR_PLAYBOOK.md` §7.
