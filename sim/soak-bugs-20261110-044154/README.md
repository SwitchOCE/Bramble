# Sim run `soak-bugs-20261110-044154`

- Commit: `34733ea224f8504d66e4f00d4d5255a03b3a7ce2`
- Kind: soak, preset B, library none
- Timing: config commit to merge 219 s; run https://github.com/SwitchOCE/Bramble/actions/runs/42757586837

**Verdict: FAIL.** 47 violations, 0 crashes, log problems in shards none.
- Report problems: none

- Games: 200 seeds, 160 played; mix {'other': 40, 'preset': 120}; field games skipped (no library) 40; synthetic games 0 (separate).

Distinct violation lines (count across shards; a directed check repeats once per shard):

- 1x `seed 8 round 14: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 8 round 15: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 8 round 16: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 17 round 18: player 7 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 22 round 17: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 23 round 15: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 26 round 12: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 28 round 12: player 0 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 40 round 12: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 40 round 15: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 40 round 17: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 43 round 17: player 7 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 45 round 17: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 48 round 13: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 50 round 15: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 62 round 15: player 7 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 65 round 12: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 65 round 15: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 65 round 17: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 65 round 17: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 65 round 18: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 65 round 19: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 68 round 15: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 76 round 14: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 80 round 14: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 80 round 16: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 87 round 18: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 93 round 14: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 93 round 16: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 100 round 15: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 100 round 17: player 7 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 101 round 17: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 121 round 14: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 127 round 17: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 151 round 14: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 162 round 15: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 162 round 18: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 167 round 15: player 7 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 167 round 17: player 7 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 167 round 18: player 7 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 175 round 17: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 182 round 17: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 186 round 16: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 186 round 18: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 190 round 16: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 193 round 13: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 195 round 17: player 7 holds 3 copies of slice untripled (7.3.1)`

Synthetic-card games: 0 violations (reported, not the verdict).

Raw logs are the workflow run's `sim-raw-<i>` artifacts (7 days).
