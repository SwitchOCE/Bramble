# B — recruit feel

Rebased onto step A, `8fe9f7d1` (`origin/ideation/main`). A’s Bazaar Stack placement, hand row, bottom bar and surfaces win. Conflict resolution kept A’s reader scrolling and its occupied-rear-slot regression. `recruit_layout.gd` only relinquishes the reader rectangle to `card_detail.gd`; no card, control or surface placement changed.

Cards retain pickup lift/shadow, bounded pointer lag and tilt, live destination rims, short travel and squash/settle. Direct shop-to-board purchases and both swap participants animate. Release preserves the landing cue; another action can interrupt immediately. Reduced motion keeps every action available. Tap alternatives remain, including explicit “Into a Belly” mode for board drags.

Tap purchases now cross beside the live formation and then along the new reserve row, ending on the actual hand card. Swallowing travels to the actual Belly glyph and settles its Ooze. No destination uses screen-position constants.

The floating reader leaves merchant buy targets, the whole formation, inspected hand/scout rows, lobby and bottom bar exposed. In a narrow free column it shows name and rules without duplicating the still-visible portrait. Hover/tap reading, keyword links and wheel scrolling remain. A teardown guard prevents stale hover timers starting as the screen exits. Explicit readers ignore stale hover exits and hidden lobby events; fresh card hovers still work. Name fitting respects the existing font minimum.

**Try:** drag shop → empty board, shop → hand, hand → Ooze; swap units and drag one onto the merchant to sell. Repeat buying/playing by tap. Inspect each row and use a shop-targeted hand spell: source and targets remain exposed.

**Tests:** only `tests/ui/test_recruit_actions_motion.gd` was rewritten: the former desktop hand-reader check becomes both-size no-reflow/row-protection coverage; added real purchase/swap, stacked-row, shop-spell, explicit Belly-drag, name-fitting and pinned-reader regressions. Its synthetic hand geometry now follows A’s lower row. No tests deleted; A’s `test_phone_layout.gd` and `player_driver.gd` are unchanged. `tests/ui/shots/recruit_feel_movie.gd` records real pointer events and saves reader shots.

**Verification:** 10/10 motion/reader and 13/13 phone/layout tests pass. Both native-size turn clips and reader shots are refreshed in `build/loop1/recruit-feel/` (not committed). The same PC ghost seed has 0 problems in the report committed at `8fe9f7d1`; the stale-hover regression in this branch is fixed. Committed-tip gate/UI-run logs are `build/recruit-feel-check.log` and `build/recruit-feel-ui-run.log`. No gameplay bugs found in the exercised turns. No rules, numbers, card text or fenced files changed.
