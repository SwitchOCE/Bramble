# Bazaar Stack framing — A2

Recruit now sits on a centred table across 74% of the PC width. Woodland remains visible at both sides and above it; phone retains a world strip between the standings rail and table and at the right edge. Ten reserve portraits stay exposed in the stack. Shop cards and the hero/action bar adapt to the narrower PC surface. Hand cards use their actual displayed sizes, so their font fitter keeps its true minimum; small bar text compensates for its parent scale.

The merchant uses warm wood with a muted cloth lip, the formation a darker moss wash, the hand blue-grey cloth, and the bar and rail their own quieter surfaces. Wood surfaces use the repainted `assets/ui/world/stump.jpg` faintly beneath ink contours, uneven edges and broad translucent washes; moss carries a quieter trace. Cream light comes from the upper right. No instructional labels were added. Art is merged from `origin/ideation/main` at `50024663` (merge `8bae9d74`); no direct image or card-art edits. The review pass also anchors the hidden tier icon to its button on every layout, draws the hand-count cloth only when its count is visible, and removes ShelfPlank’s unused face paint.

Fight keeps the accepted card size and compact formation. Both heroes now have matching side docks, with equal portrait and Health treatment; playback controls have a small central dock. World remains visible on both sides. The frame ignores pointer input from construction. Obsolete `stack_surface.gd` and its UID were replaced by `play_frame.gd`.

Look in `build/loop1/frame/` for recruit and fight stills and short clips at PC and phone sizes. Compared directly against the Bazaar frames: distinct material areas and cards remain the focus, with the woodland framing them. The retired Old Badger shot tile is left to the art branch.

Tests: `test_phone_layout.gd` retains the centred rear-slot tap regression and adds repeated-layout tier-anchor coverage at both sizes. `test_hand_fan.gd` now checks displayed font sizes including all parent transforms, conditional bar values, and repeated-layout stability, alongside its existing stat-ink overlap checks. No tests deleted; label limits unchanged. Focused group: 119 tests pass.

The prior A2 gate and two-size UI run passed. Final review validation and refreshed secondary-screen/scouting stills are pending. Drag and reader behaviour remain untouched.
