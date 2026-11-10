# Layout options

Four static choices for Step 0b. [Gallery](http://100.92.26.47:8790/loop1/layouts/) · [Bazaar comparison sheet](http://100.92.26.47:8790/loop1/layouts/sheet.jpg). Each has recruit and mid-fight at 1920×1080 and 1688×780, plus a phone reader study. All say **concept**: the forest, stump material and foreground foliage are generated paintings. Depth is visible in stills; no GIFs.

## Woodland Table

**Idea:** Large shop art, two ranks and a bottom hand fan occupy one illuminated stump top.

**Depth:** painted planks and moss, thick rim, pooled light, contact shadows and foreground leaves; Mosswood Mist world. **Changes:** a large shop row fills the top, the seven deployed tiles fill the middle, the lobby runs down the left, and gold/actions sit on the right. Fights use a close mirrored formation with scenery at the margins. **Cost:** about 2–3 days in `recruit_layout.gd`, `combat_screen.gd`, `lobby_strip.gd`, `hand_fan.gd`, `table_background.gd`. **Ink-B fit:** face-on portraits retain their bold outline and compact badges.

**Tradeoffs:** Familiar formation and large art make this the easiest transition from build 8. Shop, formation, hand and lobby remain visible together; a full hand overlaps in its fan.

## Sidecar Market

**Idea:** A tall merchant grid sits beside a broad player formation on a joined woodland counter.

**Depth:** raised planked surfaces, mossy joins, pooled light and foreground branches; Weald Glow world. **Changes:** shop wraps into two columns, formation uses the normal four/three rows, and the full-size hand fans below it; shop actions sit between the activities. Fight turns the ranks sideways into mirrored inward front columns and outward back columns. **Cost:** about 3–5 days in `board_view.gd`, `recruit_layout.gd`, `combat_screen.gd`, `combat_motion.gd`, `hand_fan.gd`. **Ink-B fit:** large, equally sized upright pieces preserve the art.

**Tradeoffs:** Shopping and deployment are visibly separate. Eye travel is wider, the full hand overlaps more, and changing rank orientation for fights needs playtesting.

## Rootbridge Diorama

**Idea:** A raised merchant shelf overlooks a receding woodland platform with upright pieces.

**Depth:** perspective-warped wood, a thick near face, projected contacts and foreground occlusion; Fen Wisplight world. **Changes:** the world recedes strongly while tile size has a floor, with the near rank only slightly larger; mirrored fights fill the stage. **Cost:** about 6–9 days for `src/ui/stage/woodland_diorama.gd`/scene and integration through `recruit_layout.gd`, `combat_screen.gd`, `combat_motion.gd`, `card_view.gd`. **Ink-B fit:** camera-facing sprites keep every portrait and badge flat and readable.

**Tradeoffs:** Strongest sense of a stage in the forest, at the highest build cost. Clamping distant tile size weakens realistic perspective, but protects readable art on phone.

## Bazaar Stack

**Idea:** A merchant above the central two-rank formation gives way to an opponent during combat, with the hero centred in a slim bottom action bar.

**Depth:** a raised merchant counter on one painted stump top, warm central light, contact shadows and edge foliage; Highcrown Rays world. **Changes:** the lobby is a slim left rail; a full-size overlapping hand pouch sits beside the formation; gold, tier up, refresh, freeze and End turn share the hero bar. Fight replaces the merchant with the opponent's mirrored side. **Cost:** about 3–4 days in `recruit_layout.gd`, `combat_screen.gd`, `hand_fan.gd`, `hero_plaque.gd`, `table_background.gd`. **Ink-B fit:** large art carries identity; compact existing badges carry changing state.

**Tradeoffs:** Closest to Bazaar's stable activity stack and compact hero HUD. Our two ranks and full hand require more space than its single item row; the pouch needs tap-to-expand selection.

## Evidence and limits

Every recruit retains five real shop units plus a spell, front four/back three, ten full-size hand cards, gold, all actions and eight lobby portraits with Health/opponent tier numerals. Shop footprints meet the build-8 desktop width; board and hand faces render at least 150 px wide on phone. Overlap in a full hand preserves tile size. No tutorial labels or static pointers were added. The existing reader and unchanged card text are shown on demand; these studies do not implement input.

Woodland recruit uses rearranged real Godot nodes; other stills use transparent renders of the same widgets. Two extra pool offers supplement the deterministic state's three offers. All options share one captured fight. [`tools/mockup/README.md`](../../../tools/mockup/README.md) documents reproduction, source art and size checks. Physical-device readability and live interaction remain untested; the orchestrator's separate critique follows this round.
