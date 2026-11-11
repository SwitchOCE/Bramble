# A4: rounded hex faces

Shared rounded 0.78:1 contour, points 19% deep, for portraits, paper frames,
mouse/touch picking, drops, Rings, Ring travel and attack-source outlines. Spells
use a violet double rim; items have brass rivets. Paper, olive-bark edge, cream
upper-right light and contact shadow remain, with 2–4 px ink. Selection and hover
paint above tucked neighbours. Three-digit badges widen; animated numbers refit
at every frame. Specific keyword and defence marks remain.

The board packs four front and three behind, half a slot offset, with a 29/226
face-height tuck. Empty slots paint only as drag targets. Nest art cover-crops
inside a hex; Rainbow bands follow the lower rim.

The owner's follow-up required fixing bounds before completion. `BoardView.configure`
now accepts a caller's height limit and fits the pocket width without shrinking
fonts. Compact boards recover their compact padding. Small guards in
`combat_screen.gd` and `recruit_layout.gd` reserve the existing footer/hand zones;
scouting retains matching columns and separates both formations. A3 can supply
its common unit box through the existing size/configure calls.

Bare Interactive screen zones retain rectangular input; cards and slots opt into
hex input. A valid press remains draggable after the pointer leaves its face.
Fallback names use the wide band rather than unnecessary side padding.

## Portraits and evidence

All 155 portraits were inspected on seven full-size sheets at the fitted combat
box (168×215.38). Small source-relative pans: old_isegrim, signor_ranocchio,
madame_bufo, gable_ratchet, grizel, grey_agnes, mrs_jay, sergeant_conkers,
pennyworth_snail. Portrait assets were not repainted.

`build/loop1/hex/` contains native 1920×1080 and 1688×780 recruit captures (7 board,
4 hand, 7 shop), core-generated 7-v-7 mid-lunge fights, golden/999/keyword/type
studies, tucked selection/hover studies, portrait sheets and a six-second
1920×1080 MP4. Every still and sampled clip frames were inspected at full size.

## UI tests updated

- `test_card_art_layout.gd`: full hex art replaces the rectangular 68% window.
- `test_big_numbers.gd`: actual badge separation/containment replaces horizontal-only placement.
- `test_combat_face.gd`: pending-gain clearance uses the card's coordinate space.
- `test_ring_travel.gd`: reduced-motion endpoint follows the hex rather than a rectangle corner.
- `test_scout_reach.gd`: foreground cue is a hex Control rather than a Panel.
- `test_hand_fan.gd`: taps and drags sample painted faces and verify each tap arrives.
- `layout_check.gd`: transformed polygon intersections detect overlap; real overlapping hexes still fail.

New `test_hex_units.gd` covers contour input/drop, native picking at tucked corners,
packing, focus and exact three-digit badges. `test_review_fixes.gd` adds rectangular
screen-zone and delayed-drag regressions. Existing behavior assertions remain.

## Verification

- Bounds/input regression selection: **94/94 tests pass** (7 scripts, 4,758 assertions).
- Full `./scripts/check.sh --keep-going --base origin/ideation/main`: **all steps pass**,
  **2,753/2,753 tests**, 269 scripts, 72,751 assertions; core and play included.
- Full `tests/ui/full_ui_run.sh 2 1000`: **zero failed**, four full games and two
  late-game checks, **zero PROBLEM lines and zero errors** at both sizes.
  Slot acquisition precedes the standard 3,600 s suite timer and 900 s game
  timer. The two-games-per-size run does not judge the depth bar.
- No implementation work remains; A3 supplies the common unit box. Renders and
  the 6-second clip are in `build/loop1/hex/`.
- Scope review: UI/widgets, two screen bounds guards, UI tests and evidence/step note.

Baseline updated to `ce242a92` by fetching and rebasing this unpublished branch
(worker rules prohibit merges). The hand-of-4 test fixes are included. The final
gate now requires **zero failures in core, play and UI**; the earlier nine baseline
failures are no longer treated as exceptions.

The owner merged `15145f83` after the gate: only the three generated UID
sidecars changed relative to the tested checkpoint. They are now tracked and
remain in place. UI source and inspected renders are unchanged. Godot
config/data/state use writable temporary directories.
