# Plan: fix what the triage audit found (8 Nov 2026, revised after the plan review)

The plan review is `evidence/plan-interrogate-triage.md`; my calls on it are in DECISIONS.md.

## The problem

- **Playtest round 5 on build 7:** four of five fresh players said "okay" and one said "good". None said "very good".
- **The cross-round tally:** `evidence/triage-audit.md` §1 counts 17 reports.
  - Unclear rules or log (14).
  - Losses snowball (14).
  - One huge unit decides games, and committing to a tribe doesn't pay (11).
  - Birds are a trap (8).
  - Ring piles (7).
  - Rainbow Chaser is too strong (6).
  - Last four drag or swing (6).
  - Hunters are flat early (6).
  - Gold-only units are traps (4).
  - Hedge Witch reaches Hex 8 (4).
- **The owner's words** (`owner-notes/2026-11-08f-birds-case-study.md`):
  - "I can't see why you would play the early-game Birds over other cards in the game."
  - "You have to have some synergy that gets you there along the entire journey."
  - "We should have an even number of cards for every tribe and an even tier distribution."
  - "If it's not fulfilling its primary purpose, then it's always useless and it becomes a trap."
  - On journeys: look for skips, and "discovery rather than planning a tribe to be formulaic."
  - On benchmark boards: "a guesstimate gives you at least something to triage against."

## Steps

At most two code branches are open at once. Every merge passes the gate and a fresh review.

1. **Damage: arm B becomes the default.** `ideation/damage` has the schedule 0,0,0,1,1,2,2,3,4,5,7,9,11,13 at 40 Health, with no toll.
   - Merge it and flip the default.
   - Count same-round knockouts from the existing `damage-v05/` data for B and the baseline. Add no burst guard unless bursts persist.
   - Update the damage page and how-to-play text to the wording guide.
   - *Moves: tally 2, 7, 19.*
2. **Measure before designing.**
   - (a) Free-choice bots: one mode with equal tribe priors that buys what the shop offers, for the per-tribe bars.
   - (b) A parity check in `check.sh`, reporting the shop-pool count and tier spread per tribe. It warns now and fails once pass 2 lands.
   - (c) Benchmark boards: one main line per tribe at rounds 3, 6, 9 and 12, each as average, high roll and low roll, with their assumptions written down. A fresh agent writes them. They fight round-robin in the engine.
   - Baseline table: benchmark win rates plus free-choice pick and win rates per tribe.
   - **Checkpoint:** does the table agree with the audit and the playtests?
3. **Pass 1: design, build and test.**
   - Birds: an early reason to own Nests, a second T5, 20 cards at 4/4/4/3/3/2.
   - Rainbow Chaser bounded.
   - A per-slot Ring cap.
   - Hedge Witch's Hex bounded.
   - Gold-only units pay in stats too, or in something you can spend this turn: Little Nip, Toll-Bard, Old Lutra, Peat Cutter, Busker, Money Spider, Pennywort.
   - Heroes: Hob Mumblecrust, Brother Bracken, Mousewife.
   - Process:
     - **Design:** cloud designers get the card's role, its window and the cards it competes with, not the budget.
     - **Review:** one fresh costing reviewer (buy-moment method plus the benchmark boards) and one fresh triage reviewer.
     - **Build:** Sol builds it on one branch.
   - Then the gate, a 200-game soak, a re-run of the step 2 table, and one fresh agent who plays Birds through rounds 1–6 and answers the owner's question.
   - **Checkpoint:** Birds' free-choice bar is met and the agent's verdict is in.
4. **Pass 2: the other breaks and parity, on its own branch.**
   - Hunters: early tempo, a T6.
   - Hedgerow folk: T5 and T6 payoffs that grow bodies.
   - Oozes: a T2 enabler, a T5 body, the top.
   - Bog folk: a T6, an earlier Mire.
   - Fairies: a T3, Shy.
   - Charcoal Burner, if the step 2 table flags it.
   - The scripted early rounds (tally 9) and thin supply (14), as the benchmark boards show them.
   - Every tribe at 20 cards, 4/4/4/3/3/2. The Worker Bee moves to neutrals.
   - The parity check now fails the gate.
   - Same review, build and measure as pass 1.
5. **Build 8 and playtest round 6.**
   - Gate: `ideation/feedback5` (clarity, tally 1) is merged first.
   - Five fresh players, with round 5's lenses plus a Birds lens and a damage-and-length lens.
   - Their problems join the cross-round tally.

## Deferred, logged

- Bot adaptation (3 reports): after build 8.
- The difficulty ladder (4 reports): obsolete, because there's only one strength since 8 Nov.
- Battlegrounds calibration: parked unless triage doesn't bring a significant improvement (owner).
