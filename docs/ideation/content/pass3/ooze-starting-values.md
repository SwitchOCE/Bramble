Merged `c5e65925`. Arm b is now Ooze preset B; C follows clamped arm c, with all 23 Ooze path dials spanning B to C. All normal/golden faces match B. Both overflow guards remain, with mutation tests proving their regressions fail without them. Runtime eating attribution was removed; historical evidence and offline analysis remain.

Frozen replays: **24/24 byte-identical**, including **12/12 without Oozes**. No fixtures or hashes changed; historical content/configs remain pinned. Proof: [replay manifest](../../evidence/ooze-promotion/replay-proof.json).

[Actions confirmation](https://github.com/SwitchOCE/Bramble/actions/runs/42759128163): preset B, no overrides, seeds 2911001–2911032, zero drops. Every seat-round reproduces arm b.

| Line | R12 p10 | Median | p90 | R8–R14 ×/round |
|---|---:|---:|---:|---:|
| Ooze engine | 592.3 | 1,205.5 | 4,272 | 1.454 |
| Pot Luck | 309 | 736 | 1,600 | 1.385 |
| Birds | — | 365 | — | — |
| Fairies | — | 351.5 | — | — |
| Bog | — | 161.5 | — | — |
| Hedgerow | — | 89 | — | — |
| Hunters | — | 102 | — | — |
| Hard | — | 740 | — | — |

Growth is the median individual seat factor per round, paired R8/R14: engine n=28, Pot Luck n=26. R12 stats are pre-start active A+H. [Detailed results](../../evidence/ooze-promotion/sim-results.json).

Review checks: 72 affected GUT and 173 gate Python tests pass; ruff, gdlint and gdformat --check pass. Two broader sim-test failures reproduce at e286d539. No full Godot suite run.
