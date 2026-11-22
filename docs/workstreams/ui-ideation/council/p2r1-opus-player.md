# Pass 2, round 1: Opus, the hundredth-game player

Judged from every render in `/data/ui-ideation/concepts/<A|D|E>/` at full size. Motion, timing, hover feel and sound: **not judged** (stills only).

## A

**Against the direction.** At rest no card is explained. Zones are still titled: "Shop" (top centre), "Hand" and "Standings" (side panels). The next opponent is named twice: "Next fight" in the standings and the "March Hare ♥16" plate above End turn. Turn 1 shows "Drag a unit here from the shop" (`first`). The tooltip works as a hover. Reminders stay in one place across all three hover frames (left panel, same top) and go with `keywords-off`. The frame is calm. Tier reads fast from the numeral plate, but the tints barely differ and golden is only a slightly brighter rim (`cards`). Golden must be impossible to miss. No next-opponent board.

**Eye on `mid`.** 1: the shop row. 2: the board, about as bright. 3: the copper End turn. Gold (a small grey box) comes late. The order is right but the margin is thin: the warm shop and the cool board are too close in brightness.

**Defects.**
1. `hover-board`: the Hedge Lancer tooltip covers Wing Commander and Blackberry Sprawl. `hover-shop` and `hover-spell` cover the two shop neighbours' tops and stats.
2. `mid`: the upgrade and refresh sub-lines ("−3 next turn", "10 at this price") are about 13 px grey on teal, with weak contrast.
3. `mid`: the shop price coins sit 30 px below the cards with numerals of about 12 px, so the price is the smallest number on the card it belongs to.
4. `mid`: the spell tiles (right of the shop) are so small their art can't be read.

**Next round.** (1) Drop the zone titles and one of the two next-opponent marks. (2) Make tooltips stop covering the units you compare against. (3) Push the board a clear step darker than the shop, and make golden unmissable.

## D

**Against the direction.** No card text at rest, but a lot of chrome is labelled: "Dame Farthing" plate, "Hand 1 of 7", "Turn 9 / Recruit", and "1ST…NEXT · 5TH…YOU · 7TH" on the standings. Turn 1 has "Drag a unit onto your board to buy it." The tooltip works as a hover. Reminders sit in one fixed shelf, low left, in every hover frame and go with `keywords-off`. The frame is the calmest of the three, but **tier can't be told at a glance**: beads are about 5 px dots, and on Wing Commander they stack directly under four identical charge pips. Golden is clear. No next-opponent board.

**Eye on `mid`.** 1: the cream End turn pane, the brightest surface on screen. 2: the board, which has the biggest cards. 3: the shop, small cards washed out on pale parchment. That's the wrong order for buying: End turn shouts before you've spent.

**Defects.**
1. `mid`, board foot: tier beads and charge pips are the same white dots, one row above the other.
2. `hover-shop`: the Hayloft Aunt tooltip drops onto the board and covers Squadron Leader and Bell-ringer. `hover-board` covers the same two.
3. `mid`: the shop units are smaller than the board units, and the spell medallions look bigger than the units.
4. `mid`: the cards' bright art sits on a light ground, so contrast is lowest exactly where you buy.
5. `mid`, standings: the place labels are about 11 px small caps.

**Next round.** (1) Make tier readable at a glance and distinct from charges. (2) Make the shop the brightest and largest zone during recruit, and quiet End turn. (3) Fix the tooltips covering the front row.

## E

**Against the direction.** Cleanest at rest: no zone labels, and the standings are portraits and health only. Small keyword glyphs remain at each card's foot (about 10 px). They are too small to act on, and a veteran knows the card from its art, so they are noise. Turn 1 has "Drag a card into the clearing to buy it." The tooltip is pinned beside the card. Reminders sit low left in every hover frame: the box is anchored at its foot, so its top moves between frames but it stays in one place. They go with `keywords-off`. Tier: beads plus metal came. At board size the cames for tiers 3 to 5 look alike and the beads are tiny. Golden is clear. The lantern hover (`extra1`) shows a result, not a board, which is fine.

**Eye on `mid`.** 1: the shop hanging from the branch. 2: the big glowing March Hare portrait (bottom right). 3: the gold coin. Your board ties with the shop for brightness. I see no "dimmed one step". Almost right: the hare is too loud.

**Defects.**
1. `hover-spell`: the Sharpen tooltip covers Sweetbriar, Shrew Cutpurse and their price tags. `hover-shop` covers Hayloft Aunt's and Sweetbriar's tops.
2. `mid`: the shop and front row are the same size with no divider, so the screen first reads as one 12-card grid.
3. `mid`, lower left: the hand is a single rondel with no slots. With the board full, you can't tell how much hand room is left.
4. `mid`: the keyword glyphs at the card foot are too small to read.
5. `mid`: the standings' health badges overlap the portrait edges, and the lanterns are about 55 px.

**Next round.** (1) Actually dim the board at rest, or light the shop much more, and quiet the hare portrait. (2) Make tier readable at a glance. (3) Make hand room visible.

## Rank

1. **E**: the calmest screen, with the biggest cards and the dark ground that the owner's art needs. Prices and stats are the fastest to read.
2. **A**: the most efficient to read (numeral tier, everything in fixed places), but it is heavy on chrome and still titles its zones.
3. **D**: tier is illegible, the shop loses to End turn, and it carries the most labels.

**Borrow.** From A: tier as one numeral. Nothing reads faster. From D: buffed stats in a different colour (the green numbers), which shows state you can't infer. From E: the dark ground with a warm light pool over the shop, and price tags hanging off the card.

**Disk:** `/data/ui-ideation/tmp/council-opus-player/` (empty folder, 0 bytes). Nothing else written.
