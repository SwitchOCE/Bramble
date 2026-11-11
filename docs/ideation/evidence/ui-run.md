# Scripted full UI run

Made by `tests/ui/full_ui_run.sh 2 1000` on a838bed6 (ideation/ui-arena), 2026-11-11.

**0 failed out of 2 games and 2 late-game checks. Depth bar: not judged: under 10 games a size.**

| Depth | Needed | Got |
|---|---|---|
| Games reaching turn 12 | 10 | 3 |
| Games reaching turn 15 | 3 | 1 |
| Games won | 1 | 0 |
| Ghost fights | 3 | 1 |
| Games reaching tier 5 in play | 2 | 4 |
| Games reaching tier 6 in play | 2 | 4 |

Smallest text on screen: phone size 31 canvas units (the minimum is 31); desktop size 31, where tile rules and lobby names may go down to 22.

Clicked for real, with each press checked to change the game or tell the player why not: New game, Buy, Sell, Play, hero power, playing a unit by tapping it and a slot, Refresh, Freeze, tier up, End turn (a turn that doesn't end never reaches game over), Scout, Who?, Close, the pause menu, Settings and its Back, the guide's pages, the speed token, Watch again, Skip, Continue and Main menu. Not clicked: drags and drops, which go through the screen's own drop handlers; the dev panel, used only by the late checks; Leave game and Quit. The New game signal is caught so a game uses this run's seed and lobby, so the first-game guide and random seeds aren't run. Naive remains a tool-only yardstick; no bot strength is offered in the menu. To test the test, Scout, Who?, Continue, Main menu, hero power, Sell and Play were unhooked by hand: the run reported each. Three no-effect presses of one thing in a turn is reported as a loop.

Each turn also opens Scout, taps their unit, a small shop tile and sometimes buys from it, and checks the layout before and after its actions and with a card selected. It watches each fight at 4x. Once a game it visits every guide page, settings and pause, and replays one fight. Words on screen are checked for bot numbers, raw ids and tribes not in the lobby.

How the games are set up: `skilled` climbs on a schedule, buys the biggest units and sells the weakest; `cap3` and `cap4` do the same with at most that many units, which makes longer games; `random` buys at random. Most slots are Naive lobbies because this is the only level the scripted player outlasts: in trials it was out by turn 9 at Easy, Normal and Hard even when skilled, so those three levels are covered but shallow. That's a limit of the scripted player, not a measure of the bots.

What it isn't: a real phone or a real finger. Agents can only measure layouts at phone size. The UI sees mouse input, which Godot also uses for touch.

| Size | Seed | Bots | Player | Place | Turns | Ghost fights | Top tier | Problems | Errors | Exit | Seconds | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1920x1080 | 1000 | naive | skilled | 7 | 11 | 0 | 6 | 0 | 0 | 0 | 306 | ok |
| 1920x1080 | 1001 | naive | cap3 | 2 | 20 | 1 | 6 | 0 | 0 | 0 | 602 | ok |
| 1688x780 | 1100 | naive | skilled | 5 | 12 | 0 | 6 | 0 | 0 | 0 | 325 | ok |
| 1688x780 | 1101 | naive | cap3 | 7 | 12 | 0 | 6 | 0 | 0 | 0 | 234 | ok |

Late-game layout, forced to tier 6 with a full board and hand:

| Size | Seed | Problems | Errors | Exit | Verdict |
|---|---|---|---|---|---|
| 1920x1080 | 1000 | 0 | 0 | 0 | ok |
| 1688x780 | 1000 | 0 | 0 | 0 | ok |
