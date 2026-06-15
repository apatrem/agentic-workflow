# ADR 0007 — Packaging: a plugin with a central engine; per-repo is decisions + config only

**Status:** accepted

> **Update (2026-06-15b) — baseline ADRs are adopted *by reference* (`AW-NNNN`), never copied.** The
> Decision below lists "the ADRs" as per-repo state — but the **baseline** ADRs (the 0001–0011 in *this*
> repo: backbone, human-merge, effort dial, remediation loop, minimalism lens, …) are central conventions,
> and the Context above already warns that *anything copy-pasted per repo drifts*. Two real adoptions proved
> both failure modes: **jayson-docs** copied baseline `0001`–`0009` byte-for-byte → they froze stale
> (Composio, missing `0010`/`0011`) **and** burned its ADR number space (its first domain ADR would now
> collide with the still-growing baseline). **jayson-editor** instead kept all of `0001`–`0023` for its
> **own domain** decisions and adopted the baseline via a single pointer ADR — **no drift, no collision.**
> jayson-editor's model wins. Therefore:
> - **The baseline ADRs live only here and are cited `AW-NNNN`** (e.g. `AW-0010` = remediation loop). The
>   `AW-` namespace makes a cross-repo citation unambiguous — bare "`ADR-0010`" means *this repo's* `0010`
>   in one repo and a domain decision in another. Within this repo, `0010` and `AW-0010` are the same thing.
> - **Consuming repos adopt by *reference*, not copy.** A repo keeps its `docs/adr/` for its **own domain
>   decisions in its own number space**, and *references* `AW-NNNN` wherever a baseline convention applies
>   (the way `jayson-editor/.../0023-adopt-agentic-workflow…` points at the pack). **No baseline ADR file is
>   copied into a consuming repo.**
> - **Each repo records a version stamp** — `agentic-workflow-baseline: <highest AW-NNNN adopted>` in its
>   `AGENTS.md` — so "are we current?" is a one-line diff against this repo's max, not an archaeology dig.
> - **Copy-adoption is retired.** A repo already on the copy model (jayson-docs) migrates: delete the copied
>   baseline files, replace with the reference + version stamp, freeing its number space for domain ADRs.
> This refines — does not contradict — the Decision: *domain* decisions are still genuinely per-repo; only
> the *baseline* moves from "copied per repo" to "referenced by `AW-NNNN`," which is the no-drift invariant
> this ADR has wanted all along.

> **Update (2026-06-15) — distribution goes cross-CLI: portable `SKILL.md` skills, not a Claude-only plugin.** The original "ship as a Claude Code plugin" is narrowed to *one delivery channel among several*. The pack now targets three **Driver seats** — **Claude Code, Codex, and Cursor** (CLI or app; see `CONTEXT.md`) — because all three discover skills in the **same `SKILL.md` format** from overlapping global dirs (`~/.agents/skills`, read by Cursor globally; `~/.codex/skills`; `~/.claude/skills`). So:
> - **Canonical source = the repo's `skills/` (`SKILL.md`).** The phase commands (`architect/plan/run/review/init`) are **converted to skills** so every invokable is portable; the two grills already are.
> - **Distribution = an idempotent installer that *symlinks*** repo skills into the shared global dirs (`~/.agents/skills` hub → `~/.codex/skills` + `~/.claude/skills`). The repo stays the **single source**; symlinks keep every seat live with **no per-tool build and no drift** — honouring this ADR's core invariant by a *simpler* mechanism. **The installer is a shell script (`bin/install.sh`), not a setup *skill*** — symlinking is deterministic plumbing, so it is *code, never an LLM call* (idempotent via `ln -sfn`; testable in CI against a temp `$HOME`). An optional thin `setup` skill (body: *“Run `bin/install.sh`.”*) is the discoverable front door — the same shim pattern as the slash sugar. (A one-time global installer run *from* the pack is the delivery mechanism, **not** per-repo copied engine code — consistent with this ADR's "no copied scripts per repo".)
> - **`.claude-plugin` is kept only as optional sugar** for the typed `/agentic-workflow:` slash namespace — no longer the distribution mechanism. **Mechanics:** the plugin ships the *same* `SKILL.md` skills (so the Claude seat behaves like Codex/Cursor) **plus thin command shims** — each `commands/<name>.md` is a one-line alias whose body is just *“Use the `<name>` skill.”*, so the prompt text lives **only** in the skill (single source; nothing to fork or drift). Typing `/agentic-workflow:run` and invoking the `run` skill resolve to the same body. The shims are **optional and Claude-only** — a Claude user who prefers skill-invocation can ignore them; Codex/Cursor never see them.
> - **Per-repo conventions unchanged:** `AGENTS.md` + templates are still scaffolded per repo by `/init` (already cross-tool). **Workers** need only `AGENTS.md`; this change is about **Driver seats**.
>
> **Rejected:** (a) *generated per-tool plugin adapters* (`.codex-plugin`/`.cursor/`) — unnecessary once we found the `SKILL.md` format is already universal and the dirs are shared (it would translate a format that needs no translation); (b) *lowest-common-denominator AGENTS.md-only* — can't carry the interactive grilling/planning skills. The decision below stands; "Claude Code plugin" now reads as "portable skills + an optional Claude plugin."

## Context
The strategy must be reusable across repos. Anything copy-pasted per repo drifts, and you lose the
ability to fix the engine once for everyone.

## Decision
Ship as a **Claude Code plugin** (conventions + role prompts + the `/agentic-workflow:*` commands + a
scaffolder), versioned centrally and riding on the external engine (ADR-0002). **Per-repo state is
only** the ADRs / `AGENTS.md` / `CONTEXT.md`, the `tasks/`, and the acceptance tests. **Zero engine
code copied per repo → no drift.** (Not a template repo, not copied scripts, not a standalone CLI —
those undermine central improvement or contradict ADR-0002.)

## Consequences
- One engine improves everywhere; repos stay independent and auditable.
- If the external engine is ever swapped, the backbone (ADR-0001) and these conventions are unaffected.
