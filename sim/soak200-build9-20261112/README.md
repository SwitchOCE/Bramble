# Sim run `soak200-build9-20261112`

- Commit: `513fedbb929e6ad0972987a19697a31a604bfcc4`
- Kind: soak, preset B, library res://content/fields/baseline.json.gz
- Timing: config commit to merge 260 s; run https://github.com/SwitchOCE/Bramble/actions/runs/43079293025

**Verdict: FAIL.** 40 violations, 0 crashes, log problems in shards none.
- Report problems: none

- Games: 200 seeds, 200 played; mix {'field': 40, 'other': 40, 'preset': 120}; field games skipped (no library) 0; synthetic games 0 (separate).

Distinct violation lines (count across shards; a directed check repeats once per shard):

- 1x `seed 4 round 0: GameSession.create failed (field game)`
- 1x `seed 9 round 0: GameSession.create failed (field game)`
- 1x `seed 14 round 0: GameSession.create failed (field game)`
- 1x `seed 19 round 0: GameSession.create failed (field game)`
- 1x `seed 24 round 0: GameSession.create failed (field game)`
- 1x `seed 29 round 0: GameSession.create failed (field game)`
- 1x `seed 34 round 0: GameSession.create failed (field game)`
- 1x `seed 39 round 0: GameSession.create failed (field game)`
- 1x `seed 44 round 0: GameSession.create failed (field game)`
- 1x `seed 49 round 0: GameSession.create failed (field game)`
- 1x `seed 54 round 0: GameSession.create failed (field game)`
- 1x `seed 59 round 0: GameSession.create failed (field game)`
- 1x `seed 64 round 0: GameSession.create failed (field game)`
- 1x `seed 69 round 0: GameSession.create failed (field game)`
- 1x `seed 74 round 0: GameSession.create failed (field game)`
- 1x `seed 79 round 0: GameSession.create failed (field game)`
- 1x `seed 84 round 0: GameSession.create failed (field game)`
- 1x `seed 89 round 0: GameSession.create failed (field game)`
- 1x `seed 94 round 0: GameSession.create failed (field game)`
- 1x `seed 99 round 0: GameSession.create failed (field game)`
- 1x `seed 104 round 0: GameSession.create failed (field game)`
- 1x `seed 109 round 0: GameSession.create failed (field game)`
- 1x `seed 114 round 0: GameSession.create failed (field game)`
- 1x `seed 119 round 0: GameSession.create failed (field game)`
- 1x `seed 124 round 0: GameSession.create failed (field game)`
- 1x `seed 129 round 0: GameSession.create failed (field game)`
- 1x `seed 134 round 0: GameSession.create failed (field game)`
- 1x `seed 139 round 0: GameSession.create failed (field game)`
- 1x `seed 144 round 0: GameSession.create failed (field game)`
- 1x `seed 149 round 0: GameSession.create failed (field game)`
- 1x `seed 154 round 0: GameSession.create failed (field game)`
- 1x `seed 159 round 0: GameSession.create failed (field game)`
- 1x `seed 164 round 0: GameSession.create failed (field game)`
- 1x `seed 169 round 0: GameSession.create failed (field game)`
- 1x `seed 174 round 0: GameSession.create failed (field game)`
- 1x `seed 179 round 0: GameSession.create failed (field game)`
- 1x `seed 184 round 0: GameSession.create failed (field game)`
- 1x `seed 189 round 0: GameSession.create failed (field game)`
- 1x `seed 194 round 0: GameSession.create failed (field game)`
- 1x `seed 199 round 0: GameSession.create failed (field game)`

Synthetic-card games: 0 violations (reported, not the verdict).

Raw logs are the workflow run's `sim-raw-<i>` artifacts (7 days).
