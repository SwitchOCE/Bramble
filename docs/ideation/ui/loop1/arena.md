# A3: the arena arrangement after A4

Built on recruit feel B, the four-card hand, and the owner's hex merge `e8674ecb`.
Checkpoints: `31a08e8a` adopts native hex boards and restores tap action targets;
`e5fb6574` grows the shared units, closes the market/board band, and fits the hand.
`c6916630` preserves the hex warning roles and keeps shop targets clear of readers;
`889e28dc` reserves enough reader height for rules and adds a rendered-rules guard.
Earlier A3 checkpoints were `a7e51733`, `ddbe2683`, `a838bed6`, `57e2adad` and `7bd2b015`.

The owner's rule is **“Vertical space goes to the boards.”** The earlier 820-pixel
board and 176×226 unit dimensions came from the lab's agent, not owner decisions.
They have been replaced by the larger geometry below.

## Geometry and continuity

- Every shop offer, hand unit/item, own unit, scouted unit and fight unit uses
  **201×257.69 logical pixels**: **201×257.69 physical pixels at 1920×1080** and
  **145.17×186.11 physical pixels at 1688×780**. The logical canvas remains 1080 high.
- The player's frame is **1035×522**, horizontally centred, at **y550**, in recruit,
  scouting and fight. The opponent/scout frame is at y16. The native hex tray is
  1035×521.9074 and is centred within each frame, without changing packing or drawing.
- The market holds **six units and one spell** at that same size. Its width is 1567;
  contents-fitted height is 445.69 on desktop or 479.69 on phone. The header is 80
  high, then the unit row, an 8-pixel gap, 88/122-pixel controls and 12 pixels below.
  Its bottom is y538 at both sizes: only the **12-pixel frame seam** remains before
  the own-board frame. Extra space is above the market rather than between the play
  surfaces.
- The hand starts at y538. Two rows of full hexes, 12-pixel gaps and 4-pixel insets
  fit above the bottom edge, including a four-card mixed unit/item hand. Capacity
  sits just above the tray. Phone width goes to the side columns: the hand frame
  widens from 422 to 575 canvas pixels and the right dock can widen to 400.
- The sizing subclass `arena_board.gd` was removed. Screens use native
  `BoardView.configure(..., height_limit)` with a 222-pixel pocket and 522-pixel
  height limit. Native row tuck, hex picking, slot paint, hover and foreground focus
  ink remain A4's implementation.

## Interaction and scope-review decisions

Resting slots stay quiet. Selecting a hand unit, a movable board unit, or an aimed
power/item exposes its legal destinations for tap play as well as drag play. Cancel
or commit clears those targets; ending a drag preserves any still-selected action.
White selection, hover lift/shadow, purple third-copy warnings and permanent gilt
material keep their separate A4 roles.

Fight standings are display-only, with no tap/hover reader or scouting. The adapter
records all standings before the round resolves; playback and rewatch keep that
pre-fight Health and survival state. `combat_scout.gd` was removed.

Every standings seat still opens its recorded last board during recruit.
`CorePort.scout_player` retains `session._scout_of(player_id)`: this is a **private
core method**, to replace with a public accessor when core work resumes. No private
hand or current opponent recruit state is exposed.

**Accepted loss:** buying waits until Market return. Scouting hides offers, Refresh,
Freeze and Ask for Kin (also a refresh of hidden offers). Gold and tier-up remain.
The dead `_scout_token`, `_who_token`, `next_tapped` and `next_requested` are deleted;
`strong_field.gd` uses the actual standings portrait and Market return.

The reader keeps B's content-fitted behavior. Its free-space search protects the
exact source card, the whole offer row and its legal targets, own/scouted boards,
gold, market controls, End turn and standings. It can cover other hand cards while
their source stays clear. Candidate bands must provide at least 300 logical pixels
of height and are scored after the 530-pixel width cap, avoiding a wide, shallow
header band that clipped the rules. Narrow side bands can be 270 pixels wide; rules
stay on the paper, with scrolling available for longer entries.

## Where the existing elements live

| Element | Home |
|---|---|
| Offers, gold, income | Upper market surface |
| Current tier, tier-up/cost, Refresh/cost, Freeze, Ask for Kin | `TIER n` in header, controls inside market; scouting retains only tier-up and gold |
| Turn and gear | Top-left; cream gear on slim dark strip, clear of Turn |
| Hand, items, capacity, Larder | Left 2×2 tray; original indices and tap/drag routes |
| Hero, Health, armor, power/cost | Right of own board; fight heroes use matching positions |
| End turn | Right dock, 270×122, with B's callbacks and end motion |
| Tribe bonuses, Ring size, Midsummer, Bog Toll, engine counters | Right dock above hero |
| Away birds, doorstep, countdowns | Right dock below hero; all inspectable |
| Standings, tiers/Health, elimination, ghost, Last Stand | Centred right portrait rail; recruit interactive, fight display-only |
| Scouted identity and return | Upper board, readable dark nameplate/portrait, Market return |
| Rules, keywords, actions, held-unit details | Shared content-fitted reader; fight reader in left dock |
| Ring/Nest/Horseshoe marks, unit counters and status | Native slot/unit widgets and readers; selected scout supplies its own Ring data |
| Pause, Settings, guide, last fight, rewatch, Dev | Gear menu; Dev beside it when enabled |
| Step, play/pause, speed, skip | Cream icons on slim dark strip left of the fight; full 88/122 input rectangles |
| Gain/sale/buy/merge/fight feedback | Existing motion helpers, anchored to current unit and visible tier geometry |

## Verification and evidence

- Native hex integration: `test_slot_target_visibility.gd` and `test_hex_units.gd`
  passed 9/9, 1,056 assertions, before growth.
- Growth regressions: arena, hand and phone layout tests passed **33/33**, 1,534
  assertions. They cover both sizes, fixed board geometry, common full size, four
  mixed hand tiles inside the viewport, shape-aware face separation, reader/input
  behavior, legal tap targets, and the 12-pixel market seam.
- Combined A4/layout run: **42/42**, 2,620 assertions, including the unchanged
  `test_slot_target_visibility.gd` and `test_hex_units.gd`.
- Final reader/layout/action/polish run: **62/62**, 2,806 assertions. The reader
  guards check that the rules viewport stays inside both reader and paper and has
  usable height at both screen sizes.
- Final gate on committed runtime tip **`889e28dc`**, against `origin/ideation/main`
  (`32a55657`): **all steps passed**, including scope fence, import/compile and strict
  GUT. **271 scripts, 2,771 tests and 74,878 assertions** passed; no core/play failures.
- Required `GODOT_SLOT_CLASS=gate timeout 3600 tests/ui/full_ui_run.sh 2 1000`,
  through the slot wrapper on **`889e28dc`**: **exit 0, zero PROBLEM lines, zero
  errors**, all four games and both late checks passed. Desktop seeds 1000/1001
  reached turns 11/20; phone seeds 1100/1101 reached turn 12 each. Both late checks
  exercised tier 6, seven board units and a full four-card hand over five rounds.
  This is the requested two games per size; the twenty-game depth bar is not judged.
- All twelve refreshed states at both sizes, paired with the matching lab captures:
  `build/loop1/arena/index.html`. Every native image and comparison was inspected;
  reader text stays on paper, all four phone hand faces fit, and the board frame is
  stationary across phases. The final reader captures were refreshed after the fix.
- Recruit and fight clips: `build/loop1/arena/recruit-turn.mp4` and `fight.mp4`, each
  1920×1080, six seconds at 30 fps. Both refreshed at the committed runtime tip;
  contact sheets and native frames inspected. The recruit clip buys, plays and ends
  a turn into a fight; the fight clip shows active playback.

Logs, JUnit XML and the six per-run UI logs are in
`build/loop1/arena/verification/`. The final evidence commit changes documentation
only; runtime and test files match the verified commit.

No UI tests were deleted. The hex follow-up rewrites geometry assertions in
`test_arena_layout.gd`, `test_hand_fan.gd`, `test_phone_layout.gd` and the old unit-size
assertion in `test_polish.gd`; tap targets are
updated to A4's accepted tap behavior, while input and overlap guards remain.
Earlier A3 layout updates also touched `test_away_tokens.gd`, `test_pass3_ui.gd`,
`test_polish.gd`, `test_slice_display.gd`, `test_tile_words.gd`,
`test_combat_declutter.gd`, `test_combat_wave2a.gd`, `test_combat_reader5_motion.gd`,
`test_recruit_actions_motion.gd` and `test_recruit_declutter.gd`.
`test_combat_start.gd` adds all-seat pre-fight Health/rewatch coverage. Capture helpers
wait for completed draws, stage pre-fight standings, and use real portrait/return
routes. No core rules, card text or gate scripts changed.

## Beside the lab

Both now use hex faces and tucked native rows. Godot keeps the lab's stationary
formation arrangement, enlarges all units together and uses the screen height for
play. The market is wider than the lab's original 1160-pixel surface so seven full
objects fit; the lab's seven-offer probe overflows. The four-card tray fits instead
of running into the lower edge.

Godot retains A2's painted play surfaces and woodland frame, a smaller End turn, real
playback controls and live game information. It omits the unsupported lab route and
resting slot captions. Scouting is absent from the lab: its native fight is labelled
as the nearest two-board comparison. Four-card/seven-offer lab shots are browser-only
capacity probes using the unchanged CSS and cloned existing cards.

Physical phone handling remains untested; captures and scripted input use its actual
landscape window size. The full strong-field evidence campaign is not repeated here;
its updated click routes are compiled by the gate.
