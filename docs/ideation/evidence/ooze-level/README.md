# Oozes: which level is the problem at? (10 Nov 2026)

The owner asked (note `2026-11-10e`) for an overestimated buff, new content or a whole-tribe rework, using the design skill, to find out why the Oozes sit far below the round-12 target of 900.

Four pieces of work ran in parallel, each blind to the others:

| File | What it is | Its diagnosis |
|---|---|---|
| `probe-report.md` | Measured: three dial arms on the same 32 B seeds, both Ooze lines, on the sim job | **Parameter.** Arm b clears 900 on the engine line |
| `redesign-d1-surgical.md` | Paper: surgical content changes | Content: no early, independent source of growing food |
| `redesign-d2-culture.md` | Paper: bottom-up mechanical, Digest cultures what it holds | Mechanic: eating is additive |
| `redesign-d3-double.md` | Paper: top-down mechanical, 16-card set where Digest doubles | Mechanic: eating is additive |

The probe's per-round spread of active board stats (alive seats, from its `seat-rounds.csv`), as p10 / p25 / median / p75 / p90:

| Arm, line | R8 | R12 | R14 | Seat growth R8–R14, p10 / median / p90 |
|---|---|---|---|---|
| a (today), engine | 55 / 80 / 114 / 128 / 140 | 247 / 274 / 352 / 434 / 582 | 447 / 573 / 628 / 832 / 1,127 | 1.24 / 1.31 / 1.52 |
| a (today), Pot Luck | 56 / 74 / 96 / 125 / 149 | 176 / 236 / 271 / 381 / 464 | 371 / 432 / 560 / 636 / 878 | 1.23 / 1.30 / 1.43 |
| **b, engine** | 67 / 159 / 257 / 357 / 425 | **625 / 863 / 1,235 / 2,105 / 4,367** | 1,276 / 1,649 / 2,468 / 8,460 / 12,004 | 1.32 / 1.45 / 1.85 |
| **b, Pot Luck** | 77 / 116 / 172 / 262 / 336 | **406 / 601 / 786 / 1,320 / 1,774** | 678 / 930 / 1,311 / 3,036 / 4,422 | 1.22 / 1.38 / 1.66 |
| c, engine | 89 / 506 / 1,899 / 4,120 / 31,290 | 2,355 / 7,122 / 17,990 / 938,324 / 125M | up to the 12B cap | 1.39 / 2.48 / 7.26 |
| c, Pot Luck | 78 / 146 / 738 / 2,148 / 13,827 | 1,035 / 2,622 / 4,400 / 16,468 / 1.0M | up to 369M | 1.25 / 1.76 / 3.97 |

Arm b's overrides, from `ooze-b-20261110-r4`: eat multiplier 7, Aspic bonus 1.8 (golden 4.6), Soup share 0.3, Slice share 0.2, golden Elder 2, the rest at t=3 of the A3.5 dials.

The decision and its reasons are in `DECISIONS.md`, "Oozes: the problem is the numbers".
