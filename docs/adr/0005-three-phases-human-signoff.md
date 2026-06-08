# ADR 0005 — Three phases; humans gate Phases 1–2; competition only in Phase 3

**Status:** accepted

## Context
Phase 3's safety is *manufactured* upstream: ADRs become the protected contracts; the plan produces
the frozen tests, risk tiers, and protected-path list. You fan out *implementation* against a frozen
spec; you do not fan out the spec.

## Decision
- **Phase 1 — Architect:** single agent + human, interactive (grill-me) → `docs/adr/*` + `CONTEXT.md`.
  The human signs each ADR.
- **Phase 2 — Plan:** single agent + human → `tasks/*.md`, each with frozen tests, `risk`, `mode`,
  `depends-on`. The human sign-off here is the **primary control point**.
- **Phase 3 — Run:** the only phase that fans out and the only phase that touches `main`.

## Consequences
- Competition is reserved for implementation, where diversity pays and a gate exists one level up.
- Cheap, high-leverage human judgment is concentrated where it matters; the loop runs autonomously after.
- Three agents writing three architectures (no gate above them) is explicitly rejected.
