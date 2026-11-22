# Pass 2, round 5 — Council vote (Gemini Neon)

*Not judged from stills: motion, timing, hover feel, and sound.*

## 1. A's screen against the owner's words

**Ground.** Back to round 3's dark amber-to-teal glass, faint diamond quarries, and six leaf boughs across all game views (`mid`, `first`, `fight`, `after`, `hover-*`, `keywords-off`); round 4's trees, sun roundel, and grass are gone. Small differences from round 3: recruit views add a lower lead rail above the hand; round 3's faint curved board arches are gone; `fight` keeps an oak-leaf medallion in the right light under March Hare.

**Sizes, shop, spells.** Round 4's unit (`112×200`) and hand (`84×150`) sizes, `140 px` pitch, `56 px` unit-to-spell gap, left-light shop controls, bottom single-row hand, and raised End turn hold; spells are round (`96 px` shop, `84 px` hand). Changes from round 4: hand gaps widened (`21` → `28 px`), spell gap widened (`24` → `28 px`), and side lights narrowed (`382` → `310 px`), cramping the left-light shop controls (`mid`, `first`, `hover-*`).

**Equal padding.** Matched within every army: `28 px` across vertical edges and `28.0 px` perpendicular between slanted edges on both diagonals (`190.26 px` row pitch) in `mid`, `first`, `fight`, and `after`. In `fight`, opposing front rows sit `56 px` tip-to-tip across the centre rail.

## 2. The frame, three takes

At `112 px` wide (blank and with art):

- **A:** Quieter than today's frame; upper two-thirds is dark lead. Six tiers separate clearly by colour and numeral; brass upper lead makes golden unmissable. Weakness: flat tier hierarchy—neutral top seals and equal coverage keep high tiers from popping over low ones. Bright cropped bottom glass and yellow-gold stat wells still slightly fight warm art.
- **D:** Quieter than today's frame; mostly lead. Six tiers read effortlessly via coloured top roundels and current bottom-third glass. Strongest high-tier prominence: from Tier 4, a coloured inner rim climbs the lead (thickest at 6), making T4–6 pop on a full board. Gilded upper lead makes golden unmissable (though a gold roundel hides its tier hue up top). Pale stat stones fight warm art less and separate stats from gold coins.
- **E:** Quietest overall; pewter lead with redrawn, vine-free bottom glass. Six tiers read cleanly (T5 gold and T6 orange-red sit close beside warm art). Thick gold upper bars make golden the most unmissable, and dark bronze/burgundy stat discs fight art least. Weakness: bottom-point petal scaling is too tiny at `112 px` to make high tiers pop.

**Ranking:**
1. **D** — Best meets quietness and high-tier salience (T4–6 inner rim + coloured roundel) while keeping current bottom ornament and calming stat wells.
2. **E** — Calmest with art and boldest golden, but petal scaling barely reads at `112 px`.
3. **A** — Faithful splice and clear golden, but flat tier hierarchy and loud gold stat wells trail D and E.

**Proportion:** **A third (`⅓`).** A quarter cuts or cramps stat wells; a half brings back noisy side glass and breaks majority-lead; a third clears the wells while keeping tier colour legible at `112 px`.

## 3. Defects in A's screens

1. **Overlap — Charge/Supply pips sit over the bottom stained-glass ornament** (`mid` back row slot 1 Wing Commander; `fight` enemy back slot 1 Weasel & your back slot 1 Wing Commander; `after` enemy back slot 1 Weasel; `first` shop slot 1 Sentry; `cards` & `extra1` Tier 5). Cream pips on bright Tier 5 yellow-gold petals (and grey pips on Tier 1 cream glass) blend into the ornament and are hard to count at `112 px`.
2. **Overlap — Buffed (`^`) and wounded (`v`) stat carets straddle the frame's vertical glass-and-lead edge** (`mid` front slots 1, 3, 4 & back slot 1; `fight` your front slots 1, 3 & back slots 1, 2; `after` enemy front slots 1, 3 & back slots 1, 2; `cards` Tiers 4–5). Each dark caret box cuts across the side bevel, while buffed green and wounded red digits on bright yellow-gold wells barely separate in hue from normal dark-brown stats at `112 px`.
3. **Crowding in the narrowed `310 px` left-light shop controls** (`mid`, `first`, `hover-shop`, `hover-board`, `hover-spell`, `keywords-off`, left light middle). Narrowing from `382 px` packs `Upgrade 23` and `Refresh 1 / 10 at this price` into ~`130 px` buttons where `10 at this price` nearly touches both inner edges (`padding: 0 4px`) and Upgrade's icon, label, and coin crowd the borders.
4. **Tight stat-well fit on wide two-digit numbers** (`fight` and `after` enemy back slot 2 Golden Gorger `38`/`68`, `after` enemy front slot 3 Holly Knight `24`/`27`; `cards` Golden `38`/`68`). At `18 px` serif inside ~`25 px` circular wells, wide two-digit values press against the inner disc rim.
5. **Misalignment — Seek in the hand floats well above its coin and off-axis from `1/7`** (`mid`, `hover-shop`, `hover-board`, `hover-spell`, `keywords-off`, bottom centre hand slot 1). The `84 px` round spell sits top-aligned in a `150 px` unit slot with a ~`22 px` void before its `3` coin (versus `10 px` in the shop), and `1/7` sits below the circle's centreline.

## 4. Next round

1. **Adopt D's `⅓`-glass frame direction with calmer, distinct stat discs** — bring in D's tier-coloured top roundel and T4–6 escalating inner rim over the bottom third of glass, and replace today's yellow-gold stat wells with neutral/distinct Attack and Health discs (D or E) sized cleanly for two-digit stats so buffed/wounded states read without carets straddling the bevel.
2. **Move Charge/Supply pips clear of the bottom glass ornament** — relocate pips off the bright bottom fleur-de-lis onto a dark, unobstructed anchor so 4–6 pips on Tier 5 and Tier 1 units are countable at a glance at `112 px`.
3. **Relieve the left-light shop-control squeeze and snug Seek's hand coin** — widen the side lights slightly from `310 px` (or re-stack Upgrade/Refresh cleanly) so button text breathes, nudge `Turn 9`/`Turn 1` clear of the top-left rose rim, and tighten Seek's coin gap in the hand to match the shop.

## 5. Ready?

**Yes.** The one deciding thing is that A's layout geometry and visual quietness are now genuinely locked in—round 3's dark ground, round 4's sizing and shop placement, round spells, and exact `28 px` equal gaps across and along both diagonals all hold together cleanly, so the remaining frame, pip, and left-light button fixes refine an already-solved screen rather than revisiting the layout.

**Disk:** `/data/ui-ideation/tmp/council-neon/` (`3.5M` total: ten PNG inspection crops — `crop_A_cards.png` 718K, `crop_E_cards.png` 616K, `crop_fight_boards.png` 464K, `crop_D_cards.png` 457K, `crop_mid_shop.png` 256K, `crop_left_hover_shop.png` 237K, `crop_mid_board.png` 223K, `crop_right_after.png` 198K, `crop_mid_hand.png` 174K, `crop_right_mid.png` 169K).
