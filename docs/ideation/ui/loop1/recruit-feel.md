# B — recruit feel

Rebased onto Bazaar Stack (`8fe9f7d1`), then merged `origin/ideation/main` with the new art (`50024663`). A’s placement and surfaces win. The only layout-file changes relinquish the reader rectangle to `card_detail.gd` and remove dead `_on_detail_shown`; no card, control or surface placement changed.

Cards have pickup lift/shadow, bounded pointer lag and tilt, live destination rims, travel and squash/settle. Direct shop-to-board purchases and both swap participants animate. Release preserves the landing cue; another action can interrupt immediately. Reduced motion and tap alternatives remain. Tap purchases cross beside the live formation and along the reserve row to the actual hand card; swallowing travels to the actual Belly glyph and settles its Ooze. Destinations come from live nodes.

The floating reader protects merchant buy targets, formation, inspected hand/scout rows, lobby and bottom bar. Its backing now fits the rules, actions and any open keyword reminder, capped by the available space; long rules scroll. The compact reader omits duplicated art/badges. There is no close button: tap the table. Explicit readers survive stale hover exits, while fresh PC card hovers still work. Name fitting respects the existing font minimum.

**Try:** drag shop → empty board, shop → hand, hand → Ooze; swap units and drag one onto the merchant to sell. Repeat by tap. Board drags always reorder, including while “Into a Belly” is selected; board-to-Ooze swallowing stays a tap action. Inspect each row and a shop-targeted hand spell.

**Tests:** `test_recruit_actions_motion.gd` covers real purchase/swap travel, both-size no-reflow/row protection, shop-spell targets, names and pinned readers. Deleted `test_board_into_belly_drag_uses_the_explicit_tap_mode_instead_of_swapping`; added content-fit/long-rules coverage. In `test_birds_pass1_ui.gd`, the Egg test checks touch ignores hover and PC hover still reads the Egg; the Lump test reads `DragLift.card` beside its shadow. In `test_recruit_declutter.gd`, the one-gold spell test now checks exact Buy price at both sizes without a duplicate compact badge. Label budgets are unchanged. `player_driver.gd` is unchanged. `recruit_feel_movie.gd` now closes the reader with a real table click.

**Verification:** reader shots at both native sizes and a complete PC recruit-turn GIF/contact sheet are refreshed with the new art in `build/loop1/recruit-feel/` (not committed). Logs: `build/recruit-feel-check.log`, `build/recruit-feel-ui-run.log`.

**Later:** hover is disabled for windows wider than 2:1, so ultrawide PC has no hover reader. No gameplay bugs found in the exercised turns; no rules, numbers, card text or fenced files changed.
