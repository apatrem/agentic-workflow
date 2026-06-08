---
description: Phase 1 — establish architecture & ADRs via an interactive grilling session
---

# /orchestrate:architect

Single agent + human. **Never fans out.** Produce the contracts that make Phase 3 safe.

1. Run an interactive grill-me session on the proposed design — walk the decision tree one branch at
   a time, each with a recommended answer, resolving dependencies. Explore the codebase to answer
   questions rather than asking the user what code can tell you.
2. As decisions crystallize, write them to `docs/adr/NNNN-*.md` (Context / Decision / Consequences)
   and update `CONTEXT.md` with the domain language.
3. **The human signs off each ADR.** These ADRs define the protected contracts for `orchestrator.config.ts`.

Output: committed `docs/adr/*` + `CONTEXT.md`. Stop when the design tree is resolved.
