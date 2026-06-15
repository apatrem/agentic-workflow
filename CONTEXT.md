# agentic-workflow

The shared vocabulary of the agentic-workflow pack itself — the roles and seats the process is described in. Glossary only; mechanics live in `docs/` and `docs/adr/`.

## Language

**Driver seat**:
A tool a human uses to *run* the interactive workflow — grilling, planning, and invoking run/review. The pack targets three: **Claude Code**, **Codex**, and **Cursor** (CLI or app). A Driver seat must have the skills installed.
_Avoid_: host, cockpit, client, IDE.

**Worker**:
A spawned agent that *implements or reviews* a task in its own worktree and reads the repo's `AGENTS.md`. A Worker never drives — it has no skills/commands, only the wrapped prompt + AGENTS.md.
_Avoid_: agent (too generic), bot, runner.

**Orchestrator**:
The role (not a tool) that runs the process from a Driver seat — spawns Workers, gates and PRs their output, synthesizes reviews. Distinct from the **Driver seat**, which is the *tool* the Orchestrator runs in.
_Avoid_: driver, coordinator, manager.

**Lineage**:
A model family / vendor line a Worker or reviewer belongs to — **cursor** (Composer), **codex** (GPT), **claude** (Opus/Fable). The unit across which independence and best-of-N are reasoned (ADR-0004).
_Avoid_: vendor, provider, model (a model is an instance of a lineage), tool.

**Skill**:
A portable `SKILL.md` (name + description frontmatter + prompt body) discovered by all three Driver seats from shared global dirs (`~/.agents/skills`, `~/.codex/skills`, `~/.claude/skills`). The canonical unit of distribution for this pack (ADR-0007 Update).
_Avoid_: plugin (a plugin is one delivery channel), command (a command is the Claude-only typed alias of a skill), adapter.

## Flagged ambiguities

- **Driver seat vs Orchestrator** — the seat is the *tool* (Cursor); the Orchestrator is the *role* running in it. The same human in Cursor is "driving from the Cursor seat as the Orchestrator."
- **Lineage vs model** — `cursor`/`codex`/`claude` are lineages; `Composer 2.5`/`GPT-5.5`/`Opus 4.8`/`Fable 5` are models. Independence (ADR-0004) is reasoned at the lineage level; the clean-lens nuance is at the model level.

## Example dialogue

> **Dev:** Can I grill from Cursor, or only Claude Code?
> **Maintainer:** Any Driver seat — Claude Code, Codex, or Cursor. They all discover the grill **skill** from the shared `~/.agents/skills` dir.
> **Dev:** And the codex agent that writes the code?
> **Maintainer:** That's a **Worker**, not a Driver seat. It only needs `AGENTS.md`; it doesn't load the skills.
> **Dev:** So if `hard` runs codex *and* cursor as implementers, that's two lineages?
> **Maintainer:** Right — two **lineages** authoring, claude held out as the clean reviewer. The seat you *drive* from is independent of which lineages do the work.
