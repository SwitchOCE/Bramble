# Frame study: how other card games and real windows build a frame

Research for the frame pass (brief `../briefs/22-frame-study.md`), 22 Nov 2026. Not decided.

Studied: 22 card pictures from 7 games and 4 windows (Chartres *Belle Verrière*; Kempe at Boston and Bakewell; Morris & Co. at Bidston), plus Bramble's six frames (`docs/design/art-direction/frame-lab/final/`) and the rejected attempt (`/data/ui-ideation/concepts/A/p2r5/cards.png`). Pictures and sources: `/data/ui-ideation/frames/study/` (not in Git).

Bramble's numbers are counted from pixels; others are read off a 5% grid, good to about ±3 points. Thickness is a fraction of card **width**; "below art" includes text boxes.

## 1. How much is frame

| Card | Art | Frame | Text / stats | Top | Sides | Below art |
|---|---|---|---|---|---|---|
| Magic, normal (Llanowar Elves) | 39% | 28% | 33% | 0.15 | 0.07 | 0.62 |
| Magic, legendary crown (Squee) | 39% | 28% | 33% | 0.15 | 0.07 | 0.62 |
| Magic, storybook showcase (Bonecrusher Giant) | 37% | 32% | 31% | 0.15 | 0.09 | 0.62 |
| Magic, stained-glass showcase (Astor) | 42% | 25% | 33% | 0.14 | 0.04 | 0.62 |
| Magic, borderless (Ao) | 58% | 2% | 40% | 0.02 | 0.02 | text floats on art |
| Hearthstone / Battlegrounds card (Argent Squire, Leeroy, Wrath Weaver, Brann) | 32% | 25% | 43% | ~0.03 (oval breaks the top) | 0.15 at the oval's widest | 0.66 |
| Battlegrounds **board token** (oval, ~110 px wide) | ~80% | ~12% | ~8% | 0.05 | 0.05 | 0.05 + gems |
| Runeterra follower (Tianna) | ~85% | ~5% | ~10% | 0.02 | 0.02 | stat bar 0.12 |
| Runeterra champion (Garen) | ~82% | ~8% | ~10% | 0.03 + name plate | 0.03 | stat bar 0.12 |
| Gwent (gold card) | ~86% | ~4% | ~10% | 0.02 | 0.02 | 0.02 |
| Marvel Snap (Iron Man) | ~80% | ~6% | ~14% | 0.03 | 0.03 | name breaks the rim |
| Slay the Spire (Bash, Bludgeon) | ~24% | ~32% | ~44% | 0.20 | 0.15 | 0.64 |
| **Bramble today** (frame-lab tiers 1–6) | 68% | 27% | 5% (roundels) | 0.07 on the slopes; 0.26 at the point with its finial | 0.07 | 0.10 (tier 1) to 0.23 (tiers 3–6, bottom fleur) |
| **Rejected attempt** (p2r5, 109 px on screen) | ~82% | ~12% | ~6% | 0.023 lead (2–3 px) | 0.023 lead; 0.04 glass in the bottom third | 0.06 + fleur 0.12 |

Reading cards (Magic, Hearthstone, Slay the Spire) give art a third; board pieces (Battlegrounds token, Runeterra, Gwent, Snap) 80% or more. Bramble's board card has no text, so it is a board piece. The Battlegrounds token, the only reference seen at Bramble's size, has a rim of ~5% of width (5–6 px).

## 2. Where the ornament goes

| Card | Ornament places | Plain |
|---|---|---|
| Magic normal | 0 (bevels only) | everything |
| Magic legendary | 1: crown along the top | sides, base |
| Magic storybook | 4+: vines on every edge, corners, text box | almost nothing |
| Hearthstone legendary | 1: dragon wrapped over the top of the oval | stone sides, text box |
| Runeterra champion | 2: name plate at top, gold corners | sides |
| Slay the Spire | 1: title banner | body, text panel |
| Kempe windows | 2: canopy above, base panel below | narrow side borders, quarry ground |
| Morris / Bidston | 2: leaf band at top, small strip at the foot | the whole figure ground |
| Bramble today | 4–5: top fleur, drop, side vines, roundel rings, bottom fleur | nothing at tiers 2–6 |

Rich: ornament on one or two structural points, long edges plain, and a step quieter than the picture (Kempe's canopies are white and silver-stain glass, so the coloured figure leads). Noise: ornament along every edge at the art's strength (Magic storybook, Bramble tiers 2–6), or pieces under ~3 px at play size (storybook vines are ~2 px at 120 px). Hearthstone's dragon still reads on a ~110 px token because it changes the **silhouette** in large pieces.

## 3. How rank or rarity shows

| Game | What changes from low to high | Reads at ~120 px? |
|---|---|---|
| Magic | set-symbol colour; crown for legendary | symbol no; crown barely |
| Hearthstone | gem on the name banner; dragon for legendary | gem no; dragon yes |
| Battlegrounds | tier stars on a pennant, in the shop only; nothing on the board | stars barely; board none |
| Runeterra | small gem at the bottom; champion gets a plate and a heavier frame | gem no; plate partly |
| Gwent | rim colour, bronze or gold | weakly (2–3 px of colour) |
| Slay the Spire | colour of the banner and the art window's rim: grey, blue, gold | yes: large areas |
| Snap | finish (frame break, 3D, animation, foil) | frame break yes; rest not judged from stills |
| Bramble today | colour of the whole frame, plus fleurs that grow | colour yes; tiers 5 and 6 only by hue |

Large colour areas (Slay the Spire's banner, ~7% of the card) and silhouette changes read small; gems, symbols and star counts do not.

## 4. Joining two zones

Looks made: each zone is a closed piece with its own edge. Magic's bars are bevelled boxes; Hearthstone's banner overlaps the oval and runs past the frame; Kempe's canopy rests on side shafts and the base on a sill, so nothing ends in mid-air. Bidston's leaf band stops at a hard line, but it crosses the whole light along a saddle bar, so it looks built.

Looks cut off: the rejected attempt. Its blue glass starts with a square end partway up a 2 px rim, with nothing marking the joint. A hard line works if it crosses the whole card as lead; a band ending mid-edge needs a cap, knot or taper.

## 5. Golden and premium

- Hearthstone: the whole frame changes material, stone to gold; shapes, gems and dragon stay. Sheen: not judged from stills.
- Battlegrounds board: the token rim turns gold with a warm glow; at ~110 px the strongest signal on the board.
- Gwent premium, Snap finishes, Magic foil: not judged from stills.
- No clash because the signals live in different parts: Hearthstone's rarity gem sits on the banner, away from the gold; Slay the Spire puts class in the body, rarity in the trim.
- Rejected attempt: golden is a flat tan line, 3–4 px. It reads as a yellow outline, not metal, and meets the purple glass at the same square cut.

## 6. Ten rules for Bramble's frame

1. Art fills 70–80% of the card (Battlegrounds token, Runeterra): the board card has no text.
2. Lead rim at least 5 px at 120 px wide, ~0.045 of width (Battlegrounds token); 2–3 px reads as a UI outline.
3. Ornament in at most two places, top finial and base (Kempe canopy and base); long sides plain lead.
4. Rank is the colour of one large glass area, at least ~8% of the card (Slay the Spire banner), not gems or dots.
5. Top tiers add one silhouette change, not more vines (Hearthstone legendary dragon).
6. Close the glass zone with a lead bar across the whole card (Bidston's leaf band on its saddle bar).
7. Glass climbing the sides narrows to lead width and ends on a knot or boss (Kempe shafts under the canopy); never a square end mid-side.
8. Frame glass a step lighter or quieter than the art (Kempe's white and silver-stain canopies).
9. No ornament piece under 6 px at 120 px wide (Hearthstone dragon reads; Magic storybook vines don't).
10. Golden changes the metal, not the glass: gilt lead with a highlight, tier colour kept, whole outline brighter (Hearthstone stone-to-gold; Battlegrounds gold rim).
