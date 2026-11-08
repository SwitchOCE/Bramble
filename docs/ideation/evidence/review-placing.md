# Review: placing bar measurement (9511223)

**0 cut, 2 ask, 2 simplify. (a) passes honestly; (b) passes but is near-trivial as written.**

- **Ask** `placing-bar-ruling.md:21`, `PLAN.md:57`: the bar searches against the exact board fought, which no player sees when placing. The "+5.3, so 5 is not trivial" calibration was the *scouted* arm (`position-test.md:60`: 1.9 old, 5.3 scouted, 10.3 real board). Should (a) also be read with scouted information?
- **Ask** `placing-bar.md:34`: `check.sh` never passed as one run (read-only `/opt`). Accept as environment?
- **Simplify** `PLAN.md:57` (b): replace "differs from the rule" with a cross-opponent swap (below). Any imperfect rule passes (b), and it misses answers within a row: the 35 boards with no row change still gained +19.6.
- **Simplify** `placing_bar_probe.gd:255`: hard-coded t criticals allow only 100 or 2 boards, so smaller reruns can't use `summarize`.

## Probe

No leaks: screening, search (uint32, below 13e9), shuffle and evaluation seeds are disjoint; `src/` matches `3aac44b`.

**Rerun.** 60 boards, 10 fresh games (31082001+), new fight seeds, plus a **decoy** arm: search against another real board from that round, scored against the real opponent. Script and rows: `review-placing/`.

| Arm (vs real opponent) | Points over rule, 95% CI |
|---|---|
| Search on real board | **+24.1** [19.3, 29.0] (replicates) |
| Search on decoy board | +6.4 [0.4, 12.5] |
| Real minus decoy | **+17.7** [12.0, 23.4] |
| Shuffled | +1.2 [−5.8, 8.3] |

On the decoy board, its own layout beats the real one by +12.3 [7.3, 17.2].

**Reading.** About 6 of 24 points is generic (weak rule; the 20–80% screen on the rule tilts against it); about 18 is opponent-specific, so (a) isn't mostly bot weakness. The gap from +5.3: exact board not scouted, mid-band screen, and a rule that lost its old +7.7 lead over random. The decoy arm (+6.4) is near the old scouted figure.

## Bot leads

1. The rule is no better than random here; a fixed rule distilled from search should gain about 5 points against anyone.
2. Most value is in matching the opponent: the lever is predicting the next board (scouting), not search budget.
