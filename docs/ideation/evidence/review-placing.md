# Review: placing bar measurement (9511223)

**0 cut, 2 ask, 2 simplify. (a) passes honestly; (b) passes but is near-trivial as written.**

- **Ask** `placing-bar-ruling.md:21`, `PLAN.md:57`: the bar searches against the exact board fought, which no player sees when placing. The "+5.3, so 5 is not trivial" calibration was the *scouted* arm (`position-test.md:60`: 1.9 old, 5.3 scouted, 10.3 real board). Should (a) also be read with scouted information?
- **Ask** `placing-bar.md:34`: `check.sh` never passed as one run (read-only `/opt`). Accept as environment?
- **Simplify** `PLAN.md:57` (b): replace "differs from the rule" with a cross-opponent swap (below). Any imperfect rule passes (b), and it misses answers within a row: the 35 boards with no row change still gained +19.6.
- **Simplify** `placing_bar_probe.gd:255`: hard-coded t criticals allow only 100 or 2 boards, so smaller reruns can't use `summarize`.

## Probe

No leaks found. Screening, search, shuffle and evaluation seeds don't overlap. Search draws uint32 fight seeds, all below 13e9. The rule layout is only screened on its own seeds. `src/` is unchanged from `3aac44b`.

**Rerun.** 60 boards from 10 fresh games (seeds 31082001+, all fight seeds new), plus a **decoy** arm: search against another real board from the same round, scored against the real opponent. Script and rows are in `review-placing/`.

| Arm (vs real opponent) | Points over rule, 95% CI |
|---|---|
| Search on real board | **+24.1** [19.3, 29.0] (replicates) |
| Search on decoy board | +6.4 [0.4, 12.5] |
| Real minus decoy | **+17.7** [12.0, 23.4] |
| Shuffled | +1.2 [−5.8, 8.3] |

On the decoy board, its own layout beats the real one by +12.3 [7.3, 17.2].

**Reading.** About 6 of the 24 points is generic: the rule is weak, and boards screened at 20–80% on the rule tilt against it. About 18 points is opponent-specific, so (a) isn't mostly bot weakness. The gap from +5.3 has three parts: an exact board instead of a scouted one, a mid-band screen, and a rule that has lost its old +7.7 lead over random. The decoy arm (+6.4) is close to the old scouted figure.

## Bot leads

1. The rule is no better than random on these boards. A fixed rule distilled from search should gain about 5 points against any opponent.
2. Most of the value is in matching the opponent, so the key lever is predicting the next opponent's board (scouting), not more search budget.
