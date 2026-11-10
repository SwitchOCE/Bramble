# Build 8: measured preset B (10 Nov 2026)

B is set from four realized-board arms. Oozes retain their promoted B. **Fairies miss the confirmation floor:** engine median 480, below 675 (0.75 × 900). **Oozes have a long upper tail:** engine R12 p90 is 116,519, 75.9× its median. No tribe hit the t=3 weak-response cap. The prescribed single confirmation ends the measurement; no redesign, refit or C run follows.

## Arms and provenance

All five runs passed, each with 32/32 seeds and no drops: **2911001–2911032**. The four fit arms use source `47fcc938e214dd1cff7e463a672470e91509da43` (content endpoints unchanged from `cca9242f`); confirmation uses `5e23dcd0f0af02a8445d889ddf7756d3ffbbebe9`. Only sim branches were pushed, through `scripts/sim-run.sh`.

| Arm | Sim id | Actions | Results commit |
|---|---|---|---|
| t0 | `a35-run1-t0-20261110` | [PASS](https://github.com/SwitchOCE/Bramble/actions/runs/42763544606) | `e510d691eabed7cae45b825cfe667962a14d11e7` |
| t1 | `a35-run1-t1-20261110` | [PASS](https://github.com/SwitchOCE/Bramble/actions/runs/42763560495) | `b7f2d85931aee1836f23afae1238457c269ff02c` |
| t2 | `a35-run1-t2-20261110` | [PASS](https://github.com/SwitchOCE/Bramble/actions/runs/42763573048) | `3193797523282667e4f85a4b85a74eb08c75e0ea` |
| t3 | `a35-run1-t3-20261110` | [PASS](https://github.com/SwitchOCE/Bramble/actions/runs/42763611734) | `09c59f3ea22e0633b4ebd5e82aee961233197a1c` |
| confirm | `a35-run1-confirm-20261110` | [PASS](https://github.com/SwitchOCE/Bramble/actions/runs/42764186157) | `3c0f8d24ead4e128cda3efda6d7840d397409a8c` |

Exact submitted [configs](configs/), original resolved [path endpoints and dial limits](path-source.json), [fit and confirmation data](results.json), [dial audit](clamps.json) and [observed stat ceiling hits](stat-caps.json) are committed here. Compact raw lobby captures remain at `sim/<id>/B.lobbies.json.gz` on each results branch and are fetched into `build/sim/<id>/` by `sim-run.sh --wait <id>`. Large fight captures remain Actions artifacts.

## Method and population

`a35_run1` seats all twelve canonical committed lines from `tools/sim/lines/*.json`. Each lobby takes eight consecutive entries from the twelve-line roster, starting at `(seed × 8) mod 12`, then shuffles seat order with a seed-specific stream. Every line gets 21–22 starting seats across the 32 lobbies. The same roster, seats and seeds are used in every arm. Shop choices and pool use diverge as values change; these are reproducible lobbies, not paired shop luck.

All arms use native pass-3 content, all six tribes, no reference Quilboar, preset B, and checkpoint settings (`card_size_caps=false`, `card_rate_limits=false`, loop guards on). Oozes use t=0 in every arm. Shared hero/spell scaling stays 10 and initial Fairy Ring stays 4. Thus the t=1 arm uses the non-Ooze path endpoints, not a run of preset C.

R12 scale is active pre-Start-of-Combat Attack + Health, excluding Bellies and reserves. For each engine line, the fit uses the intersection of seats observed at R12 in **all four arms**. Fit `log(median R12) = a + b × t` by ordinary least squares, solve `(log(900) − a) / b`, round upward to 0.25 and clamp to [0,3]. A nonpositive slope would select 3 and count as weak response. Oozes are observed but not fitted or moved. The shared fit cohorts are small (8–14 for fitted tribes) and condition on survival; the confirmation is essential evidence of the practical limit of that fit.

Confirmation R12 percentiles use every seat alive at R12. Growth is each R14 survivor’s `(R14 / R8)^(1/6)`, then p10 / median / p90 across those seats. R15 ÷ R12 is the ratio of the two medians on the **same R15-surviving seats**. Neither late metric divides changing survivor populations. `results.json` also includes the median of per-seat late ratios and R6–R15 p10/p25/median/p75/p90 for both survivors at each round and the fixed R14 cohort.

## Four points and solved t

Points below are engine-line R12 medians on the cross-arm R12 intersection. Engine lines are Homecoming, Ring, Court, Open Season, Supper and Ooze engine.

| Tribe | Fit seats | t=0 | t=1 | t=2 | t=3 | Raw solved t | Selected t |
|---|---:|---:|---:|---:|---:|---:|---:|
| Birds | 14 | 431.0 | 1,396.0 | 4,345.5 | 24,914.5 | 0.636158 | 0.75 |
| Fairies | 9 | 289.0 | 574.0 | 1,770.0 | 2,394.0 | 1.476927 | 1.50 |
| Bog | 10 | 459.0 | 945.0 | 3,354.5 | 7,587.5 | 0.771115 | 1.00 |
| Hunters | 9 | 481.0 | 604.0 | 1,370.0 | 3,801.0 | 1.202495 | 1.25 |
| Hedgerow | 8 | 698.5 | 847.5 | 4,775.5 | 9,498.5 | 0.529224 | 0.75 |
| Oozes | 18 | 1,301.5 | 2,339.0 | 2,470.5 | 6,232.5 | held | 0.00 |

For transparency, the R12 medians of all surviving engine seats in the four arms (without the intersection) are:

| Tribe | t=0 | t=1 | t=2 | t=3 |
|---|---:|---:|---:|---:|
| Birds | 383.5 | 1,130.0 | 2,467.0 | 19,803.0 |
| Fairies | 412.5 | 423.0 | 2,417.0 | 2,394.0 |
| Bog | 470.0 | 785.5 | 3,023.5 | 9,061.0 |
| Hunters | 550.0 | 682.0 | 1,548.0 | 5,973.0 |
| Hedgerow | 383.5 | 879.0 | 3,774.5 | 7,219.0 |
| Oozes | 1,264.0 | 2,339.0 | 2,666.0 | 7,923.0 |

## Confirmation at measured B

Every percentile uses linear interpolation at `(n−1)q`. Triples are p10 / median / p90. “Alive” is R12 seats / starting seats. Growth n is the number alive at R14; late n is the R15 cohort. Values are descriptive; no extra fit is made for a miss.

| Committed line | R12 A+H | R8–R14 growth ×/round | Growth n | R15 ÷ R12 (n) | Alive R12 |
|---|---:|---:|---:|---:|---:|
| birds_homecoming | 362.4 / 867.0 / 3,215.4 | 1.427 / 1.595 / 2.008 | 12 | 2.416 (10) | 19/21 (90.5%) |
| birds_tempo | 387.4 / 604.0 / 1,818.6 | 1.429 / 1.639 / 1.799 | 8 | 3.321 (8) | 15/21 (71.4%) |
| bog_court | 628.0 / 742.0 / 1,371.0 | 1.330 / 1.730 / 2.152 | 5 | 11.214 (5) | 11/21 (52.4%) |
| bog_swamp | 509.0 / 839.5 / 2,755.0 | 1.471 / 1.677 / 1.858 | 10 | 5.595 (7) | 16/21 (76.2%) |
| fairies_court | 308.5 / 901.0 / 1,746.5 | 1.392 / 1.632 / 2.073 | 10 | 7.561 (9) | 16/22 (72.7%) |
| fairies_ring | 220.1 / 480.0 / 1,658.3 | 1.391 / 1.783 / 1.960 | 7 | 13.591 (7) | 14/22 (63.6%) |
| hedgerow_parish | 337.5 / 930.0 / 7,538.0 | 1.430 / 1.723 / 2.001 | 11 | 8.873 (10) | 16/22 (72.7%) |
| hedgerow_supper | 407.2 / 1,313.0 / 3,396.2 | 1.427 / 1.707 / 2.028 | 10 | 5.661 (9) | 19/22 (86.4%) |
| hunters_open_season | 446.0 / 790.0 / 1,963.0 | 1.454 / 1.691 / 3.266 | 9 | 4.272 (7) | 16/21 (76.2%) |
| hunters_pack | 304.6 / 1,074.0 / 2,837.8 | 1.565 / 1.998 / 3.104 | 10 | 10.241 (9) | 15/21 (71.4%) |
| oozes_engine | 677.8 / 1,535.0 / 116,519.0 | 1.262 / 1.780 / 3.006 | 18 | 21.986 (15) | 19/21 (90.5%) |
| oozes_tempo | 589.8 / 1,105.0 / 9,360.4 | 1.265 / 1.407 / 2.278 | 18 | 3.209 (18) | 20/21 (95.2%) |

**Flags:** the pre-confirmation diagnostic for a collapsed lower tail was p10 < 0.25× its median; no line meets it. The required upper-tail flag (p90 > 10× median) fires for **Ooze engine only**, at 75.9×. As an additional conservative check, p10 declined on baseline/confirmation shared R12 seats for Parish (368.5 → 329.3, −10.6%, n=16) and Ooze engine (771.8 → 653.7, −15.3%, n=19). Both remain above the collapse diagnostic. These modest regressions are recorded, not treated as permission for another fit.

**Scale:** Fairies engine is 480 (0.533× target), the only engine below 675. Its Court line is 901. Birds (867), Bog (742) and Hunters (790) are below 900 but above the prescribed floor. Hedgerow is 1,313 and Oozes 1,535. None flatten after R12 on the surviving late cohort; the late figures are large, especially Oozes, and are not a guarantee for eliminated seats.

## Every limit and cap hit

No selected t was capped at 3 and no selected dial was clipped. The complete [dial audit](clamps.json) records both clipping and equality with a limit, before and after, for each arm and the selected values. Actual clipping was:

| Arm | Dial | Snapped/derived → limited |
|---|---|---:|
| t2 | `bog_tiddy_share` | 1.25 → 1 |
| t3 | `bog_tiddy_share` | 1.75 → 1 |
| t3 | `hunters_wick_share` | 1.125 → 1 |
| t3 | `hunters_grizel_share` | 1.125 → 1 |
| t3 | `hunters_pelt_share` | 1.125 → 1 |
| t3 | `hunters_golden_ermeline_pelts` | 16 → 10 |

Equality hits without clipping: in every arm and selected B, Oozes’ Elder/Hasty shares are at max 1; Nell meals, Bubble belly, Dollop belly, Slice count, Hasty swallows, Bubble splits, Wobbly drip, Frumenty meals and Syllabub fires are at min 1. Golden Dozey equals its normal wake multiplier in every arm and selected B. At t=0, golden Bird homecoming equals normal (2), and Ermeline is at min 1 Pelt. At t=2 and t=3, golden Tiddy is at max 2 after deriving from the limited normal share. At t=3, Nip, Sable, Lutra and Russet shares equal max 1. There are no other dial-limit hits.

The engine’s separate safety ceiling remains **1 billion per unit stat** even with gameplay caps off. These are every observed ceiling hit in active pre-combat unit snapshots (a unit/round can recur). The [full list](stat-caps.json) names arm, seed, seat, line, round, slot, unit and A/H:

| Arm | Unit-round hits | Seats | First round | Peak captured board A+H |
|---|---:|---:|---:|---:|
| t0 | 0 | 0 | — | 2,495,443 |
| t1 | 0 | 0 | — | 522,229,661 |
| t2 | 1 | 1 | 18 | 1,758,826,136 |
| t3 | 64 | 15 | 15 | 10,669,619,589 |
| confirm | 7 | 1 | 14 | 4,343,141,011 |

In t=2 the single hit is Ooze engine. In t=3 the hit counts by line are Ooze engine 18, Ooze tempo 11, Parish 8, Supper 13, Open Season 10, Pack 2 and Birds tempo 2. In confirmation all seven unit-round hits belong to **Ooze tempo, seed 2911018, seat 6, R14–R17**. No arm has an observed active-unit ceiling hit at R12.

## Changes and validation

`rates.json` changes only preset B and its explanatory note. Preset C, fallback rates and all Ooze B keys are byte-value equivalent to the starting JSON. Normal/golden faces, existing reminders and existing borrowed-text fragments are regenerated only where the old and new resolved numbers produce different words. The final three fragment-copy updates after confirmation have identical gameplay hashes to the confirming source; mechanics and bot policies are unchanged.

The path tests pin every measured non-Ooze B dial and the promoted Ooze endpoints. Existing mechanism counterexamples explicitly opt into their original dial fixtures in `tests/core/pass3_original_b.gd` instead of silently depending on a moving preset; current-default content/preset tests use the measured values.

Validation: **605/605 tests pass across 44 targeted core files**, plus **26/26 Python harness tests**. Ruff check/format, gdlint and gdformat --check pass using the gate’s scopes. No full Godot suite ran; the orchestrator retains the cloud gate.

```sh
XDG_DATA_HOME=/tmp/bramble-run1-data XDG_STATE_HOME=/tmp/bramble-run1-state \
  scripts/godot_slot.sh godot --headless -s addons/gut/gut_cmdln.gd \
  -gconfig=docs/ideation/evidence/a35-run1/targeted.gut.json
python3 -m unittest tools.checks.tests.test_sim_job tools.checks.tests.test_quilboar_h1_driver
ruff check && ruff format --check
gdlint src tools/checks tools/play tools/sim
(cd tests && gdlint .)
gdformat --check src tools/checks tools/play tools/sim tests
python3 docs/ideation/evidence/a35-run1/analyze.py \
  --confirmation build/sim/a35-run1-confirm-20261110 --out /tmp/a35-run1-results.json
```

To reproduce the fits, first fetch the five result branches with `scripts/sim-run.sh --wait <id>`, then run the final analysis command. No new simulations are needed. The original endpoints are frozen here because Pass3Path now interpolates from the newly authored B to the unchanged C.
