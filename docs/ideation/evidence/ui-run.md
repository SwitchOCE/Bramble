# Scripted full UI run

Made by `tests/ui/full_ui_run.sh 2 1000` on ef27d6f (ideation/main), 2026-11-07.

**1 failed out of 4 games and 2 late-game checks. Depth bar: not judged: under 10 games a size.**

| Depth | Needed | Got |
|---|---|---|
| Games reaching turn 12 | 10 | 4 |
| Games reaching turn 15 | 3 | 4 |
| Games won | 1 | 4 |
| Ghost fights | 3 | 3 |
| Games reaching tier 5 in play | 2 | 4 |
| Games reaching tier 6 in play | 2 | 4 |

Smallest text on screen: phone size 31 canvas units (the minimum is 31); desktop size 22, where tile rules and lobby names may go down to 22.

Clicked for real, with each press checked to change the game or tell the player why not: New game, a difficulty leaf, Buy, Sell, Play, hero power, playing a unit by tapping it and a slot, Refresh, Freeze, tier up, End turn (a turn that doesn't end never reaches game over), Scout, Who?, Close, the pause menu, Settings and its Back, the guide's pages, the speed token, Watch again, Skip, Continue and Main menu. Not clicked: drags and drops, which go through the screen's own drop handlers; the dev panel, used only by the late checks; Leave game and Quit. The difficulty leaf's signal is caught so a game uses this run's seed and lobby, so the first-game guide and random seeds aren't run. A Naive lobby starts from the Easy leaf, since the menu has no Naive. To test the test, Scout, Who?, Continue, Main menu, hero power, Sell and Play were unhooked by hand: the run reported each. Three no-effect presses of one thing in a turn is reported as a loop.

Each turn also opens Scout, taps their unit, a small shop tile and sometimes buys from it, and checks the layout before and after its actions and with a card selected. It watches each fight at 4x. Once a game it visits every guide page, settings and pause, and replays one fight. Words on screen are checked for bot numbers, raw ids and tribes not in the lobby.

How the games are set up: `skilled` climbs on a schedule, buys the biggest units and sells the weakest; `cap3` and `cap4` do the same with at most that many units, which makes longer games; `random` buys at random. Most slots are Naive lobbies because this is the only level the scripted player outlasts: in trials it was out by turn 9 at Easy, Normal and Hard even when skilled, so those three levels are covered but shallow. That's a limit of the scripted player, not a measure of the bots.

What it isn't: a real phone or a real finger. Agents can only measure layouts at phone size. The UI sees mouse input, which Godot also uses for touch.

| Size | Seed | Bots | Player | Place | Turns | Ghost fights | Top tier | Problems | Errors | Exit | Seconds | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1920x1080 | 1000 | naive | skilled | 1 | 16 | 0 | 6 | 0 | 1 | 0 | 248 | FAILED |
| 1920x1080 | 1001 | naive | cap3 | 1 | 17 | 1 | 6 | 0 | 0 | 0 | 244 | ok |
| 1688x780 | 1100 | naive | skilled | 1 | 18 | 1 | 6 | 0 | 0 | 0 | 212 | ok |
| 1688x780 | 1101 | naive | cap3 | 1 | 17 | 1 | 6 | 0 | 0 | 0 | 198 | ok |

Late-game layout, forced to tier 6 with a full board and hand:

| Size | Seed | Problems | Errors | Exit | Verdict |
|---|---|---|---|---|---|
| 1920x1080 | 1000 | 0 | 0 | 0 | ok |
| 1688x780 | 1000 | 0 | 0 | 0 | ok |

Build 4 timing: normal Godot engine clock, LP_NUM_THREADS=2, CPUs 2,3,4, hard `timeout -k 5 1800 tests/ui/full_ui_run.sh 2`. No minimum was lowered. The final suite flagged one cached-shader recompilation warning in desktop seed 1000; its layout and actions passed. A separate full retry of that game passed every original log and layout check (build/ui-retry4/1920x1080_1000.log). The original suite report and FAILED row are retained above; the other three games and both late checks passed. The initial run on 70366f7 found undersized Scout shop targets; e80ee58 wraps offers and scrolls overflow. Its rerun passed both desktop games and found decorative lane-guide examples intercepting input on phone; ef27d6f makes them ignore input consistently with the other guide illustrations. The complete rerun above checks both fixes. No depth-bar UI run or full bench on this commit, no real device test, sounds not checked by ear.
