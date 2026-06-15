# T-002: `bin/install.sh` — idempotent symlink installer (+ optional `setup` skill shim)

<!-- Phase 2 output. Implements ADR-0007 (2026-06-15): distribution = symlink, installer is code not an LLM call. -->

## Objective
Make the repo's skills globally discoverable by all three Driver seats with a single command, keeping the
repo the one source of truth. A shell script symlinks each `skills/<name>` into the shared global skill
dirs; re-running is safe; a pre-existing *diverged real copy* (e.g. today's `~/.agents/skills/grill-me`)
is replaced by a symlink so divergence can't recur.

## Acceptance criteria  (must be machine-checkable)
- [ ] `bin/install.sh` symlinks every `skills/<name>` into `~/.agents/skills`, `~/.codex/skills`, and
      `~/.claude/skills`, each link pointing at the repo's absolute `skills/<name>`. → `tests/install.test.sh`
- [ ] Target dirs are derived from `$HOME` (so the test can sandbox it); missing dirs are created. → `tests/install.test.sh`
- [ ] Re-running exits 0 and leaves correct links (idempotent); a pre-existing **real** dir/file at a target
      path is converted to a symlink. → `tests/install.test.sh`
- [ ] `skills/setup/SKILL.md` exists (frontmatter `name: setup`), body `Run \`bin/install.sh\`.` (thin front door)
- [ ] gate green: `bash tests/install.test.sh`

## Files likely involved
- `bin/install.sh` (new, executable)
- `skills/setup/SKILL.md` (new)

## Out of scope
- Listing skills in `plugin.json` / README / CI (→ T-003).
- Converting the phase commands (→ T-001).

## Risks / do-not-touch
- **Do not edit the frozen tests** (`tests/*`).
- **Do not touch** `commands/`, the phase skills `skills/{architect,plan,run,review,init}/`, `plugin.json`, `README.md`.
- Installer must use `ln -sfn` + `mkdir -p` (idempotent); resolve its own repo root from the script path
  (`$(cd "$(dirname "$0")/.." && pwd)`), **never** hardcode `~` paths the test can't sandbox.
- macOS `bash` 3.2 compatible (no `mapfile`, no associative-array requirement).

## Meta
- mode: low             # deterministic plumbing, fully testable
- risk: low             # acceptance is machine-checkable (tests/install.test.sh)
- depends-on: []
- parallel-safe: yes    # disjoint from T-001 (commands/, phase skills); T-003 depends on this
- size budget: < 100 lines
