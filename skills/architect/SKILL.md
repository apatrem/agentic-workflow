---
name: architect
description: Phase 1 — establish architecture & ADRs via an interactive grilling session
---

# /agentic-workflow:architect

Single agent + human. **Never fans out.** Produce the contracts that make Phase 3 safe.

1. Run the bundled **`grill-with-docs`** skill on the proposed design — it walks the decision tree one
   branch at a time (each with a recommended answer, resolving dependencies), challenges the plan
   against the existing `CONTEXT.md` and ADRs, and captures decisions to docs *inline* as they
   crystallize. Explore the codebase to answer questions rather than asking the user what code can
   tell you. (Use the lighter **`grill-me`** skill when there's no domain model to challenge yet.)
2. Decisions land in `docs/adr/NNNN-*.md` and the domain language in `CONTEXT.md`. **For this Phase-1
   step, use the house ADR format — Context / Decision / Consequences with a `Status:` line** — which
   takes precedence over the skill's lighter default `ADR-FORMAT.md`.
3. **The human signs off each ADR.** These ADRs define the protected contracts — record them in `AGENTS.md`'s forbidden/protected section.

Output: committed `docs/adr/*` + `CONTEXT.md`. Stop when the design tree is resolved.
