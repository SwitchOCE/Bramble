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

Round 5 (`build5.py`): round 4's "flow" outline, unchanged in shape. The whole border is one came, 31 units round the top and sides, cast: an H-section with broken highlights, a slight wobble, oxide in the low parts. The apex is plain.

## 4. The join

At the join the came's rails part in a rounded leaf tip and the glass opens between them, widening smoothly to 68 units round the foot. The glass is cut into panes in code, each edged in lead, with solder where pane lines meet the rails. Each pane takes its colour and streaks from one pane of the generated strips (`prompts-4.txt`), with their lead painted out.

## 5. The tier ladder

Read at 112 px:
- **Colour:** clear glass, leaf green, sapphire, violet, honey amber with green leaves, ruby.
- **Height and mass:** the join rises from y 800 to y 500, 60 units (12 px at 112) a tier.
- **Cutting, read at hover:** long quarries; wedges; chevrons; split chevrons; leaves; leaves with jewels. A keystone jewel at the foot from tier 3.

## 6. Golden

The same came in modelled gilt. The glass keeps its tier colour.

## 7. Stats, tier mark, spell

- **Roundels:** an ivory face (radius 54), a came, a ring of eight cut panes of the tier's glass, a cast collar; at (74, 788) and (486, 788).
- **Tier mark:** colour, glass height, cutting. No numeral.
- **Spell:** a round came (radius 238); the lower arc opens into cut tier glass the same way.

## What I would still fix

- **Tier 6 ruby still meets warm art** in colour; only the dark inner rail separates them.
- **Tier 3 reads more cyan than sapphire** at 112 px, because its lighter panes are teal.
- **Greyscale tiers 2 to 4 differ mostly by glass height;** the cutting shows only from about 200 px.
- **The cast finish is a code profile.** It reads as lead at hover but has no real casting marks.
- **Glow and sheen are not judged.**
