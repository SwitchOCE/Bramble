# How should the buy screen show counters?

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). You are one of three designers given this same brief; you work alone and do not see the others. This is a mock-up in HTML for the owner to look at, not game code.

## The game and the screen

Bramble is an auto-battler in the style of Hearthstone Battlegrounds: each turn you buy units in a shop, then your board fights another player's. Its look is lead and stained glass. The buy screen so far: `/data/ui-ideation/looks/L1/c/c-zones.png` (drawn by `docs/workstreams/ui-ideation/looks/L1/screen.html?view=polish&room=zones`; painted pieces in `/data/ui-ideation/looks/L1/pieces/`). The right-hand column, 244 px wide of a 1920 x 1080 screen, holds what the player acts on: gold at the top, health under it, then four small plates (a leaf 3, a wave 2, a flame 7, an hourglass 1), then card library and settings, then End turn. Those four plates are the counters. They are a placeholder nobody has designed.

What a counter is: a number some mechanic keeps for the player across turns. Today's build has two (`src/screens/glass_counters.gd`): Compost, a heap of units that have died, which opens a panel of its contents when clicked; and Tide, a level that rises. Other tribes and other mechanics will bring their own, and which mechanics are in a game varies from lobby to lobby.

## The owner's words

*[Transcribed from dictation: filler removed, punctuation added, clear dictation errors fixed.]*

24 Nov 2026:

> "Remember, Tide is not always going to be a mechanic. We just need some way of handling any number of other mechanics, like whatever your most important counter is determined to be. Other tribes will also have counters at some point. There may be other counter mechanics. You just need a way of being able to view all your auras, so it shouldn't be like a Tide button. It's more of a generalized thing. Same for Compost: it's a mechanic that may only be in some lobbies. So we just need ways of having those buttons be flexible, for anything, and having maybe up to four of them or something. I'm not sure. I don't know exactly how many would be required, but we need to have plans."

25 Nov 2026:

> "In terms of all the Tide and stuff markers, they can just be a guess."

> "The text on how many things are left is not the best way of displaying it. So now that we're able to isolate individual areas and think about specific elements of the UI, I want the agents to focus heavily on just the counter display, like how we should display counters."

("How many things are left" is the small "7 left" by the refresh button in the shop's right wing: how many refreshes remain at the current price.)

Standing rules from the owner: the main screen assumes a player who knows the rules, so numerals and clear icons, very few words, and details only on hover; no dimming filters over art; a cost is a coin overlapping the lower right of its round button; "Don't be too stringent. We're trying to do good design, right? That's the number one priority."

## The problem

Design how counters are shown on the buy screen, so that it works for one counter or six, for mechanics that do not exist yet, and for a player glancing at it mid-turn. Things a good answer has to cope with:

- none, one, two, four, and more than four counters in a game;
- a number of one digit and of three;
- a counter that is a heap with contents (Compost) and one that is only a level (Tide);
- a counter that has just changed;
- some way to reach "all your auras": everything now affecting the player, of which the counters shown are only the most important;
- the count that belongs to a button (the "7 left" on refresh), which should not be small text.

Where the counters live is yours to argue. The column's free space is roughly x 1692 to 1904, y 400 to 780, but propose another place if it is better. Look at how other games in the genre do it if that helps; do not copy any game's art.

## What to make

1. A self-contained page `docs/workstreams/ui-ideation/looks/L1/counters/<your name>.html` (your name is given in the message that sent you here) showing **two or three clearly different designs** at real size, each on the column's own ground (`/data/ui-ideation/looks/L1/pieces/l1z-quarry-moss.jpg` at half brightness), each in the states listed above, with one line under each state saying what it shows. Mark the design you recommend. Use the painted pieces where they fit (`l1p-plate.png`, `l1p-roundel-slate.png`, `l1p-coin.png`, `l1z-board.png`) or draw your own in code; name any piece you would want painted.
2. A picture of the page: `/data/ui-ideation/looks/L1/counters/<your name>.png`. Render it with
   `S=$(ls ~/.cache/ms-playwright/chromium_headless_shell-1254/*/chrome-headless-shell); timeout 60 $S --no-sandbox --hide-scrollbars --allow-file-access-from-files --window-size=1920,1400 --virtual-time-budget=5000 --screenshot=<out> "file://<page>"`
   Look at your picture at full size and fix what you see before you report. Check that every numeral can be read at this size.
3. Notes `docs/workstreams/ui-ideation/looks/L1/counters/<your name>.md`, 200 words at most: each design in two lines, your pick and why, and what you could not solve.

## Rules

Write only your three files and your scratch folder (`TMPDIR=/data/ui-ideation/tmp/counters-<your name>`; create it). No commits and no other git commands that change anything. Never run a delete command. Never read token or `auth.json` files. Start no subagents. Make no pictures with an image model. From a still picture, motion and hover feel cannot be judged: say "not judged" rather than claiming them.

## Report

Under 150 words: your designs, your pick, what falls short, and a **Disk** line (what you wrote outside the repo, with sizes).
