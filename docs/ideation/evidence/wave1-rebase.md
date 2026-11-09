# Wave 1 Step 3 rebase: authored B/C, shipped caps on

The two deciding measures are pre-start median growth R8–R14 (all seats and committed seats) and each committed starting line’s realized R12 median with a whole-seed 95% interval. All other measures below are report only; no new bars are introduced.

Both presets use source `d5b5b4f8`, five tribes, both shipped caps on, four committed line seats and four blind Hard seats, on the identical 320 selected seeds from the [prior shipped control](wave1-shipped-baseline.md). Lobbies are conditioned on Birds and Fairies appearing in the native five-tribe draw, not unconditional shipped lobbies. Common seeds reproduce the sample; purchases and shared-pool use desynchronize shop luck, so shops are unpaired.

These are the actual measured authored B/C rates, including C’s Birds dials. The separate Step 4 current-Birds 2× skilled-play check is not this C setting. This report does not establish all-Hard or field-best gate results.

Source context: this run measures the wave-1 re-base plus Bog fixes with **pass-2 Hunters and free-splashing anchors**. The later merged wave2a head, with pass-3 Hunters and the narrowed pin filter, is a separate measurement.

| Preset | Population | R8 median | R14 median | Growth/round [95% seed interval] |
|---|---|---:|---:|---|
| B | all_seats | 97.000 | 795.000 | 1.420 [1.410, 1.429] |
| B | committed_seats | 95.500 | 831.500 | 1.434 [1.422, 1.455] |
| C | all_seats | 132.500 | 4432.000 | 1.795 [1.775, 1.825] |
| C | committed_seats | 136.000 | 6365.000 | 1.898 [1.852, 1.935] |

| Preset | Starting line | R12 median [95% seed interval] | R12 survivors |
|---|---|---|---:|
| B | birds_homecoming | 367.000 [348.000, 394.500] | 269 |
| B | birds_tempo | 359.000 [342.000, 389.500] | 259 |
| B | fairies_court | 401.500 [361.000, 458.087] | 258 |
| B | fairies_ring | 306.000 [285.000, 326.000] | 264 |
| C | birds_homecoming | 2218.000 [1835.737, 2662.000] | 290 |
| C | birds_tempo | 1979.500 [1754.000, 2174.000] | 292 |
| C | fairies_court | 969.500 [796.438, 1168.000] | 232 |
| C | fairies_ring | 617.000 [541.975, 722.512] | 253 |

Round summaries contain survivors only, without zero imputation. Bootstrap sampling resamples whole lobby seeds, retaining eliminated empty clusters; these population curves do not establish within-player compounding. The prior control’s Birds Homecoming R12 median was 311 versus human examples 459/772. Human figures sum post-fight review-log stats while harness snapshots are pre-start; that comparison is context, not a matched-phase skill estimate.

## Report-only distributions and outcomes

| Preset | Line | R12 p90 | ≥2× own line median | Lobby firsts | Combat wins R8–R14 | Alive before R14 |
|---|---|---:|---:|---:|---:|---:|
| B | birds_homecoming | 672.000 | 7.4% | 1.2% | 53.7% | 171/320 (53.4%) |
| B | birds_tempo | 643.400 | 5.8% | 1.9% | 50.8% | 164/320 (51.2%) |
| B | fairies_court | 1047.400 | 18.2% | 31.6% | 54.0% | 177/320 (55.3%) |
| B | fairies_ring | 656.700 | 11.4% | 23.1% | 56.2% | 186/320 (58.1%) |
| C | birds_homecoming | 9095.700 | 29.0% | 21.9% | 67.8% | 233/320 (72.8%) |
| C | birds_tempo | 10321.000 | 25.7% | 18.1% | 66.5% | 223/320 (69.7%) |
| C | fairies_court | 2868.700 | 25.4% | 15.9% | 45.6% | 143/320 (44.7%) |
| C | fairies_ring | 2012.000 | 20.6% | 14.4% | 48.8% | 158/320 (49.4%) |

| Preset | Round | All-seat p90 | ≥2× pooled round median | Surviving boards | Strict wins / seat-fights |
|---|---:|---:|---:|---:|---:|
| B | 8 | 169.000 | 6.3% | 2560 | 1280/2560 |
| B | 9 | 228.000 | 6.1% | 2560 | 1280/2560 |
| B | 10 | 311.000 | 6.3% | 2536 | 1280/2536 |
| B | 11 | 447.000 | 8.1% | 2377 | 1248/2377 |
| B | 12 | 693.500 | 10.4% | 2096 | 1121/2096 |
| B | 13 | 1147.200 | 13.8% | 1730 | 938/1730 |
| B | 14 | 2154.700 | 18.6% | 1330 | 719/1330 |
| C | 8 | 278.000 | 12.1% | 2560 | 1280/2560 |
| C | 9 | 462.100 | 15.2% | 2560 | 1280/2560 |
| C | 10 | 938.000 | 19.1% | 2525 | 1278/2525 |
| C | 11 | 1942.700 | 22.7% | 2358 | 1242/2358 |
| C | 12 | 4154.100 | 25.5% | 2060 | 1099/2060 |
| C | 13 | 10101.800 | 26.5% | 1697 | 913/1697 |
| C | 14 | 25420.400 | 29.5% | 1313 | 713/1313 |

B: all-seat alive before R14: 1330/2560 (52.0%).

C: all-seat alive before R14: 1313/2560 (51.3%).

## Report-only noncommitted tribe drift

Assigned tribe is the single `needs_tribes` entry of the concrete strategy dealt by the seeded `hard_field:varied` resolver at session creation. These Hard strategies are pinned; final strategy ID is not board composition. Final tribe uses the existing BenchTribes classifier on the last fight-start board: a unique tribe occupying strictly more than half the non-token slots. Neutral non-token units remain in the denominator; goldens count once, while tokens, away Birds and Belly contents do not add slots.

The assigned-tribal denominator excludes neutral strategies with no required tribe, any multi-tribe assignment, and unknown assignments. “Not retaining assigned majority” means a different final label and includes `no_tribe`; the positive other-tribe majority and no-majority counts are separated. The all-seat share uses all 1,280 noncommitted seats, with unassigned seats retained in that denominator but never counted as a tribal mismatch. These are descriptive outcomes, without a new bar.

| Preset | All noncommitted N | Assigned tribal N | Unassigned neutral N | Multi-tribe N | Unknown N | Not retaining assigned majority / assigned | Different / all noncommitted | Other-tribe majority / assigned | No tribe majority / assigned |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| B | 1280 | 1093 | 187 | 0 | 0 | 617 (56.5%) | 48.2% | 481 (44.0%) | 136 (12.4%) |
| C | 1280 | 1093 | 187 | 0 | 0 | 691 (63.2%) | 54.0% | 562 (51.4%) | 129 (11.8%) |

B unassigned neutral final labels: `{"Birds": 5, "Bog folk": 102, "Fairies": 27, "Hunters": 2, "Oozes": 1, "no_tribe": 50}`. Assigned-tribal no-majority reasons: `{"mixed": 68, "tied_plurality": 68}`.


C unassigned neutral final labels: `{"Birds": 4, "Bog folk": 120, "Fairies": 22, "Hunters": 5, "Oozes": 1, "no_tribe": 35}`. Assigned-tribal no-majority reasons: `{"mixed": 75, "tied_plurality": 54}`.

| Preset | Assigned tribe | Final board tribe | Seats |
|---|---|---|---:|
| B | Birds | Birds | 72 |
| B | Birds | Bog folk | 109 |
| B | Birds | Fairies | 7 |
| B | Birds | no_tribe | 21 |
| B | Bog folk | Bog folk | 166 |
| B | Bog folk | Fairies | 1 |
| B | Bog folk | no_tribe | 2 |
| B | Fairies | Bog folk | 133 |
| B | Fairies | Fairies | 114 |
| B | Fairies | Oozes | 1 |
| B | Fairies | no_tribe | 44 |
| B | Hedgerow folk | Bog folk | 47 |
| B | Hedgerow folk | Fairies | 15 |
| B | Hedgerow folk | Hedgerow folk | 26 |
| B | Hedgerow folk | no_tribe | 20 |
| B | Hunters | Birds | 1 |
| B | Hunters | Bog folk | 87 |
| B | Hunters | Fairies | 13 |
| B | Hunters | Hunters | 51 |
| B | Hunters | no_tribe | 22 |
| B | Oozes | Bog folk | 55 |
| B | Oozes | Fairies | 12 |
| B | Oozes | Oozes | 47 |
| B | Oozes | no_tribe | 27 |
| C | Birds | Birds | 51 |
| C | Birds | Bog folk | 132 |
| C | Birds | Fairies | 10 |
| C | Birds | no_tribe | 16 |
| C | Bog folk | Bog folk | 165 |
| C | Bog folk | Fairies | 1 |
| C | Bog folk | no_tribe | 3 |
| C | Fairies | Bog folk | 160 |
| C | Fairies | Fairies | 86 |
| C | Fairies | no_tribe | 46 |
| C | Hedgerow folk | Bog folk | 51 |
| C | Hedgerow folk | Fairies | 20 |
| C | Hedgerow folk | Hedgerow folk | 20 |
| C | Hedgerow folk | no_tribe | 17 |
| C | Hunters | Bog folk | 95 |
| C | Hunters | Fairies | 14 |
| C | Hunters | Hunters | 43 |
| C | Hunters | no_tribe | 22 |
| C | Oozes | Birds | 1 |
| C | Oozes | Bog folk | 64 |
| C | Oozes | Fairies | 14 |
| C | Oozes | Oozes | 37 |
| C | Oozes | no_tribe | 25 |

Wins exclude draws and include real seats paired with ghosts. Alive before R14 means present before its fight.

## Report-only Peat rates

### B

All rounds, all real seats, including ghost-opponent fights; descriptive only.
One card-present seat-fight includes zero outputs and every native card body that started on board or entered during combat. Instances count distinct combat uid per fight; eligible instances had the native pass3 ability when observed. Golden and combat-copied bodies each count as one instance. Off-board hand, away and held cards count only if they enter. Starting-board presence is also retained.
Only successful pass3_bog:king triggers on peat_king bodies count as raises; only exact gold_next_turn carry operations immediately following pass3_bog:cutter triggers on peat_cutter bodies count as Cutter gold. Ability outputs on other bodies are separate. Original starting-side ownership is retained through Changeling swaps; King raises delivered to the opponent are reported separately. Native simultaneous-death Sink witnesses count, as in the source mechanics.
Cutter gold is actual credited next-turn gold after session carry, reconciled per fight against all gold carry plus separate early spoils. Target RecruitCarry adds gold without a carry cap. This does not measure later income, spending or whether an eliminated seat reaches its next turn.

| Round | Card / output | Card-present fights N | Zero-output share | Eligible instance-fights N | Output total | Mean / card-present fight | Mean / eligible instance-fight |
|---|---|---:|---:|---:|---:|---:|---:|
| 1 | Peat King / raises | 0 | unknown | 0 | 0 | unknown | unknown |
| 1 | Peat Cutter / credited next-turn gold | 0 | unknown | 0 | 0 | unknown | unknown |
| 2 | Peat King / raises | 0 | unknown | 0 | 0 | unknown | unknown |
| 2 | Peat Cutter / credited next-turn gold | 0 | unknown | 0 | 0 | unknown | unknown |
| 3 | Peat King / raises | 0 | unknown | 0 | 0 | unknown | unknown |
| 3 | Peat Cutter / credited next-turn gold | 29 | 41.4% | 30 | 18 | 0.621 | 0.600 |
| 4 | Peat King / raises | 0 | unknown | 0 | 0 | unknown | unknown |
| 4 | Peat Cutter / credited next-turn gold | 75 | 38.7% | 80 | 51 | 0.680 | 0.637 |
| 5 | Peat King / raises | 0 | unknown | 0 | 0 | unknown | unknown |
| 5 | Peat Cutter / credited next-turn gold | 125 | 52.8% | 135 | 61 | 0.488 | 0.452 |
| 6 | Peat King / raises | 0 | unknown | 0 | 0 | unknown | unknown |
| 6 | Peat Cutter / credited next-turn gold | 126 | 40.5% | 134 | 81 | 0.643 | 0.604 |
| 7 | Peat King / raises | 1 | 100.0% | 1 | 0 | 0.000 | 0.000 |
| 7 | Peat Cutter / credited next-turn gold | 115 | 48.7% | 121 | 64 | 0.557 | 0.529 |
| 8 | Peat King / raises | 21 | 52.4% | 21 | 12 | 0.571 | 0.571 |
| 8 | Peat Cutter / credited next-turn gold | 81 | 49.4% | 84 | 42 | 0.519 | 0.500 |
| 9 | Peat King / raises | 74 | 47.3% | 75 | 59 | 0.797 | 0.787 |
| 9 | Peat Cutter / credited next-turn gold | 55 | 40.0% | 57 | 33 | 0.600 | 0.579 |
| 10 | Peat King / raises | 186 | 46.2% | 190 | 141 | 0.758 | 0.742 |
| 10 | Peat Cutter / credited next-turn gold | 31 | 32.3% | 32 | 21 | 0.677 | 0.656 |
| 11 | Peat King / raises | 283 | 47.7% | 299 | 217 | 0.767 | 0.726 |
| 11 | Peat Cutter / credited next-turn gold | 22 | 27.3% | 22 | 16 | 0.727 | 0.727 |
| 12 | Peat King / raises | 369 | 46.9% | 414 | 328 | 0.889 | 0.792 |
| 12 | Peat Cutter / credited next-turn gold | 8 | 37.5% | 8 | 5 | 0.625 | 0.625 |
| 13 | Peat King / raises | 406 | 42.1% | 475 | 425 | 1.047 | 0.895 |
| 13 | Peat Cutter / credited next-turn gold | 5 | 40.0% | 5 | 3 | 0.600 | 0.600 |
| 14 | Peat King / raises | 382 | 40.8% | 462 | 423 | 1.107 | 0.916 |
| 14 | Peat Cutter / credited next-turn gold | 3 | 33.3% | 3 | 2 | 0.667 | 0.667 |
| 15 | Peat King / raises | 395 | 40.5% | 482 | 447 | 1.132 | 0.927 |
| 15 | Peat Cutter / credited next-turn gold | 1 | 0.0% | 1 | 1 | 1.000 | 1.000 |
| 16 | Peat King / raises | 353 | 45.0% | 440 | 420 | 1.190 | 0.955 |
| 16 | Peat Cutter / credited next-turn gold | 0 | unknown | 0 | 0 | unknown | unknown |
| 17 | Peat King / raises | 299 | 46.2% | 384 | 341 | 1.140 | 0.888 |
| 17 | Peat Cutter / credited next-turn gold | 0 | unknown | 0 | 0 | unknown | unknown |
| 18 | Peat King / raises | 227 | 41.4% | 299 | 279 | 1.229 | 0.933 |
| 18 | Peat Cutter / credited next-turn gold | 0 | unknown | 0 | 0 | unknown | unknown |
| 19 | Peat King / raises | 146 | 38.4% | 198 | 185 | 1.267 | 0.934 |
| 19 | Peat Cutter / credited next-turn gold | 0 | unknown | 0 | 0 | unknown | unknown |
| 20 | Peat King / raises | 77 | 40.3% | 105 | 107 | 1.390 | 1.019 |
| 20 | Peat Cutter / credited next-turn gold | 0 | unknown | 0 | 0 | unknown | unknown |
| 21 | Peat King / raises | 26 | 46.2% | 38 | 27 | 1.038 | 0.711 |
| 21 | Peat Cutter / credited next-turn gold | 0 | unknown | 0 | 0 | unknown | unknown |
| 22 | Peat King / raises | 6 | 16.7% | 8 | 9 | 1.500 | 1.125 |
| 22 | Peat Cutter / credited next-turn gold | 0 | unknown | 0 | 0 | unknown | unknown |
| All | Peat King / raises | 3251 | 43.6% | 3891 | 3420 | 1.052 | 0.879 |
| All | Peat Cutter / credited next-turn gold | 676 | 44.1% | 712 | 398 | 0.589 | 0.559 |

### C

All rounds, all real seats, including ghost-opponent fights; descriptive only.
One card-present seat-fight includes zero outputs and every native card body that started on board or entered during combat. Instances count distinct combat uid per fight; eligible instances had the native pass3 ability when observed. Golden and combat-copied bodies each count as one instance. Off-board hand, away and held cards count only if they enter. Starting-board presence is also retained.
Only successful pass3_bog:king triggers on peat_king bodies count as raises; only exact gold_next_turn carry operations immediately following pass3_bog:cutter triggers on peat_cutter bodies count as Cutter gold. Ability outputs on other bodies are separate. Original starting-side ownership is retained through Changeling swaps; King raises delivered to the opponent are reported separately. Native simultaneous-death Sink witnesses count, as in the source mechanics.
Cutter gold is actual credited next-turn gold after session carry, reconciled per fight against all gold carry plus separate early spoils. Target RecruitCarry adds gold without a carry cap. This does not measure later income, spending or whether an eliminated seat reaches its next turn.

| Round | Card / output | Card-present fights N | Zero-output share | Eligible instance-fights N | Output total | Mean / card-present fight | Mean / eligible instance-fight |
|---|---|---:|---:|---:|---:|---:|---:|
| 1 | Peat King / raises | 0 | unknown | 0 | 0 | unknown | unknown |
| 1 | Peat Cutter / credited next-turn gold | 0 | unknown | 0 | 0 | unknown | unknown |
| 2 | Peat King / raises | 0 | unknown | 0 | 0 | unknown | unknown |
| 2 | Peat Cutter / credited next-turn gold | 0 | unknown | 0 | 0 | unknown | unknown |
| 3 | Peat King / raises | 0 | unknown | 0 | 0 | unknown | unknown |
| 3 | Peat Cutter / credited next-turn gold | 28 | 39.3% | 29 | 18 | 0.643 | 0.621 |
| 4 | Peat King / raises | 0 | unknown | 0 | 0 | unknown | unknown |
| 4 | Peat Cutter / credited next-turn gold | 70 | 40.0% | 75 | 47 | 0.671 | 0.627 |
| 5 | Peat King / raises | 0 | unknown | 0 | 0 | unknown | unknown |
| 5 | Peat Cutter / credited next-turn gold | 120 | 46.7% | 132 | 70 | 0.583 | 0.530 |
| 6 | Peat King / raises | 0 | unknown | 0 | 0 | unknown | unknown |
| 6 | Peat Cutter / credited next-turn gold | 131 | 45.8% | 142 | 74 | 0.565 | 0.521 |
| 7 | Peat King / raises | 2 | 100.0% | 2 | 0 | 0.000 | 0.000 |
| 7 | Peat Cutter / credited next-turn gold | 113 | 49.6% | 121 | 63 | 0.558 | 0.521 |
| 8 | Peat King / raises | 30 | 43.3% | 30 | 24 | 0.800 | 0.800 |
| 8 | Peat Cutter / credited next-turn gold | 84 | 44.0% | 88 | 51 | 0.607 | 0.580 |
| 9 | Peat King / raises | 101 | 50.5% | 104 | 66 | 0.653 | 0.635 |
| 9 | Peat Cutter / credited next-turn gold | 51 | 52.9% | 51 | 26 | 0.510 | 0.510 |
| 10 | Peat King / raises | 210 | 54.8% | 224 | 136 | 0.648 | 0.607 |
| 10 | Peat Cutter / credited next-turn gold | 25 | 44.0% | 25 | 17 | 0.680 | 0.680 |
| 11 | Peat King / raises | 307 | 51.8% | 336 | 230 | 0.749 | 0.685 |
| 11 | Peat Cutter / credited next-turn gold | 13 | 30.8% | 13 | 11 | 0.846 | 0.846 |
| 12 | Peat King / raises | 361 | 47.9% | 410 | 298 | 0.825 | 0.727 |
| 12 | Peat Cutter / credited next-turn gold | 13 | 61.5% | 13 | 7 | 0.538 | 0.538 |
| 13 | Peat King / raises | 416 | 49.8% | 483 | 339 | 0.815 | 0.702 |
| 13 | Peat Cutter / credited next-turn gold | 6 | 33.3% | 6 | 5 | 0.833 | 0.833 |
| 14 | Peat King / raises | 394 | 53.6% | 487 | 310 | 0.787 | 0.637 |
| 14 | Peat Cutter / credited next-turn gold | 5 | 80.0% | 5 | 1 | 0.200 | 0.200 |
| 15 | Peat King / raises | 358 | 50.0% | 465 | 331 | 0.925 | 0.712 |
| 15 | Peat Cutter / credited next-turn gold | 2 | 50.0% | 2 | 1 | 0.500 | 0.500 |
| 16 | Peat King / raises | 305 | 49.8% | 402 | 302 | 0.990 | 0.751 |
| 16 | Peat Cutter / credited next-turn gold | 3 | 33.3% | 3 | 2 | 0.667 | 0.667 |
| 17 | Peat King / raises | 232 | 48.3% | 322 | 238 | 1.026 | 0.739 |
| 17 | Peat Cutter / credited next-turn gold | 0 | unknown | 0 | 0 | unknown | unknown |
| 18 | Peat King / raises | 171 | 44.4% | 248 | 201 | 1.175 | 0.810 |
| 18 | Peat Cutter / credited next-turn gold | 0 | unknown | 0 | 0 | unknown | unknown |
| 19 | Peat King / raises | 101 | 41.6% | 145 | 130 | 1.287 | 0.897 |
| 19 | Peat Cutter / credited next-turn gold | 0 | unknown | 0 | 0 | unknown | unknown |
| 20 | Peat King / raises | 46 | 30.4% | 71 | 77 | 1.674 | 1.085 |
| 20 | Peat Cutter / credited next-turn gold | 0 | unknown | 0 | 0 | unknown | unknown |
| 21 | Peat King / raises | 10 | 20.0% | 15 | 15 | 1.500 | 1.000 |
| 21 | Peat Cutter / credited next-turn gold | 0 | unknown | 0 | 0 | unknown | unknown |
| 22 | Peat King / raises | 3 | 0.0% | 5 | 9 | 3.000 | 1.800 |
| 22 | Peat Cutter / credited next-turn gold | 0 | unknown | 0 | 0 | unknown | unknown |
| All | Peat King / raises | 3047 | 49.5% | 3749 | 2706 | 0.888 | 0.722 |
| All | Peat Cutter / credited next-turn gold | 664 | 46.1% | 705 | 393 | 0.592 | 0.557 |

## Resolved rates and provenance

Config differences are restricted to `pass3_preset` and resolved rate-derived values. Full configs, rates, source manifests, archive references and computed hashes are retained in the comparison JSON. The source was archived for measurement; no other worktree is imported or played in place.

| Rate | B | C |
|---|---:|---:|
| `birds_cuckoo_share` | 0.1 | 0.2 |
| `birds_dunnock_targets` | 1.0 | 1.0 |
| `birds_dunnock_turns` | 1.0 | 1.0 |
| `birds_golden_egg_enabled` | True | True |
| `birds_golden_egg_multiplier` | 2.0 | 4.0 |
| `birds_golden_homecoming_multiplier` | 2.0 | 4.0 |
| `birds_golden_tern_trip_turns` | 1.0 | 1.0 |
| `birds_homecoming_multiplier` | 2.0 | 4.0 |
| `birds_jack_daw_permanent` | True | True |
| `birds_jack_daw_share` | 0.25 | 0.5 |
| `birds_lump_multiplier` | 1.0 | 1.0 |
| `birds_ratchet_multiplier` | 1.0 | 1.0 |
| `birds_redbreast_share` | 0.125 | 0.25 |
| `birds_redwing_share` | 0.5 | 0.5 |
| `birds_redwing_targets` | 2.0 | 2.0 |
| `birds_stork_gold_step` | 6.0 | 6.0 |
| `birds_stork_recalls` | 1.0 | 1.0 |
| `birds_swallow_trip_turns` | 1.0 | 1.0 |
| `birds_tom_tit_reduction` | 50.0 | 50.0 |
| `birds_tom_tit_targets` | 1.0 | 1.0 |
| `birds_trip_turns` | 2.0 | 2.0 |
| `birds_whistlers_flock_count` | 7.0 | 7.0 |
| `birds_whistlers_loss_share` | 0.5 | 0.5 |
| `bog_bitter_round_up` | True | True |
| `bog_bitter_share` | 0.25 | 0.25 |
| `bog_bufo_halvings` | 1.0 | 1.0 |
| `bog_capstone_gain_toll` | False | False |
| `bog_chorus_lends` | 2.0 | 2.0 |
| `bog_cutter_gold` | 1.0 | 1.0 |
| `bog_frog_doubles_per_turn` | 1.0 | 1.0 |
| `bog_frog_multiplier` | 2.0 | 2.0 |
| `bog_gideon_hitbacks` | 1.0 | 1.0 |
| `bog_golden_frog_multiplier` | 3.0 | 3.0 |
| `bog_golden_nan_share` | 1.0 | 1.0 |
| `bog_golden_ranocchio_share` | 1.0 | 1.0 |
| `bog_golden_soak_keep` | 4.0 | 6.0 |
| `bog_golden_tiddy_share` | 1.0 | 1.0 |
| `bog_hopkin_share` | 0.25 | 0.25 |
| `bog_jenny_pulls` | 1.0 | 1.0 |
| `bog_king_peatlings` | 2.0 | 2.0 |
| `bog_kiss_period` | 3.0 | 3.0 |
| `bog_kisses_per_fight` | 1.0 | 1.0 |
| `bog_lantern_lures` | 1.0 | 1.0 |
| `bog_nan_share` | 0.5 | 0.5 |
| `bog_peatling_stat_share` | 1.0 | 1.0 |
| `bog_pretender_gold` | 1.0 | 1.0 |
| `bog_prima_donna_patches` | 3.0 | 3.0 |
| `bog_ranocchio_share` | 0.5 | 0.5 |
| `bog_sal_toll_multiplier` | 1.0 | 1.0 |
| `bog_soak_keep` | 2.0 | 3.0 |
| `bog_soak_mired_only` | True | True |
| `bog_tiddy_share` | 0.5 | 0.5 |
| `fairies_annis_rings` | 1.0 | 1.0 |
| `fairies_annis_sale` | True | True |
| `fairies_chaser_gold` | 1.0 | 1.0 |
| `fairies_fetch_share` | 1.0 | 1.0 |
| `fairies_golden_monarch_multiplier` | 3.0 | 4.0 |
| `fairies_initial_ring_size` | 4.0 | 6.0 |
| `fairies_lob_growth` | 1.0 | 3.0 |
| `fairies_lob_turns` | 2.0 | 2.0 |
| `fairies_monarch_multiplier` | 2.0 | 3.0 |
| `fairies_monarch_period` | 2.0 | 2.0 |
| `fairies_nan_rings` | 2.0 | 2.0 |
| `fairies_queen_period` | 1.0 | 1.0 |
| `fairies_queen_rings` | 1.0 | 1.0 |
| `fairies_reel_moves` | 2.0 | 2.0 |
| `fairies_ring_growth` | 2.0 | 4.0 |
| `fairies_sally_rings` | 1.0 | 1.0 |
| `fairies_silky_growth` | 1.0 | 2.0 |
| `fairies_wisp_attack` | 1.0 | 1.0 |
| `fairies_wisp_health` | 1.0 | 1.0 |
| `scale_hero_spell_percent` | 10.0 | 20.0 |

B: source `d5b5b4f8f1e088f03ac9e0268f66080982896191`; plan SHA-256 `ed7026627caefd399854c03f8237615b4cff22ff4bff3f1e6d55284da00a85d0`; config SHA-256 `3181be6a456e422f76a5d9c7905c475c628e49c701778768d5c546fa9dd541aa`; resolved-rates SHA-256 `188db59d810674db8fd6ac03f232293d59d513742e46acc857333aa99550f024`; result SHA-256 `88458f67973f929f0b8fbe9f1ad1cc9dbe2db36eaf08c19241884fc8a4ee8b07`; analysis archive `tools/sim/evidence/wave1-rebase-B.boards.json.gz` SHA-256 `842508f3c26e7b0b63e77371fe3389da65d797af8e8191f4255ac31920303080`.

C: source `d5b5b4f8f1e088f03ac9e0268f66080982896191`; plan SHA-256 `406e357d2cda4420fa1e9e79f3202ef486f742ccad53aefc1b56cb68e408553f`; config SHA-256 `ca22f1a37fe5e329177e43220eaf236cfc35af80810f34f53588372808058b8f`; resolved-rates SHA-256 `f9cf7a7994c97f7206ccb98ced9a20c61626769b94d1950fcca1f5ae43ccb0d5`; result SHA-256 `d91d55db3ceeaf7e13f378dc84b9a67492f302bc05500571b62ee3827f34d959`; analysis archive `tools/sim/evidence/wave1-rebase-C.boards.json.gz` SHA-256 `a64c3f5cc9d8fd75bbf851a03ef4020458325372909e3811cdd44937e9753240`.

## Runtime and validation

Both presets completed all 320 planned seeds. Accepted native Godot execution was 1,175.047 s (19.58 min) for B and 1,135.430 s (18.92 min) for C. Accepted chunk wall time was 1,208.026 s and 1,335.973 s; C includes validated orphan-chunk recovery waiting time. These figures exclude earlier shared-lock queues, imports, the full gate and the rejected zero-admitted attempt. The recorded execution history describes those attempts.

The harness-tree full gate passed 1,896 tests / 42,407 assertions with the strict hook clean; 182 Python harness tests passed. The target native counter and all-four-line checks passed. One complete 20-lobby C chunk was recovered after its supervisor expired, using the same source/configuration hashes and full capture validation; its games were not re-fought. Source manifests, all accepted capture/analysis hashes, and exact seed coverage were verified before completion.

Per-line banned-card inputs and the merged wave2a keystone-removed low rolls are queued before the skilled-Birds check; they were not applied to this run.
