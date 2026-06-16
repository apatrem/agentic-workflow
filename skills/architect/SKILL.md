---
name: architect
description: Phase 1 — establish architecture & ADRs via an interactive grilling session. Use when starting a new project or feature, or amending architecture, and you need to settle and record durable decisions (ADRs + CONTEXT.md) before any code.
---

# /agentic-workflow:architect

Single agent + human. **Never fans out.** Produce the contracts that make Phase 3 safe.

**Grilling is a bounded, high-signal decision-discovery phase — run it well:**
- **Chunk the scope first.** Split large work into smaller grillable slices and grill each separately; one
  oversized session hides high-fidelity questions and pushes the model into context-rot (the ~120k-token
  "dumb zone"). Same fresh-context discipline the orchestrator uses in Phase 3.
- **Low- vs high-fidelity.** Grilling settles *low-fidelity* decisions (data shapes, trade-offs, conventions,
  interfaces). A *high-fidelity* question — UI feel, ergonomics, runtime behaviour — can't be answered by
  discussion: **spike a throwaway prototype, then grill against it.** Don't force an ADR out of a question
  grilling can't settle.
- **Stop when the next useful step is to build.** Over-grilling is its own over-engineering — stop when the
  design tree is resolved, or when the remaining questions need higher fidelity (prototype), then freeze tests
  and implement.
- **Use a frontier model in the Driver seat** — grilling/planning is the *parametric-knowledge* phase
  (`docs/MODELS.md`), not the cheap implementer.

1. Run the bundled **`grill-with-docs`** skill on the proposed design — it walks the decision tree one
   branch at a time (each with a recommended answer, resolving dependencies), challenges the plan
   against the existing `CONTEXT.md` and ADRs, and captures decisions to docs *inline* as they
   crystallize. Explore the codebase to answer questions rather than asking the user what code can
   tell you. (Use the lighter **`grill-me`** skill when there's no domain model to challenge yet.)
2. Decisions land in `docs/adr/NNNN-*.md` and the domain language in `CONTEXT.md`. **For this Phase-1
   step, use the house ADR format — Context / Decision / Consequences with a `Status:` line** — which
   takes precedence over the skill's lighter default `ADR-FORMAT.md`.
3. **The human signs off each ADR.** These ADRs define the protected contracts — record them in `AGENTS.md`'s forbidden/protected section.
4. **Governance changes are `medium` by default (AW-0004 risk floor).** Amendments to the decision record or
   conventions — `docs/adr/*`, `CONTEXT.md`, the `AGENTS.md` conventions, or this pack's own skills/templates —
   are high-blast-radius and have repeatedly shipped incoherent when authored solo. **Ship them via PR with a
   cross-lineage review before a human merges**, even when you author them directly (no worker spawn, so no
   `mode` field — `medium` here *is* "PR + cross-lineage dual review first"). Routine prose (typos, examples,
   comments) is not governance and stays `low`.

Output: committed `docs/adr/*` + `CONTEXT.md`. Stop when the design tree is resolved.
