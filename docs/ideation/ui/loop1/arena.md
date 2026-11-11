# A3: the arena arrangement

Built on recruit feel B and the hand-of-four fix. Checkpoints: `a7e51733` (screens),
`ddbe2683` (geometry, scouting, tests and capture helpers), and `a838bed6`
(owner review corrections and obsolete layout assertions). The follow-up below
applies the owner's scope-review decisions before A4 merges. That review reported
no cuts; the accepted asks and simplifications are implemented here.

The current player's framed board is 820×510 at centred x, y554 in the 1080-high canvas in
recruit, scouting and fight. The opponent/scout frame is centred at y16. Godot's
minimum-size cache is explicitly refreshed so the actual board rectangle also
matches across phases. The screen sizing adapter leaves the shared board's row
packing, slots and drawing to A4; faces remain rounded rectangles here. The 820-pixel
board and 176×226 unit dimensions are numbers chosen by the lab's agent, not owner
decisions. The owner's rule is **“Vertical space goes to the boards.”**

Units are **176×226** logical pixels everywhere. They are **176×226 physical pixels
at 1920×1080**, and **127.11×163.22 at 1688×780**. The wider phone canvas gives its
extra width to the side columns. The market is 1400×414 on desktop and 1400×448 on phone, holding the configured maximum:
six units and one spell, with no independent shrinking. Four hand units/items share
a 2×2 tray. Empty hands and resting empty slots stay quiet; empty drop targets appear
only during a drag.

## Owner review corrections

Both gears draw as 32-pixel cream icons on slim dark strips. Fight tools share one
strip with the gear. Turn keeps its own clear top-left rectangle. Input rectangles
remain 88 pixels on desktop and 122 logical pixels on phone. The current tier is
shown as `TIER n` in the market header, including during and after action motion.
Scouted names wrap on their own dark nameplate.

The market now follows its contents: an 80-pixel header, one 226-pixel offer row, an
8-pixel gap, and the control row with 12 pixels below it. This reclaims 96 pixels on
desktop and 62 on phone. Gold/income fit the compact header.

Unit growth waits for the owner's A4 merge. After it lands, grow the single shared
unit size until the empty band between market and board closes at both sizes, using
1688×780's extra width for the side columns. The current fixed dimensions are a
starting point from the lab, rather than an approved limit on board space.

## Scope-review decisions

- Fight standings are display-only: no tap or hover reader and no fight scouting.
  `combat_scout.gd` was removed. The UI adapter records every standings seat before
  resolving the round, so the rail and rewatch retain pre-fight Health and survival
  status instead of revealing the round's results.
- Any standings seat still opens its last recorded board during recruit.
  `CorePort.scout_player` still calls `session._scout_of(player_id)`, a **private core
  method**. Replace that call with a public accessor when core work resumes.
- **Accepted loss:** buying waits until returning to the market. Scouting hides the
  offers, Refresh, Freeze and Ask for Kin (also a refresh of hidden offers). Gold
  and tier-up remain available; returning restores the market without changing it.
- The dead `_scout_token`, `_who_token`, `next_tapped` and `next_requested` were
  deleted. `strong_field.gd` now clicks the standings portrait and Market return.

## Where the existing elements went

| Element | Home |
|---|---|
| Shop offers, gold, income change | Top market surface; income stays beside gold |
| Current tier, tier-up and cost, refresh and cost, freeze, optional Ask for Kin | Tier in the market header; action row inside the market. Scouting retains tier-up and gold and hides actions on hidden offers |
| Turn | Top-left, in recruit and fight |
| Hand and items, capacity and Larder count | Left tray; original indices and direct tap/drag input retained |
| Hero, Health, armor, activated power and cost | Right of the player's board; both fight heroes use matching positions |
| End turn | Right of the board, 270×122; original callbacks and end-of-turn motion retained |
| Tribe bonuses, Ring size, Midsummer, Bog Toll and other engine counters | Right dock above the hero; the original chip widgets remain |
| Away birds, doorstep and countdowns | Right dock below the hero; every token remains inspectable |
| Standings, opponent tiers/Health, elimination, ghost and Last Stand marks | Right edge, vertically centred; recruit seats scout, fight seats only display pre-fight standings |
| Scouting and opponent identity | Recruit upper board and adjacent hero/nameplate; Market returns to buying. Fight scouting removed by owner decision |
| Card rules, keywords, actions, reminders and held-unit details | B's content-fitted reader; recruit chooses a free side band, fight uses the left dock |
| Ring/Nest/Horseshoe marks, unit counters, status and transient relationship cues | Original slot/unit widgets and reader paths; the selected scout snapshot supplies empty-slot Ring details |
| Gear, pause, Settings, guide, last fight, rewatch and Dev | Gear top-left opens existing menus; Dev remains beside it when enabled |
| Fight step, play/pause, speed and skip | Cream icons on the slim dark strip left of both boards, beside the gear and clear of Turn and the reader |
| Recruit gain/sale/buy/merge feedback and fight effects | Existing motion helpers; the tier animation uses its visible numeral's anchor |

Scouting any standings seat uses the existing recorded public last-fight snapshot,
through a UI adapter accessor. No opponent hand/current recruit state is exposed.
Fight standings are display-only. Pre-fight standings Health is retained on rewatch.
No rules, card text or core files changed.

## Verification and evidence

Latest scope-review follow-up: **562/562 UI tests passed** across 74 scripts
(25,021 assertions), exit 0. After the visual check caught the lowercase speed-icon
ink, the final palette correction also passed all **12 arena tests** (754 assertions),
including the cream glyph pixels for every playback speed. All **739 scripts
compiled**, and changed files passed formatting/lint. Six native recruit/scouting/fight
renders were inspected at both sizes under `build/loop1/arena/scope-review/index.html`;
its `verification/` folder contains the passing logs. The full strong-field capture
run was not repeated; its updated real portrait/Market routes compile.

The following full-gate, full-game, comparison and clip evidence is from the prior
`a838bed6` checkpoint:

- Focused regressions: arena layout 11/11 (652 assertions), recruit actions/declutter
  22/22 (959 assertions), and the three affected combat files 52/52 (1,262 assertions).
  The five affected legacy recruit files also passed after their fixture updates.
- Full gate against `origin/ideation/main` (`494d9454`): all steps passed, exit 0.
  All 2,758 GUT tests in 269 scripts passed (72,731 assertions), including core
  and play; 193 Python tests passed; all 740 Godot scripts compiled. No waivers.
- Required `tests/ui/full_ui_run.sh 2 1000`, through the Godot slot wrapper with
  a 3,600-second timeout: four full games and both late checks passed, exit 0;
  zero PROBLEM lines and zero errors. One game reached turn 20 and a ghost fight.
  The 20-game depth bar does not apply to the requested four-game run.
- The earlier internal review found a selected-scout empty-slot Ring reader issue;
  it was fixed and covered by a regression. Phone scouting's Turn and gear were
  verified in fresh renders. The subsequent owner scope review reported no cuts.
- All 12 final Godot renders were inspected at native size. Matching native lab
  comparisons and captions are in `build/loop1/arena/index.html`.
- Recruit/fight clips: `build/loop1/arena/recruit-turn.mp4` and `fight.mp4`; both
  1920×1080, six seconds, 30 fps. Refreshed frames and contact sheets were inspected.
- Final logs, GUT XML, UI report and each game log are saved under
  `build/loop1/arena/verification/`. Both final checks ran against `a838bed6`;
  the final documentation commit adds no runtime changes.

Tests rewritten, none deleted:
`tests/ui/test_hand_fan.gd` (2×2 fixture; fonts checked at their new homes),
`tests/ui/test_phone_layout.gd` (configured six-plus-one market; visible tier anchor;
Market return and unchanged buying context), and
`tests/ui/shots/playthrough.gd` (click the new Market return instead of retired Close).
`tests/ui/test_away_tokens.gd`, `test_pass3_ui.gd`, `test_polish.gd`,
`test_slice_display.gd` and `test_tile_words.gd` update four-card and scouting fixtures
and tap routes. `test_combat_declutter.gd`, `test_combat_wave2a.gd` and
`test_combat_reader5_motion.gd` recognise the exact Turn label and the relocated controls;
all other text and art-clearance guards remain. `test_recruit_actions_motion.gd`
protects actual action homes; `test_recruit_declutter.gd` updates the two affected
label budgets, visible refresh prices and compact-reader fixture.
`tests/ui/shots/screenshot.gd` waits for the final draw before saving captures.
`tests/ui/test_arena_layout.gd` adds phase, size, capacity, reader, standings,
recruit scouting, display-only fight standings, pre-fight Health, drag-target,
selected-scout Ring, ghost, overkill, quiet-tool and market-fit checks.
`tests/ui/test_combat_start.gd` adds coverage for all-seat pre-fight Health and rewatch
without a recruit screen. The follow-up updates the tier animation/header assertions
in `test_phone_layout.gd` and `test_recruit_actions_motion.gd`, the tier font home in
`test_hand_fan.gd`, hidden refresh assertions in `test_recruit_declutter.gd`, and
removes the retired compatibility signal assertions in `test_away_tokens.gd`.
`tests/ui/shots/strong_field.gd` uses the real standings/Market click routes.
Behaviour guards were retained.

## Beside the lab

Every requested state at both sizes has its native Godot capture beside a lab capture
in the gallery. Four-card and seven-offer lab images are browser-only capacity probes
using the original CSS and cloned existing tiles. The lab has no scouting interaction;
its native fight is explicitly labelled as the nearest two-board comparison.

- Empty hand: Godot removes the resting tray decoration; the lab keeps its hand area.
- Full hand: Godot fits all four whole tiles with their count. The lab probe reaches
  the lower edge. Both retain equal object sizes.
- Maximum market: Godot's wider surface contains seven offers; the lab's original
  1160-wide frame overflows with seven. Market controls remain local in both.
- Reader: Godot keeps the source, own board and economy buttons clear. Its compact
  side reader replaces the lab's hover tooltip and tiny phone flip.
- Scouting: Godot retains the hand, gold and tier-up beside the two formations,
  with a named owner and explicit return. Buying, Refresh and Freeze wait for the
  market. This state is absent from the lab.
- Fight: the fixed lower frame matches recruit. Godot adds real playback controls and
  retains A2's painted surfaces. A4 owns the lab's hex faces and tucked row geometry.

Godot also omits the lab's unsupported route, resting sockets and slot labels, keeps
A2's world/art rather than the lab's flat glass styling, and uses a smaller End turn.
Physical phone handling remains untested; captures and scripted input are at its
actual landscape window size.

A4 integration awaits the owner's merge. Keep the arena versions of
`recruit_layout.gd` and `combat_screen.gd` when resolving those conflicts, then
pass the new trailing `BoardView.configure` height limit for the fixed frames.
Recheck the changed hex `tray_size()` and the full hand tray at 1688×780 with
actual hex faces, then grow the one shared unit size to use the vertical space
as requested above. No A4 changes or unit growth were applied before that merge.
