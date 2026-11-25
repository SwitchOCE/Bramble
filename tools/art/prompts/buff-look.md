You are making stained-glass effect sprites for a woodland auto-battler game's fight screen: the pieces that show a unit gaining Attack or Health. Use your built-in image generation tool. For EACH of items 1 to 6 below, generate exactly one image, then copy the PNG into the current working folder under the given filename, overwriting any existing file. One item at a time. Items 7 to 10 are assembled, not generated: for those only, you may write and run one short Python script with Pillow. Write no other code or files. No text, letters, logos, borders or watermarks in any image, and no numerals except in the two glyph sheets (items 1 and 2). Every design is original: do not imitate any existing game's buff, stat or number effect. Reply with just the saved filenames, and for each glyph sheet say whether every glyph came out right.

Two images are attached.
- STYLE reference: /home/alex/.t3/worktrees/Bramble/ideation-fight-animatio-00275232188037a9/docs/design/art-direction/examples/glass-concept.jpg. Match its glass, its lead lines and its glow. Do NOT copy its hexagon, its border of coloured panes, its badges or its fox.
- BASE frame for items 7 to 10: /data/fight-anim-work/buff-look/base/base-brock-f566.png (1920 x 1080, the real game at real size). The red-framed badger card in the lower board is Old Brock. Six friendly cards around him have just died, so their slots are empty. His Attack disc (a diamond, "10") and Health disc (a shield, "9") sit at the bottom of his card. Do not regenerate or repaint this frame: items 7 to 10 paste sprites onto it.

STYLE for every generated item: real leaded stained glass, lit from behind. Every colour area is its own chunky piece of glass, outlined by dark grey-black lead came (#16120e) of slightly uneven weight: thick round the outside of the shape, thinner inside it. Each piece is one colour of glass with a little streak, ripple and seed-bubble texture and a soft back-lit glow; at most one darker shade per piece, no gradients across the whole shape. Big simple pieces and few of them, never tiny fragments, no fine linework. These are small effect sprites that will be shown 20 to 70 pixels tall on a 1080p screen, so shapes must read as clear silhouettes when shrunk: bold, simple, high contrast.

BACKGROUND for every generated item: one perfectly flat, pure magenta (#FF00FF), edge to edge, with no shadow, glow spill, vignette, texture or gradient on it, so it can be keyed out. Keep every shape at least 8% of the image width away from the edges. Never use magenta, pink or purple glass anywhere in a shape.

PALETTE, shared by every item: lead #16120e. Gain glass is green: light #a6ef84, mid #5fae45, deep #2c6a20. Cream glass #fbffef to #f3ead2. Gold silver-stain glass #fff2c4 to #ffd98a to #d88a17. Never use red: red means damage in this game.

GLYPH SHEETS (items 1 and 2): Wide 4:3. A 4-column by 3-row grid of separate glyphs, all the same height, with a clear magenta gap round each. Row 1, left to right: 0 1 2 3. Row 2: 4 5 6 7. Row 3: 8 9 then a plus sign (an upright cross with arms of equal length, a little smaller than the digits), and the last cell empty. Plain, upright, heavy, very legible figures with open counters; no serifs or swashes; the 1 has a short flag and no base; the 4 is open at the top; the 7 has no bar. Every glyph must be correct: check each one and generate the sheet again if any is wrong or missing.

Items:

The gain tag, two looks: figures on their own, or figures on a small plaque.

1. gain_glyphs_green.png -- GLYPH SHEET. Each glyph is cut from one or two pieces of green glass: light green (#a6ef84) in the upper piece, mid green (#5fae45) in the lower piece. It has a thick lead came outline of even weight all round, so it reads on top of busy card art.
2. gain_glyphs_cream.png -- GLYPH SHEET. Each glyph is a single piece of cream glass (#fbffef) in a thinner lead came outline, made to sit on the green plaque of item 3.
3. gain_plaque_green.png -- Wide 12:5. One small plaque, flat-on: a long lozenge with rounded ends, in green glass. The body is mid green (#5fae45). A narrow lighter strip (#a6ef84) runs along the top edge as its own leaded piece. There is a thick lead came round the whole outline. The middle is plain and empty, ready for figures. Nothing else.
4. gain_plaque_gold.png -- The same plaque as item 3, in the same shape and pieces, but in gold silver-stain glass: body #ffd98a, top strip #fff2c4, a slightly darker #d88a17 rim piece. This is the version for a gain that lasts beyond the fight.

The disc flare: shown round a stat disc for 8 frames as a gain lands. It must never cover the number in the middle.

5. disc_flare_1.png -- Square 1:1. A halo of light round an empty centre. The inner 45% of the image width is a plain magenta circle, with nothing in it. Round it is a thin ring of pale green-gold glass (#e8f7c0), cut into six to eight leaded segments. From that ring, eight short sharp rays point outward, each a single long thin leaded piece tapering to a point: four longer rays in an upright cross and four shorter diagonal ones, in light green (#a6ef84) and pale gold (#fff2c4) alternately. Everything fits in a circle about 80% of the image width.
6. disc_flare_2.png -- Square 1:1. The same flare four frames later. The ring has widened, so the empty centre is now 55% of the image width. The ring has broken into its separate segments with small gaps between them. The rays are half as long and a little further out. It is dimmer: the glass is one shade deeper (#5fae45 and #ffd98a). Same layout as item 5.

Mock-ups, assembled with Pillow (no generation). Open the BASE frame at full size (1920 x 1080) and keep it at 1920 x 1080.

For each sprite:
- Key out the magenta background with a soft edge. Treat pixels within about 60 RGB units of #FF00FF as transparent, then shrink the alpha by one pixel and blur it by one pixel, so no pink fringe is left.
- Crop it to its visible pixels.
- Scale it with LANCZOS to the size given.
- Paste it centred on the point given.

To build a number such as "+14" from a glyph sheet: cut each glyph cell, key it, crop it, scale every glyph to the height given, and set them left to right 2 px apart, bottoms aligned. The plus sign is 80% of the digits' height and vertically centred on them.

All points are pixels on the base frame. Old Brock's card spans x 1118 to 1258 and y 560 to 806. His Attack disc is centred at (1145, 754) and his Health disc at (1230, 753); each is about 36 px across. Nothing you add may cover either disc's middle 24 px.

Save each mock-up as a PNG. For each, also save a 2x crop of the region x 640 to 1300, y 600 to 840, named with "_zoom".

7. mock_flight.png -- The first gain in flight, from the dead Sentry's empty slot towards Brock. Build "+2" and "+5" from gain_glyphs_green.png with the digits 20 px tall. Centre "+2" on (964, 718) and "+5" on (1048, 718). Brock's discs are unchanged.
8. mock_flare.png -- The second gain landing. Paste disc_flare_1.png at 66 px wide on each disc: centred on (1145, 754) and on (1230, 753). Build the running total, "+5" over Attack and "+10" over Health, from gain_glyphs_green.png with the digits 22 px tall. Centre "+5" on (1145, 716) and "+10" on (1230, 715).
9. mock_tally.png -- The final tally after six gains. Build "+14" and "+24" from gain_glyphs_green.png with the digits 22 px tall. Centre "+14" on (1145, 716) and "+24" on (1230, 715). Then make a second version, mock_tally_plaque.png:
   - Build the same numbers from gain_glyphs_cream.png with the digits 18 px tall.
   - Scale gain_plaque_green.png to 28 px tall and 14 px wider than its number.
   - Paste each plaque centred on the points above, then its number centred on it.
10. mock_tally_gold.png -- As mock_tally_plaque.png, but with gain_plaque_gold.png in place of the green plaque.
