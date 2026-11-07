# Oozes and Birds review checks — 7 Nov 2026

On `ideation/tribes2`, merging `origin/ideation/c-freed` (e0c8e36) into f51eefa. Both combat UI conflicts retain the tribe events and the incoming relocation handling. The combined screen exceeded the lint line limit; comments were condensed without changing behaviour.

Godot commands source `/opt/bramble/env.sh`, use writable temporary XDG config/data directories, and inherit CPU affinity 0,1. The requested `docs/ideation/CLOUD.md` is absent; `docs/CLOUD_SETUP.md` supplies the toolchain guidance. Portal inbox was empty.

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
