VERDICT: CHANGES NEEDED
GALLERY: A better, D average, E better

# Council round 2: opus

I checked every new render of A, D and E at full size (A: mid, first, fight, after; D: those plus extra1 and extra2; E: those plus extra1). I cropped places where a claim turned on detail and read the CSS for text sizes. Coordinates are render pixels.

In short: all three concepts did nearly all of their agreed lists. Two concepts belong in the gallery as one of the better ones (A and E), and one is about average (D). What still blocks is four small items, each under an hour of work. None of them changes the gallery verdict.

## Scores

| | Look r1 → r2 | Reading r1 → r2 | Theme | Lead and glass | Tall hexagons |
|---|---|---|---|---|---|
| A. Great window | 8 → 8.5 | 7.5 → 8.5 | pass | pass | pass |
| D. Glazier's bench | 7.5 → 8 | 8.5 → 9 | pass | pass | pass |
| E. Glass in the forest | 8.5 → 8.5 | 4.5 → 7.5 | pass | pass | pass |
| Today's game | 5 | 3 | pass | pass | pass |

(My D look was 7 in round 1 and 7.5 after the discussion.)

## Part 1. Re-check the fixes

### A. The great window

| # | Item | Status | Evidence |
|---|---|---|---|
| 1 | Two rows, same left anchor, Renown on slots | **Partly fixed** | Rows and labels are right in mid, first and fight. The new spacing makes Renown tabs collide with caption plaques; see blocking item 1. |
| 2 | Back row clear of the sill; marks clear of plaques | Fixed | The mid back-row plaques end about 3 px above the sill (y ≈ 1048). The marks sit clear in both rows. Shrew Cutpurse's mark is at y 360 and its plaque at 385. |
| 3 | Price baseline; Sweetbriar wording | Fixed | All prices sit at y ≈ 462. Sweetbriar reads "+1/+1 when a unit enters your Compost". |
| 4 | Refresh stock with Refresh | Fixed | "10 at this price" sits under Refresh (372 to 398). |
| 5 | Spells and hand | Fixed | The spells have a trimmed tier rim with no stat discs, and their own name, effect and price. The hand has seven slots. Seek's effect comes up on select. The empty part of Card details shrank from about 150 px to about 70 px. |
| 6 | Tribe at a glance | Fixed | Every shop and board card has a tribe tab. |
| 7 | Player block in one place | Fixed | Top left in all four views. |
| 8 | Names in the fight | Fixed | Both boards have names and cues, including Golden Gorger. |
| 9 | After: survivors, threats, standings | Fixed | "Survived" or "Fell" on each slot, Briar King fallen. Golden Gorger and Holly Knight sit under the 10 + 3. The standings run Dame Hoolet 23 down to Brother Bracken Out. |
| 10 | First-turn cue | Fixed | The cue points at the highlighted first front slot. |
| 11 | Notes rows 20 and 40 | Fixed | Both are in `notes.md`. |

New defects:
- **mid (480 to 1160, 765 to 785):** "Renown 3" for Wing Commander sits in the front row's caption strip, touching the Famine-caller and Squadron Leader plaques. It reads as part of that row, not as Wing Commander's slot.
- **fight and after (520 to 1380, 280 to 305):** the enemy front row's tabs (Renown 3, 4, 7 and 2) sit edge to edge with the back row's name plaques. They form one mixed strip: "Renown 3 | Weasel | Renown 4 | Golden Gorger…".
- **mid (60 to 290, 640 to 980), non-blocking:** the hand's seven slots form a 3, 2, 2 pattern whose last row hugs the two edges with a gap between.
- No text under 18 px anywhere (CSS minimum 18 px). One accent (End turn). Every card is undistorted.

**Blocking for A**
1. **mid, fight, after (Renown tabs):** lower each back row by about 24 px, or set each Renown tab on its card's top-left shoulder inside the slot surround, so every tab is clearly its own slot's and has at least 8 px of space from any plaque.

### D. The glazier's bench

| # | Item | Status | Evidence |
|---|---|---|---|
| 1 | One accent | Fixed | Only End turn (and See results in after) is lit. The left lane and the player rows share one smoky glass. |
| 2 | Warm frost; glass labels; space from the divider | Fixed | The table and window are warm frosted glass with soft lines. The labels are dark tinted glass in lead. The enemy front labels clear the strip at y ≈ 515. |
| 3 | Board cards about 215 to 230 px | Fixed in recruit, partly in fight | Recruit cards are 216 px (Famine-caller y 372 to 590); fight cards are 200 px. **I accept the 200 px:** two labelled boards plus Renown tabs in 1080 px leave no more room. |
| 4 | Shop rules at 18 px | Fixed | |
| 5 | Stat stones | Partly fixed | The stones fit the disc zone, are non-gold, and use a hexagon for Attack and a circle for Health. Changes made during the fight carry a chevron (Blackberry Sprawl 8/12 in fight). Recruit buffs (Famine-caller 15/11, printed 6/4) carry none, but extra1 gives "Printed 8/14 · Renown +3/+3". I accept the designer's reading. Not blocking. |
| 6 | Renown as a labelled slot tab, also on empty slots | Fixed | A blue-violet "Renown N" tab, shown on your emptied slot in fight and on Briar King's in after. |
| 7 | Cues and Charge | Fixed | Cues read "Dies: Tide +2", "Arms the unit ahead" and so on. Pips show on Wing Commander and Weasel. |
| 8 | Spell edge | Fixed | A sea-green leaded edge with no stat wells. |
| 9 | Hand of seven | Fixed | extra2 shows seven cards in the tray. |
| 10 | Reserves and stakes | Fixed | The reserves show real stats with 18 px names. "Kills 0 of 4" is at 20 px. |
| 11 | Side columns | Fixed | Left: stakes, reserves, you. Right: players and Skip. |
| 12 | Menu and Turn in one place | Fixed | Bottom left in every view. |
| 13 | After standings, links, starting values | Fixed | "At the start of the fight" labels the totals. |
| 14 | extra1 docked | Fixed | The panel sits inside the table (x 1340 to 1570), clear of the slots. |
| 15 | "Watch again" note | Fixed | |

New defects:
- **extra2 and mid (hand tray):** hand stat digits are 15 px (the designer says so). Stats are text a player acts on, and the brief's floor for that is 18 px.
- **Non-blocking:** board cues are 16 px (`.kw`). The shop tribe line ("BRIAR", "SPELL") and the place labels are 14 to 15 px, so they pass the 14 px floor. The mid table still has about 250 px of plain frost each side of the board. First's tutorial plate lies over the back-row slot outlines; it is removable, so I accept it.

**Blocking for D**
1. **mid, extra2 (hand tray, y 1000 to 1030):** raise the hand stat digits to 18 px. The stones grow by about 4 px, and the 135 px tray has room if the card thumbnails shrink by that much.

### E. Glass in the forest

| # | Item | Status | Evidence |
|---|---|---|---|
| 1 | Name plates; cards trimmed | Fixed | Every card has a plate. The shop is trimmed 13%, the board 15% and the fight 22%. **I accept 22% in the fight:** both boards plus the hand now fit with plates, and the cards still read. Rows don't overlap in mid. |
| 2 | Price tags | Fixed | Pennant tags hang on the chains. They no longer look like stat discs. |
| 3 | Halos dropped | Fixed | |
| 4 | Lantern names, numerals, threads, End turn | Fixed | Name plates; rank at 19 px and health at 18 px on ruby (13.7:1 measured on the names). Each lantern hangs from its own twig. The button reads "Fight March Hare". |
| 5 | One lit action | Fixed | Fight March Hare is the brightest control. The gold medallion is unlit. |
| 6 | Counters and name plates | Fixed | In recruit and the fight. |
| 7 | Hand tray | Fixed | Seek is whole; the fight hand stats are about 18 px; the badges have room. |
| 8 | Refresh cost | Fixed | |
| 9 | Bough and tray glass | Fixed | Leaded bark panes. |
| 10 | Enemy row spacing; tally labels | Fixed | "Small loss at 4 kills" and "Their small loss at 3". |
| 11 | After and extra1 | **Partly fixed** | Done: the plaque and pane are leaded, extra1 docks clear of the units, your fallen units read "Fell", and the threats carry numbered beads. Not done: the lights still show pre-fight health for everyone but you (Pipkin 31 first, Old Mother Mousewife 28, Dame Hoolet 23). The agreed item asks for health as at the end of the fight. |
| 12 | Spell edge | Fixed | |
| 13 | Notes | Fixed | |

New defects:
- **after, a fact check:** the orchestrator's fact (2) does not hold for E. E's after shows Briar King alive (12/11), "You killed 0 of 7", Gorger at 38/41 and Holly Knight at 12/4. The record has Briar King fallen, Gorger 38/57 and Holly Knight 24/27. Under round 1's rule the survivor count itself is not a defect. But the panel and the lights should match one source; see blocking item 1.
- **mid, all plates:** card names are 17 px (`.e-np b`), 1 px under the 18 px floor for names. The cues are 15 px, which passes the 14 px floor.
- **Non-blocking:** in mid the spell plates (y 315 to 360) sit about 70 px above the unit plates (385 to 430), so the shop's labels don't share a baseline. extra1's pane covers standings rows 5 to 8 and touches the top of Fight March Hare (y ≈ 795). It is a transient pane, but it should clear the button.

**Blocking for E**
1. **after (lights 1600 to 1900, 110 to 650, and the board):** show health as at the end of the turn-9 fight (Dame Hoolet 23, Pipkin 21, Little King Wren 18, Old Mother Mousewife 18, March Hare 16, Hob Mumblecrust 16, you and Brother Bracken out). Make the board and the "You killed" line follow the same record as A and D: Briar King fallen, 1 of 7.
2. **mid, first, fight (card name plates):** raise the names to 18 px.

## Part 2. The gallery check

I looked at all three sheets and these references at full size: `battlegrounds--shop-full--1`, `galaxy--shop--1`, `root--board--1`, `backpack-battles--shop--1` and `glass-masquerade--puzzle--1`. The rest I judged from the sheets.

### A: one of the better ones

References: `battlegrounds--shop-full--1` and `battlegrounds--fight--1` (the same game shape, one framed play surface); `galaxy--shop--1` (the minimal-face card game the owner follows); `monster-train--shop--1` (named cards in a dark frame); `glass-masquerade--puzzle--1` (the best glass craft in the gallery).

Judgement:
- **Flavour.** A carries warm amber and green glass, leaf tracery and lead seams into every plate and button. It is one material from the Turn plate to End turn.
- **Clarity.** A is clearer than Battlegrounds at a glance: names, effects, tribe and prices without a hover, and standings named. Battlegrounds needs a hover per minion.
- **Polish.** Battlegrounds and Glass Masquerade have more depth, light and modelling. A is flatter, a well-made 2D window. It is clearly above Galaxy's starfield and in line with Monster Train.
- **Placement.** In group A, I would put it in the top half: below Battlegrounds for richness, at or above the rest.

Against today's game: well above. It keeps the same window but fills it: warm glass in place of grey lattice, readable cards, standings in view. About 3.5 points on the look.

### D: about average

References: `backpack-battles--shop--1` (the closest diegetic shop in the gallery: a room, shelves, a bench); `inscryption--board--1` (a table you play on); `wingspan--board--2` (a crafted tabletop with names and rules on the cards); `battlegrounds--shop-full--1` (the game shape).

Judgement:
- **Flavour.** The painted bench surround (stone, leaves, brambles, the window) is real flavour. It belongs beside Backpack Battles.
- **Clarity.** D reads best of all three: full rules in the shop, cues on the board, stakes in the fight, the clearest "why".
- **What holds it to average.** The table is a large flat area of frost with about 250 px of nothing each side of the board. Three-quarters of the screen is rectangular panels (shop labels, player rows, left lane, hand tray), so it looks more like a tidy board-game app than a lit object. Beside Backpack Battles, whose whole screen is drawn, and Inscryption, whose table is lit by one candle, D's middle is plain.

What would lift D, as non-blocking work: give the light table a light source, so it glows from below, brighter at the centre and darker at the edges, with the cards casting colour onto it. Narrow the table to the board's width and give the margins to the bench art.

Against today's game: above, by about 3 points on the look. It is warmer and every panel is finished, and it is far ahead on reading.

### E: one of the better ones

References: `root--board--1` (woodland animal folk; the forest is the board); `dorfromantik--board--2` (a crafted landscape as the play surface); `wildfrost--fight--1` (named cards over a painted scene); `galaxy--shop--1` (cards floating over a scene with little chrome); `gwent--board--1` (cards on a dark painted battlefield).

Judgement:
- **Flavour.** E has the strongest flavour of our three and holds up against Root: the stained-glass clearing, the hanging bough shop and the lantern players make the place the interface.
- **Clarity.** The new plates and pennants bring reading to a level with Wildfrost.
- **Polish.** The plates are plain dark rectangles. That keeps it below Wildfrost's bespoke card plates. The background is busy behind the right-hand standings and the bottom-left hand, where Root keeps its play area calmer.
- **Placement.** It belongs in the gallery's upper half, near Root and Wildfrost and above Galaxy and Gwent's board for craft.

Against today's game: well above, by about 3.5 points on the look. It is the biggest change in feel of the three.

**At least one concept belongs at average or better: yes, A and E.**

## Non-blocking notes

1. D's look, from average to better: a lit light table (glowing from below, darker edges) narrowed to the board, with the margins given to bench art.
2. E: put the spell plates on the unit plates' baseline (y ≈ 398). Keep extra1's pane clear of the Fight March Hare button.
3. A: make the hand's seven slots a regular pattern (for example 4 over 3) instead of 3, 2, 2 with an edge-hugging last row.

## Not judged

Motion, timing, hover and drag feel, sound, and screen sizes other than 1920x1080.

## Disk

New this round: `/data/ui-ideation/tmp/council-opus/r2/` (14 PNG crops). The whole folder `/data/ui-ideation/tmp/council-opus/` is 15 MB. Everything in it can be removed when the council ends. Nothing else was written besides this file.
