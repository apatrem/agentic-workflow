---
description: Scaffold the baseline agentic-coding conventions into the current repo
---

# /agentic-workflow:init

Set the current repo up to follow the workflow (ADR-0001). Do **not** overwrite existing files; report and skip.

1. **`AGENTS.md`** from `templates/AGENTS.template.md` — fill the overview, the **one gate command**, the forbidden/protected paths, and the review checklist. (If `AGENTS.md` exists, just check it has those sections.)
2. thin **`CLAUDE.md`** (`templates/CLAUDE.template.md`) + **`.cursor/rules/conventions.mdc`** (`templates/cursor-conventions.mdc`) — both point to AGENTS.md.
3. **`tasks/`** + `templates/task.template.md`.
4. **`.pre-commit-config.yaml`** from `templates/pre-commit-config.yaml`; tell the user to run `pipx install pre-commit && pre-commit install`.
5. **CI + protected main:** ensure a CI workflow runs the gate; print the `gh api … /branches/main/protection` command to require the check + a PR (human merges).
6. Point the user to `docs/WORKFLOW.md`. **Engine setup is separate** (Composio): `npm install -g @aoagents/ao`, then `ao start`.
