# Commit review: making a tribe worth committing to

`ideation/c-commit`, 7 Nov 2026. This is a paper pick: nothing here is built or benched yet. The owner's words: "It needs to focus on interesting designs and strategic depth." The problem, from three fresh playtesters: "Committing to a tribe doesn't pay."

## The cause, measured on the real code (`commit/measure.md`)

These numbers come from 30 lobbies of 8 Hard bots, plus pinned-build and lobby-size runs.

- **Commitment has no upside.** A final board with 7 units of one tribe places 4.94 on average, and one with 3 places 4.42. Only one of 143 units counts a tribe, and none rewards the 5th to 7th unit.
- **The stat pile is generic.** At round 15, tavern spells give 30% of board stats (Stand Behind Me 15%, Harvest Supper 11%) and Rings give 12%. Buffs from your own tribe give 2%.
- **The top tiers are small.** A round-15 tier-1 unit carries 28 stats and a tier-6 unit carries 18, because buffs land on the first bodies bought.
- **Neutral scalers leak.** 62% of the Queen of Elfland's split lands on units that aren't Fairies. Charcoal Burner has no cap: a person finds that line (36/37), but bots don't.
- **Supply is thin, but it isn't the cause.** With 4 tribes per lobby there is 35% more of your tribe in each shop, and committed boards still don't place better.
- **Oozes and Birds are skipped for different reasons.** For Oozes it's the bot's priors: Hedgerow gets +5 a unit and power 8, Oozes get +3, and pinned Oozes play about average. Birds are weak in the game itself: pinned Birds boards place about 5.3 and are only a third Birds, because flown Birds leave a 0/2 Egg.

## How it was run

Three fresh designers worked from one brief without the power budget (`commit/drafts/designer-a/b/c.md`). A took tribe-count payoffs, B made the generic sources tribal, and C wrote capstones. Two critics followed (`commit/critic-play.md`, `commit/critic-feel.md`). Both critics independently rated B strong, A workable and C weak. Both took B's spells, C's Hiring Fair and C's Egg rule, and both cut every capstone. A costing reviewer came last (`commit/costing.md`): the draft overshot, giving committed boards +29% stats and mixed boards about 0. Its numbers are applied below.

## The pick

### Core: the smallest set that makes committing pay

1. **Stand Behind Me** (tier 3, cost 2): "Aim at a front-row unit: the units behind it gain +1/+1 permanently, or +2/+2 if they share its tribe."
2. **Bread from the Back** (tier 2, cost 2): "Aim at a back-row unit: the units in front of it gain +1/+1 permanently, or +2/+2 if they share its tribe."
3. **Harvest Supper** (tier 5, cost 3): "Aim at a unit with a tribe: your units of that tribe gain +1/+1 permanently, including ones you get later. Once a turn."
   - **The one new rule, the tribe bonus.** Each player has a bonus per tribe, shown on the tribe's icon and capped at +3/+3. It applies to every unit of that tribe you have (on the board, in hand, in a Belly, away) and to units you buy or play later. It doesn't apply to units summoned during a fight. Selling a unit doesn't remove the bonus, and a unit with two tribes gets both.
4. **Hiring Fair** (tier 5, cost 6): "Discover a tier 6 unit. If 5 or more of your units share a tribe, one of the three is of that tribe."
5. **Bots.** Give Oozes and Birds `power` and per-unit weights on the same scale as Hedgerow, and teach Hard to value the kin clause, the tribe bonus and the tribe option on Hiring Fair. Without this, the bench measures the bots' priors and not the game.
6. **5 tribes per lobby** (down from 6), for about 20% more supply.

Costing's estimate for items 1-4: committed boards gain about +14% stats and mixed boards lose about 5%. That makes commitment the better line without making it mandatory.

### Bounds on the neutral scalers

7. **Queen of Elfland**: "...Your other **Fairies** split their stats evenly."
8. **Charcoal Burner** (4/6): "End of Turn: burn your gold above 5, up to 4. Units behind this gain +1/+1 per 2 burned." The golden version burns up to 8.

### A tier-6 reason for the tribes without one

9. **Fairy Monarch** (4/6): "Rings under your Fairies give +1/+1 more." Golden: +2/+2.
10. **Elder Ooze** (3/4, Belly 1): "Whenever a unit comes out of one of your Oozes, it gains +1/+1 this combat for each of your units that has come out this fight, up to +3/+3." Golden: +2/+2, up to +6/+6.
11. **Moss Ooze** (tier 2, 2/4): "When a spell gives one of your Oozes stats, the units inside it gain them too." Golden: "twice that". The tribe bonus doesn't trigger it.
12. **The Laird of the Sett** (3/5): "At the bell, all your units with no quarry take the enemy across from them as quarry. After each Take this fight, your Hunters gain +1/+1 this combat." Golden: +2/+2.

Hedgerow and Bog folk get no changes here. They lead the picks, and items 1-3 already reach them.

### Birds: keep Fly South and the Nest, and stop the trip from costing the body

13. **Egg (rule change):** "While a Bird is away, the Egg on its Nest fights with that Bird's Attack and Health, and no text." Flying now pays no sale gold, since the body stays in the fight. That is costing's fix, so that Fly South isn't free. The existing rule that a Bird played this turn can't fly stays. Mother Goose's own Egg stays 0/2. With the tribe bonus, a Bird that is away keeps growing.
14. **The Seven Whistlers** (3/3): "Start of Combat: each enemy across from one of your Birds or Eggs loses 1 Attack and 1 Health this combat for each Bird you have, on the board or away, up to 6." Golden: 2 and 2, up to 12. Costing priced the uncapped draft at about 75 SP, so the cap of 6 is my call, made so the size of the flock still matters. Bench it.

## Cut

- All of C's capstones: they punish tall boards instead of paying for commitment.
- The Hedgerow "run" and the Bound-Beater: the zigzag geometry is hidden.
- "A unit on a Nest is a Bird": it breaks the type line.
- Ring doubling: costed at +80-150%.
- Figgy Duff and Old Crane growth: stats grow out of sight.
- Reynard and Peg Powler as written.
- The optional homecoming swap is held back.

## Build order

Build items 1-6 and bench them, together with 7-8. Then build 13-14, then 9-12. The bench should rerun this probe (`commit/commit_probe.gd.txt`) and check three things: 6+ of a tribe should now place better than 4 or fewer, own-tribe stats should rise above 2%, and Ooze and Birds picks should rise above 5%.
