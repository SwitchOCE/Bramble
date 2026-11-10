# B — recruit feel

Cards lift with a contact shadow, bounded follow-through and tilt; phone pickups clear the finger. A temporary rim opens around the live drop target. Shop-to-board purchases, hand plays and both swap participants travel, then squash and settle. Hand-bound purchases keep a recognisable portrait. Swallowing carries the picture into the actual Belly glyph and settles the receiving Ooze. Drag release preserves the landing animation, and another action can interrupt it immediately. Reduced motion keeps the same actions available.

The reader floats without moving the shop, board, hand or economy controls. It protects the whole inspected row and a held card's tap destinations, including shop-targeted spells. PC hover and phone tap work, including keyword links. Drag buying, selling, playing spells and reordering retain tap alternatives. The explicit “Into a Belly” mode also accepts board drags without changing ordinary swaps.

**Try:** drag a shop unit into an empty pocket, then buy into the hand and feed that card to an Ooze. Swap two units, sell onto the shop, and repeat a purchase/play by tap. Inspect each row and move between cards: the rest of that row should remain exposed.

**Outside owned files:** `recruit_layout.gd` only removes reader reservation, positioning and economy visibility changes. The overlay belongs to `card_detail.gd`; positions come from live nodes. `tests/ui/shots/recruit_feel_movie.gd` records real pointer inputs and saves reader shots. No rules, numbers or card text changed.

**Tests rewritten:** `tests/ui/test_recruit_actions_motion.gd` replaces the desktop-only hand-reader check with both-size no-reflow coverage, and adds purchase/swap, whole-row protection and explicit Belly-drag checks. No tests deleted; no layout-test rewrites. `player_driver.gd` is unchanged.

**Verification/evidence:** all eight focused action/reader checks pass; native PC and phone pointer-driven turns reach combat. GIFs, contact sheets and reader PNGs are in `build/loop1/recruit-feel/` (uncommitted). Static format, lint and scope review pass. Rebase, renewed captures and full gate await the Bazaar Stack commit; the orchestrator owns cloud gate and the four-game run. No gameplay bugs found in the exercised turn.
