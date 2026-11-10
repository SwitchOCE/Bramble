# Sim run `soak-200-b`

- Commit: `26d5bf65056820535297f3622b05dd990d06b9fe`
- Kind: soak, preset B, library none
- Timing: config commit to merge 200 s; run https://github.com/SwitchOCE/Bramble/actions/runs/42734373732

**Verdict: FAIL.** 198 violations, 0 crashes, log problems in shards none.

- Games: 200 seeds, 160 played; mix {'other': 40, 'preset': 120}; field games skipped (no library) 40; synthetic games 0 (separate).

Distinct violation lines (count across shards; a directed check repeats once per shard):

- 96x `seed 0 round 0: bog mirror raised more than two Peatlings per King`
- 3x `seed 5 round 0: LegalActions listed { "action": "play_item", "args": [0, 1] } and the rules said 'Choose a Bird'`
- 3x `seed 53 round 0: LegalActions listed { "action": "play_item", "args": [1, 0] } and the rules said 'Choose a Bird'`
- 3x `seed 90 round 0: LegalActions listed { "action": "play_item", "args": [0, 2] } and the rules said 'Choose a Bird'`
- 2x `seed 1 round 0: LegalActions listed { "action": "play_item", "args": [3, 5] } and the rules said 'Choose a Bird'`
- 2x `seed 5 round 0: LegalActions listed { "action": "play_item", "args": [0, 3] } and the rules said 'Choose a Bird'`
- 2x `seed 53 round 0: LegalActions listed { "action": "play_item", "args": [1, 6] } and the rules said 'Choose a Bird'`
- 2x `seed 90 round 0: LegalActions listed { "action": "play_item", "args": [0, 3] } and the rules said 'Choose a Bird'`
- 1x `seed 1 round 0: LegalActions listed { "action": "play_item", "args": [3, 6] } and the rules said 'Choose a Bird'`
- 1x `seed 1 round 0: LegalActions listed { "action": "play_item", "args": [3, 3] } and the rules said 'Choose a Bird'`
- 1x `seed 1 round 0: LegalActions listed { "action": "play_item", "args": [4, 5] } and the rules said 'Choose a Bird'`
- 1x `seed 1 round 0: LegalActions listed { "action": "play_item", "args": [2, 5] } and the rules said 'Choose a Bird'`
- 1x `seed 3 round 0: LegalActions listed { "action": "play_item", "args": [0, 0] } and the rules said 'Choose a Bird'`
- 1x `seed 5 round 0: LegalActions listed { "action": "play_item", "args": [0, 2] } and the rules said 'Choose a Bird'`
- 1x `seed 5 round 0: LegalActions listed { "action": "play_item", "args": [0, 0] } and the rules said 'Choose a Bird'`
- 1x `seed 7 round 0: LegalActions listed { "action": "play_item", "args": [0, 6] } and the rules said 'Choose a Bird'`
- 1x `seed 10 round 0: LegalActions listed { "action": "play_item", "args": [2, 6] } and the rules said 'Choose a Bird'`
- 1x `seed 10 round 0: LegalActions listed { "action": "play_item", "args": [2, 1] } and the rules said 'Choose a Bird'`
- 1x `seed 10 round 0: LegalActions listed { "action": "play_item", "args": [0, 1] } and the rules said 'Choose a Bird'`
- 1x `seed 15 round 18: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 15 round 19: player 7 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 17 round 0: LegalActions listed { "action": "play_item", "args": [0, 1] } and the rules said 'Choose a Bird'`
- 1x `seed 17 round 0: LegalActions listed { "action": "play_item", "args": [0, 2] } and the rules said 'Choose a Bird'`
- 1x `seed 25 round 11: fight 1 v 3 slot 0/5 already holds uid 12`
- 1x `seed 25 round 19: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 25 round 21: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 28 round 0: LegalActions listed { "action": "play_item", "args": [2, 4] } and the rules said 'Choose a Bird'`
- 1x `seed 28 round 0: LegalActions listed { "action": "play_item", "args": [2, 6] } and the rules said 'Choose a Bird'`
- 1x `seed 31 round 14: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 31 round 14: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 31 round 16: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 31 round 20: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 43 round 17: player 7 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 50 round 15: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 53 round 0: LegalActions listed { "action": "play_item", "args": [1, 2] } and the rules said 'Choose a Bird'`
- 1x `seed 53 round 0: LegalActions listed { "action": "play_item", "args": [1, 4] } and the rules said 'This Bird already had a Golden Egg'`
- 1x `seed 57 round 0: LegalActions listed { "action": "play_item", "args": [0, 1] } and the rules said 'Choose a Bird'`
- 1x `seed 57 round 0: LegalActions listed { "action": "play_item", "args": [0, 5] } and the rules said 'Choose a Bird'`
- 1x `seed 63 round 8: fight 1 v 7 slot 1/5 already holds uid 11`
- 1x `seed 75 round 16: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 75 round 19: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 80 round 14: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 80 round 15: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 80 round 16: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 82 round 0: LegalActions listed { "action": "play_item", "args": [4, 6] } and the rules said 'Choose a Bird'`
- 1x `seed 88 round 20: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 90 round 0: LegalActions listed { "action": "play_item", "args": [0, 6] } and the rules said 'Choose a Bird'`
- 1x `seed 91 round 18: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 105 round 15: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 105 round 16: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 105 round 17: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 105 round 18: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 113 round 0: LegalActions listed { "action": "play_item", "args": [1, 5] } and the rules said 'Choose a Bird'`
- 1x `seed 126 round 11: fight 3 v 7 golden changeling starts at 4/4`
- 1x `seed 127 round 0: LegalActions listed { "action": "play_item", "args": [2, 4] } and the rules said 'Choose a Bird'`
- 1x `seed 127 round 0: LegalActions listed { "action": "play_item", "args": [2, 3] } and the rules said 'Choose a Bird'`
- 1x `seed 142 round 17: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 142 round 18: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 143 round 17: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 143 round 19: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 143 round 20: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 147 round 10: fight 5 v 6 golden will_o_the_wisp starts at 5/8`
- 1x `seed 147 round 11: fight 4 v 5 golden will_o_the_wisp starts at 5/8`
- 1x `seed 147 round 12: fight 3 v 5 golden fairy_monarch starts at 6/8`
- 1x `seed 147 round 13: fight 5 v 7 golden fairy_monarch starts at 6/8`
- 1x `seed 147 round 14: fight 1 v 5 golden fairy_monarch starts at 6/8`
- 1x `seed 152 round 15: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 156 round 17: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 170 round 18: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 171 round 14: player 7 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 172 round 0: LegalActions listed { "action": "play_item", "args": [3, 4] } and the rules said 'Choose a Bird'`
- 1x `seed 172 round 0: LegalActions listed { "action": "play_item", "args": [3, 3] } and the rules said 'Choose a Bird'`
- 1x `seed 172 round 0: LegalActions listed { "action": "play_item", "args": [3, 6] } and the rules said 'Choose a Bird'`
- 1x `seed 172 round 17: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 172 round 19: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 175 round 14: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 175 round 16: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 175 round 17: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 175 round 19: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 176 round 18: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 177 round 15: player 7 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 177 round 18: player 7 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 180 round 14: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 180 round 19: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 192 round 19: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 192 round 20: player 5 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 193 round 13: player 3 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 195 round 0: LegalActions listed { "action": "play_item", "args": [0, 4] } and the rules said 'Choose a Bird'`
- 1x `seed 195 round 0: LegalActions listed { "action": "play_item", "args": [0, 3] } and the rules said 'Choose a Bird'`
- 1x `seed 195 round 16: player 7 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 195 round 18: player 7 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 198 round 16: player 1 holds 3 copies of slice untripled (7.3.1)`
- 1x `seed 198 round 19: player 1 holds 3 copies of slice untripled (7.3.1)`

Synthetic-card games: 0 violations (reported, not the verdict).

Raw logs are the workflow run's `sim-raw-<i>` artifacts (7 days).
