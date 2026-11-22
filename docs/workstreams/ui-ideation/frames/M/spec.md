# Take M: the lead opens to hold the glass

Card units 560 × 1000; numbers in `make_guides.py`.

## 1. What the frame is for

Hold the art, show tier and stats, then step back: at 112 px the art must win.
- **Runeterra** (closest model): near full-bleed art, narrow metal rim, stats low in the corners; champion vs common changes the metal, not the layout.
- **Magic:** frame colour carries identity; a dark keyline divides art from frame.
- **Hearthstone:** rarity is small; legendary ornament breaks the silhouette at one point; golden changes the whole frame's material.
- **Canterbury, Bidston windows:** ornament sits in its own base band, set off by a bar.

## 2. Art to border

Today's art window is kept exactly, so painted art still fits: art is 81% of the card (Magic about 37%, Hearthstone about 30%, Runeterra above 80%; at 112 px Runeterra's share is right). Border about 31 units (6 px at 112 px): lead about 13%, glass about 5% (tier 1) to 7% (tier 6) with roundel rings.

## 3. Ornament

Only below the join and in the bottom crest. Above is one pewter came, drawn in code and identical on every tier: rounded, one highlight line, about 6 px at 112 px. The apex is plain. At 112 px only shapes survive, so the tier lives in band height and crest; piece detail is for the hover.

## 4. The join

The came's two rails part to hold the glass: the inner rail curves away in a leaf tip closed by a solder knot, so the glass grows out of the lead, not cut off. Both rails run unbroken, so the card reads as one piece of leadwork. A straight saddle-bar join is ordered for comparison (items 15, 16).

## 5. The tier ladder

Read at 112 px:
- **Colour:** pearl grey, strong leaf green, sapphire, violet, deep honey amber, ruby.
- **Height:** the join rises from y 704 (glass on the lowest 30%) to y 504 (50%), 40 units (8 px at 112) a tier. Code sets it (`build3.py`); the image tool would not.
- **Bottom crest:** none, bud, trefoil, trefoil with jewel, fleur with leaves, fleur with jewel and glow.

Pieces per side rise 1 to 6; glow from none to warm.

## 6. Golden

The metal changes, not the glass: the came turns pale, shiny gilt all the way round, so it reads on the whole silhouette. Lead between glass pieces stays dark, so each tier's colour holds. Tier 5's glass is deep honey, darker than the gilt.

## 7. Stats, tier mark, spell

- **Roundels:** one roundel drawn in code, the same on every tier: an ivory glass face (radius 58, 23 px at 112), a ring of the tier's glass, came round both, at (111, 766) and (449, 766). Gold means golden only.
- **Tier mark:** colour plus glass height. No numeral.
- **Spell:** a round came ring (radius 238), same rule: lower arc in tier glass with a small crest. No stats.

## What I would still fix

Round 3 assembles one master in code: the came, the roundel and the outline are identical on every tier. Only the glass and crest are generated.
- **Neighbouring tiers in greyscale still differ only by 8 px of glass.** Tiers 3 and 4 are closest.
- **The roundel rings are paler** than each tier's band glass.
- **The spells keep round 3's picture arcs.** Their joins follow the picture, not a fixed angle.
- **Tier 3's glass** comes from round 1, re-leaded in code.
- **Glow and sheen are not judged.**
