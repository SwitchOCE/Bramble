# Brief: map today's game (screens, decisions, baseline critique)

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). Everything outside quotation marks is my proposal: where you see a better way to reach the same result, take it and say what you changed.

## Why

The owner wants agents to propose other UIs for Bramble, judged by a council. Designers and the council need one true picture of today's game to start from and to beat: what every screen looks like mid-game, what the player decides on each, and what is wrong with it today. That picture has to come from the running game, not from docs or memory.

## The owner's words

> "I want you to have a look at the work that's being done in the PDoom repo in terms of on this PC, in terms of using the council skill for design stuff. And I'd like to start a new ideation branch where agents focus on improving our UI and UX in the same method and process that I've gone through there. Can you have a crack at that?"

> "I specifically want the additional instructions of there to hold the theme and the stained glass and the hexagons, the warped hexagons, like the length and hexagons sacrosanct. Everything else is up for debate. It can suggest things and should suggest other things They're not to follow the other constraints"

From the earlier work this follows: "we need to start the UI from first principles. What needs to be shown? What is most important".

## Read first

- `/data/ui-ideation/skills/game-ui-design/SKILL.md`: the method. Follow it. Its two owner rules apply: the main screen serves the hundredth game, and the UI must be teachable.
- `tools/look/README.md`: how to run and photograph the game. `docs/AGENT-BLIND-SPOTS.md`: what you cannot see.
- `docs/workstreams/ui-ideation/README.md`: what is fixed and what is open on this branch.

You are in the branch's own checkout (`ideation/ui-ux`, at `dev`'s head). Other sessions are working on `dev` in other worktrees: do not touch their worktrees or branches. Do not change game code, tests or assets here; this task only reads and photographs the game.

## What to produce

1. **Screenshots of every screen a player meets**, 1920x1080, in `/data/ui-ideation/baseline/shots/`, named by screen and state (`recruit-mid.png`, `fight-mid.png`, ...). At least:
   - the start of a game and whatever comes before it (title, menus, any choice);
   - recruit on turn 1, and recruit mid-game with a full or nearly full board, units in hand and a full shop: this is the main one;
   - recruit with each thing a player opens or triggers: a unit tooltip or inspect view, a keyword tip, the leaderboard or opponent view, a duplicate mark and a triple with its reward, a spell, a locked shop, not enough gold, a full board or hand, the card browser, the compost screen, pause;
   - the fight: its start, mid-fight, a big moment, its end and result;
   - the end of a game.
   If a state is hard to reach by playing, look for a fixture, a test scene or a debug route before giving up, and say which you used. List any screen you could not reach, and why.
2. **`docs/workstreams/ui-ideation/map/state.md`: the mid-game state, written down exactly**, so six designers can draw the same moment: turn, gold, shop tier and its upgrade cost, health, every unit on the board with its slot, name, tribe, tier, Attack, Health, keywords and rules text, the hand, the shop's offers and prices, the opponents and their health, and anything else on screen. Add the fight that follows it (both boards). Also list the files a designer may reuse: card art, frames, fonts and layout numbers (`assets/units/`, `assets/glass/`, `docs/ideation-track-2/mockups/`), with paths.
3. **`docs/workstreams/ui-ideation/map/map.md`: the map.** For each phase (recruit, fight, and each other screen): the decisions the player makes, in player words, taken from the live game and the code; for each decision, what the player must know to make it; every element on screen sorted into the skill's tiers (glance, reach, archive, hidden by design, not yet); and the glance-tier count. Say how a player moves between screens.
4. **`docs/workstreams/ui-ideation/map/critique.md`: a critique of today's recruit and fight screens**, in the skill's output format, judged mid-game. This is the baseline the new concepts must beat, so be specific and name what works as well as what does not. Judge today's layout on its merits: on this branch it is one option among others, not a rule. Then one short section: the one or two player outcomes you think a redesign should target first, and why.

From stills, write "not judged" for motion, timing, hover feel and sound. Never pass them.

## Rules

- Long commands (imports, anything over a minute or so) run in the background with a time limit. At most four `look` games run on the machine at once, shared with other sessions: stop yours when done.
- Screenshots go to `/data/ui-ideation/baseline/`, never into Git. The three `.md` files go in the checkout under `docs/workstreams/ui-ideation/map/`. Do not commit: another worker writes in this checkout at the same time, and I commit both.
- Set `TMPDIR=/data/ui-ideation/tmp` for scratch. `/tmp` is memory on this machine.
- Never run `rm -rf`, or any other delete, outside this checkout. Instead list what should be removed.
- Never read token or `auth.json` files. If a permission check refuses something, do not work around it: report it.
- End your report with a **Disk** section: every folder you created or wrote into outside the checkout, each with its `du -sh` size, whether it is still needed, and which ones I can delete; and `df -h /data /` at the start and at the end.

## Report

A short summary: the paths, the screens you could not reach, the glance-tier counts, the top three findings, and the Disk section.
