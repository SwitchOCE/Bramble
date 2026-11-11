# A4: rounded hex faces

Shared rounded 0.78:1 contour, with points 19% deep, for card paint, portraits,
native mouse/touch picking, drops, floor Rings and Ring travel. Units, spells and
items fit their caller's box. Spells have a violet double rim; items have brass
rivets. Paper, bark edge, cream upper-right light and soft contact shadow remain.
Ink scales from 2–4 canvas units. Selection/hover rims paint above neighbours on
an independent layer; combat keeps its animation ordering.

Board rows remain four front, three behind, offset half a slot, with the painted
back row tucked by 29/226 of the face height. Opposing front rows face each other.
Recruit's extra 40 px per card is removed. Empty slots have no resting paint and
show drop outlines only during a drag. Nest portraits cover-crop into a hex.
Three-digit badges widen. Tiny legacy scout boxes step Attack up when two wide
badges cannot fit abreast; neither badge covers the other or leaves its box.
Specific Mire, Quarry and Swoop marks remain, as do defence/counter marks.
Rainbow bands follow the lower hex rim. The transient attack-source outline
uses the same contour and ink weight. Animated stat rolls resize their badges.

All 155 portraits were inspected first at 176×226 on five full-size contact
sheets. Final sheets use the current combat board box, 199×255.
Small source-relative pans correct cropped faces/props on old_isegrim,
signor_ranocchio, madame_bufo, gable_ratchet, grizel, grey_agnes, mrs_jay,
sergeant_conkers and pennyworth_snail. No portrait files were repainted.

Tests rewritten:
- `test_card_art_layout.gd`: full hex art replaces the rectangular 68% art window.
- `layout_check.gd`: transformed polygon intersections replace rectangle overlaps;
  actual overlapping hexes still fail.
- `test_big_numbers.gd`: badges must not intersect and must stay in their caller's
  box, replacing the old horizontal-only placement assertion. Font/precision and
  recruit/combat behaviour checks remain.
- `test_scout_reach.gd`: the foreground cue is a drawn hex Control, replacing a
  rectangular Panel; its lifetime and foreground assertions remain.

- `test_combat_face.gd`: pending-gain clearance is checked in the card's coordinate
  space, accounting for the inset hex face.
- `test_ring_travel.gd`: the reduced-motion destination is the actual hex's first
  perimeter point, replacing the old rectangle corner; no-route checks remain.

New `test_hex_units.gd` checks arbitrary boxes, contour hits/drops, actual Godot
GUI picking at tucked corners, opposing row packing, real overlap detection,
foreground focus and exact three-digit badges.

Evidence: `build/loop1/hex/`; `tests/ui/shots/hex_evidence.gd` uses real screen
widgets with a staged full shop, seven units and four hand cards, and core-generated
7-v-7 combat for the still and clip. The portrait sheets include every JPG.

## Integration and verification

Final focused run: 67/68 tests pass across 11 scripts. The remaining test is the
unchanged combat-screen bounds assertion in `test_big_numbers.gd`. Exact stats,
font minimums, native input, recruit motion, attack/death/replay cues and Ring
travel checks pass. Formatting and lint pass. Final gate/UI run pending. The current screen layout predates A3. Its combat `POCKET=220`
produces a 1025×541 tray and places the lower board beyond the 1080 canvas. A3 must
supply its common unit box and screen anchors; no screen files were changed here.
`CardView.set_card_size` fits the exact caller box; `size_for` offers 0.78:1 in all
modes. Board `configure` retains its existing pocket-width argument and tile-width
mapping (112/124); no recruit-only height is added.

The first required gate stops at three importer-generated, untracked `.uid` files
under fenced paths. Automatic approval review refused cleanup; owner approval is
pending. These files are not staged or committed. Remaining checks run through the
gate's existing `--keep-going` option.
