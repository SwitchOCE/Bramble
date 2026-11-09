# Hard Fairy bot follow-up

The original review's event probe was deleted with its temporary project copies. Its surviving `mut-E_events.log` records aggregate counts, but neither lobby seeds nor setup. These results therefore use the explicit replacement trio **412, 413, 414**; they do not claim to reproduce the reviewer's 5 thanks or its purchase/sale totals. Seed 412 is the existing wave 1 bot regression seed.

The before policy is frozen commit `13eac5f`, extracted with `git archive`; the after policy is source checkpoint `76c259b`. Both run the same probe. The original quarter growth is explicitly pinned in the baseline and the paired after control; the approved growth 1 appears in the primary after run.

Every run uses `GameConfig.full_game()`, all six tribes in the shop pool, and eight Hard seats: Birds summer/winter, passage, highway; Fairies rings, rainbow, help, hag; Birds summer/winter. Each lobby plays ordinary legal recruit actions and real combat for 15 rounds or until game over, with no board or health injections. The 80 HP control keeps the twelve Fairy seats available at R12; the separate 40 HP run checks ordinary starting health. Changing policy changes later shared-pool draws, so identical seeds compare whole lobbies rather than matched later shop offers.

Changes are limited to the existing brain: retain the last Lob/Hob and Cluricaun while tier-ups remain; value Lob's bank and Cluricaun's future growth; price profitable Shy departures in aimed-spell buying and aiming; and buy affordable missing Rings before a planned Cluricaun tier-up. Duplicate engine pieces may be replaced; Cluricaun may retire at tier 6. Hob's thank-you value includes the lost Shield. Silky waits while another Shy remains.

## Fairy-route seats only

| Policy / growth / HP | Thanks | Lob sold / bought | Hob sold / bought | Cluricaun sold / bought |
| --- | ---: | ---: | ---: | ---: |
| before / 0.25 / 80 | 3 | 2 / 2 | 3 / 6 | 1 / 1 |
| after / 0.25 / 80 | 9 | 1 / 9 | 0 / 7 | 2 / 3 |
| after / 1 / 80 | 17 | 0 / 4 | 1 / 8 | 1 / 3 |
| before / 0.25 / 40 | 5 | 2 / 3 | 3 / 6 | 0 / 1 |
| after / 1 / 40 | 11 | 0 / 3 | 0 / 7 | 1 / 4 |

## All eight seats (same aggregation as the review)

| Policy / growth / HP | Thanks | Lob sold / bought | Hob sold / bought | Cluricaun sold / bought |
| --- | ---: | ---: | ---: | ---: |
| before / 0.25 / 80 | 4 | 5 / 5 | 4 / 7 | 1 / 1 |
| after / 0.25 / 80 | 10 | 1 / 10 | 1 / 8 | 3 / 4 |
| after / 1 / 80 | 19 | 0 / 5 | 2 / 9 | 4 / 6 |
| before / 0.25 / 40 | 6 | 6 / 7 | 4 / 7 | 0 / 1 |
| after / 1 / 40 | 13 | 0 / 4 | 1 / 8 | 5 / 8 |

## Ring size at R12

A snapshot is taken immediately after each bot's R12 recruit turn, before `end_phase`. Values in each cell are seats 3/4/5/6: rings, rainbow, help, hag. A dash means the seat did not reach its R12 turn. These are Ring **sizes**, not Ring counts or board totals.

| Seed | Before, quarter / 80 HP | After, quarter / 80 HP | After, growth 1 / 80 HP | Before, quarter / 40 HP | After, growth 1 / 40 HP |
| --- | --- | --- | --- | --- | --- |
| 412 | 1 / 1 / 2 / 1 | 1 / 1 / 2 / 1 | 3 / 2 / 3 / 2 | 1 / 1 / 2 / 1 | 3 / 1 / 3 / 1 |
| 413 | 2 / 1 / 2 / 1 | 3 / 3 / 2 / 1 | 3 / 2 / 2 / 1 | 3 / — / 2 / 1 | — / — / 2 / 1 |
| 414 | 1 / 1 / 1 / 1 | 3 / 1 / 1 / 1 | 3 / 1 / 3 / 1 | 2 / — / 2 / 1 | 3 / — / 3 / 1 |

- `before-g025-health80`: mean 1.25, median 1; 3/12 seats above size 1.
- `after-g025-health80`: mean 1.67, median 1; 5/12 seats above size 1.
- `after-g1-health80`: mean 2.17, median 2; 9/12 seats above size 1.

The unchanged-quarter control isolates a policy improvement: more thanks and fewer Lob/Hob sales without the dial increase. Some Fairy seats still have size 1 or few Rings at R12; this is a small legal-play sanity sample, not a balance or win-rate claim. The JSON includes each R12 board, Ring count and ringed slots, plus every watched recruit event and the source seat.

Cluricaun sale tiers in Fairy-route seats:

- `before-g025-health80`: seed 413 seat 4, R13, tier 6.
- `after-g025-health80`: seed 412 seat 5, R11, tier 6, seed 412 seat 3, R12, tier 6.
- `after-g1-health80`: seed 413 seat 3, R13, tier 6.
- `before-g025-health40`: none.
- `after-g1-health40`: seed 412 seat 3, R15, tier 6.

The before 80 HP control's sole Cluricaun sale was also at tier 6; its raw sale count alone is not evidence of premature retirement. The focused regression separately proves that the new policy preserves Cluricaun while tier-ups remain and permits retirement after tier 6.

## Reproduction and files

```sh
source /opt/bramble/env.sh
flock /tmp/bramble-godot.lock systemd-run --user --scope -p MemoryMax=3G timeout 180 godot --headless -s res://tools/checks/wave1_fairy_bot_probe.gd -- out=/tmp/after-g1-health80.json growth=1 label=after health=80
```

For the before run, extract `git archive 13eac5f` into an isolated directory under `/tmp`, copy the current probe into `tools/checks/`, import that isolated project under the same lock/cap, then add `--path <archive>` and `growth=0.25 label=before`. Change `health=40` for ordinary starting health. The probe is independent of `tools/sim/bench.gd` and `BenchSuites`.

- [before-g025-health80.json](before-g025-health80.json) — complete counts, per-seat counts, R12 snapshots and watched events; [Godot log](before-g025-health80.log).
- [after-g025-health80.json](after-g025-health80.json) — complete counts, per-seat counts, R12 snapshots and watched events; [Godot log](after-g025-health80.log).
- [after-g1-health80.json](after-g1-health80.json) — complete counts, per-seat counts, R12 snapshots and watched events; [Godot log](after-g1-health80.log).
- [before-g025-health40.json](before-g025-health40.json) — complete counts, per-seat counts, R12 snapshots and watched events; [Godot log](before-g025-health40.log).
- [after-g1-health40.json](after-g1-health40.json) — complete counts, per-seat counts, R12 snapshots and watched events; [Godot log](after-g1-health40.log).

Focused validation: [`test_pass3_bots.gd` run](focused-tests.log) passes 20/20 tests (61 assertions), including five added regressions for retention, a real purchased thank-you aimed past a large carry, Hob's Shield trade, finishing a rainbow before a real tier-up, and reading the resolved growth dial. Changed bot files, probe and tests pass `gdlint`/`gdformat`.

[Independent verification](verification.json) recomputes every aggregate and per-seat count from watched events, checks all twelve R12 seats in the 80-Health control, verifies that every after-policy Fairy-route Cluricaun sale was at tier 6, and records hashes of all five reports and their clean Godot logs. The full source gate is recorded in [review-gate.log](review-gate.log).

The full gate on `76c259b` passes: 1,791 tests and 29,353 assertions across 163 scripts, with the strict hook clean and all other gate steps passing (493 source files compile). It ran as:

```sh
source /opt/bramble/env.sh
flock /tmp/bramble-godot.lock systemd-run --user --scope -p MemoryMax=3G timeout 1800 ./scripts/check.sh > docs/ideation/evidence/wave1/bot-review/review-gate.log 2>&1
```
