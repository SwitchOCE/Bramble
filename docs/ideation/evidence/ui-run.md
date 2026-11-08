# Scripted full UI run

Made by `tests/ui/full_ui_run.sh 2 1000` on 04b1a96 (ideation/main), 2026-11-07.

**1 failed out of 4 games and 2 late-game checks. Depth bar: not judged: under 10 games a size.**

| Depth | Needed | Got |
|---|---|---|
| Games reaching turn 12 | 10 | 1 |
| Games reaching turn 15 | 3 | 0 |
| Games won | 1 | 0 |
| Ghost fights | 3 | 0 |
| Games reaching tier 5 in play | 2 | 3 |
| Games reaching tier 6 in play | 2 | 2 |

Smallest text on screen: phone size 31 canvas units (the minimum is 31); desktop size 22, where tile rules and lobby names may go down to 22.

Clicked for real, with each press checked to change the game or tell the player why not: New game, Buy, Sell, Play, hero power, playing a unit by tapping it and a slot, Refresh, Freeze, tier up, End turn (a turn that doesn't end never reaches game over), Scout, Who?, Close, the pause menu, Settings and its Back, the guide's pages, the speed token, Watch again, Skip, Continue and Main menu. Not clicked: drags and drops, which go through the screen's own drop handlers; the dev panel, used only by the late checks; Leave game and Quit. The New game signal is caught so a game uses this run's seed and lobby, so the first-game guide and random seeds aren't run. Naive remains a tool-only yardstick; no bot strength is offered in the menu. To test the test, Scout, Who?, Continue, Main menu, hero power, Sell and Play were unhooked by hand: the run reported each. Three no-effect presses of one thing in a turn is reported as a loop.

Each turn also opens Scout, taps their unit, a small shop tile and sometimes buys from it, and checks the layout before and after its actions and with a card selected. It watches each fight at 4x. Once a game it visits every guide page, settings and pause, and replays one fight. Words on screen are checked for bot numbers, raw ids and tribes not in the lobby.

How the games are set up: `skilled` climbs on a schedule, buys the biggest units and sells the weakest; `cap3` and `cap4` do the same with at most that many units, which makes longer games; `random` buys at random. Most slots are Naive lobbies because this is the only level the scripted player outlasts: in trials it was out by turn 9 at Easy, Normal and Hard even when skilled, so those three levels are covered but shallow. That's a limit of the scripted player, not a measure of the bots.

What it isn't: a real phone or a real finger. Agents can only measure layouts at phone size. The UI sees mouse input, which Godot also uses for touch.

| Size | Seed | Bots | Player | Place | Turns | Ghost fights | Top tier | Problems | Errors | Exit | Seconds | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1920x1080 | 1000 | naive | skilled | 3 | 12 | 0 | 6 | 0 | 0 | 0 | 290 | ok |
| 1920x1080 | 1001 | naive | cap3 | 8 | 10 | 0 | 6 | 0 | 0 | 0 | 231 | ok |
| 1688x780 | 1100 | naive | skilled | 8 | 7 | 0 | 4 | 0 | 0 | 0 | 94 | ok |
| 1688x780 | 1101 | naive | cap3 | 8 | 10 | 0 | 5 | 3 | 0 | 0 | 148 | FAILED |

Late-game layout, forced to tier 6 with a full board and hand:

| Size | Seed | Problems | Errors | Exit | Verdict |
|---|---|---|---|---|---|
| 1920x1080 | 1000 | 0 | 0 | 0 | ok |
| 1688x780 | 1000 | 0 | 0 | 0 | ok |

## Problems seen (first 40)

- 1688x780 seed 1101 round 2 guide page 12: 'Oozes' on screen in: Oozes
- 1688x780 seed 1101 round 2 guide page 12: 'Oozes' on screen in: Oozes hold; Birds travel
- 1688x780 seed 1101 round 2 guide page 12: 'Ooze' on screen in: Drop a unit into an Ooze's Belly to keep it inside. When the Ooze fain

Build 5 delivery: source 8c78def plus the opening-name and waiting-hit-panel fixes, core 3 only, LP_NUM_THREADS=1, normal engine clock; hard `timeout -k 5 2400 tests/ui/full_ui_run.sh 2 1000`. Original UI minimums retained. Original suite flagged only three absent-lobby Ooze references in the general guide in phone seed 1101; its full affected-game retry passed after the then-unreviewed whole-game guide vocabulary scope correction. The affected-game retry used the same player, seed and size with a hard 15-minute timeout; other three games and both late checks passed. Original failure rows/logs are retained. The generated report labels these slots Naive, but playthrough.gd currently calls port.setup() without a level override and uses the sole full-game bot strength; its --level argument is parsed but unused. The table's legacy level labels and historical discussion of Easy/Normal/Hard coverage do not describe the actual lobby configuration. Easy and Normal no longer exist; no bot strength is offered in the menu. No depth-bar UI run or full bench, no real device and no listening test. Burner remains provisional and bot-tuned.


The later [engines review](review-engines.md), range (b), kept the opening-name, waiting-panel and guide-checker fixes. That review occurred after build-5 delivery; the delivery check was not itself a fresh review.
