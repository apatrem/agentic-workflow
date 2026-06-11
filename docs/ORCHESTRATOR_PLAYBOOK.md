# Orchestrator playbook — the lived `/run` loop

Companion to `commands/run.md`. `run.md` is the *policy* (what to spawn per tier); this is the *operational loop* an orchestrator actually executes, distilled from real runs. The engine is **Superset** (ADR-0002); commands verified against **v0.2.x** — re-check `superset --help` on upgrade, and treat the §7 reliability notes as version-pinned (they may go stale), the loop in §1–6 as durable.

## 1. The loop

```
spawn → monitor → verify → PR → review → synthesize → remediate → re-verify → cleanup
```

The orchestrator stays in its own thread and never implements or reviews inline — it spawns workers, then inspects, gates, and PRs their output. **One *authoring* worker = one workspace = one worktree = one branch** — that maps the implementer (and, at `hard`, each best-of-N candidate) 1:1 to a branch. **Reviewers and the remediator are *added into* an existing authoring workspace, not given their own** (`agents create --workspace <ws>`); they don't get a fresh branch. So a single `low`/`medium` workspace hosts the implementer, then the reviewer(s), then (if needed) the remediator — several agents, one branch.

## 2. Spawn — what actually works

**Two-step, not one** — the canonical sequence (confirmed first-try for **all three lineages**: cursor, claude, codex). Create the workspace first (its worktree + setup hook run), *then* add the agent into the ready workspace:

```bash
# 1. workspace WITHOUT --agent → returns workspace.id
superset workspaces create --local --project <prj-id> --name <task> --branch agent/<lineage>/<task> --json
# 2. agent into the ready workspace
superset agents create --workspace <ws-id> --agent <preset> --prompt "$(cat /tmp/<task>-prompt.txt)" --json
```

`<lineage>` → `<preset>`: **cursor → `cursor-agent`** (default `low` implementer) · **claude → `claude`** · **codex → `codex`**. `<prj-id>` from `superset projects list`.

The `--agent`-at-create form in `run.md` works when it works, but a silent race can leave the worktree up with no agent; the two-step is the reliable default and is also how you add reviewers to an existing workspace. Workspaces created this way are first-class in the Superset v2 sidebar (no UI workaround). Earlier-session spawn failures traced to *conditions* (`--pr`-created review workspaces, oversized prompts, a first-worktree trust prompt) — not this sequence.

**Pinning a model per spawn.** `agents create` has no `--model` flag — the model comes from the lineage preset, which falls back to the CLI default if unpinned. To run one spawn on a specific model (a cheap throwaway, or to dodge a rate-limited tier), temporarily set it in the preset's host config and revert right after — the daemon reads it per-spawn, running agents are unaffected (args read at launch), and the revert leaves no trace. (Engine-internal and version-pinned — confirm the host-config shape on your Superset version.)

**Preconditions that bite (each fails *silently* — `ok: true` proves nothing):**
- The lineage **preset must carry its auto-approve flag** or the worker hangs on the first prompt forever (cursor `--force`/`--yolo`; claude `--dangerously-skip-permissions`; codex `--dangerously-bypass-approvals-and-sandbox`). Stored in the engine's host config, not the CLI call — verify with `superset agents list --local`.
- **`--pr <N>` / `--branch` dies if that branch is checked out in another worktree** (git refuses duplicate checkout → setup fails, no worktree appears). Free the branch first.

**Wrap the prompt — never pass the bare task file.** A worker driven by `cat tasks/<id>.md` alone doesn't know the house rules. Prepend an orchestrator preamble:

> Read AGENTS.md first (source of truth). Implement task `<id>` in **this** worktree on the current branch. Honour the task's do-not-touch list and size budget; no new dependencies; never auto-"fix" invalid input — fail loudly. *(If a sibling task runs in parallel, state the file-set disjointness constraints.)* Run the full gate until green. Commit small — **but do NOT push**: the orchestrator inspects the diff and opens the PR.

The "don't push" clause is load-bearing: it keeps the PR boundary with the orchestrator, who verifies before anything reaches `origin`.

## 3. Monitor — `ok` means nothing

Don't trust the spawn's return. Watch for the *artifact*: commits landing on the branch, then the tree going quiet. With several cursor workers running, process-exit is ambiguous — key the "done" signal on **commits present + working tree clean for N minutes** instead. Sanity-check liveness early (process exists / fresh session log / worktree materialized); if a spawn produced nothing after a few minutes, it failed silently — re-spawn or fall back (§5).

## 4. Verify before PR — the orchestrator's gate

Before pushing a worker's branch, the orchestrator independently:
1. **Inspects diff scope** — `git diff main --stat`; confirm the **do-not-touch / protected contracts are untouched** (`git diff main --name-only | grep <protected>`).
2. **Runs the full gate itself** in the worktree (build + lint + test + validate) — a worker's green claim is not proof.
3. Only then pushes and opens the PR via `gh`, with a body that maps changes to the task's acceptance criteria. Wait for **CI green** before paying for review (Ritual 2 — don't review red code).

## 5. Review per tier — with a direct-CLI fallback

Tiers per `run.md`/`review.md`: `low` → one adversarial reviewer; `medium`/post-`hard` → the cross-lineage dual review. Reviewers run as **spawned workers, never inline**, each posting its own PR comment; the orchestrator synthesizes.

**A reviewer acts on the *PR*, not the branch** — it reads the diff and posts a comment; it does **not** commit and does **not** branch. It's spawned *into the authoring workspace* (`agents create --workspace <ws>`) only so the checkout is already there; its output is the PR comment, not a worktree change. (Contrast the *remediator* — §6 — which is also added to that same workspace but **does** commit to the branch.) The implementer's worktree may be dirty/ahead of the pushed PR head; if a reviewer needs a clean tree it can run on a fresh `--pr <N>` checkout instead — same model, same PR-comment contract.

**If a Superset spawn genuinely stalls** (rare — e.g. a first-worktree trust prompt the headless PTY can't answer), run the CLI **directly** in the workspace's worktree — same model, same independence, same PR-comment contract, just no engine UI:

```bash
codex exec --dangerously-bypass-approvals-and-sandbox - < review-prompt.txt          # GPT-lineage, xhigh from ~/.codex/config.toml
claude -p --model claude-opus-4-8 --effort xhigh --dangerously-skip-permissions < review-prompt.txt  # Claude-lineage reviewer (models: docs/MODELS.md)
```

Pass the prompt via stdin/file to dodge argv quoting. Tell each reviewer to verify external/claimed facts itself and to run the gate.

## 6. Synthesize → remediate → re-check (the loop — ADR-0010)

The decision behind this loop (remediator = tier implementer; excess-findings escalation; 3-round cap) is **ADR-0010**; this is how you run it.

- **Synthesize** both lenses into one PR comment: agreements (highest priority), disagreements (adjudicate — keep only real blockers), a deduped severity-ranked punch-list, and a verdict (*blockers present → changes required*, else advisory-only). Emit two machine-usable signals alongside it: the **blocker count** and a **`systemic` flag** (is the diff wrong in *approach*, or just in details?). Adjudicate honestly: a finding one reviewer reproduced and the other missed is still a blocker (real runs: a same-basename image collision and a test-helper masking a missing chart-category cache — each caught by exactly one lens). **This synthesis is round 1** of the 3-round cap.
- **Remediate on the same branch/workspace** with the **tier's implementer** (the *remediator* — `low`/`medium`: cursor/Composer; `hard`: the winning best-of-N lineage; `docs/MODELS.md`): spawn a worker whose prompt *is* the synthesis punch-list ("fix exactly this, nothing else"), same do-not-touch constraints, gate-until-green, commit-don't-push. Have it **report if the fix ballooned** beyond the punch-list.
- **Re-check the remediated diff — pick one:**
  - **Default — targeted re-verify (cheap, uncapped):** hand each blocker back to the reviewer that raised it for an adversarial RESOLVED / NOT-RESOLVED verdict — re-running its own reproduction, not just trusting the new tests. All RESOLVED + CI green → done.
  - **Excess findings → full re-review (counts as a round):** if **any** of — blocker count ≥ *N* for the tier (`docs/MODELS.md`), the synthesis flagged **`systemic`**, or the remediator **ballooned** — then **escalate one tier** and run a **full fresh review round** on the remediated diff:
    - **`low→medium`** — add the cross-lineage dual review to the same diff.
    - **`medium→hard`** — **keep the diff as seed candidate #0**, spawn best-of-N **in parallel**, smart-merge {seed + attempts} into one diff (don't discard the remediation work), then the triple review.
- **Bound:** at most **3 full review rounds** (round 1 = the initial synthesis above; targeted re-verifies don't count). Blockers surviving round 3 → **`needs-human`** (ADR-0006): stop auto-looping, hand the PR to the human merging with the open blockers flagged. *(The unattended auto-merge tier keeps ADR-0008's stricter "repair once" — don't apply this 3-round budget there.)*

## 7. Cleanup after merge (engine-reliability notes)

After a human merges, leave no debris: delete the Superset workspace, delete the branch (local + remote), prune the worktree, pull `main`.

Version-pinned quirks to expect (Superset v0.2.x / v1.12.x): `workspaces delete` has returned `Error: Unexpected end of JSON input` and not deleted — re-check. On **v2**, CLI-created workspaces appear in the sidebar like any other (confirmed); the old "invisible / needs Add-to-sidebar" issue was **v1-only** (`superset-sh/superset#5083`).
