# L1 polished: the buy screen, taken to the next level

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). For the art director of look L1. The owner has looked at your real-size screens, asked for changes, some of which I made, and now wants one fully polished buy screen. You design and build in code; a separate worker paints any pictures you order.

## What has changed since you last built

- The owner rejected the smaller hand. I changed `looks/L1/screen.html`: hand cards are full size and cut off by the bottom of the screen (`hand=half` or `hand=peek`), and `hover=N` raises one. See `/data/ui-ideation/looks/L1/real/hand-half-hover-c.png`.
- The owner asked to see the shop with the units centred, spells stacked at the right and the buttons at the left. I added `shop=stack`: `/data/ui-ideation/looks/L1/real/shop-stack-c.png`. The owner's reaction to that picture is below.
- Shape C (0.69, 173 x 250) is accepted: "I don't mind the aspect ratio change."

## The owner's words (24 Nov 2026)

*[Transcribed from dictation: filler removed, punctuation added, clear dictation errors fixed. My guesses are in brackets.]*

On the hand:

> "For me it's a non-negotiable that the cards are the same size in the hand, because you need to be able to drag them around. I'd rather have the hand trim off the bottom of the screen and the bottom half of the card not be visible. And hovering over the card pops it out vertically. We can just downsize things, use more negative space elsewhere if need be."

On the shop, first:

> "How about we stack the two spells, make the spells smaller, stack them vertically as if they're coming out of the right-hand edge of the shop. And how about we move the shop controls and the gold to the equal space at the top left of the shop. So the shop feels balanced and the cards are centralized."

Then, after seeing `shop-stack-c.png`:

> "How about we put one spell either side then? That would at least keep the cards centred. I think that's better. I just feel like the controls for at least re-rolling and freezing and [tiering] up the shop, maybe not the player's gold, should go up there. Remember, you've forgotten a few things here: the player still needs the ability to access the card library, their compost on the left, maybe some other things. I'm not sure. I think for some reason I want the buttons for the shop on the right-hand side of the shop rather than the left. So I'd like to swap the scoreboard to the left-hand side, maybe. I don't know how you feel about that."

> "For some reason, one card on the board is a different size and different positioning. They're not actually correct for some reason. And there's some weird sort of shadowing effect underneath the cards. You've made these hexagon shadows underneath them. I don't quite understand what those are supposed to be. I think the edits to the image have messed up some of the assets."

> "Let's say that this is where we want to go. Let's try and take this to a next level. Take a fully polished version, I guess, with some of those changes."

Standing: "Don't be too stringent. We're trying to do good design, right? That's the number one priority." And on 22 Nov, of a screen calmed by dimming the art: it "sucked all the joy out of the scene"; no dimming filters over art.

## What the owner's reaction means

- **The raised card.** The board card drawn lifted and 4% larger (your "pointed-at" card) read as a mistake. Board cards at rest are all the same size and sit exactly on their slots. If you show a card being pointed at, draw the pointer, and do not scale it.
- **The shadows and thrown colour** (the depth layer; it was my suggestion) did not read: the owner saw odd hexagon shapes under the cards. The owner still wants "a bit more of a 3D feel ... almost like two-and-a-half-D". Find depth that reads at once without explanation.
- **Things were forgotten.** The screen must hold everything the game needs; the list is below.

## What the buy screen must hold

From the build and the earlier layout the owner liked (`/data/ui-ideation/concepts/A/p2r5/mid.png`; use it for content, not look) and `docs/workstreams/ui-ideation/owner-decisions.md`:

- The shop: five units and two spells, each with its price; the unit cards centred on the screen; one spell either side.
- The shop's buttons, at the right-hand side of the shop: tier up (with its cost, which must read clearly, and the shop's tier; a discount shows as a discount), refresh (with its cost, and a subtle count of refreshes left at this price), freeze.
- Gold. Next turn's gold as a small "+X".
- Your board: seven slots, four over three, centred. Your hand: up to seven, full size.
- The scoreboard of eight players: portrait and health, you marked, your next opponent marked, a knocked-out player greyed. The owner would "maybe" move it to the left.
- Your own hero and health. Your tribe counters (the build shows two as plates by the portrait: Compost, and Tide); each opens its panel when clicked.
- The card library (a browser of all units and spells, opens during a game) and a settings cog.
- The turn number. End turn.
- A unit you cannot afford is shown as such without a dimming filter over its art if you can find another way; otherwise leave that state out of the still.

The owner wants a clean screen that assumes a player who knows the rules: numerals and clear icons, very few words, details on hover. Where an icon alone would be a puzzle (Compost may be one), a short word is fine.

## The orchestrator's view (advice, for you to test or overturn)

- **Left is what you watch, right is what you act on.** Scoreboard on the left, as in Battlegrounds, with your counters and the library at its foot. On the right, top to bottom: the shop's three buttons level with the shop, gold just below them (the biggest thing on that side), End turn at the bottom. I agree with the owner's instinct here.
- **The side windows may be the wrong container.** With one spell either side the shop row is about 1430 px wide, so the buttons cannot sit on the wall between the side windows as they are. Let the shop wall run wider and the buttons live at its right-hand end, or redesign the side columns. The unit cards and the board stay centred on the screen.
- **Depth as thickness.** The table is seen from above and the cards lie on it. I would give each card a visible thickness (a slab of leaded glass a few pixels deep, its lower edge showing) and a tight soft shadow, and give a carried or pointed-at card a larger, softer, offset shadow. The niches recessed into the wall and the table edge do the rest. No shapes on the table that a player has to interpret.
- **Polish.** One material language: the buttons, plates, coins, sills and counters should look made by the same hands as the cards. Order painted pieces for what code cannot draw well. Check every gap is the one gap.

## The cards

A second art director is ordering the eighteen cards on this screen repainted to the proposed colour guide (`docs/workstreams/ui-ideation/palette/guide.md`) for the wider window, about 2:3. They will arrive as `/data/bramble-art/uiid-palette/c69/<tribe>-<name>.png` (for instance `mouse-fencing-master.png`), full-bleed pictures with no frame. Add a switch `art=guide|today`; with `guide`, use a repainted picture where the file exists and today's art where it does not. The owner has not approved the guide, so render both.

## What to do

**Stage 1 (about 20 minutes).** Write `docs/workstreams/ui-ideation/looks/L1/polish.md`, 300 words at most: the layout (where each thing in the list goes, and why), your depth idea, and what you will order. If you need painted pieces, write `docs/workstreams/ui-ideation/looks/L1/prompts-4.txt` (up to 10 items, in the format of your earlier orders; pieces and plain surfaces, not finished screens). Reply at once; the orchestrator runs the order and messages you.

**Stage 2.** Build it in `screen.html` behind a switch (`view=polish`, or as you see fit; keep the existing views working). Render at 1920x1080 into `/data/ui-ideation/looks/L1/polish/`: the buy screen with repainted art and with today's art; the same with one hand card pointed at; and one with the scoreboard on the right, if you think the owner should compare. Look at every render at full size and fix what you see before you report. Add a short "Polished" section to `look.md`.

## Rules

Write only `docs/workstreams/ui-ideation/looks/L1/`, `/data/ui-ideation/looks/L1/` and your scratch folder (`TMPDIR=/data/ui-ideation/tmp/look-L1`; create it). No commits. Never run a delete command. Never read token or `auth.json` files. Start no subagents. Make no pictures with an image model yourself. From stills, motion, hover feel and glow timing are "not judged".

## Report

Each stage, in under 200 words: what you decided or built, what falls short, what you need next, and a **Disk** line (what you wrote outside the repo, with sizes).
