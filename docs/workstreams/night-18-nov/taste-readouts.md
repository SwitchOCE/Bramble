# Next-turn readouts — 18 November 2026

## Taste calls

- Used the existing cream counter plate, its dark lead border, existing label fonts and the selected `GoldCoin` stamp. The readouts are quiet economy information beside the portraits. The owner's selected line icon is the only new drawing.
- “Next turn +7” with a coin, beside the player's portrait. The plus sign identifies income gained, separate from the balance above the shop. It never adds unspent gold to the displayed income.
- Owner review, 18 November: “It's a discount.” Replaced the discount's words with the selected option A market-stall/up-arrow icon, using exactly the supplied SVG. Its 24 px strokes use the plate's dark ink (`#120e0b`). The signed “−1” uses the existing damaged-number red from `.card .num.hurt` (`#9e0f0a`), with 6.11:1 contrast against the cream base colour (`#e8dcc0`, before its texture). Kept the coin. Hide the entire plate when the effective discount is zero; upgrading redraws it immediately with the new tier's reset discount.
- The Tier up button uses the same `shop_up` icon at 18 px, centred above the tier numbers in the caption's existing `#c9bda6`. The tier numbers, cost coin and button hit area remain. `GlassPieces.icon` routes the supplied SVG through the existing stroked, no-fill renderer. It is marked STAND-IN in code because pulling the mock-ups regenerates `layout.json` and would overwrite a hand-added entry.
- Stand-in placement outside the mock-up: 44 px high plates on the lower sill, at stage y = height − 118. Income starts at x = 196; the discount ends at x = 1700. Both sit beside their portraits, clear of Health badges, counter chips, the hand fan and the End turn hit area. The income's existing 20 px label and both 26 px values scale with the stage. Replacing the discount caption makes that plate narrower while retaining its right edge.
- No hover teaching text. The shop icon and signed red number identify a discount for a player who knows the rules. “Next turn +7” is unchanged; its 1920 × 1080 crop is pixel-identical to the initial capture.

## Evidence

Inspected full-screen `tools/look` captures of `res://tests/screens/recruit_tribes.tscn`, using the real core and view adapter with a full board and five cards in hand:

- `/home/alex/code/Bramble-media/next-turn-readouts/review-recruit-1920x1080.png`
- `/home/alex/code/Bramble-media/next-turn-readouts/review-recruit-1366x768.png`

Inspected unscaled detail crops beside those full captures, in the same media folder:

- `review-discount-1920x1080.png`, `review-tier-up-1920x1080.png`
- `review-discount-1366x768.png`, `review-tier-up-1366x768.png`

At both sizes the plates remain readable and clear of the portraits and hand. The 1366 × 768 capture keeps the same layout, with no clipping. Both captures show turn 1: +7 income and −1 discount. The detail crops show the same stall and upward arrow in both locations, with the red discount separate from the gold coin. Both look sessions reported zero game errors or warnings and were stopped after capture. Godot was bounded by `timeout -k 10`.

The adapter queries `Rules.income(player, round + 1)`, exactly the income query used by `Recruit.start_turn`. The discount preview compares `Rules.upgrade_cost` now with the same query on a detached player with one more turn waited, retaining the board and modifier context. It uses the core's `waiting_discount` indirectly through `upgrade_cost`, including its zero floor, and leaves the live session unchanged. No rules logic changed and no rule discrepancy was found in these calculations.

GUT coverage checks several turns, every upgradeable tier, wait ages through the discount cap, a partial final drop, zero cost, top tier, modified income and upgrade cost, session immutability, and actual upgrades resetting the plate. Screen checks also cover gold spending, advancing a turn, a free upgrade, and upgrading to the top tier.

## Checks

- Owner-review affected GUT suites: `test_glass_pieces` (11), `test_recruit_screen` (37), `test_recruit_core` (17), `test_shop_prices` (5), `test_view_adapter` (14): **84 tests passed**, strict hooks clean. Tests cover the exact supplied SVG at both icon sizes, the discount's red and dark-ink icon, retained tier numbers/cost, unchanged income styling, free-upgrade reset and top-tier hiding. Each run used `timeout -k 10` and a 90 or 120 second limit.
- Changed GDScript formatting/lint and `git diff --check`: passed.
- Initial feature's `scripts/check.sh` run: passed leftovers, tool versions, version drift, shell, Python (20 tests), formatting and lint. Stopped at import because the sandbox cannot save `/home/alex/.config/godot/editor_settings-4.7.tres`; both import passes reported that permission failure. The remaining full-gate steps are for the orchestrator's run, as the brief allows.
