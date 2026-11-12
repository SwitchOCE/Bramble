# Damage Lab (archived 12 Nov 2026)

An interactive page and the Python scripts used on 12 Nov 2026 to explore hero health and loss damage. Exploratory work. The scripts and the page are a toy model, not a rules engine, and nothing here is a rule.

**What was decided from it.** The owner chose a damage system in chat on 12 Nov 2026. It lives in the rulebook (rules 2.2.5 and 10.1, source C12) on the `design/damage-and-health` branch, not here:
- heroes start on 40 health;
- a small loss deals the round number + 1, up to 10;
- a big loss deals 3 more, and happens when the loser killed fewer than half of the winner's starting units;
- a draw deals 0.

## The page

[damage-lab.html](damage-lab.html) is a single page with no build step. Open it in a browser. It runs a toy 8-player lobby in the browser and charts:
- health in one sample lobby;
- loss damage by round;
- when games end and when the first player goes out;
- how many losses it takes to go out;
- how often a big loss means the loser was outclassed.

The sliders cover starting health, the round-1 loss, growth per round, the cap, the big-loss bonus, how many big losses players avoid, and draws. The presets are the rulebook values with no, some or all greed.

## The model

All scripts in [model/](model/) use the Python standard library only. Run each from inside `model/`, with `python -I <script>.py`. Several scripts load another script from the same folder.

The model's assumptions:
- 8 live players, paired at random each round; a ghost when the count is odd.
- Each player has a fixed skill plus a board strength that drifts each round. The winner is decided by the strength gap plus luck.
- Boards have 2 units on round 1 and grow to 7 by round 6.
- The winner's survivors grow with how lopsided the fight was.

Bramble's async model (rulebook 2.1.5) is still open, so read results as shapes, not final values.

| Script | What it explored |
|---|---|
| econ.py | Board-building gold under the owner's price idea (units cost tier + 1, sell for 1 less) against Battlegrounds prices |
| dmg.py, grid.py | Early loss-damage schedules: base damage by round plus 1 per surviving unit |
| tft.py, tft2.py | TFT's damage numbers (patch 18.1: stage damage 2/5/8/10/12/17 plus 1 per surviving unit, 100 health), squeezed into Bramble's shorter games |
| twolevel.py, detail.py | The two-level small/big loss rule at 100 health: a curve search and per-phase detail |
| v2.py | Big loss = 1.5 × small loss, small loss starting at 4%, with draws |
| small_numbers.py | Whole-number versions of that curve at 50, 40, 30, 25 and 20 health |
| h40.py, h40b.py | 40 health with big loss = small + 3: the owner's table against "round + 1", with and without players avoiding big losses |
