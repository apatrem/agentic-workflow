/**
 * Per-repo orchestration config — the ONLY repo-specific artifact.
 * Copy into a target repo's root (via `/orchestrate:init`) and edit.
 * The example values below are for the `jayson-docs` repo — replace them.
 */
export interface OrchestratorConfig {
  /** Deterministic acceptance gate. Must exit non-zero on any failure. */
  gate: string;

  /**
   * Globs that ALWAYS route to a human (never auto-merge). Lock the contracts
   * and — critically — the gate itself, so an agent can't weaken its own judge.
   */
  protectedPaths: string[];

  /** Runaway detector. Diffs beyond this go to a human regardless of green. */
  diffBudget: { files: number; lines: number };

  /** Competitive workers. Heterogeneous on purpose. */
  agents: Array<{ name: string; cli: string; model?: string; role: string }>;

  synthesizer: { cli: string; model: string; effort?: string };
  reviewer: { cli: string; model?: string };
  prescreen: { cli: string };

  ci: { provider: "github"; mergeMethod: "squash" | "merge" | "rebase" };

  /** Daily token budget; competitive tasks auto-downgrade to solo when near. */
  budget?: { dailyTokens: number };
}

const config: OrchestratorConfig = {
  gate: "npm run build && npm run lint && npm test && npm run validate",

  protectedPaths: [
    // core LLM-boundary contract (layouts/** is intentionally NOT protected)
    "src/schema/index.ts",
    "src/schema/chart.ts",
    "src/schema/block.ts",
    "src/schema/slide.ts",
    "src/schema/brand.ts",
    // the gate + build/deps — an agent must never weaken its own judge
    ".github/**",
    "package.json",
    "package-lock.json",
    "tsconfig.json",
    "vitest.config.ts",
    "eslint.config.mjs",
    "tests/**", // frozen acceptance tests are immutable (add new tests elsewhere)
    // brand / master ground truth
    "src/brand/brand.yaml",
    "templates/**",
    // Phase-1 contracts
    "docs/DECISIONS_LOG.md",
    "docs/ARCHITECTURE.md",
    "CONTEXT.md",
    "AGENTS.md",
  ],

  diffBudget: { files: 25, lines: 1000 },

  agents: [
    { name: "claude", cli: "claude -p",                           model: "sonnet", role: "cleanest" },
    { name: "codex",  cli: "codex exec --sandbox workspace-write",                  role: "most test-driven" },
    { name: "cursor", cli: "cursor-agent -p",                                       role: "smallest diff" },
  ],

  synthesizer: { cli: "claude", model: "opus", effort: "xhigh" },
  reviewer:    { cli: "codex",  model: "high" }, // cross-lineage vs the Opus synthesizer
  prescreen:   { cli: "cursor-agent" },

  ci: { provider: "github", mergeMethod: "squash" },

  budget: { dailyTokens: 5_000_000 },
};

export default config;
