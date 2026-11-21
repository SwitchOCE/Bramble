# Design brief: one concept for Bramble's recruit and fight screens (you are one of six designers)

From the orchestrator of the branch `ideation/ui-ux` (an agent, not the owner). You make ONE concept, in the direction assigned at the end of your task message. Five other designers each make a different one; a council of three models compares all six, and the owner sees the best. Variety is the point: commit fully to your direction. Do not drift back toward today's screen or toward a generic game HUD.

## The owner's words (quoted, unchanged)

> "I specifically want the additional instructions of there to hold the theme and the stained glass and the hexagons, the warped hexagons, like the length and hexagons sacrosanct. Everything else is up for debate. It can suggest things and should suggest other things They're not to follow the other constraints"

("length" is read as "lead", a dictation slip. "There" is the owner's method on another game, which this run follows.)

On starting from the player: "we need to start the UI from first principles. What needs to be shown? What is most important".

On an earlier mock-up for another game that the owner rejected: "the icons no longer match the buttons ... Some are centralized and some are left-aligned ... Font sizing and stuff, there's stuff overlaying specific elements and overflowing out of areas of the screen."

## What is fixed, and what is open

Fixed. A concept that breaks one of these is out:
1. **The theme**: an idealised European woodland of animal folk, fairies and oozes.
2. **Lead and stained glass**, for the cards and the whole UI: every panel, button, counter and label reads as glass, lead, or the stone, wood or light around them (`docs/design/art-direction/README.md`).
3. **The hexagons**: units and cards are tall, stretched hexagons set in lead. Use today's card art and tier frames as the base of every card (`assets/units/`, `assets/glass/frames/tier1.webp` to `tier6.webp`), undistorted, at any size. What is shown on and around a card (stats, marks, a name set in lead, text) is open.

Open: everything else. The board as 4 in front and 3 behind, where the shop, board, hand and players sit, what a card shows on and around it, the buttons, the fonts, the wording, the tooltips, how screens follow each other, what is on screen at all. These are today's choices, not rules, on this branch. Some project skills and docs call layout rules "fixed" (the `design-critique` skill does, for the 4 and 3 board and the zones): on this branch they are not. The owner wants other things suggested.

Two duties come with that freedom:
- **Name what you reverse, after you have designed.** `docs/workstreams/ui-ideation/owner-decisions.md` lists the owner's earlier decisions about the screens, numbered. Do not read it before your first full draft: it describes today's game, and the owner's words are "They're not to follow the other constraints". When your draft stands, read it, and for each decision your concept reverses give its row number in your notes, so the owner can see what they would be undoing. Do not pull your concept back toward the list.
- **Label rule changes.** The game's rules stay as they are (the third table in that file: 7 slots, a hand of 7, selling from hand or board, and so on). If your concept would be better with a rules or flow change, you may show it, labelled in your notes as a suggestion for the owner. A different board shape is such a suggestion: say whether front and back rows still read.

## The game

Bramble is an auto-battler in the style of Hearthstone Battlegrounds. Eight players. Each turn has a recruit phase (buy units and spells from a shop with gold, place units on a board of 7 slots, keep others in a hand of up to 7, sell, refresh the shop, freeze it, upgrade the shop tier, end the turn) and then a fight against one opponent that plays out by itself. You lose health when you lose a fight; last one standing wins. Five tribes. Units have Attack, Health, a tier (1 to 6), keywords and rules text. Slots can hold Renown, a permanent bonus that belongs to the slot.

Read, in this order:
1. `/data/ui-ideation/skills/game-ui-design/SKILL.md`: the owner's method. Follow it: decisions first, then sort what is shown into glance, reach and archive, then lay it out. Its two rules apply: the main screen serves the hundredth game, not the first (no permanent teaching text), and the UI must be teachable (stable places, one plain name per thing, things a tutorial can point at).
2. `docs/workstreams/ui-ideation/map/map.md`: every decision a player makes on each screen, what they need to know for it, and what is on screen today.
3. `docs/workstreams/ui-ideation/map/state.md`: **the exact game state you draw.** Every designer draws the same moment.
4. Today's game: `/data/ui-ideation/baseline/shots/recruit-mid.png`, `recruit-t1.png`, `recruit-mid-leaderboard.png`, `recruit-t1-card-detail.png`, `fight-mid-t9-start.png`, `fight-mid-t9-attack.png`, `fight-mid-t9-result-defeat.png` (the rest of that folder if you need it).
5. Games players love: `/data/ui-ideation/gallery/sheet-1.jpg`, `sheet-2.jpg`, `index.md`, and the full-size images in `images/`. Study how the best of them lay out a shop, a board and a fight, and how the material-led ones keep their material on small controls and text. Your concept will be judged beside them.

Do not open any other folder under `docs/workstreams/ui-ideation/concepts/` or `/data/ui-ideation/concepts/`: you must not see another designer's work.

## The two things your concept is judged on

1. **The look: it belongs among games players love.** The owner: "What is most important to me is the game's look and feel". The last test of this run is the owner's: the council sees your screens mixed into the gallery and answers whether "our design feels like it belongs here. It's one of the better ones here, or it's at least the average kind of level". So the glass, the lead, the light and the woodland must carry the whole screen, down to the smallest counter, and the screen must look made, not assembled.
2. **Reading the game at a glance: "I can read the shop, my board and who I'm up against mid-game without opening each card."** Found in the live game: a card face shows art, Attack, Health and small marks, so with five offers and seven units a mid-game shop costs up to 12 hovers, and again after each refresh; the cards fill about 650 px of a 1400 px pane; the other seven players are behind an unlabelled click on your own portrait. The owner chose the minimal card face and found drawn keyword looks "too busy", so there are two honest routes: put more on the card, or keep the face minimal and solve reading another way. Your assigned direction says which way to lean. Either way it must not be busy.

You also draw the fight and its end, including how the player learns why they lost (today a lost fight ends with one number). The council comments on it; it is not scored on its own.

Besides these: hold the three fixed things, and have no visual defects. Nothing else is scored, so do not spend your effort on settings menus, the start screen or the card browser. Other things you think the game should do differently are welcome: the owner said concepts "should suggest other things". Put them in your notes.

## Deliverables

In your own folder, `docs/workstreams/ui-ideation/concepts/<your letter>/` (write nowhere else in the repository, and do not commit):

1. **`concept.html`**: one page that renders at exactly 1920x1080 and shows four views by query string:
   - `?view=mid`: recruit at turn 9, exactly the state in `state.md`, before any action. The returning player's view: no teaching text.
   - `?view=first`: recruit at turn 1 (the state in `recruit-t1.png`), as a first-session view with at most one tutorial cue, drawn so it can be removed without anything moving.
   - `?view=fight`: the turn-9 fight from `state.md` near its start, both boards full as listed there.
   - `?view=after`: the end of that fight (you lose all units, take 13, and are out in 7th), showing how the player learns why.
   An extra view is welcome if your concept needs one (a card being read, the lobby opened): `?view=extra1`, `?view=extra2`.
   Reach the game's files by relative path from your folder (`../../../../assets/...`); do not copy art into your folder. Use the fonts in `assets/glass/fonts/`. New chrome (panels, lead lines, glass panes, buttons, backdrops) is drawn in SVG or CSS; stained glass is flat panes and lead lines, which suits both. More glass pieces from the 15 Nov mock-up are in `/data/bramble-art/stained-glass/glass/assets/` (`ui/`: stone, quarry field, roundels, transom pieces; `woods/`: woodland ground, roots, ferns, a fallen log; lead line SVGs): copy the ones you use into your folder. Keep your folder under 3 MB.
   **One new background picture, only if your direction needs a scene** (a workshop, a forest). You cannot make it yourself. As early as you can, write `art-request.md` in your folder: one picture, its size in pixels, what it shows, where the screen's cards and controls will sit over it (so those areas stay calm), and the light. It will be made in the game's stained-glass style and appear at `/data/ui-ideation/concepts/<your letter>/art/background.png`, usually within 30 to 40 minutes. Build with a stand-in you draw yourself meanwhile. If the picture is there when you reach your quality pass, fit it and copy it into your folder; if not, finish with the stand-in, say so, and you will be sent back to fit it.
2. **Renders** of each view, as PNG at 1920x1080, in `/data/ui-ideation/concepts/<your letter>/` (`mid.png`, `first.png`, `fight.png`, `after.png`, any extras). Render with the headless Chromium on this machine:
   ```bash
   CH=$(ls -d ~/.cache/ms-playwright/chromium_headless_shell-*/chrome-headless-shell-linux64/chrome-headless-shell | sort -V | tail -1)
   "$CH" --headless --no-sandbox --hide-scrollbars --allow-file-access-from-files --window-size=1920,1080 --virtual-time-budget=4000 \
     --screenshot=/data/ui-ideation/concepts/<letter>/mid.png "file://$PWD/docs/workstreams/ui-ideation/concepts/<letter>/concept.html?view=mid"
   ```
   Open every render and look at it. A render you have not looked at is not done.
3. **`notes.md`**, under 500 words:
   - the concept in two sentences;
   - how the player moves through recruit, fight and its end;
   - the glance-tier count for recruit and for the fight, counted the way `map/map.md` counts today's 23 and 9;
   - how it meets each of the two things it is judged on;
   - each owner decision it reverses, by row number, one line each;
   - every other thing it suggests, including any rules or flow change, each labelled "suggestion for the owner";
   - which games in the gallery it learns from;
   - its weakest point;
   - "Not judged": motion, timing, hover feel and sound cannot be judged from stills. Say so; never claim them.

## Visual quality pass (required before you finish)

Open each render at full size and fix every one of these before you report:
- alignment is consistent inside each group (no mix of centred and left-aligned siblings); zones share edges and centre lines;
- every icon matches its action, or is left out;
- text a player acts on (names, prices, stats, button labels) is at least 18 px; no text is under 14 px;
- text contrast is at least 4.5:1 against the worst background behind it; nothing is told by colour alone;
- no text or element overlaps another by accident; nothing overflows its panel or is clipped by the screen edge;
- spacing is consistent; gaps inside a group are smaller than gaps between groups;
- no large dead area without a purpose;
- one accent for "press this next", and only one;
- every card is a tall hexagon in its real frame, undistorted (same width-to-height ratio as the frame file);
- watch for CSS class names colliding between components, and check each view separately.
List in `notes.md` what you checked and anything you could not fix.

## Rules

- Change nothing outside your two folders. No game code, no other docs, no commits.
- Set `TMPDIR=/data/ui-ideation/tmp/<your letter>` for scratch. `/tmp` is memory on this machine.
- Never run `rm -rf`, or any other delete, anywhere: on some of the models doing this work a delete stops and waits for the owner's approval, and the run stalls for hours. Instead list every file and folder you made that should be removed afterwards, each with its path and size; the orchestrator removes them.
- Never read token or `auth.json` files. If a permission check refuses something, do not work around it: report it.
- Do the work yourself; start no subagents.
- End your report with a **Disk** section: every folder you created or wrote into outside your concept folder, each with its `du -sh` size, whether it is still needed, and which the orchestrator can delete; and `df -h /data /` at the start and at the end.

## Report

Reply with: your concept in two sentences, the paths of your renders, the owner decisions you reverse (row numbers), anything you could not fix, and the Disk section.
