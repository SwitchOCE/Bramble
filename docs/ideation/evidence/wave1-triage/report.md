# Wave 1 triage: real boards far below paper

## Symptom

This compares the real R12 median with paper across 640 lobbies:

| Line | Real vs paper | Ratio |
|---|---|---|
| Birds Homecoming | 270 vs 615 | 0.44x |
| Birds Tempo | 260 vs 361 | 0.72x |
| Fairies Ring | 142 vs 530 | 0.27x |
| Fairies Court | 160 vs 945 | 0.17x |

- Fairy engine pieces are on the R12 board in only 30-60% of committed games.
- Lobby growth from R8 to R14 is x1.29 a round. Checkpoint 1 needs x1.3.
- Birds lead the lobby: 1.9x the field at R12, and 72-78% wins over R10-R14. Fairies sit level with the field, at about 50% wins.
- The 09a problem (stat scale too low and too flat) is not fixed yet.

## Hypotheses

Each figure is the share of the R12 gap to paper that the hypothesis explains, measured in log terms. The hypotheses overlap, so the shares don't add up to 100%.

| Hypothesis | Verdict | Homecoming | Tempo | Ring | Court |
|---|---|---|---|---|---|
| Paper models assume every piece arrives on time | **Kept** | 120-137% | 160-183% | ~130% | 119-123% |
| Bots misplay | Partly | ~30% | ~50% | ~15% | ~12% |
| Shop supplies pieces rarely | Partly | 3-8% | 30-60% | 7-20% | 5-12% |
| Keystones missing | Partly | 15-35% | ~50% | ~12% | 15-17% |
| Keystones fail their role | Partly | not measured | not measured | 25-45% | 22-39% |
| Games split into two groups | Ruled out | 0 | 0 | 0 | 0 |

- **Paper models (kept).**
  - Replaying the unchanged paper models with real arrivals tracks the measured ratio (log r = 0.99 over 16 line-and-round cells).
  - The replayed boards come out about x1.3 below the real ones, because real bots buy off-plan.
  - Each paper line's full schedule of arrivals is on time in 0.00% of draws.
  - Ring's paper board is in the real top 0.6%. Court's paper board is above the real maximum.
  - Gold and tier climb are not short.
- **Bots (partly).**
  - Bots buy about what they're offered, and every engine card fires as written.
  - But most line-file rules (`thank`, `max_copies`, `stayer_cap`) are never run.
  - The bigger Birds carry stays home on 88% of eligible turns.
  - Ring boards end turns with 1.2 empty slots.
- **Supply (partly).**
  - A given T2 card shows in about 9% of shop fills at T2 and 3.5% at T4.
  - Old Moth Annis is offered by R3 in only 8% of games.
  - Other seats taking copies changes the odds very little.
  - Supply mostly decides how often an engine assembles (snowball frequency, 09d), more than the median.
- **Keystones (partly).**
  - Boards that have the keystones still fall short: Ring with Annis reaches 0.31x paper, and Homecoming with all four engine pieces 0.58x.
- **Split (ruled out).**
  - Every line has one peak, not two.
  - At R12, 7-12% of boards are at 2x their line's median, against Battlegrounds' 23%.
  - Stats rise smoothly with how often the engine fires: a median of 4 homecomings over R8-R12, against the paper's 10.

## Cards that fail their role

- **Cluricaun** (T3 3/5, size engine): "After you Tier up: if every slot has a Ring, your Rings grow +1/+1." **Trap.**
  - Every slot has a Ring before only 13-19% of its tier-ups.
  - 42-55% of its rounds on the board are at T6, where it can't fire.
  - Ring size is 2.0 with it and 2.0 without it. Four lenses found this.
- **Mr Redbreast** (T2 2/4, second carry): "After a Bird comes home: gain an eighth of its stats."
  - He has 43 stats at R12, against the paper's 105.
  - Win rate is 76% with him and 76% without, yet he is the line's first buy.
- **Mrs Stork** (T4 4/7, recall): "Every 6 gold you spend: a Bird that missed a fight comes home."
  - No Bird is away on a third of her turns.
  - Homecomings over R8-R12 are 4 with her and 4 without.
- **Redwing** (T2 2/4): "Your two biggest Birds away leave Eggs with half their stats."
  - Win rate is 68% with it and 77% without. This is observational, so other factors may play a part.

## Journey gaps

- **Fairies break.**
  - R1-3: Old Moth Annis (T2 2/4, "End of Turn and after you sell: Ring the slots behind this.") is the only card that adds Rings, and she is on time in only 8-21% of games.
  - R4-6: the cards that grow Ring size arrive long before every slot has a Ring. Only 4% of boards have that at R8.
  - R7-9: the T4 cards that read Rings find 5-7 Rings at size 1.
  - R10+: the Queen adds Rings only at T6. The Monarch ("Every 3rd End of Turn: double your Ring size.") first doubles a size of 1-2 at R13-R14.
  - There is no second route to Ring count: without Annis, the Court line reaches R12 in 54% of games, against 87% with her.
- **Birds hold.**
  - Five fliers across T1-T5 can each become the carry.
  - Their gap is how often the engine fires: 35-50% of R8-R14 rounds have no homecoming.

## Process cause

The paper-model step should have caught this.

- Every pass 3 model scripts the arrivals ("arrival rounds stand in for the shop").
- The low-roll rows still keep the keystone.
- The presets' "shop luck" moved rounds but never removed a piece.
- Calibrating six tribes against each other can't show a bias they all share.
- Amendment 7 moved Cluricaun's trigger to tier-ups without checking when the full-board Ring condition is met.
- The line files list rules the bots never run, and no review flagged it.
- The plan's 0.5-2x accounting check is what caught it.

The same cause is in the Bog, Hunters, Oozes and Hedgerow paper models, in all six tribes' B and C values, in checkpoint 1's 900 and 1,800 targets, and in wave 2's line files. The accounting run also used `tribes_per_lobby` 0, not the shipped 5.

## The fix: one package before wave 2's dials land

**Presets: re-base B and C on realized boards, then scale the dials. Don't change supply yet.**

B and C keep their targets (about 900 and 1,800 at R12), but as real medians, not paper boards. Today's B gives wave 1 about 290-330 under real arrivals, which would leave 09a unfixed.

1. **Measure against real arrivals.**
   - Every paper model gets an arrival replay. Card odds come from the pool rules, through one helper that reads `game_config` at `tribes_per_lobby` 5. It samples shops and reports each line's median (p50) and p90.
   - The written line stays, labelled as a high roll, with its chance of arriving on time.
   - Calibrate the replay on this run, then set every B and C value against it.
   - This changes no boards by itself.
2. **Re-set wave 1's dials against it: raise the floor before the ceiling.**
   - **Fairies:**
     - `fairies_initial_ring_size` from 1 to 3, for the Fairy player only.
     - `fairies_annis_rings` and `fairies_sally_rings` from 1 to 2.
     - Cluricaun becomes "After you Tier up: your Rings grow +1/+1, or +2/+2 if every slot has a Ring."
     - The Ring-growth dials stay at B's values.
     - R12 median: Ring rises from 142 to about 210-250, Court from 160 to about 260-320.
     - Growth: about unchanged at x1.23-1.32 a round. The whole curve moves up.
     - Spread: p90/p50 stays at 1.80-1.87. The share of boards at 2x the median holds at R12 and falls at R14 (17% to 13%, 23% to 14%).
   - **Birds:**
     - Today's C becomes B. The new C adds `birds_homecoming_multiplier` 3 (golden 3.5).
     - R12 median: rises from 265 to 650-800 in B, and 865-1,043 in C.
     - Growth: rises from x1.36 to x1.62-1.68 in B, and x1.77-1.83 in C.
     - Spread: boards above 3x the median go from 1-4% to about 8-11% in B. C reaches a p90/p50 of 3.0-3.5 (Battlegrounds is 2.53), with high rolls of 7-13k. Test C's tail on constructed setups (09d) before any playtest.
     - This overrules the distribution lens's advice to hold the growth dials, for Birds only. Most of the Birds dials' effect reaches real boards: x1.64-1.86 against x1.96 on paper. Fairy growth dials give only x1.07-1.09 against x1.65.
   - Result: Birds land near Battlegrounds' 759 at turn 12, and Fairies 2-4x below them, still within an order of magnitude (09c). Fairies' next step is a second card that adds Rings.

These figures come from replays and re-pricing of the captured boards, not from fights. Shop odds are estimates from the pool rules. The lens scripts are in `docs/ideation/evidence/wave1-triage/scripts/`.

**After this, not blocking:** have the bots run the ignored line-file rules, base the elimination guard on expected damage, and fill empty slots. Keep today's bots as a control. That adds about 10-25% to committed R12 boards.

**Not now:**
- a shop tribe guarantee, Ask for Kin or a kin Discover. These would assemble the engine in more games, but they lift the median little and touch the owner's worry about discovery.
- reworks of Mrs Stork, Mr Redbreast and Redwing.

## Wave 2 briefs (Bog, Hunters, Oozes, Hedgerow)

- Name each engine's keystones, with each one's chance of being offered by the end of its window. A keystone under about 60% gets a second card doing its job at another tier. This is a guide, not a bar (09i), and it is not the power budget.
- Paper models replay arrivals, and the low-roll row removes the keystone itself.
- Spend generosity first on floor dials that act in most games, and only then on growth dials tied to rare pieces.
- Check each card's condition against when its trigger can fire.
- Line files hold only rules the bots actually run.