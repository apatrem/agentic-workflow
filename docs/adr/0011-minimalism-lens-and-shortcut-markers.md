# ADR 0011 — Minimalism review lens + `SHORTCUT(…)` markers (imported from Ponytail's philosophy)

**Status:** accepted

## Context

We evaluated [Ponytail](https://github.com/DietrichGebert/ponytail) — a popular (MIT) rule-pack that pushes
agents toward minimal code ("lazy senior developer": YAGNI → stdlib → platform → existing dep → one-liner →
minimal). Ponytail is **hybrid**: it ships *both* a plugin/hooks delivery path **and** a committed
`AGENTS.md` rules-file path. We **declined the plugin/hooks delivery channel — not Ponytail wholesale**: the
hooks inject behaviour from *outside* the repo, which conflicts with ADR-0001 (rules live in `AGENTS.md`,
committed and verifiable, not in the harness). What we adopted is the content of Ponytail's *own committed
rules-file mode*, re-authored into `AGENTS.template.md` — so this is choosing Ponytail's in-repo channel over
its harness channel, plus filling three real gaps. (Most of its thesis already lived in our conventions —
`ROLES.md` "smallest diff", "no new dependencies", the small-PR ritual.) We imported the *content*, not the tool.

The gap: in a workflow where a cheap implementer writes minimal diffs by default, **deliberate corner-cutting
is invisible** to the human merger — they can't tell "naive on purpose, here's the ceiling" from "naive
because the model didn't think." Our gate/tests/protected-paths defend the corners that must *never* be cut;
nothing made the *acceptable* corners legible.

## Decision

1. **Decision-hierarchy ladder + a minimalism floor** (authoring rules, every tier — `AGENTS.template.md`).
   The "smallest correct change" rule becomes an explicit ladder (*needed at all? → stdlib → platform →
   installed dep → one line → minimal code*), paired with a **floor**: minimalism never cuts input
   validation at trust boundaries, error handling that prevents data loss, security, or accessibility.

2. **`// SHORTCUT(<ceiling>): <upgrade path>` markers.** Each deliberate simplification is marked inline,
   naming the known ceiling **and** the upgrade path — e.g. `// SHORTCUT(O(n²) scan): ok <1k rows; add an
   index if it grows`. This is a "constraint the code can't show" (it survives the minimal-comment ethos),
   it travels with the code, and it is greppable.

3. **An advisory minimalism *lens* on the existing reviewer** (`skills/review/SKILL.md`, `skills/run/SKILL.md`).
   The adversarial reviewer we already run on every tier gains one dimension: produce an over-engineering
   **delete-list**, and **enforce** that every deliberate corner carries a `SHORTCUT(…)` marker (adding the
   markers the cheap author missed). The synthesis lists the SHORTCUTs a PR adds.

4. **The code is the ledger** — no committed `DEBT.md`. `grep -rn 'SHORTCUT('` is the running inventory;
   `/agentic-workflow:review` surfaces what each PR *adds* (debt seen the moment it's created).

### Three load-bearing choices (do not drop)

- **Advisory, not a veto.** Over-engineering does **not** become a blocker class — the veto stays
  blockers-only (correctness / security / spec-violation / regression — ADR-0004). Subjective vetoes thrash;
  minimalism is a quality nudge, not a merge gate.
- **Reviewer-enforced, not author-mandated.** Marking is a job for the **premium, reliable reviewer**, not
  the cheap implementer — a discretionary convention on the weakest model decays, and an inconsistent marker
  is worse than none (absence would falsely read as "no shortcut").
- **No ledger file.** A committed `DEBT.md` duplicates the code and drifts — the same single-source argument
  that keeps model picks in `docs/MODELS.md` only. The markers in code are the source of truth.

## Consequences

- **Deliberate corners are legible at the merge gate** — the human merger sees the ceilings and upgrade
  paths a minimal diff took on, without an out-of-band tracker.
- **Cost is bounded:** a little comment density on genuinely-cut corners, and one advisory dimension added
  to a review that runs anyway. No new agent, no new command, no new file.
- **Relation to the other ADRs:** complements ADR-0001 (we imported *content into the repo*, not a harness
  plugin), respects ADR-0004's blockers-only veto, and reuses the single-source discipline behind
  `docs/MODELS.md`. Distinct from the **lessons → guardrails** ritual, which tracks *mistakes*; this tracks
  *deliberate* shortcuts.
- **Not imported from Ponytail:** the modes dial, the statusline, the benchmarks, and the plugin/hooks
  themselves. On the modes dial specifically: Ponytail's modes are an *intensity-of-minimalism* axis
  (`lite | full | ultra`, where `ultra` "deletes before adding, may reject the task"); our `mode` is an
  *effort/review-rigor* axis (AW-0004). The two are **orthogonal**, not the same knob — so we skip Ponytail's
  dial for two precise reasons: (a) a **naming collision** on "mode," and (b) we **deliberately fixed our
  minimalism posture** (ladder + floor, always-on, one advisory lens) rather than making it tunable — a fixed
  floor is more predictable than a per-task intensity setting.
