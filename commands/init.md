---
description: Scaffold the baseline agentic-coding conventions into the current repo
---

# /agentic-workflow:init

Set the current repo up to follow the workflow (ADR-0001). Do **not** overwrite existing files; report and skip.

1. **`AGENTS.md`** from `templates/AGENTS.template.md` — fill the overview, the **one gate command**, the forbidden/protected paths, and the review checklist. (If `AGENTS.md` exists, just check it has those sections.)
2. thin **`CLAUDE.md`** (`templates/CLAUDE.template.md`) + **`.cursor/rules/conventions.mdc`** (`templates/cursor-conventions.mdc`) — both point to AGENTS.md.
3. **`tasks/`** + `templates/task.template.md`.
4. **`.pre-commit-config.yaml`** from `templates/pre-commit-config.yaml`; tell the user to run `pipx install pre-commit && pre-commit install`.
5. **CI + protected main:** ensure a CI workflow runs the gate — for a Node repo, lay down `.github/workflows/ci.yml` from `templates/ci.yaml` (it uses Corepack + pnpm). Then print the `gh api … /branches/main/protection` command to require the check + a PR (human merges).
6. **Node setup — standardize on pnpm (Corepack):** if this is (or will be) a Node repo, write `package.json` from `templates/package.template.json` with `packageManager: "pnpm@<version>"` so every clone, worktree, and CI run uses the same pnpm. Commit `pnpm-lock.yaml`; do **not** also commit `package-lock.json` / `yarn.lock`. (Skip for non-Node repos.)
7. **Repo-level AO config:** write `agent-orchestrator.yaml` from `templates/agent-orchestrator.template.yaml` and fill `runtime` / `agent` / `workspace` / `worker.agent` and the `agentRules` gate. Its `postCreate` (`corepack enable` + `pnpm install --prefer-offline --frozen-lockfile`) bootstraps deps fast in each new worktree — pnpm hardlinks from its global store, so a worktree costs ~no extra disk instead of a full `node_modules` copy. The commented `permissions: permissionless` is opt-in (skips Claude Code's per-worktree trust dialog for sandboxed worktrees).
8. Point the user to `docs/WORKFLOW.md`. **Engine setup is separate** (Composio): `npm install -g @aoagents/ao`, then `ao start`.
