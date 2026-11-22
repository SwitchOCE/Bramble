# Concept E: Glass in the forest

One stained-glass clearing at dusk: the shop hangs from a bough, your board stands on the moss, the other players are lights in the trees. Each card has a tribe crest and a leaded name plate; the frame alone shows tier.

## Flow
- **Recruit:** gold, tier-up, Refresh and Freeze hang at the bough's left; prices are tags on each chain. End turn ("Fight March Hare") is the next opponent's lantern. A click opens a reading pane (`extra1`).
- **Fight:** both fighters on the left, each with a labelled **tally**: one hexagon per starting unit, a bar at half.
- **End:** a leaded plaque: the loss, why it was big, and **What beat you**, three enemy units numbered on the board.

## Glance count
- Recruit: **23** (today 23). Added crest, name plates, players' lights. Refresh stock is *not yet*, the discount *reach*; Past fights and Cards are one Journal.
- Fight: **13** (today 9). Added tally, name plates, hand, dimmed lights.

## Judged things
1. **Look:** a painted glass background, and every control a leaded glass object in it.
2. **Reading:** name plates and crests show pairings (Hayloft Aunt's mouse crest matches Bell-ringer). Opponents' name, place and health always show.

## Owner decisions reversed
- 14, 37: no frames; the scene separates areas.
- 20: a tribe crest is on the card.
- 36, 51: card sizes differ (shop 236, board 254, spells 170, fight 196, hand 186–190).
- 43, 50: spells hang beside the units, as tall hexagons.
- 45: the refresh count shows at 3 left.
- 47: "3 gold short" replaces the discount.
- 48: the controls are on one side, with tier-up under the gold.
- 55: the hand shows in the fight.
- 40: every player's name shows beside their lantern, not only on hover.
- 71: the reading pane docks beside the board, not under the card.
- A1, A3, A4: no stone window; both fighters on the left; the leaderboard always shows.

## Suggestions
- Suggestion for the owner: one Journal for Past fights and Cards.
- Suggestion for the owner: a fight log so What beat you can be computed (lines here are illustrative).
- Suggestion for the owner (flow): "Watch again" after a fight replays it from the result plaque.
- Suggestion for the owner: the bough gains lanterns per shop tier (46).
- No rules changes.

## Learned from
Battlegrounds, Root, Dorfromantik, Glass Masquerade, Inscryption, TFT.

## Weakest point
Name plates make the clearing busier than round 0. Fight cards shrank 22%, not 10–15%.

## Quality pass
Checked per view: alignment, icons, text size, contrast, overlaps, spacing, one accent, card ratio.

Round 1: all five views re-checked with crops; a script confirms no plate text overflows. Not fixed: nothing known.

**Not judged:** motion, timing, hover feel and sound can't be judged from stills.

## Round 1 fixes
1. Done. Every shop card, spell and board unit has a lead-set name plate with one short cue; in the fight, name and keyword. Shop 270→236 (−13%), board 300→254 (−15%), spells 190→170 (−11%). Rows don't overlap at a full board: the back row's top point sits in the gap between front plates. Fight cards went 250→196 (−22%), more than asked, to fit two boards with plates.
2. Done. Prices are pennant-shaped leaded tags hung on each card's chain; grey when you can't afford it.
3. Done. Tribe halos removed; the crest stays; every card has the same soft white glow.
4. Done. Name plate beside each lantern with rank (19 px) and health (18 px, cream on ruby) or "Out"; each lantern hangs from its own twig. End turn reads "Fight March Hare".
5. Done. "Fight March Hare" is the one brightly lit button; the gold medallion has no glow and darker amber.
6. Done. "Compost 3" and "Tide 2" are named plates in recruit and fight; "Dame Farthing" plate over the portrait (March Hare too in the fight).
7. Done. The log tray is fully on screen with Seek whole; hand stats 18 px or more; count badges 22 px with 16 px numbers and their own spacing.
8. Done. Refresh is a full-width button with its cost inside.
9. Done. The bough and log are cut into leaded bark panes with seams and real glass mottle.
10. Done. Enemy rows are spaced so marks clear the Renown leaves; both tallies are labelled ("Small loss at 4 kills", "Their small loss at 3").
11. Done. Result plaque and reading pane have a lead edge, a segmented amber glass border and pane texture. The reading pane docks right, clear of Home Guard, Squadron Leader and Wing Commander, which are lifted above the veil and ringed. Enemies stay lit; your fallen units are dark, cracked and marked "Fell"; the three threats glow and carry numbered beads; lights show your health as 0 / Out.
12. Done. Spells have a lead edge and an amber came line; the art fills its hexagon at its own proportions.
13. Done. Row 40 added to reversed rows; "Watch again" labelled a flow suggestion. A6 is no longer reversed: counters are now named plates.

Non-blocking: tier cue on the card face not done (it would add a mark the frame already carries).

## Round 2 fixes
1. Done. The after view follows the recorded end of the turn-9 fight: Briar King fallen (dark, cracked, "Fell"), six survivors lit with their end stats (Gorger 38/57, Holly Knight 24/27, Greatsword Bearer 7/10, Weasel 9/2), both tallies at 1 of 7 killed, Compost 4 and Tide 4, and the lanterns in the recorded order (Dame Hoolet 23, Pipkin 21, Little King Wren 18, Old Mother Mousewife 18, March Hare 16, Hob Mumblecrust 16, you and Brother Bracken out). The plaque spells out "10 turn 9 + 3 big loss"; the numbered threat markers stay.
2. Done. Card names and cues are 18 px and fit inside every plate (a script checks each view; none overflows). Shop plates are 164 wide, so the gold, tier-up, Refresh and Freeze moved 90 px left. Cues corrected against the card data: Sweetbriar "Compost in: +1/+1", Hedge Lancer "First attack: unhurt", and also Bell-ringer "Hand-me-downs +3". Squadron Leader ("Front: Sortie +3") and Blackberry Sprawl ("Grow 2") were shortened to fit. Tally labels and lantern names are 18 px. Dimmed states now dim the portraits and the plate glass, not the text: rank, health on ruby (about 8:1) and "Fell" keep full contrast.

Non-blocking, both done: spell plates sit on the unit plates' baseline; the reading pane in extra1 ends above the Fight March Hare button.

## Round 3 fixes
1. Done. Renown sits on its own card's upper-left shoulder in every view, not on the top point, so it no longer falls between the row above's plates; a script measures the nearest badge to any plate at 11 px in fight and after (21 px in recruit). The after view keeps slot Renown on fallen units: Briar King 4, Famine-caller 7, Bell-ringer 2, Wing Commander 3.
2. Done. In extra1 the roster stays above the veil: its lanterns and plate glass dim, its rank and health text do not; the reading pane starts below Little King Wren so no row is cut. In after, fallen cards no longer show their dimmed numbers; the "Fell" label carries the state.

Optional, done: the result plaque is 22 px narrower, so it ends 8 px short of Greatsword Bearer's plate (Weasel's line shortened to "hit both reservists as they arrived" to fit).

## Pass 2, round 1
**At rest** a card shows art, Attack, Health, small keyword marks along the bottom (rows 22, 23), slot Renown, charge left and Golden. These change during a game or can't be inferred. Names, cues, crests and labels are gone; cards are back to full size (shop 270, board 300, fight 250).

**Eye order (mid):** 1) the shop, under a warm pool of light, at full colour; 2) your board, its art dimmed one step; 3) gold and "Fight March Hare". The hand, lanterns and counters stay quiet, and the scene darkens towards the edges.

**Frame:** one lead line, a thin inner came in the tier's metal (iron, copper, bronze, silver, gold, white gold), and 1–6 clear beads in the top point. Stats are dark leaded glass discs, so they no longer look like gold (26). Golden doubles the gold came. Spells are round rondels with a pale came and eight spokes.

**Hover:** a leaded tooltip pinned beside the card: right if there is room, else left, lifted to stay on screen. It doesn't follow the pointer. **Keyword reminders** always sit low on the left over the oak (x 24–324, ending at y 712); a setting hides them (`keywords-off`). Hovering a lantern shows that player (`extra1`; its history line is illustrative). No board is ever shown.

**Reversed:** 24 (no type line at rest); 42 (price tags hang above the card on its chain).

**Suggestions:** paint future card art with a calmer, darker edge zone so frames need less dimming.

## Pass 2, round 2
1. Done: tier is one numeral at the card's foot; one plain came for every tier.
2. Done: keyword marks removed at rest; they live in the tooltip.
3. Done: End turn and March Hare stay unlit while gold is unspent (`mid`, `first`).
4. Done: seven sockets on the log, lit per card held.
5. Done: lanterns 72 px; health sits beside, not on, the portrait.
6. Done: "See standings" sits inside the frame.
7. Done: Renown 19 px.
8. Done: the recorded start has no hand, so `fight` shows none.

For all three: board a step darker than the shop; in the fight only the blow is lit; changed stats get a green or red ring; Golden has a gold glow and rings; "What beat you" title cut. Optional, done: hint moved clear of the slots. Not done: tier-up discount (row 47) still reads "3 gold short".

## Pass 2, round 3
No art, no filters. One gap per zone, equal across and down.

| Zone | W × H | Across | Down | Why |
|---|---|---|---|---|
| Shop | 126 × 225 | 28 | – | coins fit below |
| Spells | ⌀126 | 28 | – | unit width; 56 from units |
| Board | 134 × 240 | 28 | 28 | rows offset, not interlocked |
| Hand | 63 × 112 | 8 | – | seven fit beside the board |
| Fight | 120 × 215 | 24 | 24 | 64 between boards |

`mid-b`: smaller cards (shop 106 × 190, board 118 × 210), honeycomb, 28 edge to edge. More air, but rows merge into one block. I pick `mid`.

Council: 1 done: tier in the top point's lead, no disc. 2 done: buffs ringed green; wounds dark disc, red ring. 3 done: lantern smaller (112), not dimmed. 4 done: Holly Knight 24/31; extra1 tip clears health. Golden: gold metal, no glow. Optional, done: Seek in a socket, no fight log, "Fell" plates and made-up history cut. Prices under cards (row 42).
