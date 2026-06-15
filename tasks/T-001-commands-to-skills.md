# T-001: Convert the five phase commands to SKILL.md skills + thin Claude slash shims

<!-- Phase 2 output. Implements ADR-0007 (2026-06-15 cross-CLI update): skills/ is the single source. -->

## Objective
Make every phase invokable portable across Driver seats (Claude/Codex/Cursor) by turning each phase
command into a `SKILL.md` skill, and reduce the Claude slash command to a thin shim so the prompt text
lives in exactly one place (the skill). This is the cross-CLI change's core; the prompt bodies are
load-bearing and must move *intact*.

## Acceptance criteria  (must be machine-checkable)
- [ ] For each of `architect, plan, run, review, init`: `skills/<name>/SKILL.md` exists with frontmatter
      `name: <name>` (matching the folder) + a non-empty `description:`, and the **command body has moved
      into it** (the body marker is present in the skill). → covered by `tests/skills.test.sh`
- [ ] Each `commands/<name>.md` is a **thin shim** — body is `Use the \`<name>\` skill.`, ≤ 8 lines, and
      the original body marker is **absent** (no duplicated prompt). → covered by `tests/skills.test.sh`
- [ ] gate green: `bash tests/skills.test.sh`

## Files likely involved
- `skills/architect/SKILL.md`, `skills/plan/SKILL.md`, `skills/run/SKILL.md`, `skills/review/SKILL.md`, `skills/init/SKILL.md` (new)
- `commands/architect.md`, `commands/plan.md`, `commands/run.md`, `commands/review.md`, `commands/init.md` (rewritten to shims)

## Out of scope
- `plugin.json` skills list, README, CI wiring (→ T-003).
- The installer / `setup` skill (→ T-002).
- The two grill skills (already `SKILL.md`).

## Risks / do-not-touch
- **Do not edit the frozen tests** (`tests/*.test.sh`, `tests/lib.sh`, `tests/run.sh`) to pass — only add/move content.
- **Do not touch** `bin/`, `skills/setup/`, `plugin.json`, `README.md`, `.github/`.
- **Preserve the prompt bodies verbatim** when moving them — `description` frontmatter can come from the
  command's existing `description:`. Carry `argument-hint` where present (run/review) into the skill if useful.
- The Claude slash namespace (`/agentic-workflow:<name>`) must still resolve via the shim.

## Meta
- mode: medium          # justified: highest-blast-radius change (every entrypoint); body fidelity is
                        # testable but "still works as a skill in each seat" is partly semantic → dual review.
- risk: low             # acceptance is machine-checkable (tests/skills.test.sh)
- depends-on: []
- parallel-safe: yes    # disjoint from T-002 (bin/, skills/setup/); T-003 depends on this
- size budget: mostly relocation; review for content loss, not line count
