# Build 9: provisional C from realized run-1 boards

Provisional: the endpoints, shared scaling and Soup have changed since run 1. No new arms were run. Only preset C is authored here; preset B and the Ooze probe C are unchanged. Confirmation waits for the bounded content worker’s Ooze/Fairy changes. A miss is reported, never refitted.

## Frozen fit

The five engine-line points and their cross-arm R12 cohort sizes come unchanged from `../a35-run1/results.json`. The path endpoints and card limits come from `../a35-run1/path-source.json`. Fit natural-log median against t, solve for 1,800, round upward to 0.25 and limit t to [0,3]. Oozes keep the probe C rather than receiving a fit.

| Tribe | Cohort n | t=0 / 1 / 2 / 3 median | Raw t | Selected t |
|---|---:|---|---:|---:|
| Birds | 14 | 431.0 / 1,396.0 / 4,345.5 / 24,914.5 | 1.157054 | 1.25 |
| Fairies | 9 | 289.0 / 574.0 / 1,770.0 / 2,394.0 | 2.404961 | 2.50 |
| Bog | 10 | 459.0 / 945.0 / 3,354.5 / 7,587.5 | 1.486991 | 1.50 |
| Hunters | 9 | 481.0 / 604.0 / 1,370.0 / 3,801.0 | 2.189821 | 2.25 |
| Hedgerow | 8 | 698.5 / 847.5 / 4,775.5 / 9,498.5 | 1.254363 | 1.50 |

No tribe hits the weak-response t=3 cap. Tiddy’s normal/golden shares reach 1.0 and 2.0 respectively; golden Ermeline reaches 10 Pelts. These are equality hits, with no dial clipped after snapping. The full numeric audit is in `provisional-rates.json`.

Reproduce the path (through a shared slot):

```sh
source /opt/bramble/env.sh
GODOT_SLOT_CLASS=worker scripts/godot_slot.sh godot --headless -s res://tools/sim/b9_preset_c.gd
```

## Local run and deciding criteria

The one confirmation uses `confirm.json`: preset C, `a35_run1`, seeds 2911001–2911032, 32 lobbies, all twelve committed lines seated 21–22 times, and checkpoint caps off. Shared hero/spell scaling is C’s 20; the initial Fairy Ring is C’s 6. Run locally with `python3 tools/sim/sim_job.py local docs/ideation/evidence/b9-measure/confirm.json build/b9-measure/confirm --jobs 3`; the runner acquires its own slots. No pushes or Actions sims.

Decides: every engine R12 median is within [1,350, 3,600]; every committed line’s median per-seat R8–R14 growth is at least ×1.3 per round. R12 is active pre-start A+H on all surviving seats. Growth uses R14 survivors and `(R14/R8)^(1/6)` per seat; R15÷R12 divides medians on the same R15-surviving cohort. Percentiles interpolate at `(n−1)q`. Low-tail and >10× upper-tail flags are reported, along with R6–R15 distributions and stat ceilings.

## Runtime change

`31e6650a` adds `/tmp/bramble-godot-third.lock` to the two existing shared locks, admits local `--jobs 1–3`, and retains MemoryMax=3G per run. Measurement may use three jobs; other workers keep two. The 17 targeted Python tests include a live lock-concurrency test: three holders enter, a fourth waits, and releasing one admits it. Ruff, shellcheck and whitespace checks pass. Historical decision/owner-note records are unchanged.

## Provisional-preset validation

562 tests across all 40 pass-3 core test files pass (the two affected files were rechecked after correcting their numeric expectations). The new C pin covers every fitted dial; the historical mechanism-path helper now freezes both original endpoints. B’s JSON map, A, fallback rates, metadata and every Ooze C entry are unchanged. Authored default faces remain B’s; C’s faces are generated from C at runtime and checked against the live dial path. Targeted gdlint/gdformat and Ruff checks pass.
