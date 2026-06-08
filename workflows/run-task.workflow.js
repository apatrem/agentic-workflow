export const meta = {
  name: 'orchestrate-run-task',
  description:
    'Competitive best-of-N for one task: fan out to official CLIs in worktrees, pre-screen, synthesize (Opus), gate on frozen tests, review (Codex), then auto-merge via PR or flag a human. The merge decision is computed in code, never by an LLM.',
  phases: [
    { title: 'Setup' },
    { title: 'Workers' },
    { title: 'Pre-screen' },
    { title: 'Synthesize', model: 'opus' },
    { title: 'Gate' },
    { title: 'Review' },
    { title: 'Finalize' },
  ],
};

// ─────────────────────────────────────────────────────────────────────────
// Inputs (passed by /orchestrate:run as `args`): the loaded config + the task.
//   args = { config: OrchestratorConfig, task: { id, path, risk, mode, dependsOn } }
// The script has no fs/Bash; all side effects happen inside agent() steps, which
// have tools. Worker steps instruct a sub-agent to run the official vendor CLI.
// ─────────────────────────────────────────────────────────────────────────
const { config, task } = args;
const taskId = task.id;
const competitive = task.mode === 'competitive';

// Budget guard: auto-downgrade competitive → solo when near the daily ceiling.
const downgraded =
  competitive && budget.total && budget.remaining() < 250_000;
const workers = downgraded || !competitive ? [config.agents[0]] : config.agents;
if (downgraded) log(`budget low — running ${taskId} as solo`);

// ── Structured-output schemas ────────────────────────────────────────────
const WORKER = { type: 'object', required: ['agent', 'committed'], properties: {
  agent: { type: 'string' }, committed: { type: 'boolean' },
  branch: { type: 'string' }, note: { type: 'string' } } };
const PRESCREEN = { type: 'object', required: ['viable'], properties: {
  agent: { type: 'string' }, viable: { type: 'boolean' }, reason: { type: 'string' } } };
const GATE = { type: 'object', required: ['pass'], properties: {
  pass: { type: 'boolean' }, output: { type: 'string' } } };
const VERDICT = { type: 'object', required: ['blocker'], properties: {
  blocker: { type: 'boolean' },
  issues: { type: 'array', items: { type: 'object' } },
  followups: { type: 'array', items: { type: 'string' } } } };
const DIFF = { type: 'object', required: ['files', 'lines', 'touchesProtected'], properties: {
  files: { type: 'number' }, lines: { type: 'number' },
  touchesProtected: { type: 'boolean' }, paths: { type: 'array', items: { type: 'string' } } } };

// ── THE DECISION — pure code. The only thing that authorizes moving main. ──
function decideAutoMerge({ gate, verdict, diff, risk }) {
  const reasons = [];
  if (!gate.pass) reasons.push('frozen gate red');
  if (verdict.blocker) reasons.push('reviewer raised a blocker');
  if (diff.touchesProtected) reasons.push('touches a protected path');
  if (diff.files > config.diffBudget.files || diff.lines > config.diffBudget.lines)
    reasons.push('exceeds diff budget');
  if (risk !== 'low') reasons.push(`risk=${risk}`);
  return { auto: reasons.length === 0, reasons };
}

// ── Phase 1 — Setup: align main, create ephemeral worktrees + branches ─────
phase('Setup');
await agent(
  `Align main with origin/main (fetch --prune; main worktree must be clean). ` +
  `For each of [${workers.map((w) => w.name).join(', ')}], create an ephemeral ` +
  `branch agent/<name>/${taskId} from origin/main and a worktree for it; write ` +
  `_AGENT_TASK.md (task spec + the shared worker rules from templates/ROLES.md) ` +
  `into each. Also create integrate/${taskId} + its worktree. Abort if dependsOn ` +
  `(${JSON.stringify(task.dependsOn ?? [])}) are not all merged.`,
  { phase: 'Setup', label: 'setup-worktrees' },
);

// ── Phase 2 — Workers: each runs its OFFICIAL CLI in its worktree ──────────
phase('Workers');
const results = await parallel(
  workers.map((w) => () =>
    agent(
      `In the ${w.name} worktree, run the official CLI to implement the task:\n` +
      `  ${w.cli} "Read _AGENT_TASK.md and complete it. Commit locally. Do not push."\n` +
      `Apply the "${w.role}" flavor. Sandboxed: no network, no secrets, no push. ` +
      `Then remove _AGENT_TASK.md and commit the result on agent/${w.name}/${taskId}. ` +
      `Report whether a commit was produced.`,
      { phase: 'Workers', label: `worker:${w.name}`, schema: WORKER },
    ).catch(() => ({ agent: w.name, committed: false, note: 'errored' })),
  ),
);
const candidates = results.filter((r) => r && r.committed);
if (candidates.length === 0) {
  return finalizeNeedsHuman(['zero viable candidates']);
}

// ── Phase 3 — Pre-screen (Cursor, fast/cheap): drop obvious breakage ───────
phase('Pre-screen');
const screened = competitive
  ? (await parallel(candidates.map((c) => () =>
      agent(
        `Fast triage of agent/${c.agent}/${taskId} vs origin/main using ${config.prescreen.cli}. ` +
        `Viable attempt, no obvious breakage? Do not deep-review.`,
        { phase: 'Pre-screen', label: `prescreen:${c.agent}`, schema: PRESCREEN },
      ).then((p) => ({ ...c, viable: p.viable })),
    ))).filter((c) => c.viable)
  : candidates;
if (screened.length === 0) return finalizeNeedsHuman(['all candidates failed pre-screen']);

// ── Phase 4 — Synthesize (Opus, blind-to-author) onto integrate/<task> ─────
phase('Synthesize');
let repaired = 0;
let gate, verdict, diff;
while (true) {
  await agent(
    `On integrate/${taskId}, build the best final implementation of the task, ` +
    `judging candidates [${screened.map((c) => c.agent).join(', ')}] BLIND TO AUTHOR ` +
    `against the spec + frozen tests. Prefer smallest correct. Do not touch protected ` +
    `paths. ${repaired ? 'Address the prior gate/review failure fed back to you.' : ''} ` +
    `Commit locally; do not push.`,
    { phase: 'Synthesize', label: repaired ? `synthesize:repair${repaired}` : 'synthesize',
      model: config.synthesizer.model },
  );

  // ── Phase 5 — Gate: run the FROZEN suite; verify frozen tests byte-intact
  phase('Gate');
  gate = await agent(
    `On integrate/${taskId}: assert the frozen test files are byte-identical to ` +
    `origin/main (fail if an agent altered them), then run: ${config.gate}. Report pass + tail.`,
    { phase: 'Gate', label: 'gate', schema: GATE },
  );

  // ── Phase 6 — Review (Codex, cross-lineage): blockers-only ───────────────
  phase('Review');
  diff = await agent(
    `Diff integrate/${taskId} vs origin/main. Return files, net lines, and whether ` +
    `any path matches protectedPaths: ${JSON.stringify(config.protectedPaths)}.`,
    { phase: 'Review', label: 'diffstat', schema: DIFF },
  );
  verdict = gate.pass
    ? await agent(
        `Using ${config.reviewer.cli}, adversarially review the integrate/${taskId} diff. ` +
        `BLOCKERS ONLY (correctness/security/spec-violation/regression). Nits are followups.`,
        { phase: 'Review', label: 'review', schema: VERDICT },
      )
    : { blocker: false, issues: [], followups: [] };

  const needsRepair = (!gate.pass || verdict.blocker) && repaired < 1; // repair once
  if (!needsRepair) break;
  repaired++;
  log(`repairing ${taskId} (attempt ${repaired}): ${gate.pass ? 'reviewer blocker' : 'gate red'}`);
}

// ── Phase 7 — Finalize: open PR, then auto-merge or flag human (code) ──────
phase('Finalize');
const decision = decideAutoMerge({ gate, verdict, diff, risk: task.risk });
return decision.auto ? await finalizeAutoMerge(verdict) : await finalizeNeedsHuman(decision.reasons, verdict);

// ── Finalize helpers ──────────────────────────────────────────────────────
async function finalizeAutoMerge(verdict) {
  await agent(
    `Push integrate/${taskId} and open a PR to main via gh (body: summary + any ` +
    `followups ${JSON.stringify(verdict?.followups ?? [])}; label "auto-merged"). ` +
    `Wait for CI (canonical re-run of the gate). If green, merge --${config.ci.mergeMethod}. ` +
    `If CI is red, convert to needs-human instead. Then delete the ephemeral branches/worktrees.`,
    { phase: 'Finalize', label: 'auto-merge' },
  );
  return { task: taskId, outcome: 'auto-merged' };
}
async function finalizeNeedsHuman(reasons, verdict) {
  await agent(
    `Push the best branch and open a PR to main via gh, labeled "needs-human". ` +
    `Body: why it stopped (${JSON.stringify(reasons)}), the reviewer notes ` +
    `(${JSON.stringify(verdict?.issues ?? [])}), and how to inspect the candidates. ` +
    `Do NOT merge. Leave worktrees for inspection.`,
    { phase: 'Finalize', label: 'needs-human' },
  );
  return { task: taskId, outcome: 'needs-human', reasons };
}
