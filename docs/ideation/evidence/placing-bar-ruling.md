# Ruling: the "Position matters" bar

**Replace it.** It measures the price of nonsense placement and the placer's own tuning, not whether position is "a tactical and strategic motif" that "matters a bit" (owner, 8 Nov, N-B §8.1).

## What the number measures

- `hard@shuffled` (`bot_level.gd`, `bot_placer.gd`) re-randomises every unpinned unit every turn through `RecruitRules.move`. It still buys position cards, then wrecks them. So the gain is mostly "random is bad", and it grows with every card that punishes a wrong slot. `back_row_half` doubled it with no new decisions (`position-test.md`).
- The search arm is mostly `rule_layout`. Search only runs with 4+ units, a scout and a stat ratio of 0.6 to 1.7, at 20 fights a turn. On 6 Nov the rule gave +0.68 of the +0.77, and search past it was not distinguishable from zero.
- **The bot confounds it.** The reading went 0.91, then 0.57, then 0.14 with no rules change. `STAY_BONUS` and `ROW_STAY` alone move it from 0.14 to 0.57 (`balance-1.md`), so the bar tracks placer tuning. At ±0.22 to ±0.28 it rarely gives a verdict.
- **0.5 is the wrong size.** Hard over Normal, the whole skill bar, is about 1 place. Half of that for position alone is "a big part of the game", not "a bit". The number also says nothing about counterplay.

## Replacement bar text

> **Position matters a bit, and differs by opponent.** Take 100 mid- and late-game boards from bench games (5+ units, pool as it stands), each paired with the opponent board it really fought, keeping fights the rule layout wins 20–80% of the time.
> (a) The best layout found against that opponent wins at least 5 points more than the rule layout (95% CI above 0).
> (b) On at least a quarter of those boards, the best layout puts a different unit in some row than the rule layout does: no single fixed answer.
> (c) Fresh playtesters: most name a fight that placement won or lost for them, or a placement they changed to answer an opponent.

## How to measure it cheaply

It's combat only, with no full games. Adapt `position_unit_value.gd`'s probe: per board, the rule layout plus `BoardSearch` at budget 200, each scored on 40 fresh fights. That's about 30,000 fights, minutes on one core, and it doesn't depend on bot hysteresis constants. On 6 Nov the scouted search scored +5.3 points on full boards, so 5 is reachable and not trivial. Part (c) goes into the playtester brief.

Keep search against shuffled as a printed smoke line, with no bar. If it drops near 0, placement is broken.
