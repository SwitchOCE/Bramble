# Complete-game re-pin after build 9 Sally

The cloud gate on `9affb598` reports the expected whole-game change for seed 20261109. Content and configs remain frozen at the historical fixtures; production rules/AI run as usual. `normal-b9-content.json` is a new fixture, preserving every earlier fixture and all four original configs. Only seed 20261109's hash/count changes; the regression additionally asserts that the other three records equal the previous fixture.

## Causal proof before re-pinning

`field-repin.gd` exports exactly the test's normalized combat inputs, complete results/events, standings and game log, through the unchanged `ReplayContract.gameplay` projection. Raw bytes/logs remain under `build/b9-content/field-repin/`; `field-repin.json` preserves hashes and the first difference.

| Seed | Previous count/hash | Current count/hash |
|---|---|---|
| 3 | 59 / bd608510… | 59 / bd608510… |
| 17 | 64 / a84614ae… | 64 / a84614ae… |
| 71 | 62 / 57c1caf1… | 62 / 57c1caf1… |
| 20261109 | 59 / 1eac0efb… | 61 / c3e36d64… |

1. With just Sally's target selection reverted in `src/core/pass3_fairies.gd` to `de0c0a9a`, the affected game returns to **59 fights**. Its hash is e8a04875… because the new Sally wording is still printed. All other three games are byte-identical to current and match their historical hashes.
2. Compare that rules-only control with current, keeping the same new face on both: **the first 11 fights are identical**. Fight index 11 is **R3, seats 4 versus 5**. Every input field except slot effects is identical. Seat 4 has Sally in occupied **B1 (slot 4)**. The old rule Rings empty **B2 (slot 5)**; the new rule Rings Sally's own unringed B1. Event 0 (`combat_start`) therefore shows Sally **2/4 → 3/5**. Subsequent damage and games diverge from that intended target change.
3. Revert both Sally's targeting and its face (`src/core/pass3_fairies.gd` and `src/core/pass3_text.gd` to `de0c0a9a`): seed 20261109 restores **exactly 59 fights and SHA-256 `1eac0efb94eb01ff3e59787f932c4e3edb72b5c482820c61a340b0a397832a15`**. All other build 9 changes remain present. Both production files are restored byte-for-byte afterward.
4. Mallow in the frozen `content-0946909.json` has legacy mechanic `mrs_mallow`, not native `pass3_hedgerow`. The build 9 Mallow target/valuation changes do not apply to this fixture. The complete Sally revert proving the old hash also rules out the overflow guards or attribution tooling as causes.

Current affected SHA-256 is `c3e36d64e35d713cd2e8bfbc0a4efac020cc903a9263e6e2a2ae4f186066fb23`. No projection, frozen content, config or test threshold is weakened.

## Search for other pins

Searched all `tests/` GDScript/JSON for the four seeds, `fight_count`, full-game hashes and literal 64-digit hashes. Only `test_field_normal_regression.gd` consumes an active whole-game hash/count fixture for these seeds. `normal-0946909.json` and `normal-067429a3.json` are archived stages; `normal-a35-dial-bots.json` is the preserved previous fixture. No other active full-game pin needs changing. `test_full_games.gd` checks determinism/invariants, not these historical hashes/counts. UI shot reports and play-tool state hashes compare generated states, rather than pinning these four complete games.

## Reproduction and validation

```sh
source /opt/bramble/env.sh
export XDG_CONFIG_HOME="$PWD/build/b9-content/config"
export XDG_DATA_HOME="$PWD/build/b9-content/field-repin/data"
export XDG_STATE_HOME="$PWD/build/b9-content/state"
GODOT_SLOT_CLASS=worker scripts/godot_slot.sh godot --headless -s res://docs/ideation/evidence/b9-content/field-repin.gd -- build/b9-content/field-repin/current
# The exporter accepts an optional seed after the output directory for a narrow counterfactual.
GODOT_SLOT_CLASS=worker scripts/godot_slot.sh godot --headless -s addons/gut/gut_cmdln.gd -gdir= -gtest=res://tests/core/test_field_normal_regression.gd,res://tests/core/test_pass3_fairies_recruit.gd -gexit
```

The initial diagnostic used `/opt/bramble/env.sh`'s unwritable default log directory; it still exported the complete-game bytes. The complete Sally-revert control and final targeted tests use the explicit writable paths above. **31/31 targeted GUT tests pass** (normal complete-game regression plus native Fairy recruit tests; 1,149 assertions). Both touched GDScript files pass gdlint and gdformat --check. No full suite runs; production code/content have no remaining diff.
