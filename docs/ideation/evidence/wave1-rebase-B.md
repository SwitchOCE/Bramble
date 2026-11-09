# Wave 1 five-tribe baseline: B

Five-tribe lobbies conditioned on including Birds and Fairies; one committed seat per written line plus four blind Hard seats. Other three tribes follow the actual seeded game rotation. Not the unconditional shipped lobby population.

Same eligible seed set across cap settings; shop comparisons are unpaired because purchases and pool use desynchronize draws.

320 lobbies; source `d5b5b4f8f1e088f03ac9e0268f66080982896191`; execution wall 1208.0s.

Only growth and realized committed R12 medians decide this step. Other numbers below are reported, not pass/fail.

| Population | Pre-start R8–R14 growth | Seed 95% interval |
|---|---:|---|
| all_seats | 1.420 | [1.410, 1.429] |
| committed_seats | 1.434 | [1.422, 1.455] |

| Starting line | R12 median [seed 95% interval] | R12 survivors | p90 | ≥2× line median | Lobby wins | Fight wins R8–14 | R14 alive |
|---|---|---:|---:|---:|---:|---:|---:|
| line_birds_homecoming | 367.000 [348.000, 394.500] | 269 | 672.000 | 7.4% | 1.2% | 53.7% | 171/320 (53.4%) |
| line_birds_tempo | 359.000 [342.000, 389.500] | 259 | 643.400 | 5.8% | 1.9% | 50.8% | 164/320 (51.2%) |
| line_fairies_ring | 306.000 [285.000, 326.000] | 264 | 656.700 | 11.4% | 23.1% | 56.2% | 186/320 (58.1%) |
| line_fairies_court | 401.500 [361.000, 458.087] | 258 | 1047.400 | 18.2% | 31.6% | 54.0% | 177/320 (55.3%) |

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
| 7 | 1 | 1 | 1 | 0 | 0 | 0.000 | 0.000 |
| 8 | 21 | 11 | 21 | 0 | 12 | 0.571 | 0.571 |
| 9 | 74 | 35 | 75 | 0 | 59 | 0.797 | 0.787 |
| 10 | 186 | 86 | 190 | 0 | 141 | 0.758 | 0.742 |
| 11 | 283 | 135 | 299 | 0 | 217 | 0.767 | 0.726 |
| 12 | 369 | 173 | 414 | 5 | 328 | 0.889 | 0.792 |
| 13 | 406 | 171 | 475 | 27 | 425 | 1.047 | 0.895 |
| 14 | 382 | 156 | 462 | 52 | 423 | 1.107 | 0.916 |
| 15 | 395 | 160 | 482 | 87 | 447 | 1.132 | 0.927 |
| 16 | 353 | 159 | 440 | 103 | 420 | 1.190 | 0.955 |
| 17 | 299 | 138 | 384 | 124 | 341 | 1.140 | 0.888 |
| 18 | 227 | 94 | 299 | 110 | 279 | 1.229 | 0.933 |
| 19 | 146 | 56 | 198 | 81 | 185 | 1.267 | 0.934 |
| 20 | 77 | 31 | 105 | 54 | 107 | 1.390 | 1.019 |
| 21 | 26 | 12 | 38 | 20 | 27 | 1.038 | 0.711 |
| 22 | 6 | 1 | 8 | 3 | 9 | 1.500 | 1.125 |
| All | 3251 | 1419 | 3891 | 666 | 3420 | 1.052 | 0.879 |

Peat Cutter by round (report only).

| Round | Card-present fights | Zero-output fights | Eligible instances | Golden instances | Gold credited next turn | Per card-present fight | Per eligible instance-fight |
|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 2 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 3 | 29 | 12 | 30 | 0 | 18 | 0.621 | 0.600 |
| 4 | 75 | 29 | 80 | 0 | 51 | 0.680 | 0.637 |
| 5 | 125 | 66 | 135 | 1 | 61 | 0.488 | 0.452 |
| 6 | 126 | 51 | 134 | 2 | 81 | 0.643 | 0.604 |
| 7 | 115 | 56 | 121 | 2 | 64 | 0.557 | 0.529 |
| 8 | 81 | 40 | 84 | 1 | 42 | 0.519 | 0.500 |
| 9 | 55 | 22 | 57 | 1 | 33 | 0.600 | 0.579 |
| 10 | 31 | 10 | 32 | 1 | 21 | 0.677 | 0.656 |
| 11 | 22 | 6 | 22 | 1 | 16 | 0.727 | 0.727 |
| 12 | 8 | 3 | 8 | 0 | 5 | 0.625 | 0.625 |
| 13 | 5 | 2 | 5 | 0 | 3 | 0.600 | 0.600 |
| 14 | 3 | 1 | 3 | 0 | 2 | 0.667 | 0.667 |
| 15 | 1 | 0 | 1 | 0 | 1 | 1.000 | 1.000 |
| 16 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 17 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 18 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 19 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 20 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 21 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| 22 | 0 | 0 | 0 | 0 | 0 | unknown | unknown |
| All | 676 | 298 | 712 | 9 | 398 | 0.589 | 0.559 |
