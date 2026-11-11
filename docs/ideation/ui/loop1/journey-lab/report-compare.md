# Lab beside build

Reviewed `ideation/main` at `5e8a0407`, the briefs and handoff, all supplied images at original resolution, the named widgets/screens and relevant UI tests. Also viewed Bazaar, Battlegrounds and TFT reference frames. Only this report changed; no commits, denied actions or Godot/test runs. Runtime behaviour remains unverified.

The lab makes the formation feel like a permanent object; our build feels like four shelves. Its strongest advance is continuity between phases, followed by putting supporting controls beside their subject. Our distinct surfaces and centred formation already converge independently with the lab. Keep those gains and the quieter empty slots.

## Rule comparison

References below are branch file lines: **R** = `src/ui/screens/recruit_layout.gd`, **C** = `screens/combat_screen.gd`, **V** = `widgets/card_view.gd`, **B** = `widgets/board_view.gd` (all under `src/ui/`); **D** = `docs/ideation/DECISIONS.md`.

| Owner rule | Build and evidence |
|---|---|
| 1. Clean Arena base | **Partly.** Central stacked shop/formation, but Bazaar Stack remains the call (D16); hand/bar occupy the lower centre (R185–241). |
| 2. Board never moves | **Conflicts.** Recruit uses pocket 222, y302 (R104–106); fight uses 220 and places yours below the enemy tray (C38,224–234). Scouting also resizes/repositions yours (R156–162). No journey phase exists in the inspected screen flow (`app.gd:185–228`). |
| 3. Board centred | **Already.** R101–105 and C229–232 centre horizontally, independently matching the lab. No left-right layout needs implementing. |
| 4. Equal units everywhere | **Conflicts.** Shop dimensions vary with offers (R121–135,265–267); hand height is 152 (R270–272); board uses another ratio (V106–112); fight/scout sizes differ again. |
| 5. Contained board | **Already.** R543 and C238–242 provide separate framed surfaces; `painted_surface.gd:12–60` draws their edges. Independent convergence, explicitly D31. |
| 6. Shop contains its buttons | **Partly.** Own shop surface exists (R542), but buttons remain in the bottom bar (R216–227,502–512). |
| 7. Height for boards | **Partly.** Fight prioritises boards; recruit reserves hand/bar bands (R185–241,544–547), despite spare side width. |
| 8. Right, centred leaderboard | **Conflicts.** Left rail at x8/y40 (R107–108); `lobby_strip.gd:74–85` stacks fixed-height seats. Fight has none. |
| 9. Layout B sides | **Partly.** Portrait strip exists, but wrong side; hero, turn and End turn remain below, hand across the bottom (R173–241). Route is absent. |
| 10. Rounded, packed tall hex | **Conflicts.** Rounded rectangles (V491–535), wide board ratio (V21), separate rows (B154–182), no point nesting. |
| 11. Four front, three offset behind | **Already.** B14–15,166–182 implement half-slot staggering, matching rulebook §8.1 independently of the lab. |
| 12. Ignore placeholder art fit | **Already compatible.** No portrait replacement is needed to evaluate layout. Existing art-share checks concern presentation, not the owner's placeholder crop. |

## Gaps, dependencies and risk

- **Market grouping — small:** R’s `_layout_right`, `_fit_bar`, `_layout_frame` can move tier/refresh/freeze and gold into the shop surface, preserving callbacks. Refit offers and reader together. Risk: shop height and reader/action collisions on phone; exercise `test_phone_layout.gd` and `test_recruit_actions_motion.gd`.
- **Right rail — small in recruit; medium across phases:** change R, `lobby_strip.gd`, C and `app.gd` to retain standings in fight. Move the gear/reader clear. Eight lab portraits fit by using smaller seats; preserve usable phone targets rather than copying its 96-pixel strip. Keep pre-fight health consistent. Recruit relocation can land independently.
- **Permanent board and side docks — medium together:** share geometry between R/C, move hand left and hero/End turn right, relocate turn top-left; adjust `hand_fan.gd`, reader placement and `recruit_action_motion.gd`. Scouting must use that same board rectangle. A ten-card hand needs a real grid/scroll arrangement; the lab's one-card example proves little here. Risks: `test_hand_fan.gd`, `test_phone_layout.gd`, `test_field_presentation.gd`, reader and away-token reachability.
- **Equal hex units — large:** V, `art_frame.gd`, B, `slot_view.gd`, `interactive.gd`, hand/shop layout and `combat_face.gd` must agree on dimensions, mask, nesting, hit regions and mark anchors. Hex-only input must accompany nesting. Eight shop offers must wrap/scroll without shrinking independently. Adapt `layout_check.gd:59–72` to actual shapes; rectangular overlap checks would reject legitimate nesting. Revisit `test_card_art_layout.gd`, counters, Ring travel and combat-motion tests together.

All are UI-only. Cosmetic journey scenery/route could follow through `world_background.gd`/`app.gd`; do not import the lab's two-turn travel schedule or invent gameplay. On-demand reading already converges (V3–4); card flipping is optional. Empty slot codes and repeated labels conflict with D30/40 and should stay omitted.

After implementation, run the gate, four-game UI run (two per size, plus late states), and inspect 1920×1080/1688×780 captures, real hex taps and drags. The scripted run does not perform physical drags. No tests were rewritten here.

## Decisions requiring revision

Replace D16’s Bazaar Stack base; revise D24’s “A alone rewrites” restriction for the replacement layout worker. Amend D29’s “hero in the bottom bar.” Revisit D18–19’s frame-only/light-pass limit for hex work; retain D20’s paper material treatment. D31’s distinct zones, D40’s declutter and D44’s collapsed scouting remain compatible; persistent scouting geometry does not require retaining the lobby.

## Three changes

1. Put tier-up, refresh, freeze and gold inside the shop surface; reuse the existing controls (small).
2. Move the portrait leaderboard to the right and centre its seats vertically, preserving phone tap targets (small for recruit).
3. Move the hand left and hero/End turn right, then share one fixed player-board rectangle across recruit, scouting and fight (medium, coupled).
