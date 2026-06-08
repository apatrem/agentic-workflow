# Agentic coding workflow (one page)

**Backbone (every repo):** `AGENTS.md` (cross-tool source of truth) + a deterministic gate (build/lint/test/typecheck) enforced by **CI required checks** on a **protected main** + small **PRs**.
*LLMs propose. Tools verify. Git isolates. CI decides. Humans merge. Rules remember.*

## The loop
idea → **/grill-me** → `tasks/T-xxx.md` (acceptance = tests) → *(codegraph maps blast radius)* → implement in an isolated worktree → gate green → small PR → sparse review (blockers only) → **human merges** → recurring mistake → a test/lint/rule.

## Default mode = solo
One implementer + deterministic gate + one adversarial reviewer. Reserve **competitive best-of-N** for hard / ambiguous / risky / security tasks (~10%). Set per task: `mode: solo | competitive`.

## Tiers — add complexity only when a trigger fires
- **Baseline (always):** AGENTS.md, thin CLAUDE.md/.cursor rules, task template, the gate + CI required check + protected main, pre-commit, the rituals below. *Recommended:* codegraph + code-review-graph (navigation, **not proof**).
- **Deferred (add when…):** Semgrep/CodeQL (security/scale) · ast-grep (codemods) · stacked PRs (large changes) · SonarQube/CodeRabbit (team).
- **Advanced (earned, opt-in per repo):** autonomous auto-merge — only after real CI required-checks + a Narrow→Widen rollout. Until then, **humans merge.**

## Engine
Orchestration (fan-out worktrees, run agents, open PRs) = **Composio (`ao`)**, driven on subscriptions. This pack does not implement an engine. Best-of-N in Composio is **manual** (same task, agent overridden); a human picks/merges.

## Rituals
1. **Grill before code** — ambiguity dies in /grill-me, not in the PR.
2. **Deterministic gate before any AI review** — don't pay tokens to review red code.
3. **Small-PR budget** — routine < 300 lines; split/stack larger; separate mechanical from behavioural.
4. **Sparse review** — blockers only, ≤10 findings, ranked. AI review is an assistant, not a merge authority (it catches ~15–31% of issues).
5. **Lessons → guardrails** — every recurring mistake becomes a test / lint / Semgrep / AGENTS.md rule.
