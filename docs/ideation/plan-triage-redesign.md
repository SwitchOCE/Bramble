# Plan: fix what the triage audit found (8 Nov 2026)

## The problem

- **Playtest round 5 on build 7:** four of five fresh players said "okay" and one said "good". None said "very good".
- **The cross-round tally:** `evidence/triage-audit.md` §1 counts 17 reports. Losses snowball (14). One huge unit or stat pile decides games, and committing to a tribe doesn't pay (11). Birds are a trap (8). Ring piles (7). Rainbow Chaser is too strong (6). Hunters are flat early (6). Gold-only units are traps (4). No-room failures (3). Knockouts come in bursts (3).
- **The owner's words** (`owner-notes/2026-11-08f-birds-case-study.md`):
  - "I can't see why you would play the early-game Birds over other cards in the game."
  - "You have to have some synergy that gets you there along the entire journey."
  - "We should have an even number of cards for every tribe and an even tier distribution."
  - "If it's not fulfilling its primary purpose, then it's always useless and it becomes a trap."
  - On journeys: "a lot of problems actually come from skips", and "we still want there to be discovery rather than planning a tribe to be formulaic."
  - On benchmark boards: "a guesstimate gives you at least something to triage against."
- **Already in flight, outside this plan:** fight-log and text clarity on `ideation/feedback5`, Sol worker w20.

## Steps

1. **Losses snowball: make the v0.5 damage rule the default (arm D).** It's built and gated on `ideation/damage` (526246c). In sims it moved the first knockout from round 9 to 12 and comebacks from 22% to 30%. All arms miss T2, the game-length target. Merge it, flip the default, and re-run 200 lobbies against the current rule to check the burst knockouts. Add one guard if bursts persist: when several heroes would go out in the same round, take the lowest out first. Fresh review before merge. *Moves: tally 2, 7, 19.*
2. **Benchmark boards (the owner's idea).**
   - For each tribe and its main sub-varieties: a board at rounds 3, 6, 9 and 12, each as average, high roll and low roll.
   - Each board lists its assumptions: gold spent, tier, and the cards found.
   - Fight them round-robin in the engine (`tools/sim/`, a small script plus a JSON of boards). Output a table of each tribe's win rate at each round against the field.
   - This gives the baseline, and the same table is re-run after step 4.
   - A fresh agent who isn't the designer writes the boards from the pool. *Moves: says which stage of which tribe is behind, and how far.*
3. **Redesign the failing roles (cloud designers, briefed without the power budget).**
   - Inputs: the audit's §2 failures and §3 journey breaks, plus the step 2 table.
   - Order by tally count:
     - Birds: an early reason to own Nests, a second T5.
     - Rainbow Chaser and Ring piles: a per-slot Ring cap. Chaser's growth or sale is bounded.
     - Gold-only units: each pays in stats too, or in something you can turn the gold into this turn. Covers Nip, Toll-Bard, Lutra, Peat Cutter, Busker, Money Spider, Pennywort.
     - Hunters: early tempo, a T6.
     - Hedgerow folk: T5 and T6 payoffs that grow bodies.
     - Oozes: a T2 enabler, a T5 body, a stronger top.
     - Bog folk: a T6, an earlier Mire.
     - Fairies: one T3 that isn't a Ring source.
     - Heroes: Hob Mumblecrust, Brother Bracken, Mousewife.
   - Parity: 20 shop cards per tribe at 4/4/4/3/3/2. Cut first from the audit's failures. The Worker Bee moves to neutrals.
   - Each card keeps its idea where it can (rule F).
   - Each tribe keeps several sub-varieties, with no single formula.
   - Then one costing reviewer (buy-moment method plus step 2 boards) and one triage reviewer (the skill's role and journey checks). Both are fresh. Where they agree, act; where they split, I decide and log it. *Moves: tally 3, 4, 5, 6, 8, 12, and the owner's Birds problem.*
4. **Build the redesign (Sol, one branch).** Rules and content, portraits for new cards, and a wording pass to the guide. Then the gate, a 200-game soak, and a re-run of the step 2 table. Per-tribe bars on free-choice bots: each tribe's pick rate is 8–25% and its win rate 8–20% in 500 lobbies. Fresh scope review before merge. *Moves: proves step 3 in the engine.*
5. **Build 8 and playtest round 6.** Five fresh players, with the same lenses as round 5 plus a Birds lens. *Moves: the playtest bar.*

## Checkpoints

- After step 2: does the table agree with the audit and with the playtests? If it doesn't, fix the boards or the audit before designing.
- After step 4: the step 2 table and the per-tribe bars. A tribe still behind goes back to step 3 for that tribe only.
- After step 5: the playtest verdicts. Tally the round-6 problems into the cross-round table.

## Not in this plan

Calibrating the process against Battlegrounds data stays parked (owner: only "if we don't get significant improvement"). Bot adaptation (3 reports) waits until after build 8.
