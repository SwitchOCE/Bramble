# The mid-game state every concept draws

The moment is **turn 9, recruit, before any action**, from a real game of today's build (`ideation/ui-ux` at `98e8ba68`, the same game code as `dev` at `007e2789`), seed 7, at 1920 x 1080. Every number below was read from the game's own record of that game, replayed (not from memory), and checked against the screenshot.

Picture: `/data/ui-ideation/baseline/shots/recruit-mid.png` (with the leaderboard open: `recruit-mid-leaderboard.png`).

**How it was reached.** I played turns 1 and 2 by hand, then let the build's debug autoplay (F8, a simple bot) play turns 3 to 8, and took control again at turn 9. The seven opponents are ghosts cut from 30 games of the build's own simple bots (FlowBot) at this build's rules, made for this task, because the shipped field (`res://ghosts/field`) is not in the checkout. So the opponents' boards are plausible but weaker-played than league bots. Nothing about the layout depends on that.

## The player (you)

| | |
|---|---|
| Name and portrait | Dame Farthing (`assets/glass/portraits/dame_farthing.jpg`) |
| Turn | 9 |
| Health | 11 of 40 (no armour) |
| Gold | 20 |
| Shop tier | 5. Upgrade to 6 costs 23 (can't afford: drawn dimmed, price in pink); "−3 next turn" (the upgrade gets 3 cheaper each turn you wait) |
| Refresh | 1 gold; "10 left at this price" (after ten paid refreshes the price steps up to 2) |
| Freeze | available, shop not frozen |
| Income shown on End turn | +19 gold next turn |
| Hand | 1 of 7: **Seek** (spell, costs 3, "Discover a unit.") |
| Counters (plates above the portrait) | **Compost 3** (Briar heap: Old Campaigner 6/9 T2, Blackthorn Sapling 5/6 T2, Blackthorn Sapling 5/6 T2, newest first). **Tide 2** (Locusts' extra Attack for the rest of the game) |
| Standing tribe rules in play | Badger Grudge pay, Locust Swarm, Pigeon Guard post, Briar Compost |

## The board: 7 of 7 slots full

Slots 0–3 are the front row (left to right), 4–6 the back row. Renown belongs to the **slot**, not the unit (a pill above the card: "Renown N").

| Slot | Unit | Tribe | Tier | Attack / Health (printed) | Keywords and marks on the card | Rules text |
|---|---|---|---|---|---|---|
| 0 (front) | Famine-caller | Locust | 3 | **15 / 11** (6/4; Tide +2/+0, Renown +7/+7) | slot pill "Renown 7" | When this dies, Tide +2. |
| 1 (front) | Squadron Leader | Pigeon | 3 | **4 / 9** (4/9) | none | The units in front of this have Sortie and +3 Attack. |
| 2 (front) | Bell-ringer | Mouse | 3 | **5 / 7** (3/5; Renown +2/+2) | Hand-me-down mark; slot pill "Renown 2" | Hand-me-down. Your Hand-me-downs give +3 more Attack. |
| 3 (front) | Granary Glutton | Locust | 4 | **7 / 7** (5/7; Tide +2/+0) | none | Whenever you sell a Locust, this eats it. |
| 4 (back) | Wing Commander | Pigeon | 5 | **11 / 17** (8/14; Renown +3/+3) | Sortie mark; 4 Charge pips; slot pill "Renown 3" | Sortie. Charge 4: After one of your Pigeons with Sortie kills, give its slot 3 Renown. |
| 5 (back) | Blackberry Sprawl | Briar | 3 | **4 / 8** (4/8) | Grow 2 mark | Grow 2. (Start of fight: gain +2/+2 for every 2 units in your Compost.) |
| 6 (back) | Hedge Lancer | Badger | 3 | **6 / 12** (6/12) | Fury 1 mark | Fury 1. The first time this attacks each fight, it takes no damage. |

Card frame colour is the tier: T1 cream, T2 green, T3 blue, T4 purple, T5 gold, T6 red (`assets/glass/frames/tier1–6.webp`). No golden units. The card face shows art, Attack, Health and small keyword marks only; name, tribe and text are in the hover or click detail.

Keyword texts as the game words them (from its tooltips): **Sortie**: attacks the enemy back row while it has units. **Charge N**: works this many times, then stops; refills each fight. **Renown**: the unit that starts the fight here, and any reservist who steps in, has +1/+1 for each. **Hand-me-down**: when this dies, the nearest friendly Mouse gains its Attack this fight. **Fury N**: whenever this attacks or is attacked, gain +1 Attack, and +1 more for each unit you're outnumbered by. **Tide**: your Locusts have this much extra Attack for the rest of the game. **Compost**: your heap; units you bought go here when you sell them.

## The shop

Five units and two spells. Prices are coins under each unit and on the corner of each spell. All are affordable with 20 gold.

| Place | Offer | Tribe | Tier | A / H | Price | Rules text |
|---|---|---|---|---|---|---|
| Unit 1 | Bramble Runner | Briar | 1 | 4 / 5 | 2 | Seed. (When this dies, add a copy of it to your Compost.) |
| Unit 2 | Home Guard | Pigeon | 3 | 3 / 11 | 4 | Guard. Reserve. (Guard: enemies must attack this first. Reserve: in a fight, steps from your hand into a slot a friendly unit died in; your Guard post first; up to 2 a fight.) |
| Unit 3 | Hayloft Aunt | Mouse | 2 | 2 / 9 | 3 | Hand-me-down. Recruit: Add a Cousin to your hand. (Cousin: a 2/2 Mouse with Hand-me-down.) |
| Unit 4 | Sweetbriar | Briar | 2 | 3 / 7 | 3 | Whenever a unit goes into your Compost, gain +1/+1 permanently. |
| Unit 5 | Shrew Cutpurse | Mouse | 2 | 2 / 4 | 3 | Pile on 1. After this piles on, gain 2 gold. |
| Spell 1 | Sharpen | spell | 1 | — | 1 | Give a friendly unit +2/+2. |
| Spell 2 | Sharpen | spell | 1 | — | 1 | Give a friendly unit +2/+2. |

The two spells sit above the shop row, at the top centre, smaller, in hexagon cut-outs. The board is full, so a bought unit goes to the hand.

## The opponents (leaderboard, one click on your own portrait)

| Place | Name | Health | Note |
|---|---|---|---|
| 1 | Pipkin | 31 | |
| 2 | Old Mother Mousewife | 28 | |
| 3 | Dame Hoolet | 23 | |
| 4 | Little King Wren | 18 | your last opponent (turn 8) |
| 5 | March Hare | 16 | **next opponent**: portrait on the End turn button, ringed in the leaderboard |
| 6 | Hob Mumblecrust | 16 | |
| 7 | Dame Farthing (you) | 11 | ringed |
| 8 | Brother Bracken | out | greyed |

The names and portraits are stand-ins (`src/game/game_flow.gd`, `assets/glass/portraits/`). The leaderboard shows portrait, place and health only; no tier, tribe or last board.

## Everything else on screen

- Top left (left light, top): settings cog; "Turn 9"; **Past boards** button.
- Top right (right light, top): **Cards** button (the card browser).
- Bottom left: counter plates Compost 3 and Tide 2; name "Dame Farthing"; portrait with health 11.
- Bottom centre: "Hand 1/7" and the hand card, only its top third showing above the screen edge.
- Bottom right: "End turn" over March Hare's portrait (health 16); "+19" gold pill.
- Left of the shop: gold 20; upgrade button (tier icon, "5 → 6", coin 23); "−3 next turn".
- Right of the shop: "10 left at this price"; refresh (coin 1); freeze (snowflake).
- The four side panels below and above the lights are empty lattice glass.

## The fight that follows (turn 9, against March Hare)

Before ending the turn I did what a player might: bought Home Guard and Hayloft Aunt (to the hand, board full), cast Seek and picked Hedge Lancer (to the hand), refreshed ten times (gold 20 → 3), and sold Granary Glutton (slot 3). So the fight starts with slot 3 empty and four cards in hand (Home Guard and Hayloft Aunt can step in as reservists). Picture: `fight-mid-t9-start.png`; its end: `fight-mid-t9-result-defeat.png`; the result screen: `game-end-result.png`.

**You (bottom half)**, as shown at the start of the fight:

| Slot | Unit | A / H on screen | Marks |
|---|---|---|---|
| 0 | Famine-caller | 15 / 11 | Renown 7 |
| 1 | Squadron Leader | 4 / 9 | |
| 2 | Bell-ringer | 5 / 7 | Renown 2, Hand-me-down |
| 3 | empty | | |
| 4 | Wing Commander | 11 / 17 | Renown 3, Sortie, 4 Charge pips |
| 5 | Blackberry Sprawl | 8 / 12 (Grow 2 with Compost 4) | Grow 2 |
| 6 | Hedge Lancer | 6 / 12 | Fury 1 |

**March Hare (top half; their back row is drawn at the top, front row next to the middle line)**:

| Slot | Unit | Tribe | Tier | A / H | Marks | Rules text |
|---|---|---|---|---|---|---|
| 0 (front) | Greatsword Bearer | Badger | 4 | 7 / 15 | Renown 3, Squire mark | Squire. The units in front of this have Overrun. |
| 1 (front) | Briar King | Briar | 6 | 12 / 20 | Renown 4, a mark with 4 | Your other front-row Briars have Grow 2. |
| 2 (front) | Holly Knight | Briar | 4 | 12 / 19 | Renown 7, Grow 2 mark | Your front-row Briars have +1 Thorns for every 3 units in your Compost. |
| 3 (front) | The Eighth Plague | Locust | 5 | 6 / 14 | Renown 2 | After a friendly unit dies, deal damage to a random enemy equal to the number of friendly units that died this fight. |
| 4 (back) | Weasel | neutral | 5 | 9 / 13 | Renown 1, 6 Charge pips | Charge 6: After an enemy is summoned, Hit it. |
| 5 (back) | Gorger | Locust | 4 | **golden** 38 / 68 | golden rim | The first time you sell a unit each turn, this eats it. |
| 6 (back) | Dame Bodkin | Mouse | 5 | 6 / 9 | Pile on 2 mark | Pile on 2. Your Mice's pile-on hits deal double damage. |

Outcome: you lose every unit; March Hare loses Briar King and keeps the other six. You take 13 damage (11 → 0) and are out in 7th place. The result screen lists all eight with health. (On the fight screen the left light shows your plates and portrait, the right light March Hare's portrait, name and health; a Skip button bottom right; the leaderboard slides in on the right at the end.)

A second, closer mid-game fight is also shot: turn 8 against Little King Wren (`fight-mid-start.png` … `fight-mid-result-defeat.png`, you lose 12).

## Files a designer may reuse

All paths are in this checkout unless they start with `/data`.

| What | Where |
|---|---|
| Card art, the five tribes' units (108 pictures) | `assets/units/<badger, locust, mouse, pigeon, thorn, shared>/<card-id>.jpg` (Briars are the `thorn` folder) |
| Stand-in art (mock-up animals, the three spells' pictures `spell-1`, `spell-2`) | `assets/glass/art/` |
| Card frames, one per tier (lead and glass hexagon) | `assets/glass/frames/tier1.webp` … `tier6.webp` |
| Player portraits (the eight stand-in characters) | `assets/glass/portraits/*.jpg` |
| Screen textures (pane, stone, quarries, round and transom pieces) | `assets/glass/ui/` |
| Fonts: Alegreya (headings, numbers), Alegreya Sans (text), with licences | `assets/glass/fonts/` |
| Layout numbers (card size, number styling, sheet text sizes and more) | `assets/glass/layout.json`; keyword names, colours and icons `assets/glass/keywords.json`; card data for the mock-ups `assets/glass/card_data.json` |
| Card data the game uses (names, tiers, stats, text, keywords) | `src/content/<tribe>/units.json` and `display.json` (keyword wording); spells `src/game/data/stand_in_units.json` |
| HTML mock-ups of today's screens, with their CSS and JS pieces | `docs/ideation-track-2/mockups/` (`recruit.html`, `recruit-play.html`, `fight.html`, `start.html`, `result.html`, `pause.html`, `stand-ins.html`, `polish.html`; `card.css`/`card.js` draw a glass card; its README says which scene matches which page). Its `assets/` is a link to `assets/glass` |
| This state as data | `/data/ui-ideation/baseline/state-t9.json` (the player at turn-9 start and both fight boards), `/data/ui-ideation/baseline/fight-t9-boards.json` (the record's fight entry) |
| Screenshots of today's game | `/data/ui-ideation/baseline/shots/` (list in `map.md`) |
