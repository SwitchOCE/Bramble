# Next-turn readouts — 18 November 2026

## Taste calls

- Used the existing cream counter plate, its dark lead border, existing label fonts and the selected `GoldCoin` stamp. The readouts are quiet economy information beside the portraits; no new art, animation or button treatment.
- “Next turn +7” with a coin, beside the player's portrait. The plus sign identifies income gained, separate from the balance above the shop. It never adds unspent gold to the displayed income.
- “Tier-up drop −1” with a coin, beside End turn. The minus sign identifies the reduction in price. Hide the entire plate when the effective drop is zero; upgrading redraws it immediately with the new tier's reset discount.
- Stand-in placement outside the mock-up: 44 px high plates on the lower sill, at stage y = height − 118. Income starts at x = 196; the drop ends at x = 1700. Both sit beside their portraits, clear of Health badges, counter chips, the hand fan and the End turn hit area. The existing 20 px label and 26 px value sizes scale with the stage.
- Kept the words visible instead of adding hover teaching text. These captions and signed numbers identify the two values for a player who already knows the rules.

## Evidence

Inspected full-screen `tools/look` captures of `res://tests/screens/recruit_tribes.tscn`, using the real core and view adapter with a full board and five cards in hand:

- `/home/alex/code/Bramble-media/next-turn-readouts/recruit-1920x1080.png`
- `/home/alex/code/Bramble-media/next-turn-readouts/look/20261118-143033-92c20f/001-recruit-1366x768.png`

At both sizes the plates remain readable and clear of the portraits and hand. The 1366 × 768 capture keeps the same layout, with no clipping. Both captures show turn 1: +7 income and −1 tier-up drop. Both look sessions reported zero game errors or warnings and were stopped after capture. Godot was bounded by `timeout -k 10`.

The adapter queries `Rules.income(player, round + 1)`, exactly the income query used by `Recruit.start_turn`. The discount preview compares `Rules.upgrade_cost` now with the same query on a detached player with one more turn waited, retaining the board and modifier context. It uses the core's `waiting_discount` indirectly through `upgrade_cost`, including its zero floor, and leaves the live session unchanged. No rules logic changed and no rule discrepancy was found in these calculations.

GUT coverage checks several turns, every upgradeable tier, wait ages through the discount cap, a partial final drop, zero cost, top tier, modified income and upgrade cost, session immutability, and actual upgrades resetting the plate. Screen checks also cover gold spending, advancing a turn, a free upgrade, and upgrading to the top tier.

## Checks

- Affected GUT suites: `test_view_adapter` (14), `test_recruit_core` (17), `test_recruit_screen` (36), `test_economy_rules` (15): **82 tests passed**, strict hooks clean. The final screen suite includes both free-upgrade and top-tier upgrade actions. Each run used `timeout -k 10` and a 90 or 120 second limit.
- Changed GDScript formatting/lint and `git diff --check`: passed.
- `scripts/check.sh`: passed leftovers, tool versions, version drift, shell, Python (20 tests), formatting and lint. Stopped at import because the sandbox cannot save `/home/alex/.config/godot/editor_settings-4.7.tres`; both import passes reported that permission failure. The remaining full-gate steps are for the orchestrator's run, as the brief allows.
