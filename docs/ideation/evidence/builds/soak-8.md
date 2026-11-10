# Build 8 field-inclusive soak — 10 Nov 2026

**PASS: 200/200 games played; 0 violations; 0 crashes; 0 field games skipped.**

- Sim id: `soak200-build8-20261110`.
- Base/library commit: `75bf679674d982127c7fc7057f4a5aa257221b6c`.
- Config commit: `c2dd69b87cf979761c3df550ccda8c846dce27ff`.
- Result commit: `f44d6b584eed65f53f60640e258c467383b5b301`.
- Branch: `ideation/sim/soak200-build8-20261110`.
- The only push was through `scripts/sim-run.sh`. Its `--wait` exited 0.

Config at `sim/soak200-build8-20261110.json` on that branch:

```json
{
  "kind": "soak",
  "preset": "B",
  "first_seed": 1,
  "lobbies": 200,
  "shards": 8,
  "library": "res://content/fields/baseline.json.gz",
  "synthetic": 0
}
```

All seeds 1–200 are accounted for across eight shards: 120 preset games,
40 other-preset games and all 40 field games. No dropped seeds, log problems
or shard report problems. Longest shard: 183.0 seconds.
The [raw summary](soak-8.json) preserves the complete merged receipt.
Local results: `build/sim/soak200-build8-20261110/`.

Subsequent fixes affect UI presentation, animation labels, logs and the UI
harness, without changing game rules, rates, content or line policies. The
final-source library gameplay hashes and profiles still match the capture.
The soak includes the merged combat-start identity fix and Soup 0.2.
