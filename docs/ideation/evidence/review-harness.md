# Review: the measurement harness (ideation/harness 04f5beb..f7a30eb, Step 1 Track A)

A fresh scope reviewer, 9 Nov 2026. 28 items: 14 keep, 5 cut, 3 simplify, 6 ask. Moves the problem partly. Pooled shape and outcome metrics are honest enough for the sweep, but line and tribe ranking and engine questions are not ready yet.

**Verified correct:**
- exact re-fights (469 planted fights; 59,117 Health checks and all 500 winners in the offline replay);
- the percentiles, seed bootstrap, comeback and tier-arrival logic, field weights and power calculations.

**Cuts (all sent to the worker):**
1. **The orchestrator's redefined test (b) can't fail.** It takes a max over a set that includes Hard. Restore a real (b) against `hard_field`.
2. **The original (b) runs were unequal.** Blind lines played Hard with scouting and a 20-fight placement search. So "tribal lines lose because the pool rewards no commitment" was unsupported. Re-run against `hard_field`.
3. **The null arm planted nothing.** It was a determinism check. Plant a real do-nothing card.
4. **Line field rates rested on 1–4 boards each,** with no interval. Stratify the field, add board-cluster intervals, and rank lines on lobby placement.
5. **HARNESS.md credited the owner with the gate change.** It was the orchestrator's call.

**The orchestrator's calls on the asks:**
- `after_start_effects` gets a reader (metrics use post–Start of Combat stats).
- Knob tuning is dropped (noise at feasible budgets).
- The sweep's engine, economy, doubler and tribe reads are gated on the lever-build (b).
- An engine dose ladder and a pool-planted engine run before the engine dial.
- Upsets are split by cause.
- A designed-board input is added to the field (owner 9d).
- A curvature test replaces R², because the old flat check passed 15% compounding a round.
- One metrics format.

**Lesson for the orchestrator:** I reframed a failing known-answer test without checking that the new version could fail. A reframed test must still be able to fail.
