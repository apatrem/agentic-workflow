# T-003: plugin.json parity + README install section + CI runs the gate

<!-- Phase 2 output. Integration task — depends on T-001 (skills+shims) and T-002 (installer+setup). -->

## Objective
Tie the cross-CLI change together: register every skill in the Claude plugin, document per-seat install,
and make the bash gate a required check so shim↔skill consistency and `SKILL.md` validity are enforced
on every PR (not just JSON/YAML).

## Acceptance criteria  (must be machine-checkable)
- [ ] `.claude-plugin/plugin.json` `skills` array equals the set of `skills/*` dirs (no missing/extra),
      including the five phase skills + `setup` + the two grills. → covered by `tests/packaging.test.sh`
- [ ] Every `commands/<name>.md` shim references an existing `skills/<name>/`; every `SKILL.md` has
      `name` matching its folder + a `description`. → `tests/packaging.test.sh`
- [ ] `.github/workflows/validate-templates.yml` runs the bash gate (`tests/run.sh`). → `tests/packaging.test.sh`
- [ ] `README.md` has a per-seat **Install** section naming `bin/install.sh`. → `tests/packaging.test.sh`
- [ ] full gate green: `bash tests/run.sh` (all of skills + install + packaging — integration)

## Files likely involved
- `.claude-plugin/plugin.json` (skills list)
- `README.md` (Install section)
- `.github/workflows/validate-templates.yml` (add a step running `tests/run.sh`)

## Out of scope
- Editing skill/command prompt content (owned by T-001) or the installer (T-002) — only *reference* them.

## Risks / do-not-touch
- **Do not edit the frozen tests** (`tests/*`).
- **Do not modify** any `skills/*/SKILL.md` body, `commands/*.md`, or `bin/install.sh` — this task only
  registers/documents/wires what T-001 and T-002 produced.
- Bump `plugin.json` `version` (so installs pick up the new skills) — coordinate with any concurrently
  open version-bump PRs (take the next free patch number).

## Meta
- mode: low             # mechanical integration; fully testable
- risk: low             # acceptance is machine-checkable (tests/packaging.test.sh + tests/run.sh)
- depends-on: [T-001, T-002]
- parallel-safe: no     # integrates both; touches plugin.json/README/CI that reference all skills
- size budget: < 120 lines
