# Balance step 1: before and after

Three points in the work. **Before:** commit b1499f7, its `bench-latest.md`. **Step 1:** commit 1d12de0, `bench-latest.md` as it stands: 2000 games of the spread. **After review:** commit 3b3b5c5, targeted suites: 400 games of the spread, 200-400 of each ladder suite. The last column has wider margins than a full bench.

| Measure | Before | Step 1 | After review |
|---|---:|---:|---:|
| Median seat is out at round | 11 | 14 | 14 (middle half 12-16) |
| Last fight of the lobby, round | 14.9 | 17.9 | 17.7 |
| Seats on tavern 5+ at round 12 | 52% | 85% | 84% |
| Alderman Dozey on final boards | 82.8% | 28.2% | 29.5% |
| Strategies at 6-25% wins | 4 of 8 | 8 of 9 | 7 of 9 |
| Highest strategy's wins | low_roll 26.4% | economy 24.6% ±2.0 | economy 22.2% ±4.3 |
| Lowest strategy's wins | treasury, rainbow 2% | rings 3.9% ±0.9 | rings 3.9% ±2.0 |
| Hard among Normal, place | 3.49 ±0.20 | 3.41 ±0.18 | 3.30 ±0.19 |
| Hard among Normal, wins | 27.8% ±3.9 | 23.4% ±3.7 | 25.0% ±4.2 |
| Hard among Easy, place | 1.97 ±0.21 | 2.36 ±0.22 | 1.97 ±0.21 |
| Hard among Easy, wins | 69.7% ±5.2 | 52.3% ±5.7 | 56.5% ±6.9 |
| Normal among Easy, place | 2.77 ±0.19 | 3.37 ±0.27 | 2.50 ±0.26 |
| Normal among Easy, wins | 40.2% ±4.3 | 35.0% ±5.4 | 43.5% ±6.9 |
| Search over shuffled placing (bar 0.5) | 0.91 ±0.19 | 0.57 ±0.22 | **FAIL:** 0.14 ±0.27 |

Step 1 made the ladder worse than the Before column: Easy got stronger against both. Fixing that was the review's call. An uncommitted pass in between, kept here as history only, had Hard winning 5% among Easy, as Easy reached tier 6 by round 9.

## Game length

The brief asked for a game that commonly reaches tier 5-6 and about round 14-16. A median seat goes out at round 14, and 84% of seats are on tavern 5 or 6 at round 12. The lobby's last fight is near round 18, longer than the target; a person may find that long.

## What placing lost

Placing is what all three reviewers praised, and its value fell from 0.91 to 0.57 in Step 1. Measured at 1d12de0 with 300 games a side:

| Arm | Search over shuffled |
|---|---:|
| Step 1 as it stands (500 games) | 0.57 ±0.22 |
| `STAY_BONUS` 0 | 0.14 ±0.28 |
| Whirligig out of the shop | 0.37 ±0.28 |

And at 3b3b5c5, 300 games a side:

| Arm | Search over shuffled |
|---|---:|
| As it stands | 0.14 ±0.27 |
| `ROW_STAY` 0 | 0.36 ±0.28 |

All margins use the bench's own paired method (`paired_gain` in `summarize_bench.py`, by seed), recomputed from the CSVs.

**Placing fails its bar: 0.14 ±0.27 against 0.5.** No arm brings it back to 0.91, so none of the three suspects is shown to be the cause, and nothing was changed. The cause is unknown. This measures what bots gain from their search, which may not be what a person gains from thinking about position.

## The opening, rounds 1-2

Reviewers agreed the first two rounds were scripted. The first shop of rounds 1 and 2 now shows Rainy Day and A Leg Up in place of a drawn spell, so a player chooses between a unit (tempo), Rainy Day (economy) and A Leg Up (a climb). Normal and Hard toss a coin for their opening. 300 games of the spread, seats by what they did in round 1:

| Opening | Seats | Avg place | Wins | Top 4 |
|---|---:|---:|---:|---:|
| Tempo | 792 | 4.52 ±0.16 | 13.0% | 49.0% |
| Economy | 794 | 4.53 ±0.16 | 11.5% | 49.6% |
| Climb | 814 | 4.44 ±0.16 | 13.0% | 51.4% |

The first version, A Leg Up at 3 off, gave Climb 4.19 against 4.61 and 4.71, so it went to 2. The three are now level for bots, who take them by coin toss. It doesn't show a person will find the choice interesting. No one has played it by hand.

## Cards the review asked about, 3b3b5c5

- **Old Mother Mast,** paying only after you buy a unit, once a turn: 16.2% of boards, 23.4% wins on those. Treasury went from 16.2% to 10.7% wins, its Acorn supply cut.
- **Sleeping Partner,** 3 payments a stay in a slot when measured: 23.2% of boards, 13.1% wins. The bound then moved to the unit's life (DECISIONS) and hasn't been benched.
- **Rainbow Chaser,** 5 gold more for all seven: 12.6% of boards, 6.5% wins, Rainbow 15.8% wins. It doesn't run away. The bot sells it at seven bands.

## Saving and Acorns, 2000 games at 1d12de0

Before all later Mast and Partner changes, from the rounds table:

| Build | Holds 15+ gold at round 8 | at round 10 | 5+ of Acorns at round 6 | at round 16, of those left |
|---|---:|---:|---:|---:|
| The Long Purse | 86% | 48% | 13% | 11% |
| Spend Late | 43% | 53% | 8% | 14% |
| Treasury | 8% | 7% | 32% | 73% |

Before this step a Stash was held in 19 of 4,475 turns.

**Whether saving is a real line is untested by hand.** The Long Purse holds gold on a set schedule and wins 5.1% ±2.3 at 3b3b5c5, top 4 30.3%; the next reviewers test the line. Spend Late (`neutrals_economy`) doesn't save: it climbs on a fast curve and spends what it has. Its strength says nothing about saving.

## Bots in 40 games of the spread, 1d12de0

Units that keep their slot between rounds: 66%, against about half reported in playtest 1. Jill's power used 8 times, Shake the Tree bought about 286 times, Rainy Day cast 755.

## New designs for the next reviewers

The 11 cards beyond the brief stay. Money Spider (6.2% of boards, 2.0% wins), Squirrel Away and Hiring Fair go to the next reviewers as new designs: they have not been judged by anyone but the bench.

## Not rerun

`plant`, `hard_lobby_hard`, `place_rule`, `place_big` and the `blind_*` suites at any of the later commits. Whether scouting earns its place hasn't been measured on these cards.
