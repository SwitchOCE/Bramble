# Placing: why the bar fell, and what it would take

**Run 7 Nov 2026 on `ideation/c-placing`, from `ideation/tribes2` at f51eefa.** The bar (PLAN.md, Done means 2): the searching placer averages at least 0.5 of a place better than the same bot with shuffled placement. Earlier readings: 0.91 at b1499f7, 0.57 ±0.22 at 1d12de0, 0.14 ±0.27 at 3b3b5c5 (`balance-1.md`).

## The answer

**The bar as the bench defines it fails: 0.31 ±0.15 at f51eefa, 1000 paired seeds. I could not get it above 0.5, and I didn't change the game to force it.**

- **The measure can be trusted, but it leaves out most of what placing is worth.** The bench's "shuffled" bot never moves a pinned unit, meaning one partway through a turn count, waiting on a timer, standing on its band or keeping a Nest. Shuffling those too costs **1.75 ±0.16 places** (1000 paired seeds). So keeping committed units still is worth **1.44 ±0.16** places on its own, and the bar measures only what is left. Alderman Dozey (41% of final boards) and Sleeping Partner (39%) are pinned most of the time.
- **What is left, the fights, fell at the balance step, and mostly for a good reason.** Knowing the real enemy board, the best layout of a fight side was worth +30 win-rate points at b1499f7 and +14 from 1d12de0 on. At b1499f7, Hedge Witch, uncapped at the time, stood on 81% of boards and aimed a growing −Attack hex at the enemy across. Fights she was in had a ceiling 11 points higher than fights without her. Step 1 capped her at −8, rightly, and with her went much of the swing.
- **The bot is not the bottleneck.** Hard already gets about what its information allows: the best layout against the scouted board, using 150 fights against Hard's 20, adds only +1.6 points a fight over Hard. Two fixes for real gaps in the bot made no measurable difference (0.32 ±0.15), so I reverted them.
- **Most of the fight value is matchup, and the scout is too stale to use it.** A good layout picked without knowing the opponent is worth +2.7 points a fight over random, and a big search against the scout +4.3. Against the real board it is worth +14.1, and +24.7 in contested fights. Only 57% of scouted units stand in the same slot when the fight comes.
- **The four-tribe game barely shows up in this test.** Hard lobbies play Hedgerow and Fairies: of the 1000 focus seats, 3.2% followed an Oozes build and 0.2% a Birds build. So this bar says almost nothing yet about the new tribes' position text.

## Can the measure be trusted?

| Check | Result |
|---|---|
| Sample size | 1000 seeds a side gives ±0.15, enough to tell 0.5 from 0.15. The bench's paired method (`paired_gain`, by seed, same focus seat) was used throughout. Pairing gains little: a shuffled bot's game soon differs from the searcher's, and per-seed differences have an SD of about 2.4 places. |
| The shuffled arm | Keeps pinned units still, so it gets the game's most valuable placing rule free: 1.44 places. This is the biggest thing the measure leaves out. |
| Does the search understand new cards? | It plays real `Combat` fights, so every fight effect is in it, Whirligig, Changeling, Bellies and Nests included. It does not see recruit-phase effects (End of Turn buffs, Passes past its layout bonus), and its board leaves out Eggs, which only matters for Birds. The bot's rule layout aimed only the first unit with a `faces` hint each turn, and didn't know a scouted Whirligig flips its rows. Fixing both changed nothing measurable (below). |
| Phone budget | Hard turns average 50 ms here, about 0.74 s for 7 bots on the assumed phone core (`bench-latest.md`), so a bigger search budget isn't available. |

## The bench readings

One Hard among 7 Hard, everyone scouting, seeds 1-1000, paired by seed. Lower places are better; the gain is the shuffled arm's place minus the searcher's.

| Commit | Arm against search | Games a side | Gain (95% CI) |
|---|---|---:|---:|
| f51eefa | shuffled, pinned units kept (the bar) | 1000 | **0.31 ±0.15, FAIL** |
| f51eefa + shuffle-all arm | every unit shuffled | 1000 | 1.75 ±0.16 |
| same | pinned kept against every unit shuffled | 1000 | 1.44 ±0.16 |
| 4798094 (bot fixes below) | shuffled, pinned units kept | 1000 | 0.32 ±0.15 |

The shuffle-all run used f51eefa's bot code with only the new arm added. 8ebf615, this branch's head before the evidence, has the same bot code. Average places: search 4.47, shuffled 4.79, shuffled all 6.23.

## Why it fell: what a layout is worth in each fight

`tools/sim/place_probe.gd` plays bench games (8 Hard bots). At every fight, it replays each side's board against the real enemy board on the same 32 fight seeds, in several layouts. Numbers are win-rate points (ties half) over shuffling every unit, with 95% CIs paired by fight side. Combat only: recruit-phase position value (turn counts, End of Turn buffs, bands) isn't in these numbers.

| Commit (bench reading) | Games, sides | Rule layout | Hard (rule + 20 fights on scout) | 150 fights on scout | 150 fights on real board | Real board, contested fights only |
|---|---:|---:|---:|---:|---:|---:|
| b1499f7 (0.91) | 8, 629 | +5.1 ±2.0 | +5.3 ±2.0 | +9.8 ±2.0 | **+29.9 ±2.1** | +40.4 |
| 1d12de0 (0.57) | 2, 415 | +1.8 ±2.1 | +1.4 ±2.1 | +3.6 ±2.1 | +17.2 ±1.9 | +26.9 ±2.5 |
| 3b3b5c5 (0.14) | 2, 382 | +2.1 ±1.7 | +2.3 ±1.6 | +4.2 ±1.6 | +15.5 ±1.9 | +24.7 ±2.6 |
| f51eefa (0.31) | 8, 798 | +0.9 ±1.1 | +1.7 ±1.1 | +3.8 ±1.2 | +13.8 ±1.3 | +24.5 ±1.9 |
| 8ebf615, seeds 31-38 | 8, 796 | +1.7 ±1.2 | +2.7 ±1.2 | +4.3 ±1.2 | +14.1 ±1.3 | +24.7 ±2.0 |

Contested means shuffled wins 10-90%: 62% of fights at b1499f7, 43-45% now. At 8ebf615 a 150-fight search against another player's board, standing in for knowing nothing, gets +2.7 ±1.2, the same as Hard.

**The drop came at the balance step (6650047, measured at 1d12de0), and it holds in contested fights too.** So it isn't only that fights got more lopsided. The step added no rule change to combat. Comparing the cards in contested fights at b1499f7:

| Card at b1499f7 | Share of boards | Ceiling with it minus without |
|---|---:|---:|
| Hedge Witch (uncapped) | 81% | +11.1 |
| Queen of Elfland | 3% | +10.6 |
| Belladonna ("the 2 front enemies facing this", then) | 19% | +6.3 |

At 8ebf615, Hedge Witch is on 25% of probe boards and still leads: +8.6. Nan Toadstool (a Ring) follows at +8.2. **Cards that read the enemy across are what make a layout matter in a fight.** This is the position test's finding again. When one of them was on most boards, the bar read 0.91. The cap was right: she was on 81% of boards. The bar lost what she carried.

**Where the rest of placing's value sits.** The per-fight numbers above are small next to 1.44 places for not breaking turn counts and bands. Bramble's position depth now sits mostly in the recruit phase: Dozey's and Partner's counts, bands, Rings and Nests. The bar's shuffled arm is spared all of that.

## What I tried

Each was measured on the same fights as the code before it (probe, paired), then on the bench. Both were bot changes; neither changed a card or rule.

| Change | Probe, paired | Bench at 4798094 | Kept? |
|---|---|---|---|
| B1: the rule layout aims every `faces` unit, the most valuable first, each at its own target (Belladonna at the back slot whose two front enemies hit hardest), and stands the board with its rows swapped against a scouted Whirligig | Rule +1.3 ±1.8 (204 sides), +0.4 ±0.9 (355), −0.3 ±0.8 (383) | — | No |
| B2: the search keeps its starting layout in to the final call, and its layout bonus no longer shrinks as fights add up, so a challenger must beat it by `STAY_BONUS` on the same seeds | Hard with B1 and B2 against Hard before: −0.5 ±1.5 (204), +0.6 ±0.9 (355), +0.2 ±0.7 (383) | B1 + B2: 0.32 ±0.15 (1000) against 0.31 ±0.15 | No |

Hard's turn time with both: mean 48 ms against 50 ms. Neither did harm, but code that measures nothing is a cost, so 8ebf615 reverts both. The probe's columns for them are in the history at 4798094.

## What it would take

None of these is done. The bar should pass because placing gets deeper, not because the measure changed or a penalty grew.

| Option | Expected effect | My call |
|---|---|---|
| Count slot commitment: shuffle every unit | Passes today: 1.75 ±0.16 | **Not adopted.** It passes by redefining the arm after seeing the result. It is mostly one rule: don't move a counting unit. The bench now reports it beside the bar so the orchestrator can decide what the bar is for. |
| Show the real enemy board before the fight: after recruiting, both boards revealed, and each player makes a swap or two at the same time | Ceiling +14 a fight against +4 with the scout; the biggest decision placing has | **The most promising, and not mine to add on this brief.** It adds a step to every round, changes the UI and the bots, and needs simultaneous play to stay fair. It deserves its own brief and a test with players. |
| More "across from" text on the cards Hard lobbies play (Hedgerow and Fairies), near budget on stats | Hedge Witch shows +8.6 a fight on 25% of boards | Content work for a designer, costed against the power budget. Untested. |
| A rule that punishes bad layouts (back row deals half damage; a bonus for units that stay put) | Would raise the bar mechanically | **Not recommended.** The position test found back-row-half is "a bigger penalty, not much more thinking". A stay bonus would also mostly add one rule. |

## Calls I made

1. **The bar stays as the bench defines it, with pinned units kept.** Shuffle-all goes in the report as context. If the orchestrator decides commitment should count, the data is there.
2. **Reverted B1 and B2**, with no gain measured. Hard's placing code is as it was at f51eefa, plus `worth_searching` made public for the probe.
3. **Didn't change cards or rules.** No small change I could defend was shown to move the bar. The changes that would are a new step in every round, or new content, and both are bigger than this brief.
4. **Didn't rerun shuffle-all at b1499f7,** so I can't say how much of the fall from 0.91 came from more units being pinned. The probe puts 1.8 units pinned a board there and 2.3 at f51eefa (3.2 at 1d12de0). Doubles a run of about 40 minutes.

## Limits

- The probe is combat only and bot only: a person scouting, with no search, gets less than these numbers.
- The 1d12de0 and 3b3b5c5 probes are 2 games each. The probes at older commits use the probe on that commit's code, with the Egg check off: no Birds then.
- The search's 20-fight budget is a phone assumption no device has tested.

## How to reproduce

```
tools/sim/bench.sh --cores 4 place_search=1000 place_shuffled=1000 place_shuffled_all=1000
godot --headless -s res://tools/sim/place_probe.gd -- games=2 first_seed=31 out=<csv>
python3 tools/sim/summarize_probe.py <csv> [<csv> ...]
```

Data: [placing-data/](placing-data/): `bench-focus-places.csv` (the focus seat's place per seed in each bench arm above) and the probe CSVs for b1499f7, f51eefa and the final code. A probe game takes about 3-4 minutes on one core; the bench about 6 s a game on each core.
