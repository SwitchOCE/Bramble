# Commit review: making a tribe worth committing to

`ideation/c-commit`, 7 Nov 2026. A paper pick: nothing is built or benched. The owner: "It needs to focus on interesting designs and strategic depth." The playtesters: "Committing to a tribe doesn't pay."

## Cause and method

Measured on the real code (`commit/measure.md`, Hard lobbies). Seven units of one tribe place 4.94 on average, against 4.42 for three. Only one of 143 units counts a tribe. At round 15, spells give 30% of stats, Rings 12%, your own tribe 2%. A tier-1 carries 28 stats and a tier-6 carries 18. 62% of the Queen's split lands on non-Fairies, and Charcoal Burner has no cap. Thin supply isn't the cause: at 4 tribes per lobby, supply rises 35% and commitment still doesn't pay. Bots skip Oozes because of their priors (pinned Oozes play about average). Birds are weak in the game itself: pinned they place about 5.3.

Three designers (`commit/drafts/`), two critics (`commit/critic-play.md`, `commit/critic-feel.md`) and a costing reviewer (`commit/costing.md`) ran as in design review 3. Both critics took B's spells, C's Hiring Fair and C's Egg rule, and cut every capstone. Costing found the draft overshot (+29% committed); its numbers are applied.

## The pick

### Core: the smallest set that makes committing pay

1. **Stand Behind Me** (tier 3, cost 2): "Aim at a front-row unit: the units behind it gain +1/+1 permanently, or +2/+2 if they share its tribe."
2. **Bread from the Back** (tier 2, cost 2): "Aim at a back-row unit: the units in front of it gain +1/+1 permanently, or +2/+2 if they share its tribe."
3. **Harvest Supper** (tier 5, cost 3): "Aim at a unit with a tribe: your units of that tribe gain +1/+1 permanently, including ones you get later. Once a turn."
   - **The one new rule:** a per-tribe bonus, shown on the tribe's icon and capped at +3/+3. It applies to every unit of that tribe you have, wherever it is, and to ones you get later, but not to units summoned in fights. A unit with two tribes gets both bonuses.
4. **Hiring Fair** (tier 5, cost 6): "Discover a tier 6 unit. If 5 or more of your units share a tribe, one of the three is of that tribe."
5. **Bots:** give Oozes and Birds `power` and per-unit weights on Hedgerow's scale, and teach Hard to value kin, the bonus and Hiring Fair.
6. **5 tribes per lobby** (down from 6), for about 20% more supply.

Costing's estimate: committed boards +14% stats, mixed boards -5%.

### Bounds on the neutral scalers

7. **Queen of Elfland**: "...Your other **Fairies** split their stats evenly."
8. **Charcoal Burner** (4/6): "End of Turn: burn your gold above 5, up to 4. Units behind this gain +1/+1 per 2 burned." The golden version burns up to 8.

### Tier-6 reasons

9. **Fairy Monarch** (4/6): "Rings under your Fairies give +1/+1 more." Golden: +2/+2.
10. **Elder Ooze** (3/4, Belly 1): "Whenever a unit comes out of one of your Oozes, it gains +1/+1 this combat for each of your units that has come out this fight, up to +3/+3." Golden: +2/+2, up to +6/+6.
11. **Moss Ooze** (tier 2, 2/4): "When a spell gives one of your Oozes stats, the units inside it gain them too." Golden: "twice that". The tribe bonus doesn't trigger it.
12. **The Laird of the Sett** (3/5): "At the bell, all your units with no quarry take the enemy across from them as quarry. After each Take this fight, your Hunters gain +1/+1 this combat." Golden: +2/+2.

Hedgerow and Bog folk, the pick leaders, get nothing here.

### Birds: the trip stops costing the body

13. **Egg (rule change):** "While a Bird is away, the Egg on its Nest fights with that Bird's Attack and Health, and no text." Flying pays no sale gold, so Fly South isn't free (costing). Mother Goose's own Egg stays 0/2.
14. **The Seven Whistlers** (3/3): "Start of Combat: each enemy across from one of your Birds or Eggs loses 1 Attack and 1 Health this combat for each Bird you have, on the board or away, up to 6." Golden: 2 and 2, up to 12. The cap of 6 is my call against costing's 1/1, so the flock still matters; bench it.

## Cut

All of C's capstones, since they punish tall boards. The Hedgerow "run" (hidden geometry). "A unit on a Nest is a Bird". Ring doubling (+80-150%). Figgy Duff and Old Crane growth. Reynard and Peg Powler as written.

## Build order

Build and bench 1-8 first, then 13-14, then 9-12. Rerun `commit/commit_probe.gd.txt`. It passes if 6+ of a tribe places better than 4 or fewer, own-tribe stats rise above 2%, and Oozes and Birds each pass 5% of picks.
