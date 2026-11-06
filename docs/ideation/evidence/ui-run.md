# Scripted full UI run

Made by `tests/ui/full_ui_run.sh 10 1000` on 1d01cd2 (ideation/polish), 2026-11-06.

**0 failed out of 20 games and 2 late-game checks.** Smallest text on screen: 31 canvas units (the phone minimum is 31).

What a game does: starts from the menu state, picks a hero, plays every turn to game over with a seeded scripted player. Buttons and tiles are real mouse clicks, and a click that doesn't reach its target is a problem. Drags go through the screen's own drop handlers. Each turn it opens Scout, taps their unit and a small shop tile, checks the layout before and after its actions and with a card selected, and watches the fight at 4x. Once a game it visits every guide page, settings and pause. Words on screen are checked for bot numbers, raw ids and tribes not in the lobby.

What it isn't: a real phone or a real finger. Agents can only measure layouts at phone size. The UI sees mouse input, which Godot also uses for touch.

| Size | Seed | Bots | Place | Turns | Problems | Errors | Exit | Seconds | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| 1920x1080 | 1000 | naive | 6 | 9 | 0 | 0 | 0 | 112 | ok |
| 1920x1080 | 1001 | easy | 8 | 7 | 0 | 0 | 0 | 64 | ok |
| 1920x1080 | 1002 | normal | 8 | 8 | 0 | 0 | 0 | 95 | ok |
| 1920x1080 | 1003 | hard | 8 | 7 | 0 | 0 | 0 | 72 | ok |
| 1920x1080 | 1004 | naive | 8 | 7 | 0 | 0 | 0 | 62 | ok |
| 1920x1080 | 1005 | easy | 8 | 8 | 0 | 0 | 0 | 101 | ok |
| 1920x1080 | 1006 | normal | 8 | 6 | 0 | 0 | 0 | 48 | ok |
| 1920x1080 | 1007 | hard | 8 | 7 | 0 | 0 | 0 | 66 | ok |
| 1920x1080 | 1008 | naive | 7 | 8 | 0 | 0 | 0 | 82 | ok |
| 1920x1080 | 1009 | easy | 8 | 6 | 0 | 0 | 0 | 56 | ok |
| 1688x780 | 1000 | naive | 6 | 9 | 0 | 0 | 0 | 86 | ok |
| 1688x780 | 1001 | easy | 8 | 7 | 0 | 0 | 0 | 48 | ok |
| 1688x780 | 1002 | normal | 8 | 8 | 0 | 0 | 0 | 73 | ok |
| 1688x780 | 1003 | hard | 8 | 7 | 0 | 0 | 0 | 57 | ok |
| 1688x780 | 1004 | naive | 8 | 7 | 0 | 0 | 0 | 45 | ok |
| 1688x780 | 1005 | easy | 8 | 8 | 0 | 0 | 0 | 80 | ok |
| 1688x780 | 1006 | normal | 8 | 6 | 0 | 0 | 0 | 35 | ok |
| 1688x780 | 1007 | hard | 8 | 7 | 0 | 0 | 0 | 49 | ok |
| 1688x780 | 1008 | naive | 7 | 8 | 0 | 0 | 0 | 64 | ok |
| 1688x780 | 1009 | easy | 8 | 6 | 0 | 0 | 0 | 41 | ok |

Late-game layout, forced to tier 6 with a full board and hand:

| Size | Seed | Problems | Exit | Verdict |
|---|---|---|---|---|
| 1920x1080 | 1000 | 0 | 0 | ok |
| 1688x780 | 1000 | 0 | 0 | ok |
