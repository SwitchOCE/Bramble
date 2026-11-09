# Wave 1 five-tribe baseline: C

Five-tribe lobbies conditioned on including Birds and Fairies; one committed seat per written line plus four blind Hard seats. Other three tribes follow the actual seeded game rotation. Not the unconditional shipped lobby population.

Same eligible seed set across cap settings; shop comparisons are unpaired because purchases and pool use desynchronize draws.

320 lobbies; source `d5b5b4f8f1e088f03ac9e0268f66080982896191`; execution wall 1336.0s.

Only growth and realized committed R12 medians decide this step. Other numbers below are reported, not pass/fail.

| Population | Pre-start R8–R14 growth | Seed 95% interval |
|---|---:|---|
| all_seats | 1.795 | [1.775, 1.825] |
| committed_seats | 1.898 | [1.852, 1.935] |

| Starting line | R12 median [seed 95% interval] | R12 survivors | p90 | ≥2× line median | Lobby wins | Fight wins R8–14 | R14 alive |
|---|---|---:|---:|---:|---:|---:|---:|
| line_birds_homecoming | 2218.000 [1835.737, 2662.000] | 290 | 9095.700 | 29.0% | 21.9% | 67.8% | 233/320 (72.8%) |
| line_birds_tempo | 1979.500 [1754.000, 2174.000] | 292 | 10321.000 | 25.7% | 18.1% | 66.5% | 223/320 (69.7%) |
| line_fairies_ring | 617.000 [541.975, 722.512] | 253 | 2012.000 | 20.6% | 14.4% | 48.8% | 158/320 (49.4%) |
| line_fairies_court | 969.500 [796.438, 1168.000] | 232 | 2868.700 | 25.4% | 15.9% | 45.6% | 143/320 (44.7%) |

Round summaries contain surviving seats only, with counts and R14 survival reported. No zero imputation. Whole-lobby seed bootstrap retains empty/eliminated clusters.

All line grouping uses immutable starting line; final line is retained separately.

All rounds, all real seats, including ghost-opponent fights; descriptive only.

One card-present seat-fight includes zero outputs and every native card body that started on board or entered during combat. Instances count distinct combat uid per fight; eligible instances had the native pass3 ability when observed. Golden and combat-copied bodies each count as one instance. Off-board hand, away and held cards count only if they enter. Starting-board presence is also retained.

Only successful pass3_bog:king triggers on peat_king bodies count as raises; only exact gold_next_turn carry operations immediately following pass3_bog:cutter triggers on peat_cutter bodies count as Cutter gold. Ability outputs on other bodies are separate. Original starting-side ownership is retained through Changeling swaps; King raises delivered to the opponent are reported separately. Native simultaneous-death Sink witnesses count, as in the source mechanics.

Cutter gold is actual credited next-turn gold after session carry, reconciled per fight against all gold carry plus separate early spoils. Target RecruitCarry adds gold without a carry cap. This does not measure later income, spending or whether an eliminated seat reaches its next turn.

Peat King by round (report only).

| Round | Card-present fights | Zero-output fights | Eligible instances | Golden instances | Peatlings raised | Per card-present fight | Per eligible instance-fight |
|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 2 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 3 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 4 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 5 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 6 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 7 | 2 | 2 | 2 | 0 | 0 | 0.000 | 0.000 |
| 8 | 30 | 13 | 30 | 0 | 24 | 0.800 | 0.800 |
| 9 | 101 | 51 | 104 | 0 | 66 | 0.653 | 0.635 |
| 10 | 210 | 115 | 224 | 0 | 136 | 0.648 | 0.607 |
| 11 | 307 | 159 | 336 | 5 | 230 | 0.749 | 0.685 |
| 12 | 361 | 173 | 410 | 12 | 298 | 0.825 | 0.727 |
| 13 | 416 | 207 | 483 | 28 | 339 | 0.815 | 0.702 |
| 14 | 394 | 211 | 487 | 45 | 310 | 0.787 | 0.637 |
| 15 | 358 | 179 | 465 | 68 | 331 | 0.925 | 0.712 |
| 16 | 305 | 152 | 402 | 91 | 302 | 0.990 | 0.751 |
| 17 | 232 | 112 | 322 | 83 | 238 | 1.026 | 0.739 |
| 18 | 171 | 76 | 248 | 73 | 201 | 1.175 | 0.810 |
| 19 | 101 | 42 | 145 | 48 | 130 | 1.287 | 0.897 |
| 20 | 46 | 14 | 71 | 29 | 77 | 1.674 | 1.085 |
| 21 | 10 | 2 | 15 | 8 | 15 | 1.500 | 1.000 |
| 22 | 3 | 0 | 5 | 2 | 9 | 3.000 | 1.800 |
| All | 3047 | 1508 | 3749 | 492 | 2706 | 0.888 | 0.722 |

Peat Cutter by round (report only).

| Round | Card-present fights | Zero-output fights | Eligible instances | Golden instances | Gold credited next turn | Per card-present fight | Per eligible instance-fight |
|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 2 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 3 | 28 | 11 | 29 | 0 | 18 | 0.643 | 0.621 |
| 4 | 70 | 28 | 75 | 0 | 47 | 0.671 | 0.627 |
| 5 | 120 | 56 | 132 | 1 | 70 | 0.583 | 0.530 |
| 6 | 131 | 60 | 142 | 2 | 74 | 0.565 | 0.521 |
| 7 | 113 | 56 | 121 | 3 | 63 | 0.558 | 0.521 |
| 8 | 84 | 37 | 88 | 2 | 51 | 0.607 | 0.580 |
| 9 | 51 | 27 | 51 | 3 | 26 | 0.510 | 0.510 |
| 10 | 25 | 11 | 25 | 3 | 17 | 0.680 | 0.680 |
| 11 | 13 | 4 | 13 | 2 | 11 | 0.846 | 0.846 |
| 12 | 13 | 8 | 13 | 2 | 7 | 0.538 | 0.538 |
| 13 | 6 | 2 | 6 | 1 | 5 | 0.833 | 0.833 |
| 14 | 5 | 4 | 5 | 1 | 1 | 0.200 | 0.200 |
| 15 | 2 | 1 | 2 | 1 | 1 | 0.500 | 0.500 |
| 16 | 3 | 1 | 3 | 1 | 2 | 0.667 | 0.667 |
| 17 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 18 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 19 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 20 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 21 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 22 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| All | 664 | 306 | 705 | 22 | 393 | 0.592 | 0.557 |

C Birds rows in this historical run are superseded: they measured provisional 4× homecoming, now being replaced by paper C at 2.5× on wave2a. B Birds remain unchanged. Aggregate C figures describe the measured 4× build.
