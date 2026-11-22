# Pass 2, round 1: what the council asked for

Put together by the orchestrator (an agent) from the three voting members' answers (`p2r1-opus-player.md`, `p2r1-opus-craft.md`, `p2r1-neon.md`) and their keep-or-drop marks on the checker's items (`p2r1-keep-*.md`, on `p2r1-sol-items.md`). The assembly is clerical: an item is listed as agreed when at least two of the three voters raised it, and each item names who did. Nothing here is the orchestrator's judgement. The owner's reactions, when they come, outrank all of it.

## Rank

**E, A, D**, from all three voters.

## For all three concepts

Ideas the voters asked every designer to consider. How you do it is yours.

- **Light does the ordering** (all three voters). A dark ground, the shop in the warmest light at full colour, the board a clear step quieter, and the scene falling away at the edges, so the glass is what glows.
- **Tier as one numeral** (player, neon). "Nothing reads faster", and it cannot be confused with charge pips. One plain frame, the same for every tier (craft).
- **Changed stats look changed** (player, neon). A buffed or wounded Attack or Health is told from a base one by its colour, with no text.
- **In the fight, light only the blow being struck** (craft), and let everything else step down.
- **Golden is unmissable** (player, neon).
- **No zone titles** (all three): words such as "Shop", "Hand", "Standings", "Fight", "Opponent", and plates that repeat what the picture already says.

## A. The great window, refit

Agreed (at least two voters):
1. `mid`, `first`, `fight`, `after`: remove the zone titles ("Shop", "Hand", "Standings", "Fight", "OPPONENT", "March Hare's board", "Turn 9 standings"), and one of the two next-opponent marks ("Next fight" in the standings and the March Hare plate above End turn). (all three)
2. `mid`: push the board a clear step darker or quieter than the shop. Today they are about equally bright and compete. (all three)
3. `cards`, `fight`: make a golden unit unmissable. The brass seam barely reads. (player, neon)
4. `mid`, `first`: the spell tiles are too small to read (about 90 px wide beside 165 px hexes) and their prices sit off to the right, away from the shop's price line. (all three)
5. `mid`: the sub-lines under Upgrade and Refresh ("−3 next turn", "10 at this price") are small grey text on teal with weak contrast. (player, craft)

One voter each (optional):
- A quiet tier tell in the metal or bevel besides the number; the tier tints barely differ. (craft; player and neon noted the tints)
- The table is one flat teal with a faint lattice, so the cards have nothing behind them. (craft)
- Shop price numerals are about 12 px, the smallest number by the card. (player)
- `fight`: the hand and reserves vanish, hiding waiting reservists. `mid`: the hand's 4 + 3 slots shrink Seek to a dark sliver with no cost. (neon)
- Renown pills sit over card art and share the tier seal's muted palette. (neon)

## D. The glazier's bench

Agreed:
1. `mid`: the eye order is backwards. The cream End turn pane is the brightest thing on screen and the pale table and window outshine the glass. Make the surfaces dark enough that the glass carries the light, the shop leads during recruit, and End turn stays quiet while gold is unspent. (all three)
2. `mid`, `fight`, `cards`: tier cannot be read at a glance. The beads are about 5 px dots and stack directly under the charge pips on Wing Commander and Weasel. (all three)
3. `mid`, `fight`, `after`: labelled chrome is left: the "Dame Farthing" plate, "Hand 1 of 7", "Turn 9 / Recruit", the place labels on the standings ("1ST", "NEXT · 5TH", "YOU · 7TH"), "Reserves in hand", "Fight", "FIGHTING", "Fight over". (all three)
4. `fight`, `after` (x760, y0): the top of Weasel's Renown diamond is clipped by the screen. (checker; all three keep) Renown diamonds wedge against neighbouring card tips. (neon)
5. `mid` (standings): the place labels are about 11 px and under 4.5:1 (3.66:1 and 3.24:1 measured). (checker; all three keep; player)

One voter each (optional):
- The eight saturated red health discs in the standings are the noisiest thing on screen. (craft)
- The shop's price coins overlap each frame's top-left shoulder and clip the lead. (craft)
- Shop units are smaller than board units, and the spell medallions look bigger than the units. (player)
- Two-digit stat stones are tight and the buff chevrons crowd their rims; the shattered glass in `fight` and `after` reads as confetti. (neon)

## E. Glass in the forest

Agreed:
1. `mid`, `fight`, `cards`: tier cannot be read at a glance. The metal lines of neighbouring tiers look alike at board size (copper, bronze and gold), the beads are tiny, sit tight under the price-tag chain, and at tiers 5 and 6 spill past the hexagon's top. (all three)
2. `mid`, `first`, `fight`: the keyword marks at the card's foot are about 10 to 12 px and cannot be read or told apart. (all three; player and craft add that a player who knows the card does not need them)
3. `mid`: the lit March Hare portrait and "Fight March Hare" pull the eye too early, with 20 gold unspent. (player, neon)
4. `mid`, `fight`: the hand. A single rondel with no slots, so you cannot tell how much room is left; in `fight`, Home Guard's 11 overlaps Hayloft Aunt. (player, neon)
5. `mid` (right edge): the player lanterns are about 55 px and their health badges cover the portraits' edges. (player, craft)
6. `after` (x560–570, y811–867): the "See the standings" button overlaps the result panel's right frame by about 10 px. (checker; all three keep)
7. `mid`: the Renown numbers 7, 2 and 3 are 17 px. (checker; player and neon keep)
8. `fight`: three cards are in hand; `state.md` says four at the start of the fight but names three (Home Guard, Hayloft Aunt, Hedge Lancer). Check `/data/ui-ideation/baseline/shots/fight-mid-t9-start.png` and match it. (checker; all three keep)

One voter each (optional):
- "I see no 'dimmed one step'" on the board: dim it for real, or light the shop much more. (player; craft and neon read the board as dimmed)
- The shop and the front row are the same size with no divider, so the screen first reads as one 12-card grid. (player)
- "+19" (bottom right) is far from the gold coin (top left). The leaded trees add line noise behind the cards. `first`: the hint box overlaps the third and fourth empty slots. (craft)
- Upgrade's discount is missing. `hover-board` never tests an edge flip. (neon)

## Where the voters split

**A tooltip covering the cards next to it.** The checker measured it in every concept. Player: a defect ("Make tooltips stop covering the units you compare against"). Craft and neon: not a defect ("a hover covers its neighbours for a moment; moving the pointer shows them"). Two to one, so it is not on the lists. It is a question for the owner.

## The checker's items

Sixteen measurable items, none asking for text on screen. Kept by at least two voters: D1, D4, E2, E3, E6 (in the lists above). Dropped: A1 to A3, D2, D3, D6, E1, E4 (tooltips covering neighbours), D5 (16 px sub-lines), E5 (a reminder showing "+N"), E7 (the reminder panel growing upward from a fixed foot).

## Not judged

Motion, timing, hover feel and sound.
