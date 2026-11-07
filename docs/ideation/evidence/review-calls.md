# Oozes and Birds review checks — 7 Nov 2026

On `ideation/tribes2`, merging `origin/ideation/c-freed` (e0c8e36) into f51eefa. Both combat UI conflicts retain the tribe events and the incoming relocation handling. The combined screen exceeded the lint line limit; comments were condensed without changing behaviour.

Godot commands source `/opt/bramble/env.sh`, use writable temporary XDG config/data directories, and inherit CPU affinity 0,1. The requested `docs/ideation/CLOUD.md` is absent from this worktree; it was located and read at `/home/alex/code/Bramble-ideation/docs/ideation/CLOUD.md`. `docs/CLOUD_SETUP.md` supplies the toolchain guidance. Portal inbox was empty.

## Regression proof

Commands: `godot --headless -s addons/gut/gut_cmdln.gd -gselect=<suite>` (one process per suite). Logs are local under `/tmp/bramble-red-*` and `/tmp/bramble-green-*`.

| Suite | Before the fix | After the fix |
|---|---|---|
| test_balance_2 | Restoring exact board count fails: 2 versus 1. A diagnostic shows Mrs Burdock plus her summoned Kit. | 32/32; retain the lower bound with that explanation and assert exactly one unit bought. |
| test_oozes | All four added tests fail: ordinary Pie never stops, golden Pie never stops, fresh Pie has no persisted payment count, and both plain bird copies fly. | 58/58; caps survive a move, golden pays twice per payment, new units start fresh, and copies sell normally without returning. |
| test_fly_south | Added full-hand golden test fails for both One Swallow and Mrs Jay: played_round 0 and immediate flight. | 27/27; auto-boarded goldens have the current played round and sell for good. |
| test_held_view | Added plain-copy sale test incorrectly says Fly south and promises a return. | 21/21; button and note say final sale. |

The initial red run also exposed two test expectations corrected before green: board moves return bool, and ordinary Created sales use the configured sale value (0), not a Bought unit's value (1).

An independent reviewer inspected the changed rules and coverage and found no material issue. UI-run results are in `ui-run.md`; the gate, screenshot inspection and soak results are recorded below after execution.

## Gate and screenshots

`scripts/check.sh`: all ten steps pass; compilation 254 files, no failures; GUT 952/952 tests, 10,378 assertions, no risky or pending tests. The first gate attempt stopped on the merged screen's line limit; the final gate passes without weakening the limit.

`tests/ui/render_screens.sh recruit recruit_held recruit_held_ooze recruit_held_bird`: eight renders succeeded. All eight JPEGs inspected at 1920×1080 and 1688×780: shop text, Belly chips (empty/full), Nest chips (bare/occupied), held-unit detail and bird sale controls remain on screen and readable. The Pie's rules and Belly reminder use the existing detail scroll area. Images remain local in `build/screens/jpg/`.

## First UI attempt and harness corrections

The exact requested full-run command was started on 9f1ef41. Desktop seed 1000 completed in 252 seconds: first place after 17 turns, tier 6, zero log errors, and 15 PROBLEM lines. The run was stopped (outer exit 143) before completing a second game, because these proved to be harness faults; the old generated `ui-run.md` was not replaced by this interrupted attempt. Original logs remain local in `build/ui-run-first-attempt/` and `/tmp/bramble-ui-first-attempt.log`.

- The word checker unconditionally forbade Oozes and Birds. It now builds its pattern from `lobby_tribes`, with a regression checking present and absent tribes plus raw ids, bot numbers and grammar. The depth bar and SLOTS are unchanged.
- The refused-drop probe expected every occupied slot to reject a shop unit. A Belly with room correctly accepts one; the driver now checks that case against the held-unit rule.
- A diagnostic copy of the playthrough, skipping fight animations, reproduced seed 1000's Sell miss. The action button was 2×128 pixels before its pending container sort and 442×128 after it. Sorting before the same-frame driver click eliminated the miss (the ordinary UI gets that sort on the next frame). The driver also recognises a bird's Fly south action as a sale.
- The runner created its output directory after initialising log filtering. On a fresh run this printed a missing-file error; the directory is now created first.

These fixes change the test harness; no game or layout bug had been observed in the completed first game or the requested screenshot inspection. The complete rerun below determines the final result.

Gate after harness corrections: all steps pass; 255 files compile, GUT 953/953 tests and 10,385 assertions.

## Complete UI rerun

`GAME_TIMEOUT=600 timeout 4500 tests/ui/full_ui_run.sh 10 1000` on dc7d005: **exit 0**, 20/20 full games and 2/2 forced late-game checks clean. No PROBLEM or script/log errors. The original SLOTS and depth thresholds are unchanged; the bar is met: 15 games reach turn 12, 13 reach turn 15, 11 wins, 7 ghost fights, all 20 reach tier 5 and 17 reach tier 6. Smallest text: phone 31 canvas units, desktop 22 (the permitted desktop tile/name minimum).

The run continued across a bridge turn limit; its existing process was monitored to completion, not duplicated. The generated `ui-run.md` contains every seed and result. No additional game or layout bug appeared after the harness corrections. The requested screenshot inspection is recorded above.

## Soak

`timeout 1800 tools/checks/soak.sh 200 1` on dc7d005, after sourcing `/opt/bramble/env.sh`, under affinity 0,1: **exit 0**, no Godot log problems. Launched with `setsid nohup` and a waiting supervisor; start, finish and exit status were saved independently under `build/check/soak-review.*`, so the job could survive a bridge turn limit. Started 2026-11-07 06:25:01 UTC, finished 06:26:55 UTC.

```text
soak: games 200 (seeds 1-200)
soak: rounds 3265, fights 10408, reasons { "board_empty": 10404, "no_attacks": 4 }
soak: max events per fight 182 (seed 97 round 17 fight 3 v 7)
soak: time 113.2 s, 566 ms per game, slowest 1007 ms
soak: not reached this run (report only) ["trigger:on_home", "trigger:on_swallow"]
soak: slice cards never fired []
soak: slice keywords never fired ["Bristle", "Hunker"]
soak: violations 0
```

The four no-attacks draws are reported cases, not attack/trigger-limit stalls. Coverage gaps remain visible above; this run does not claim every trigger or keyword was exercised. Full local logs: `build/check/soak.log` and `build/check/soak-review-runner.log`.

## Scope left unchanged

All four tribes remain in each lobby. Shops were not re-tuned, nor were UI SLOTS or depth thresholds changed. No additional game/layout defect was found by the completed UI rerun or soak. No changes were pushed or merged into `main`; no approval review rejected an action. Screenshot JPEGs and raw logs remain local; the committed Markdown records the checks and their limits.
