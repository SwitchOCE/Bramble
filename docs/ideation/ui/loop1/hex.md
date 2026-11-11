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
- Formatting, lint, import, compile and parity pass.
- Full gate and full UI run: final results pending below.
- Scope review: UI/widgets, two screen bounds guards, UI tests and evidence/step note.

The owner identified these nine baseline hand-limit failures and is fixing them
separately; they are reported rather than edited here:

| Script | Test |
|---|---|
| `tests/core/test_pass3_birds_recruit.gd` | `test_homecoming_full_hand_waits_on_doorstep_and_doubles_once` |
| `tests/core/test_pass3_dial_behaviour.gd` | `test_ermeline_printed_count_and_pelt_share_match_award_and_spell_effect` |
| `tests/core/test_pass3_hedge_recruit.gd` | `test_mast_caps_each_source_and_caps_off_counterexample` |
| `tests/core/test_pass3_hedge_shares.gd` | `test_mast_normal_and_golden_caps_pay_five_or_ten_actual_acorns` |
| `tests/core/test_pass3_presets.gd` | `test_optional_bird_dials_can_be_swept_and_captured_from_b` |
| `tests/core/test_pass3_slice_triples.gd` | `test_golden_first_slice_triple_frees_hand_room_for_its_second_slice` |
| `tests/core/test_quilboar.gd` | `test_trailblazer_combines_one_card_per_turn_and_golden_combines_two` |
| `tests/core/test_review3_mast.gd` | `test_buying_mast_does_not_pay_but_playing_it_then_buying_does` |
| `tests/play/test_play_tools.gd` | `test_every_action_kind_round_trips_through_play_game_run` |

Automatic approval review refused cleanup of three untracked importer-generated
identifiers: `src/core/combat/combat_events.gd.uid`,
`tests/core/pass3_original_b.gd.uid`, `tests/core/test_replay_contract.gd.uid`.
Owner approval to remove only those generated files is pending; the scope fence
still reports them. They are not committed.
