---
description: Scaffold orchestration into the current repo (config, tasks dir, git rules)
---

# /orchestrate:init

Set up the current repo to use agent-orchestrator. Do **not** overwrite existing files; report and skip.

1. Copy `templates/orchestrator.config.ts` to the repo root. Infer sensible defaults:
   - `gate`: detect the stack (package.json scripts / Makefile) and assemble build+lint+test+typecheck.
   - `protectedPaths`: pre-fill with `.github/**`, lockfiles, build/test config, `tests/**`, and any
     obvious contract files (schemas, public API, migrations). Ask the user to confirm.
   - `diffBudget`: default `{ files: 25, lines: 1000 }`.
   - `agents` / `synthesizer` / `reviewer` / `prescreen`: the official-CLI defaults.
2. Create `tasks/` with `templates/task.template.md` copied in as `tasks/EXAMPLE.md`.
3. Append `templates/AGENT_RULES.md` into `CLAUDE.md` and `AGENTS.md` (create if absent).
4. Verify prerequisites are installed + logged in: `claude`, `codex`, `cursor-agent`, `gh`. Report any missing.
5. Print next steps: run `/orchestrate:architect`, then `/orchestrate:plan`, then `/orchestrate:run`.
