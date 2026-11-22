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

Round 4 (`build4.py`, version "flow"): the whole border is one cast-lead came, drawn in code, 31 units round the top and sides. The apex is plain; there is no bottom crest.

## 4. The join

At the join the came's two rails part in a leaf tip and the tier's glass opens between them. From there the band widens smoothly, by the glass only, to 62 units round the foot: the bottom is bigger but one piece with the sides. Glass is the generated strips (`prompts-4.txt`) laid along the band.

## 5. The tier ladder

Read at 112 px:
- **Colour:** pearl, leaf green, sapphire, violet, honey amber, ruby.
- **Height and mass:** the join rises from y 800 to y 500, 60 units (12 px at 112) a tier, so higher tiers carry more glass.
- Panes get shorter by tier.

## 6. Golden

The came turns modelled gilt, as wide as the lead, all the way round. The glass keeps its tier colour.

## 7. Stats, tier mark, spell

- **Roundels:** an ivory face (radius 54), a came, a ring of the tier's own glass, an outer came; on the band's lower corners at (74, 788) and (486, 788).
- **Tier mark:** colour plus glass height. No numeral.
- **Spell:** a round came (radius 238); the lower arc opens into tier glass the same way.

## What I would still fix

- **Tier 5 amber and tier 6 ruby sit close to warm art,** so on sunset or fire art the glass merges with the picture.
- **The strips' own lead lines cross the band at fixed steps,** not at pane ends, here and there.
- **Greyscale tiers 1 to 3 differ only by glass height.**
- **The lead's cast finish is a code profile;** at 300 px it reads smooth, not cast.
- **The "near" version is barely different at 112 px;** I show it only for the record.
- **Glow and sheen are not judged.**
