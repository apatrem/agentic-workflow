---
description: Phase 3 — run a task via Superset (spawn workers in worktrees); a human merges
argument-hint: "[tasks/<id>.md]"
---

# /agentic-workflow:run

The engine is **Superset** (ADR-0002 Update) — a macOS app **and** a headless **CLI / SDK / MCP server**. Each
worker runs the chosen model in its own git worktree. **A human merges** by default (not an auto-merge harness).

> **Orchestrator interface — exact spawn calls live in the engine, not here.** Drive Superset via its **MCP
> server** (preferred — self-describing spawn tools) or the bundled **`superset` CLI** (`~/.superset/bin/superset`;
> add `~/.superset/bin` to `PATH`, or use a Superset terminal where it is already on `PATH`). The authoritative
> command/flag surface is `superset --help` / the MCP tool schemas; this repo records the *policy* (what to
> spawn, per tier), **not** the engine's API — external (ADR-0002 / 0007) and versioned. Commands below verified
> against **superset v0.2.19** — re-check on upgrade. The end-to-end operational loop an orchestrator actually
> runs — wrapped prompts, monitoring, verify-before-PR, the remediation→re-verify cycle, cleanup, and
> spawn-reliability fallbacks — is in **`docs/ORCHESTRATOR_PLAYBOOK.md`**.

1. **Pre-flight:** `main` clean + protected; the agent CLIs (`claude` / `codex` / `cursor-agent`) logged in on
   your subscription **and each engine preset set to run non-interactively** — a preset is a stored command
   (ADR-0002), and it must carry its CLI's auto-approve flag or the worker blocks on the first approval prompt
   and the spawn never returns. Flags (verify against each CLI's `--help`; external/versioned per ADR-0002):
   **cursor `--force`** (alias `--yolo`) — the default `low` implementer, so this one matters most; **claude
   `--dangerously-skip-permissions`**; **codex `--dangerously-bypass-approvals-and-sandbox`**. Per-role
   model + effort picks (orchestrator, implementer, reviewers, synthesizer) live in **`docs/MODELS.md`** —
   pin Claude via `--model <id> --effort <level>` per spawn (or run the CLI directly). Then `gh`
   authed; the task's `depends-on` already merged. Register the repo once:
   `superset projects create --local --clone <url>` (returns a `prj_…` id).
2. **Spawn the worker(s)** per the task's **`mode`** (ADR-0004) — each gets its own worktree + the right model.
   Create-and-spawn in one call (wrap the task file in an orchestrator preamble — playbook §2 — never pass it bare):
   ```
   # verified against superset v0.2.19 — confirm with `superset --help`
   superset workspaces create --local --project prj_… --name <task> \
     --branch agent/<lineage>/<task> --agent <lineage> --prompt "$(cat /tmp/<task>-prompt.txt)"
   # add --quiet for just the workspace id (scripting); --base-branch defaults to the project default
   # if the agent doesn't materialize (silent race), two-step instead — the reliable default:
   #   superset workspaces create … (no --agent), then
   #   superset agents create --workspace <ws> --agent <lineage> --prompt "$(cat /tmp/<task>-prompt.txt)"
   ```
   - **`low`** *(default)* — one worker, lineage **cursor** (Cursor Composer) + the gate + one adversarial reviewer.
   - **`medium`** — one worker, then the dual review on the PR → `/agentic-workflow:review`.
   - **`hard`** — best-of-N over **two authoring lineages** (`--agent cursor` + `--agent codex`; bias each per
     `templates/ROLES.md`; models per **`docs/MODELS.md`**). **Hold the third lineage — claude — out of
     authoring and synthesis**, so it stays the *structurally-clean* reviewer (ADR-0004 invariant). Then
     **smart-merge** the best into one diff with the **codex** synthesizer — **not** the claude orchestrator,
     or claude is no longer clean (`docs/MODELS.md`). Then the cross-lineage dual review with **Opus as the
     clean lens** (+ optional Fable third) — **hard ⊇ medium** (`/agentic-workflow:review`).

   **Parallel fan-out:** tasks marked `parallel-safe: yes` (disjoint file sets, no unmet `depends-on`) should
   be **spawned concurrently** — one workspace/worktree each, same calls as above. Don't serialize work the
   plan already declared independent; conversely, never run two non-`parallel-safe` tasks at once.

   (GUI equivalent: `⌘N` new workspace → run the agent in its terminal.)
3. **Gate + inspect.** Run the gate in each worktree —
   `superset terminals create --workspace <ws> --command "<gate>"` — and review the diff (GUI `⌘L`, or open the
   worktree in your editor). For `hard`, compare attempts side-by-side and synthesize the smallest correct diff —
   reward the smallest passing diff, not cleverness. **Verify before pushing:** diff scope + do-not-touch
   contracts untouched + the gate green by *your own* run, not the worker's claim (`ok` proves nothing — playbook §3–4).
4. Push the chosen branch; open a PR via `gh` → CI re-runs the gate. Once CI is green, review per tier
   (blockers only):
   - **`low`** — one **adversarial reviewer** (≤10 ranked findings), a lineage **independent of the
     implementer** (model in **`docs/MODELS.md`**) — spawn via
     `superset agents create --workspace <ws> --agent <preset> --prompt "Review PR <pr> …"` (or run the CLI
     directly, or review the diff yourself) and post as a PR comment; nits are advisory. The reviewer also
     runs the advisory **minimalism lens** (over-engineering delete-list + `SHORTCUT(…)` marker enforcement —
     ADR-0011); it stays advisory, the veto is blockers-only.
   - **`medium`** / post-**`hard`** smart-merge — run `/agentic-workflow:review` on the PR (dual
     cross-lineage review).
   - If a lineage's Superset spawn is flaky (codex not starting, claude PTY stalling on the worktree
     trust-prompt), run the reviewer **directly** in the worktree — `codex exec … < prompt` / `claude -p … < prompt`
     — same model + PR-comment contract (playbook §5).
   If review raises blockers, run the **remediation loop** (ADR-0010; mechanics in playbook §6): **remediate
   on the same branch** with the **tier's implementer** (the *remediator* — `low`/`medium`: cursor; `hard`: the
   winning best-of-N lineage; `docs/MODELS.md`), prompt = the punch-list. Then re-check: the **default** is a
   cheap **targeted re-verify** (each blocker back to the reviewer that raised it); but if findings are
   *excessive* (blocker count ≥ the tier's *N*, a **`systemic`** flag, or the fix **ballooned**) **escalate one
   tier and run a full fresh review round** — `low→medium` adds the dual review; `medium→hard` keeps the diff as
   **seed candidate #0**, runs best-of-N in parallel, and smart-merges {seed + attempts}. Cap: **3 full review
   rounds** (the initial review counts; re-verifies don't); blockers surviving round 3 → **`needs-human`**
   (ADR-0006). Then **a human merges**. **smart-merge ≠ auto-merge**; autonomous auto-merge is the separate
   advanced tier (ADR-0003 / 0008).
5. **Lessons → guardrails:** turn any recurring mistake into a test / lint rule / AGENTS.md line.
