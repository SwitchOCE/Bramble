# Bazaar Stack framing — A2

Recruit now sits on a centred table across 74% of the PC width. Woodland remains visible at both sides and above it; phone retains a world strip between the standings rail and table and at the right edge. Ten reserve portraits stay exposed in the stack. Shop cards and the hero/action bar scale into the narrower PC surface through shared parent transforms that preserve the widgets’ ordinary animation scales.

The merchant uses warm wood with a muted cloth lip, the formation a darker moss wash, the hand blue-grey cloth, and the bar and rail their own quieter surfaces. Shared surfaces use code-drawn ink contours, uneven edges, broad translucent washes and cream light from the upper right. No photographic grain or new instructional labels. The world and portrait images are untouched.

Fight keeps the accepted card size and compact formation. Both heroes now have matching side docks, with equal portrait and Health treatment; playback controls have a small central dock. World remains visible on both sides. The frame ignores pointer input from construction. Obsolete `stack_surface.gd` and its UID were replaced by `play_frame.gd`.

Look in `build/loop1/frame/` for recruit and fight stills and short clips at PC and phone sizes. Compared directly against the Bazaar frames: distinct material areas and cards remain the focus, with the woodland framing them. The retired Old Badger shot tile is left to the art branch.

Tests rewritten: only `tests/ui/test_phone_layout.gd::test_pc_reader_leaves_occupied_rear_slots_fully_tappable`. The occupied rear-slot checks retain centre and attempted hit-fraction taps while following the centred table, instead of hardcoding coordinates from the old placement. No tests deleted; label limits unchanged. Focused layout/declutter/hand/reader group: 117 tests pass.

`./scripts/check.sh --keep-going --base 8fe9f7d1` passes: all steps and 2,740 tests. The one-game-per-size UI run is in progress; PC seed 1000 completed 12 turns with zero problems and zero errors. Drag and reader behaviour remain with step B; its integration awaits the orchestrator’s merge point.
