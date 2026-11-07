# Does committing pay? What the real code says

`ideation/c-commit`, base `origin/ideation/main` (7 Nov 2026). Probe: `commit_probe.gd.txt` (needs the 3-line QA hook in `probe_hook.patch`, reverted after the run), analysis `analyze.py`. 30 lobbies of 8 Hard bots (seeds 91000-91029), plus 56 games with one Hard seat pinned to a build (seeds 92000-92007). Small samples: read differences under about 0.5 of a place as noise.

## 1. How many tribes winning boards hold

| Board | Distinct tribes | Units of main tribe / board |
|---|---|---|
| Round 10, top 4 | 2.6 | 66% |
| Round 10, bottom 4 | 2.5 | 71% |
| Final, winner | 2.5 | 67% |
| Final, bottom 4 | 2.3 | 75% |

The more of one tribe on the final board, the worse the place:

| Main-tribe units | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|
| Avg place (final) | 4.42 | 4.17 | 4.57 | 4.59 | 4.94 |
| Avg place (round 10 board) | 3.85 | 4.04 | 4.23 | 3.94 | 5.24 |

A full tribe board does worst. Bots are mostly 4-5 of a tribe plus splash, so "winning boards are mixed" is true but mild; what's strong is that **commitment has no upside**.

## 2. Cards that pay for tribe count or presence

Of 143 pool units, **one** counts a tribe (One Swallow: "next to a Bird"). Five mention a tribe at all (Drumming Woodpecker, Laird of the Sett, Mountain Glutton, Mr Syllabub, One Swallow). About 30 pay off a tribe keyword event (Mired death, Take, Belly, Acorn), which needs 2-3 enablers, not a board. **No card anywhere rewards the fifth, sixth or seventh unit of a tribe.**

## 3. Where board stats come from (share of all Attack + Health on board)

| Source | Round 10 | Round 15 |
|---|---|---|
| Printed stats (golden doubled) | 49% | 43% |
| **Tavern spells** (neutral) | **29%** | **30%** |
| of which Stand Behind Me | 21% | 15% |
| of which Harvest Supper | 1% | 11% |
| **Rings** (made by Fairies, worn by anyone) | 11% | 12% |
| Unit grows itself (Dozey's Acorns, waits) | 6% | 5% |
| Buff from another unit of the same tribe | 1% | 2% |
| Buff from a unit of another tribe | 2% | 3-4% |
| Fight carry (Grizel and the like) | 0-1% | 3% |
| Unit auras, bands, heroes, unattributed | 3% | 3% |

**Tribe-to-tribe buffing is 1-2% of stats. Generic sources (spells and Rings) are 40-42%.** Stand Behind Me (tier 3, 2 gold, "the units behind it gain +1/+2") was cast 112 times in 3 lobbies, about 4.7 per player. Bots casting a cheap repeatable buff with spare gold (gold reaches 56) is the stat pile.

## 4. Tier 5-6 against a buffed tier 1

Average Attack + Health of non-golden units on boards:

| Tier | Printed | Round 10 | Round 15 |
|---|---|---|---|
| 1 | 3.6 | 16.0 | **28.3** |
| 2 | 4.5 | 12.5 | 26.8 |
| 3 | 6.8 | 14.3 | 23.9 |
| 4 | 8.0 | 10.4 | 19.4 |
| 5 | 10.3 | 12.3 | 17.5 |
| 6 | 14.1 | 15.0 | 18.4 |

A tier-6 body (printed 11.6 across the pool) is smaller than a round-10 tier 1. Buffs land where units stand early and never move, so the first bodies bought keep the stats; a tier-6 must win on text alone, and most tier-6 text adds no stats. Golden share at round 15 is 25% for tier 1-3 and 19% for tier 6.

## 5. One unit stacked

Biggest unit's share of board stats: winners 24-26%, bottom 4 31%. So one huge unit isn't what wins on average; it's what playtesters see because it's what beats them (Belladonna, Wisp, Queen). Belladonna is on 53 of 120 top-4 final boards, Queen of Elfland 46.

## 6. Why Hard bots skip Oozes and Birds

Hard seats chose: Hedgerow 76 of 240, Fairies 52, Bog folk 68, Hunters 40, **Oozes 3, Birds 0**.

- **It's the bot's prior, mostly.** `BotEval.strategy_fit` adds a hand-set weight per owned unit of the build's tribe, plus `power`. Hedgerow Parish: +5 a Hedgerow unit and power 8. Fairies: power 6-8. Oozes +3-4, Birds +1-3, and neither has `power`. With equal shops a bot holding two Hedgerow units already out-scores one holding four Birds.
- **Pinned, Oozes play about average:** Second Helpings 4.25, Waste Not 5.00 (8 games each).
- **Birds are game-weak as a tribe:** Passage 5.38, Summer and Winter 5.25; the best Bird line, Highway Robbery (2.88), is the least Bird one. Pinned Birds boards are only 31-37% Birds, because flown Birds aren't on the board and their Nests give no stats.

## 7. Neutral scalers (added at the orchestrator's request, after pt3-a)

At round 15 the Queen of Elfland's split is 3.9% of all board stats, and 62% of it lands on units that aren't Fairies, so a Fairy card feeds whatever board holds it. Charcoal Burner barely registers with bots (6 of 240 final boards; bots spend their gold). Its uncapped gold-to-stats (pt3-a: a Spider from 6/7 to 36/37 in five turns) is a line a person finds and bots don't. The bench can't see it, so it needs a design bound, not a tuning pass.

## 8. Tribe supply and tribes per lobby

Same 30 seeds of 8 Hard bots, `tribes_per_lobby` 6, 5 and 4. "Per shop view" is units of that tribe in one look at the shop.

| Tribes per lobby | Your tribe per shop view (rounds 1-5 / 6-10 / 11+) | Final main-tribe units | Avg place, 6+ of a tribe | Avg place, 4 or fewer |
|---|---|---|---|---|
| 6 | 0.5 / 0.7 / 0.8 | 4.9 | 4.75 | 4.22 |
| 5 | 0.6 / 0.8 / 1.0 | 5.3 | 4.47 | 4.61 |
| 4 | 0.7 / 1.0 / 1.1 | 5.5 | 4.65 | 4.38 |

Hedgerow is the thinnest (0.40 early at 6 tribes), yet the most picked, so pick share isn't supply. Going to 4 tribes lifts supply about 35% and boards get more committed, but commitment still doesn't place better. **Thin supply makes builds unreliable; it doesn't explain why commitment fails to pay.** A smaller lobby helps once committed boards are rewarded; on its own it changes little.
