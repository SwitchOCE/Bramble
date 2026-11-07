# Scripted full UI run

Made by `tests/ui/full_ui_run.sh 10 1000` on dc7d005 (ideation/tribes2), 2026-11-07.

**0 failed out of 20 games and 2 late-game checks. Depth bar: met.**

| Depth | Needed | Got |
|---|---|---|
| Games reaching turn 12 | 10 | 15 |
| Games reaching turn 15 | 3 | 13 |
| Games won | 1 | 11 |
| Ghost fights | 3 | 7 |
| Games reaching tier 5 in play | 2 | 20 |
| Games reaching tier 6 in play | 2 | 17 |

Smallest text on screen: phone size 31 canvas units (the minimum is 31); desktop size 22, where tile rules and lobby names may go down to 22.

Clicked for real, with each press checked to change the game or tell the player why not: New game, a difficulty leaf, Buy, Sell, Play, hero power, playing a unit by tapping it and a slot, Refresh, Freeze, tier up, End turn (a turn that doesn't end never reaches game over), Scout, Who?, Close, the pause menu, Settings and its Back, the guide's pages, the speed token, Watch again, Skip, Continue and Main menu. Not clicked: drags and drops, which go through the screen's own drop handlers; the dev panel, used only by the late checks; Leave game and Quit. The difficulty leaf's signal is caught so a game uses this run's seed and lobby, so the first-game guide and random seeds aren't run. A Naive lobby starts from the Easy leaf, since the menu has no Naive. To test the test, Scout, Who?, Continue, Main menu, hero power, Sell and Play were unhooked by hand: the run reported each. Three no-effect presses of one thing in a turn is reported as a loop.

Each turn also opens Scout, taps their unit, a small shop tile and sometimes buys from it, and checks the layout before and after its actions and with a card selected. It watches each fight at 4x. Once a game it visits every guide page, settings and pause, and replays one fight. Words on screen are checked for bot numbers, raw ids and tribes not in the lobby.

How the games are set up: `skilled` climbs on a schedule, buys the biggest units and sells the weakest; `cap3` and `cap4` do the same with at most that many units, which makes longer games; `random` buys at random. Most slots are Naive lobbies because this is the only level the scripted player outlasts: in trials it was out by turn 9 at Easy, Normal and Hard even when skilled, so those three levels are covered but shallow. That's a limit of the scripted player, not a measure of the bots.

What it isn't: a real phone or a real finger. Agents can only measure layouts at phone size. The UI sees mouse input, which Godot also uses for touch.

| Size | Seed | Bots | Player | Place | Turns | Ghost fights | Top tier | Problems | Errors | Exit | Seconds | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1920x1080 | 1000 | naive | skilled | 1 | 17 | 0 | 6 | 0 | 0 | 0 | 235 | ok |
| 1920x1080 | 1001 | naive | cap3 | 1 | 17 | 1 | 6 | 0 | 0 | 0 | 212 | ok |
| 1920x1080 | 1002 | easy | skilled | 4 | 15 | 0 | 6 | 0 | 0 | 0 | 238 | ok |
| 1920x1080 | 1003 | naive | cap4 | 1 | 16 | 1 | 6 | 0 | 0 | 0 | 201 | ok |
| 1920x1080 | 1004 | normal | skilled | 8 | 11 | 0 | 6 | 0 | 0 | 0 | 146 | ok |
| 1920x1080 | 1005 | naive | skilled | 1 | 19 | 2 | 6 | 0 | 0 | 0 | 251 | ok |
| 1920x1080 | 1006 | naive | cap4 | 1 | 15 | 1 | 6 | 0 | 0 | 0 | 182 | ok |
| 1920x1080 | 1007 | hard | skilled | 8 | 10 | 0 | 6 | 0 | 0 | 0 | 115 | ok |
| 1920x1080 | 1008 | naive | cap3 | 1 | 15 | 0 | 6 | 0 | 0 | 0 | 178 | ok |
| 1920x1080 | 1009 | naive | random | 6 | 15 | 0 | 5 | 0 | 0 | 0 | 176 | ok |
| 1688x780 | 1100 | naive | skilled | 1 | 16 | 1 | 6 | 0 | 0 | 0 | 176 | ok |
| 1688x780 | 1101 | naive | cap3 | 1 | 16 | 1 | 6 | 0 | 0 | 0 | 156 | ok |
| 1688x780 | 1102 | easy | skilled | 8 | 10 | 0 | 6 | 0 | 0 | 0 | 109 | ok |
| 1688x780 | 1103 | naive | cap4 | 1 | 15 | 0 | 6 | 0 | 0 | 0 | 181 | ok |
| 1688x780 | 1104 | normal | skilled | 8 | 8 | 0 | 5 | 0 | 0 | 0 | 77 | ok |
| 1688x780 | 1105 | naive | skilled | 1 | 15 | 0 | 6 | 0 | 0 | 0 | 144 | ok |
| 1688x780 | 1106 | naive | cap4 | 1 | 15 | 0 | 6 | 0 | 0 | 0 | 143 | ok |
| 1688x780 | 1107 | hard | skilled | 8 | 9 | 0 | 5 | 0 | 0 | 0 | 86 | ok |
| 1688x780 | 1108 | naive | cap3 | 5 | 14 | 0 | 6 | 0 | 0 | 0 | 120 | ok |
| 1688x780 | 1109 | naive | random | 6 | 14 | 0 | 6 | 0 | 0 | 0 | 146 | ok |

Late-game layout, forced to tier 6 with a full board and hand:

| Size | Seed | Problems | Errors | Exit | Verdict |
|---|---|---|---|---|---|
| 1920x1080 | 1000 | 0 | 0 | 0 | ok |
| 1688x780 | 1000 | 0 | 0 | 0 | ok |
