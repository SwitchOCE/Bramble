# Content guardrails

Rules for content design: what units, spells and modifiers must not do, or must only do carefully. These guardrails stand in for system-level limits. The owner's principle, from [owner-notes/archive/2026-10-27f-power-budget-decisions.md](owner-notes/archive/2026-10-27f-power-budget-decisions.md):

> Not every problem needs a system to prevent it, we can have content safeguards as well.

Each guardrail names the risk it guards against and where it came from.

## G1. Free and triggered refreshes can't chain without end

**Rule (owner's wording, 2 Nov 2026):** "G1. Free and triggered refreshes can't chain without end. Any refresh the player doesn't pay for (a free Refresh, or an effect that refreshes the shop) must be limited so that an endless chain is mathematically impossible: on the strongest legal board, the expected number of unpaid refreshes each shop leads to stays well below 1. A rare card that gives a few is fine; a common trigger such as 'when sold, refresh the shop' on most shop units is not. Purpose: unpaid refreshes skip the rising price, so with no turn timer they are the one way a turn could run forever."

**Risk:** free refreshes don't count toward the refresh-cost steps (rulebook 4.4.5). A repeatable free refresh, combined with retriggers, can loop without limit. In Battlegrounds, a refresh anomaly combined with golden Brann and Battlecry retriggers did exactly this.

**Guardrail:**
- Free refreshes come only from sources that can't be retriggered or repeated cheaply. Examples: a once-per-turn effect, a one-off spell, or an effect that can't stack with retriggers.
- Any card or modifier that grants free refreshes is reviewed against every retrigger effect in the pool.

**Source:** owner decision, 27 Oct 2026; reworded and widened to effect refreshes by the owner, 2 Nov 2026 (owner-notes/archive/2026-11-02d-refresh-schedule-and-free-refreshes.md). The paid refresh price (rulebook 4.4) is the primary guardrail against infinites; G1 covers the refreshes that skip it.
