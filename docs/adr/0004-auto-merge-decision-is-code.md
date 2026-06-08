# ADR 0004 — The auto-merge decision is code, with latitude

**Status:** accepted

## Context
"Merge autonomously if possible, else flag a human" requires a precise rule for *if possible*.
"Tests green" alone is insufficient. The user's posture is wide latitude with a few hard tripwires.

## Decision
Auto-merge **iff all** hold, else open a `needs-human` PR — computed by **plain code**, never an
LLM call (the LLM emits structured findings; code decides):
1. frozen gate green (ADR-0002),
2. reviewer returns no blocker (ADR-0003),
3. no **protected path** touched,
4. within **diff budget** (runaway detector),
5. task `risk: low`.

Convergence among workers is logged as a confidence signal, not required. Protected paths lock the
**contracts and the gate itself** (so an agent can't weaken its own judge); `src/schema/layouts/**`
is deliberately *not* protected so additive layout work flows. The per-task `risk` tier is the dial
that gives or withholds latitude without touching the engine.

## Consequences
- The one dangerous action (moving `main`) sits behind deterministic logic the model can't talk past.
- Latitude is tuned via the protected-path list, diff budget, and per-task `risk` — not by weakening the gate.
