# ADR 0002 — Buy the orchestration engine; build only the conventions/policy

> **Current engine: Superset** (the original pick, Composio, is retained below as decision history). The
> decision is the **principle** — *buy the orchestration engine, build the conventions* — not the vendor;
> the engine is a swappable slot (see the 2026-06 Update).

**Status:** accepted — engine *pick* amended 2026-06 (**Composio → Superset**; see Update below); the
**principle** (separate policy from engine) stands.

## Context
The orchestration plumbing — isolating worktrees, running agents, opening PRs — is commoditised and
more mature off-the-shelf than anything we would maintain. Our differentiator is the
**policy/conventions**, not a from-scratch runner. Operating constraint: the operator drives monthly
**subscriptions, not API keys**; vendor terms permit driving the **official CLIs** headlessly under
subscription (rate-limited) but prohibit extracting OAuth tokens into a custom client.

## Decision
- **Engine = Composio (`@aoagents/ao`)** — it drives the official Claude / Codex / Cursor CLIs on
  subscription auth, isolates each worker in its own worktree, and opens PRs. **Never token
  extraction.** **Engine pick superseded — see Update (engine, 2026-06) below.**
- This pack ships only the **conventions, planning (grill-with-docs), task template, and ADRs** — the
  operating manual and scaffolder that sit on top of the engine.
- **Merge vehicle = a PR**, never `git push HEAD:main`. CI re-runs the gate in the canonical
  environment; **the PR is both the merge vehicle and the human handoff**.

## Consequences
- One mature engine, maintained by someone else; we maintain policy.
- Composio is fleet-first, so **competitive best-of-N is manual** (same task, agent overridden;
  a human picks/merges) — acceptable, since best-of-N is the ~10% case (ADR-0004).
- Cursor CLI was beta at time of writing (the flakiest worker); the engine degrades gracefully if a
  worker errors. **Superseded for the default implementer — see Update (2026-06) below.**
- If Composio is ever swapped out, the backbone (ADR-0001) and these conventions are unaffected.

## Update (2026-06) — engine pick swapped: Composio → Superset
Composio caused real operating friction — **bugs**, a **weak interface**, and **suspected high token spend**
(its LLM-driven orchestrator burns tokens on coordination, separate from implement/review). The **principle
above is unchanged** — the engine was always a swappable slot (see Consequences) — so only the *pick* moves.
Read the engine generically as **"an interactive worktree session manager"**; the specific tool is a
one-line, swappable detail.

- **Current pick = [Superset](https://github.com/superset-sh/superset)** — a macOS app; each agent in its
  own git worktree; first-class **Cursor** support (the Cursor-Composer solo default below carries over),
  plus Claude / Codex / OpenCode / Amp. Zero token markup. The orchestrator runs **no LLM**, which removes
  the token-overhead concern.
- **Two surfaces — interactive *and* headless.** Superset is both a macOS app **and** a **CLI / TypeScript
  SDK / MCP server** ([docs.superset.sh](https://docs.superset.sh); CLI bundled at `~/.superset/bin/superset`).
  An operator can spawn workers programmatically — via MCP (preferred) or the CLI — with a one-shot
  `superset workspaces create … --agent <lineage> --prompt <task>` (verified v0.2.19; re-check on upgrade),
  putting each worker with the right model in its own worktree. Use `superset agents create --workspace …`
  to run an agent in an *existing* workspace (e.g. PR reviewers). A human still merges by default
  (ADR-0003 / 0006). Best-of-N (`hard`, ADR-0004): spawn N agents across lineages, compare diffs, pick.
- **Mechanism:** the Composio `agent-orchestrator.yaml` / `ao spawn` wiring is gone; pick the worker/reviewer
  model via `--agent <preset>` on spawn (CLI/GUI) or per session in the GUI. The Cursor-Composer-default
  *preference* stands (see Update below).
- **Caveats (recorded — solo / local / macOS):** Superset is **Elastic License 2.0** (source-available, not
  OSS) and **macOS-only** today. **Auth:** the control plane logs in via OAuth device-code / API key
  (`superset auth login`); the *agents* run the underlying CLIs (a preset is a stored command run in a
  terminal), so they use **the CLI's own subscription login** — the no-token-extraction constraint above
  holds. *Confirmed (2026-06): spawning `claude` / `cursor-agent` uses the existing CLI login, no provider API key.*
- **ADR-0008 is *not* blocked by the engine.** The headless CLI/SDK gives the spawn + gate primitives an
  auto-merge loop needs (`superset workspaces create … --agent … --prompt …`;
  `superset terminals create --command <gate>`); what
  remains is ADR-0008's own code-side decision + `gh` merge. (An earlier draft wrongly called an interactive
  engine a dead-end here.)
- **Fallbacks (one-line swap):** **Claude Squad** (minimal TUI, more battle-tested); **Sculptor**
  (Docker-container isolation, stronger than worktrees — ADR-0006); **herdr** (open, cross-platform,
  fully headless — evaluated in the Update below).

## Update (2026-06) — Cursor Composer is the default solo implementer

Under Superset the agent is picked **per spawn or session** (`--agent cursor` / Cursor Composer in the GUI) —
not via a repo-level harness config. The latest Cursor Composer (driven via `cursor-agent`) has matured past
the beta-era flakiness noted above and is the **default solo implementer** for `mode: low` (ADR-0004): one
worker on lineage **cursor**, routine ~90% path. Rationale: reliable enough in practice, and its tendency
toward small, surgical diffs matches the reward function — *"reward the smallest passing diff, not
cleverness."* `claude` and `codex` remain first-class overrides for competitive best-of-N (`templates/ROLES.md`);
graceful degradation on worker error is unchanged.

## Update (2026-06) — scheduled automations: an allowed *trigger* for the loop, under the same policy

The loop is human-*initiated* today (a human runs `/agentic-workflow:run`). The engine also lets a loop
**trigger itself on a schedule** — Superset ships automations/scheduling; herdr and cron do too — so an agent
can run unattended on a cadence (nightly "find flaky tests", "triage new issues", "flag dependency drift") and
surface work nobody asked for yet. This idea is borrowed from Addy Osmani's *Loop Engineering* (the
"Automations" primitive). **It changes only *who starts the loop*, not what the loop is** — so it inherits
every existing guarantee rather than earning an exception:

- **A schedule must not implement unplanned work.** The Phase-2 human sign-off (ADR-0005) is the control point
  for *what* gets built and at what scope/risk; `skills/run` is for **planned, human-approved** tasks. A
  schedule that *discovers* work nobody asked for cannot then *implement* it autonomously — that would bypass
  the sign-off. So a scheduled job is one of two shapes only:
  1. **Discovery/triage that stops before Phase 3** — it produces an *artifact* (a filed issue, a draft
     `tasks/T-xxx.md`, a report comment), never code. A human triages and approves before any `/run`.
  2. **A pre-authorized recurring task** — a human has signed off a **bounded** recurring spec up front (fixed
     scope, acceptance, do-not-touch, declared `mode`); the schedule re-runs *that* approved task (e.g. "regen
     the changelog", "bump the lockfile and run the gate"), never open-ended work.
- **A scheduled `/run` (shape 2) is still just a `/run`** — same worktree-per-worker, deterministic gate,
  verify-before-PR. It grants **no merge authority by itself**: human-merge stays the default (AW-0003 / 0006),
  and a repo that has separately *earned* the ADR-0008 auto-merge tier keeps using that tier's policy — the
  schedule neither adds nor removes it.
- **The risk floor applies unchanged** (AW-0004): a scheduled job that touches destructive-or-protected or
  governance surface runs at **≥ medium** with the cross-lineage review, exactly as a hand-started one would.
  The schedule does not lower scrutiny.
- **The orchestrator stays thin** (ORCHESTRATOR_PLAYBOOK §1): a scheduled job spawns workers and opens PRs (or
  files triage artifacts); it does not accumulate context or merge. A run that finds *nothing* should cost
  ~nothing and open no PR.
- **"Stay the engineer"** — Osmani's own caveat: an unattended loop still makes unattended mistakes, and
  unread generated code is *comprehension debt*. Automations surface and prepare work; a human still reads the
  diff and merges. They are a convenience for *initiating* the loop, not a licence to leave it.

Net: automations are **permitted and engine-provided, governed by the existing ADRs** — no new merge authority,
no new risk-floor exemption, and **no path from a schedule to unplanned implementation** (ADR-0005 holds).
Worth adopting when a repo has recurring unprompted work (triage, drift, flakiness); skip until it does (the
minimalism tier ladder — `docs/WORKFLOW.md`).

## Update (2026-06) — [herdr](https://github.com/ogulcancelik/herdr) flagged as a candidate engine (evaluated, not adopted)

A potential replacement for Superset, recorded here so the comparison isn't lost. **Not adopted — Superset
remains the current pick.** herdr ([herdr.dev](https://herdr.dev)) is a Rust single-binary terminal session
manager for coding agents. It maps cleanly onto the **seven-operation engine contract** this ADR demands
(register repo → project; per-task isolated worktree on a named branch; spawn agent into worktree via the
CLI's auto-approve flag, multi-lineage; run a gate command in a worktree; monitor status + diff; capture the
transcript; tear down after merge), so the swap is **roughly the same effort as the Composio → Superset move
— a half-day `medium` PR**.

**Pros**
- **Open + cross-platform** — AGPL-3.0 (or commercial), Linux/macOS (Windows beta). Removes Superset's two
  standing caveats: **ELv2 source-available** and **macOS-only**.
- **Fully headless** — server + complete CLI + JSON socket API; **native** `herdr worktree create/open/list/remove`
  (don't rebuild these — AW-0002). Multi-CLI first-class (claude/codex/cursor). Remote-over-SSH.
- **Semantic states** — `herdr wait output|agent-status` exposes done/blocked, so the monitor loop
  (ORCHESTRATOR_PLAYBOOK §3) needs no PTY heuristics to know a worker finished.

**Cons / watch-outs**
- **Pre-1.0 (v0.7.0)** — less battle-tested than a shipping app.
- **No GUI.** Terminal-native: **no visual diff preview, no clickable PR-merge buttons.** These are Superset
  *conveniences*, not contract functions — diff review already has a CLI path (`git diff` / `gh pr diff` /
  open the worktree in your editor, per the `run` skill), and **a human merges on GitHub** (`gh pr merge` /
  web UI), which is never an engine function (AW-0003). So it's a real **ergonomics downgrade** for the human
  review/merge step, not a functional blocker — and the engine choice doesn't lock the review surface (you can
  run herdr headless and still review/merge on github.com).
- **No preset abstraction** — you assemble argv + the auto-approve flag yourself. Glue needed: a **~20-line
  spawn wrapper** encoding lineage → argv + flag (cursor `--force`, claude `--dangerously-skip-permissions`,
  codex `--dangerously-bypass-approvals-and-sandbox`), replacing `templates/superset-config.template.json`'s
  preset store.
- **Transcript capture is PTY-buffer scraping** (`herdr pane read --source recent-unwrapped`), not a transcript
  file — coarser than Superset's capture.
- **Compact pane/agent ids are reused on close** — re-list, don't cache.

**If adopted:** amend this ADR in place (don't supersede), rewrite the spawn/gate/cleanup snippets in
`skills/run/SKILL.md` + `ORCHESTRATOR_PLAYBOOK.md`, replace the Superset config template with the lineage→argv
table + spawn wrapper. The backbone (ADR-0001) and all conventions are unaffected — that's the point of the
swappable-slot principle.
