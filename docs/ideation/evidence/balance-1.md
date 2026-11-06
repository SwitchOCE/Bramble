# Balance step 1: before and after

Before is commit b1499f7 (100 games of the spread). After is commit 1d12de0 (`bench-latest.md`, 2000 games of the spread). Neither figure is the bar's verdict alone: `bench-reading.md` says what they can and can't show.

| Measure | Before | After |
|---|---:|---:|
| Median seat is out at round | 11 | 14 (middle half 12-16) |
| Last fight of the lobby | 14.9 | 17.9 |
| Seats on tavern 5+ at round 12 | 52% | 85% |
| Alderman Dozey on final boards | 83% | 30% |
| Strategies at 6-25% wins | 4 of 8 (100 games) | 8 of 9 |
| Highest strategy's wins | low_roll 28% | economy 24.6% ±2.0 |
| Lowest strategy's wins | treasury, rainbow 2% | rings 3.9% ±0.9 |
| Hard among Normal, average place | 3.49 ±0.20 | 3.41 ±0.18 |
| Hard among Normal, wins | | 23.4% ±3.7 |
| Hard among Easy, wins | 5% (first balance pass, before Easy slowed) | 52.3% ±5.7 |
| Normal among Easy, wins | 9% (same) | 35.0% ±5.4 |
| Search over shuffled placing | 0.91 ±0.19 | 0.57 ±0.22 |
| Hard's most common build | 98% one build (first balance pass) | Parish 33%, Treasury 25%, Rainbow 22%, Hag 19% |

## Game length

The brief asked for a game that commonly reaches tier 5-6 and about round 14-16. A median seat now goes out at round 14, and 85% of seats alive at round 12 are on tavern 5 or 6. The lobby's last fight is near round 18, longer than the target for the last two players; a person may find that long.

## The routes the runs took

- 100 games at 30 Health, before anything: low_roll 28, hag 23, parish 17, rings 14, help 10, economy 4, treasury 2, rainbow 2.
- First pass, Mast too strong: Treasury 44.6%, and the Larder reached 37 at round 17.
- Mast cut: Parish 26.8, economy 23.3, rainbow 20, with Rings 3.4 and the saver 2.2.
- Saver climbs on time; Rings and Help sooner; Hard's prior lowered: the table above.

## Saving and Acorns

In 200 games before the last change, from the rounds table: The Long Purse holds 15+ gold at round 8 in 88% of seats, and wins 6.9% at 2000 games with a low 30.5% top 4. It's a real line at a high variance, and not a strong one. Treasury holds a Stash's worth (5+) in 37% of seats at round 6, and in 72% of its survivors at round 16; before this step a Stash was held in 19 of 4,475 turns.

## Bots in 40 games of the spread

Units that keep their slot between rounds: 66%, from about half. Jill's power used 8 times, Shake the Tree cast about 286 times, Rainy Day 755.

## Not rerun at 1d12de0

`plant`, `hard_normal`, `hard_lobby_hard`, `easy_naive`, `place_rule`, `place_big` and the `blind_*` suites. Whether scouting earns its place hasn't been measured on these cards.
