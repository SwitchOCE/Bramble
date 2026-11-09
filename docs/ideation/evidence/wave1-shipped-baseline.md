# Wave 1 shipped-config baseline

The deciding measures are pre-start lobby growth R8–R14 and each starting line’s realized committed R12 median with a whole-seed 95% interval. P90, tails, wins and R14 survival are reported only.

Both settings use five tribes, current unchanged wave-1 rates, four committed line seats and four blind Hard seats. Seeds are the same presized eligible prefix of the original 640 accounting seeds, conditioned on Birds and Fairies both appearing in the native five-tribe draw. This is a calibration population, not an estimate of unconditional shipped lobbies.

Shipped uses `full_game()` with caps on; checkpoint changes only `card_size_caps=false` and `card_rate_limits=false`. Source and preset/config hashes are recorded with each result. Common seeds ensure reproducibility; shop luck is unpaired because purchases and shared-pool use desynchronize draws.

| Setting | Lobbies | Population | R8 median | R14 median | Growth/round [95% seed interval] |
|---|---:|---|---:|---:|---|
| shipped | 320 | all_seats | 71.000 | 344.000 | 1.301 [1.290, 1.312] |
| shipped | 320 | committed_seats | 69.000 | 460.000 | 1.372 [1.362, 1.386] |
| checkpoint | 320 | all_seats | 73.000 | 357.000 | 1.303 [1.295, 1.315] |
| checkpoint | 320 | committed_seats | 69.000 | 459.000 | 1.371 [1.357, 1.384] |

| Setting | Starting line | R12 median [95% seed interval] | R12 survivors |
|---|---|---|---:|
| shipped | birds_homecoming | 311.000 [281.000, 339.000] | 303 |
| shipped | birds_tempo | 302.500 [275.000, 335.000] | 300 |
| shipped | fairies_court | 163.500 [156.000, 181.000] | 202 |
| shipped | fairies_ring | 142.500 [135.000, 148.500] | 228 |
| checkpoint | birds_homecoming | 311.000 [291.975, 336.000] | 303 |
| checkpoint | birds_tempo | 294.000 [279.000, 312.000] | 295 |
| checkpoint | fairies_court | 167.000 [160.000, 183.000] | 215 |
| checkpoint | fairies_ring | 153.000 [148.000, 160.000] | 237 |

B’s 900 is the future realized-board reference; these current-value medians provide the control. No extra band or tail bar is introduced.

Homecoming (shipped) has a realized R12 median of 311.0, versus the two human Birds games’ 459 and 772 (1.48× and 2.48× that script median); the human R14 boards were 883 and 2,085. These are two user-reported examples, not a player-population estimate.
Homecoming (checkpoint) has a realized R12 median of 311.0, versus the two human Birds games’ 459 and 772 (1.48× and 2.48× that script median); the human R14 boards were 883 and 2,085. These are two user-reported examples, not a player-population estimate.

Tester C has 459/883 at R12/R14; tester A has 772/2,085. These supplied figures sum the post-fight review-log board stats, while harness medians use pre-start combat snapshots; the comparison is contextual, not a matched-phase estimate of skill. Human logs: `origin/ideation/c-funprobe-a` and `origin/ideation/c-funprobe-c`, under `docs/ideation/evidence/fun-probe/tester-{a,c}/*birds*`. Birds dials remain unchanged. The later skilled-play check will use current values; the former Birds C tail check is superseded.

## Reported distributions and outcomes

| Setting | Starting line | R12 p90 | ≥2× own line median | Lobby firsts | Combat wins R8–R14 | Alive before R14 |
|---|---|---:|---:|---:|---:|---:|
| shipped | birds_homecoming | 695.0 | 11.9% | 35.3% | 73.1% | 269/320 (84.1%) |
| shipped | birds_tempo | 638.2 | 11.3% | 30.9% | 70.2% | 259/320 (80.9%) |
| shipped | fairies_court | 330.9 | 11.4% | 9.4% | 42.0% | 115/320 (35.9%) |
| shipped | fairies_ring | 267.3 | 8.3% | 9.4% | 43.9% | 142/320 (44.4%) |
| checkpoint | birds_homecoming | 662.0 | 10.9% | 32.8% | 71.5% | 262/320 (81.9%) |
| checkpoint | birds_tempo | 607.4 | 10.5% | 23.1% | 69.6% | 259/320 (80.9%) |
| checkpoint | fairies_court | 330.2 | 9.8% | 10.9% | 42.1% | 120/320 (37.5%) |
| checkpoint | fairies_ring | 277.6 | 7.2% | 10.3% | 44.6% | 141/320 (44.1%) |

| Setting | Round | All-seat p90 | ≥2× pooled round median | Surviving boards |
|---|---:|---:|---:|---:|
| shipped | 8 | 100.0 | 0.9% | 2560 |
| shipped | 9 | 131.0 | 2.9% | 2559 |
| shipped | 10 | 201.8 | 8.3% | 2543 |
| shipped | 11 | 286.0 | 12.7% | 2428 |
| shipped | 12 | 438.0 | 17.9% | 2162 |
| shipped | 13 | 640.0 | 19.6% | 1771 |
| shipped | 14 | 1038.2 | 21.5% | 1355 |
| checkpoint | 8 | 102.0 | 0.9% | 2560 |
| checkpoint | 9 | 137.0 | 3.4% | 2559 |
| checkpoint | 10 | 200.0 | 6.8% | 2541 |
| checkpoint | 11 | 286.0 | 11.5% | 2419 |
| checkpoint | 12 | 429.4 | 15.6% | 2154 |
| checkpoint | 13 | 653.5 | 18.4% | 1736 |
| checkpoint | 14 | 1060.0 | 20.5% | 1371 |

Round medians contain survivors only. The bootstrap resamples whole lobby seeds, preserving seats and empty/eliminated clusters; these curves do not establish within-player compounding. “Alive at R14” means present before the R14 fight. Combat win rates are strict wins (draws are not wins), including real seats paired with ghosts.

The source/preset runner is `tools/sim/wave1_baseline.py`. Another commit is copied with `git archive` under `build/`; another worktree is never imported or played in place. Future presets require explicit override JSON instead of invented dial values. Plans, progress, source/config/rate hashes and sufficient analysis archives accompany the results.
