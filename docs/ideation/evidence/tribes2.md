# Oozes and Birds: what was measured

On `ideation/tribes2`. Code at c243cb4 unless said. All on one core, so the samples are small.

## Spread

`tools/sim/bench.sh --cores 1 --seed 5000 spread=120`: 120 games, 8 Hard seats from 15 builds, so 47 to 76 seats per build. A seat's fair share is 12.5%. With about 65 seats a win rate is good to about ±8 points (two standard errors at 20%), so most gaps below are too close to call.

| Build | Seats | Win | Mean place |
|---|---|---|---|
| hedgerow_parish | 60 | 25.0% | 3.62 |
| **birds_highway** | 65 | 23.1% | 3.46 |
| neutrals_economy | 65 | 21.5% | 4.12 |
| neutrals_low_roll | 68 | 19.1% | 3.56 |
| fairies_hag | 68 | 19.1% | 3.54 |
| fairies_rainbow | 68 | 14.7% | 3.93 |
| neutrals_purse | 59 | 11.9% | 5.47 |
| fairies_help | 64 | 10.9% | 4.58 |
| **birds_summer_winter** | 56 | 8.9% | 5.18 |
| **oozes_second_helpings** | 47 | 8.5% | 4.87 |
| **oozes_waste_not** | 70 | 7.1% | 5.43 |
| **oozes_rude_awakening** | 76 | 5.3% | 5.04 |
| **birds_passage** | 61 | 4.9% | 4.90 |
| hedgerow_treasury | 65 | 4.6% | 5.40 |
| fairies_rings | 68 | 2.9% | 4.59 |

No new build is above 25%. The Highway is near that line, and its upper bound isn't below it. All three Ooze builds and the Passage sit under the fair share. Whether that's the cards or how bots play them isn't known: their stats on the board ran 15-35% below the Parish's from round 8 on in an earlier 60-game run, and what's inside a Belly isn't counted in that.

The builds were tuned on two earlier runs (60 and 80 games, seeds 1000 and 2000), so this run's seeds are fresh but the tuning was light: three rounds of bot data files, no unit changes from the bench.

## Soak

`tools/checks/soak.sh 200 1` at c243cb4: 200 games, 0 violations. All 29 new units and tokens fired in natural games. Counts over the 200 games: 923 swallows, about 490 flights (972 log lines count each twice), 349 landings, 90 Belly discounts.

## Not measured

- The ladder (Hard over Normal over Easy) with four tribes. No bench of it was run here.
- The placing test, which failed before this step. Nest and Belly cards add position decisions, but nobody has tested whether they matter more.
- Any person playing these tribes.
- Whether the bots use the tribes well. They use them at every level (a whole-game test proves it), but which unit goes in last and who touches Granny are only decided by Hard's fight search or not at all.
- Tribe spread at 2000 games on many cores, as the balance step did.

## Looked at by eye

`tests/ui/render_screens.sh` at 1920x1080 and 1688x780: `recruit_held`, `recruit_held_ooze`, `recruit_held_bird`, `scout_held`, `combat_held`, `guide_8`. New portraits checked on a contact sheet at 96 px: all read.
