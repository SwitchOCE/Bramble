# Does where you put your units matter?

**Run 6 Nov 2026 on `ideation/position-test`.** The question comes from the owner, 2 Nov: "make sure that our combat rules in terms of positioning actually add a little bit of extra depth compared to Battlegrounds. And if they're not working, we can just cut them."

## The answer

**The bar passes: on the pool with position units, the searching placer beats shuffled by 0.77 of a place (95% CI 0.64 to 0.89; bar 0.5). But that pass flatters the rows.**

- 0.68 of the 0.77 comes from the crude heuristic, which mostly just reads each card's row hint. Search on old boards adds only +0.09 over it (CI -0.03 to +0.20): not distinguishable from nothing.
- So today, placement is worth a lot if you get it wrong, and little past a simple rule. That is the same finding as the old Python study.
- The real decision exists, but it is locked behind information. Knowing the board you are about to fight is worth +0.85 over the heuristic. Today nobody knows it.
- **Recommendation: keep the rows, add a scouting rule, and write "across from" text into tribes.** Showing the next opponent's board as it fought last round gives +0.40 over the heuristic (CI +0.28 to +0.51). It is the only change tested that adds a clear gain past the rule of thumb.

## Average place

One Balanced bot against the seven default bots, 1000 games per arm, the same seeds in every arm. Lower is better. CIs are 95%, paired by seed.

| Pool | Rules | Arm | Avg place (SE) | Gain over shuffled | Gain over heuristic |
|---|---|---|---:|---:|---:|
| (a) today | | shuffled | 3.18 (0.07) | | |
| | | heuristic | 3.07 (0.06) | +0.11 (0.01 to 0.22) | |
| | | search | 3.04 (0.06) | +0.14 (0.03 to 0.25) | +0.03 (-0.08 to 0.14) |
| **(b) 12 position units, less filler** | | shuffled | 3.82 (0.06) | | |
| | | heuristic | 3.14 (0.06) | +0.68 (0.56 to 0.80) | |
| | | **search** | 3.05 (0.06) | **+0.77 (0.64 to 0.89)** | +0.09 (-0.03 to 0.20) |
| | scouting | search on last round's board | 2.74 (0.06) | +1.08 (0.95 to 1.20) | **+0.40 (0.28 to 0.51)** |
| | ceiling | search on the real board | 2.29 (0.06) | +1.53 (1.40 to 1.66) | +0.85 (0.74 to 0.96) |
| (b) | back_row_half | shuffled | 4.30 (0.06) | | |
| | | heuristic | 3.30 (0.06) | +1.00 (0.88 to 1.12) | |
| | | search | 3.12 (0.06) | +1.18 (1.05 to 1.31) | +0.18 (0.06 to 0.30) |
| (a) | back_row_half | shuffled | 4.27 (0.06) | | |
| | | heuristic | 3.29 (0.06) | +0.98 (0.86 to 1.10) | |
| | | search | 3.37 (0.06) | +0.90 (0.79 to 1.02) | -0.08 (-0.19 to 0.03) |
| (b) | across_targeting | shuffled | 3.87 (0.06) | | |
| | | heuristic | 3.10 (0.06) | +0.77 (0.64 to 0.89) | |
| | | search | 3.02 (0.06) | +0.86 (0.74 to 0.98) | +0.09 (-0.03 to 0.20) |
| | | scouting | 2.67 (0.06) | +1.20 (1.08 to 1.33) | +0.44 (0.32 to 0.55) |

The real-board ceiling is not a rule anyone could ship: it reads a board the opponent has just finished building.

## By game stage

Win rate of the same board against the real opponent, ties counting half, so this has no survivor bias. Pool (b), no rule changes, 150 games.

| Stage | Avg units | Random layout | Heuristic | Search, old boards | Search, scouted | Search, real board |
|---|---:|---:|---:|---:|---:|---:|
| Early (rounds 1-4) | 2.0 | 43.9% | 44.9% | 45.1% | 45.5% | 50.3% |
| Mid (rounds 5-8) | 6.4 | 51.7% | 60.7% | 61.9% | 65.2% | 69.9% |
| Late (rounds 9+) | 7.0 | 57.0% | 63.0% | 65.0% | 68.8% | 74.1% |
| Full boards only | 7.0 | 54.3% | 62.0% | 63.9% | 67.3% | 72.3% |

Pool (a) on the same measure, 100 games (random / heuristic / old boards / real board): early 45.5 / 46.1 / 46.0 / 47.9, mid 54.8 / 60.0 / 59.8 / 65.8, late 61.8 / 62.1 / 66.5 / 74.8. In real games, shuffling plain units late cost nothing measurable (win rate 67.5% shuffled, 66.7% heuristic, though survivor bias favours shuffled here).

The tables for real-game fights by stage are in [position-test-data/summary.md](position-test-data/summary.md).

## What makes position matter, and what doesn't

**Full boards are not the problem.** I expected a full late board to leave little choice. It leaves the most: 18 points between a random layout and the best one found. Early boards leave the least, because 1-2 units have almost nothing to arrange.

**The biggest limit is not knowing the opponent.** On full boards the search's gain over the heuristic goes 1.9 points on old boards, 5.3 scouted, 10.3 on the real board. Layouts that beat one board don't beat another.

**Many fights are settled by stats.** Under random layouts, 31% of boards win over 90% of the time and 29% win under 10%. On the middle 40%, the best layout gains 15.7 points over the heuristic; on the top band it gains 1.2, and on the bottom band 5.8. Stat edge predicts it (first probe run, before the Rotate fix): boards 10+ stat points ahead win about 90%, and those 3-10 behind win about 11%.

**Back-row protection (`column_protection`).** Protecting back units by column instead of by row added nothing in a 45-game screen: on full boards search gained 1.4 points over the heuristic, against 1.9 with today's rule. It wasn't given a full run.

**Random targeting (`across_targeting`).** Making attackers hit the unit across turned placement into a pure matchup game. The real board is worth 87.8% against 72.3% today (45-game screen), but search on old boards fell below the heuristic. In full games it changed nothing that scouting doesn't already give (+0.44 against +0.40, CIs overlap).

**Back row deals half damage (`back_row_half`).** This makes a wrong layout much more costly, even for plain units (+0.98 on pool (a), against +0.11). But on plain units it is one rule: hitters in front, and search can't beat that. It adds +0.18 over the heuristic on pool (b) only. That's a bigger penalty, not much more thinking.

## Which rules text creates a decision

Each unit was tried in all 7 slots on 60 sampled full boards, with 20 fights per slot in each of two halves. **Fixed** is the best slot overall against an average slot: one rule of thumb gets it. **Adaptive** is choosing per board against that best slot, picked on one half and scored on the other. Data: [unit_value.csv](position-test-data/unit_value.csv).

The noise floor matters. The 8 plain filler units in that pool can't react to anything, yet they score adaptive +0.6 to +4.6. So only about +5 and up counts as a real decision.

| Kind of text | Units | Fixed | Adaptive | What it gives |
|---|---|---:|---:|---|
| **Reads the enemy slot ("across from")** | Pack Alpha, Robin Fledgling, Fox Cub | +1.8, +1.5, -0.5 | **+7.1, +6.8, +6.5** | A real decision, and no fixed answer |
| **Pairs on named slots** | Hedgehog Twin, Furrow Racer | +2.2, +6.8 | +5.3, +4.0 | A goal to build toward; at or just above the floor |
| **Buffs "the units in front of this"** | Glow-worm Lantern, Noctule Captain, Weasel Second | +13.9, +11.8, +8.1 | +4.7, -0.6, +1.6 | A big obvious answer. Teaches the board, not depth |
| **Rewards one row** | Fox Notary, Fieldfare (plain, front) | +11.1, +5.3 | +0.7, +0.6 | Same: one right row |
| **Two-sided stance** | Pipistrelle, Double-agent Bat | +3.3, +3.4 | +2.8, +2.3 | Little, at these stats |
| **Moves in combat** | Lead Goose, Barnacle Matriarch, Warren Lookout | +2.6, +0.4, +1.8 | +0.8, +4.0, +2.6 | Nothing measurable |
| **Needs gaps (Solitary)** | Pine Marten, Lone Lynx | +3.3, +7.0 | +0.5, +3.2 | Little on full boards. Lynx wants the corner B3 |
| **Plain stats** | 8 filler units | +0.4 to +5.3 | floor | Nothing past "sturdy in front" |

Ermine Duellist (Quick while undamaged) scored fixed +6.8, adaptive +7.2. I can't explain the adaptive part and haven't looked into it, so don't read it as a rule.

### Guidelines for tribe designers

1. **Each tribe gets 2-3 cards whose value depends on the enemy's slots**: "across from", "the enemy in the same column". These are the only text that clearly created a decision, and scouting is what lets a player use them.
2. **Use "the units in front of / behind this" freely, but don't count it as depth.** It is worth a lot and has one obvious answer. Good for teaching and for punishing careless play. To make it a decision, make the target matter: pair it with a buff that suits only some units in the row.
3. **Give pairs a real cost.** Both Ends works because it ties up two named slots. More text that competes for the same slots should raise the decision further (untested).
4. **Don't rely on moving units or gaps for depth.** Rotate and Bolt measured nothing. Gap text is blank on the full boards that make up all of the late game. Keep them only for flavour or for a tribe's identity.
5. **Position text needs close fights.** With 60% of fights outside the contested band, position cards should stay near budget on stats: extra stats move a fight out of reach of any layout.

## What to do

| Change | Call | Why |
|---|---|---|
| Keep the rows | **Yes** | They pass the bar, and the real-board ceiling shows plenty of room for decisions |
| Add scouting: see the next opponent's board as it fought last round | **Yes, test it in play next** | +0.40 past the rule of thumb, the only clear gain |
| "Across from" text in tribes | **Yes** | The only text that clears the noise floor |
| Back row deals half damage | **Not now; keep as a dial** | Bigger penalty, mostly one rule. Reconsider if playtests find plain units flat |
| Attackers target across | No | Adds nothing past scouting, and drops the randomness of targets |
| Back-row protection by column | No | No gain in the screen |

## How far to trust this

- **A lone scout.** Only the test bot searches or scouts; the other seven neither scout nor respond. If every player scouts, it stops being an edge over the lobby and becomes a skill difference, and layouts may turn into guessing games. Not tested: it needs search in all eight seats. This is the first thing to check by playing.
- **A bot isn't a person.** Search runs 200 fights a turn, which no player can do. The +0.40 is what the information can buy with that much calculation; a person will get less.
- **The heuristic has help.** It reads the row hint on each card, and I wrote those hints for the 12 new units. That helps explain +0.68 on pool (b) against +0.11 on pool (a). Part of it is my labelling, not a rule a new player would know. Under `back_row_half` the heuristic sorts hitters to the front, so that comparison is fair to it.
- **Buying ignores position.** All arms buy identically (tested: same units through round 5 of one seed, before any elimination), and no arm drafts for position. A player building around position could gain more. Boards averaged 2.5 position units of 7 late.
- **The units aren't balanced.** The 12 units follow the library with some text changes (listed in each file's `source.stat_fix`); Lone Lynx's growth lasts this combat, not permanently, and Bolt checks only after attacks. Rotate and Bolt results apply to these versions.
- **The unit probe uses full boards only**, sampled at nearby tiers and arranged sturdiest-first. So it understates gap text on part-full boards. Its adaptive column has an SE of about 2 points, so the ordering within a row of the table isn't reliable.
- **Sample sizes vary.** Full tournaments are 1000 games per arm. Same-board probes are 150 games on pool (b) and 100 on pool (a). Rule screens are 45 games.
- **One bug, caught and re-run.** A failed edit left `on_after_attacking` unwired during the first pool (b) runs, so Rotate did nothing and Bolt fired only when attacked. All pool (b) tables here come from after the fix, apart from the one stat-edge line marked above. Search over shuffled moved from +0.74 to +0.77, which fits Rotate measuring nothing.
- **Pool (a) search wasn't re-run after that fix.** The fix can't touch pool (a), which has no such units, and re-runs of its shuffled and heuristic arms matched byte for byte. The pool (a) probe also predates scouting, so it has no scouted column.

## How to reproduce

```
source /opt/bramble/env.sh
tools/sim/run_position_tournament.sh <out> 3 1000 pool=b arm=search budget=200
# arm=shuffled|heuristic|search|scout|oracle  pool=a|b  rules=back_row_half  probe=true
python3 tools/sim/summarize_position.py <out>
godot --headless -s res://tools/sim/position_unit_value.gd -- <out>/unit_value.csv 60 20
```

Seeds run from 1 in every arm. A search arm took about 15-30 minutes on 3 cores on the shared machine. Games, probe and unit tables: [position-test-data/](position-test-data/). Per-fight CSVs aren't committed; the runs regenerate them.

**What was built:** `src/core/bots/board_search.gd` (budget a parameter, pure, reusable by a Hard bot), 12 units plus a Kit token marked `source.experiment = "position_test"`, 11 mechanic scripts, and the flags in `Combat` (`RULE_*`) and `GameConfig` (`combat_rules`, `pool_exclude`, `human_placement`). All are off by default, and the units load only with `UnitLibrary.load_dir(dir, "position_test")`, so normal games don't change.
