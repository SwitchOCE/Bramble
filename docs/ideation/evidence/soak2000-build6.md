# Soak, 2,000 games, build 6

Build: `927b0b7` (ideation build 6). Run on 8 Nov 2026 in a cloud VM, 4 cores. No game code changed.

## Method

`tools/checks/soak.sh 50 <seed>`, 40 chunks of 50 games, seeds **900001–902000**. Four git worktrees, each with its own import cache, ran 10 chunks in sequence, one worktree per core. Each chunk has its own log, so a crash would have cost at most 50 games.

## Results

| Measure | Value |
|---|---|
| Games | 2,000 |
| Rounds / fights | 31,577 / 97,847 |
| Violations | **0** (40 of 40 chunks print `violations 0`) |
| Crashes / log problems | **0** (every chunk exits 0; no ERROR, WARNING or SCRIPT ERROR lines) |
| Wall time | 29 min 16 s (1,756 s) |

## Note, not a bug

The soak flagged 43 fights as `no-winner fight` (`no_attacks`), about 1 in 2,300 fights. The soak counts these as information, not violations. In each one, every unit left on both sides has 0 Attack, so neither side can attack. 42 of the 43 have `marmot_lookout` on both sides. An example is seed 900330, round 5 (`tools/checks/soak.sh 1 900330`). This is a design point, not a rules bug.
