You are making stained-glass effect sprites for a woodland auto-battler game's fight screen. Use your built-in image generation tool. For EACH of items 1 to 11 below, generate exactly one image, then copy the PNG into the current working folder under the given filename, overwriting any existing file. One item at a time. Items 12 to 15 are assembled, not generated: for those only, you may write and run one short Python script with Pillow. Write no other code or files. No text, letters, numerals, logos, borders or watermarks in any image. Every design is original: do not imitate any existing game's thorns, vine, whip or hit effect. Reply with just the saved filenames, and for each generated item one line on whether it matches its description.

Images to attach or open:
- STYLE reference: /home/alex/.t3/worktrees/Bramble/ideation-fight-animatio-00275232188037a9/docs/design/art-direction/examples/glass-concept.jpg. Match its glass, its lead lines and its glow. Do NOT copy its hexagon, its border of coloured panes, its badges or its fox.
- BASE frames for items 12 to 15, all 1920 x 1080, the real game at real size, in /data/fight-anim-work/thorns-look/base/. Do not regenerate or repaint them: items 12 to 15 paste sprites onto them.
  - base-c-f193.png: a pale-framed plant card (the defender, "Nettle Sprout") at the top, and below it a green-framed orange card (the attacker) raised and slightly enlarged, with a red jagged damage star reading "-2" on it.
  - base-d-f322.png: the same plant card at the top, and a different attacker (a pale-framed green grasshopper card) raised diagonally below and to the right, with a "-2" star on it.
  - base-c-today-f178.png: the attacker card one frame from touching the plant card from below, its top point overlapping the plant card's bottom point.
  - base-c-f172.png: the attacker raised below the plant card, nothing else.

STYLE for every generated item: real leaded stained glass, lit from behind. Every colour area is its own chunky piece of glass, outlined by dark grey-black lead came (#16120e) of slightly uneven weight: thick round the outside of the shape, thinner inside it. Each piece is one colour of glass with a little streak, ripple and seed-bubble texture and a soft back-lit glow; at most one darker shade per piece, no gradients across the whole shape. Big simple pieces and few of them, never tiny fragments, no fine linework. These are small effect sprites that will be shown 12 to 60 pixels tall on a 1080p screen, so shapes must read as clear silhouettes when shrunk: bold, simple, high contrast. A thorn is always one sharp triangular piece of glass with its own lead outline, never a drawn line.

BACKGROUND for every generated item: one perfectly flat, pure magenta (#FF00FF), edge to edge, with no shadow, glow spill, vignette, texture or gradient on it, so it can be keyed out. Keep every shape at least 8% of the image width away from the edges. Never use magenta, pink or purple glass anywhere in a shape.

PALETTE, shared by every item: lead #16120e. Bramble cane glass is RUSSET, not green: mid #8a3a22, light streak #c0623a, dark #4e1d12. Thorns are bone-white glass (#f2e6c4) shading to russet (#8a3a22) at their base, like rose thorns. Leaves, only where an item asks for them, are deep dull green (#2a5228, #3f6a30). Never use bright red, gold, yellow or bright green, and never a white or golden glow core: the game already uses red for damage numbers, gold for combo counts and bright green for stat gains.

Items:

Direction A, "lash": a bramble vine whips out of the defending card and strikes the attacker. The vine is built in the game from short segments laid end to end along a curve, so items 2 to 4 must join seamlessly end to end.

1. thorns_bud.png -- Square 1:1. The knot where the vine breaks out of a card: a tight twist of russet cane, roughly round, with three small pointed deep-green leaves fanning out of it and two bone thorns jutting from it. Compact; fills a circle about 70% of the image width. Bold and simple: about six glass pieces in all.
2. thorns_seg_1.png -- Wide 2:1. One straight length of bramble cane lying exactly horizontal, running from the left edge margin to the right edge margin, of even thickness about one quarter of the image height, in one russet glass piece with a light streak along its top. One bone thorn sticks up from the upper edge, a little left of centre, and one points down from the lower edge, a little right of centre, each about as long as the cane is thick, leaning towards the right. Both ends of the cane are cut square and capped with a lead joint, so segments can be laid end to end.
3. thorns_seg_2.png -- Same as item 2, same cane thickness, same square lead-capped ends at the same height, but the cane has a slight twist (a diagonal lead line across it, dividing it into a lighter and a darker piece) and the thorns are placed differently: two on the upper edge, none below.
4. thorns_seg_3.png -- Same as item 2, same cane thickness and ends, with one small bud-knot bulge in the middle of the cane and one thorn on the lower edge only.
5. thorns_tip.png -- Wide 2:1. The striking end of the vine, pointing RIGHT. On the left, a square lead-capped end the same thickness as items 2 to 4. The cane then narrows and curls into a tight hook at the right, like a bramble tip, ending in one large bone thorn that points right and slightly down, the biggest thorn of the set. Two small thorns along the curl.
6. thorns_impact_1.png -- Square 1:1. The moment a thorn bites: a small dark russet star (#4e1d12 body, #c0623a edges) of five short points, with three bone thorns driven into it from the upper left, all pointing in roughly the same direction, toward the lower right. No white or golden core, no rays. Compact; fits in a circle about 65% of the image width.
7. thorns_impact_2.png -- Square 1:1. The same bite four frames later: the russet star has broken into four or five separate pieces drifting apart, and the three thorns have splintered into smaller bone shards scattered outward with clear magenta gaps between them; slightly dimmer. Fills a ring about 85% of the image width.

Direction B, "prick": a row of thorns grows along the defending card's edge, and the attacker strikes into it.

8. thorns_bristle_1.png -- Wide 3:1. A short straight russet stem lying exactly horizontal along the top third of the image, with five small bone thorns half grown, all pointing straight DOWN, evenly spaced. The thorns are short stubs, about half the stem's length apart.
9. thorns_bristle_2.png -- Wide 3:1. The same stem in the same place, with the same five thorns fully grown: long, sharp, pointing straight DOWN and fanning very slightly outward at the two ends, each about twice as long as the stem is thick.
10. thorns_prick.png -- Square 1:1. The moment the attacker lands on the thorns: a small dark russet star of six short points with three long bone thorns piercing it from below, pointing UP and slightly apart. No white or golden core, no rays. Compact; fits in a circle about 70% of the image width.

Direction C, "volley": the defender flings thorns.

11. thorns_dart.png -- Wide 3:1. One single flying thorn pointing RIGHT: a long, slim, sharp bone-white glass thorn shading to russet at its broad left end, in two glass pieces, with a thick lead outline. Nothing else.

Mock-ups, assembled with Pillow (no generation). Keep each base frame at 1920 x 1080.

For every sprite:
- Key out the magenta background with a soft edge: treat pixels within about 60 RGB units of #FF00FF as transparent, then shrink the alpha by one pixel and blur it by one pixel, so no pink fringe is left.
- Crop it to its visible pixels.
- Scale it with LANCZOS to the WIDTH given, keeping its aspect.
- To rotate it, use Image.rotate(-a, expand=True, resample=BICUBIC), where a is the direction in degrees measured on screen (y down) as math.degrees(math.atan2(dy, dx)).
- Paste it centred on the point given.

All points are pixels on the base frame. Save each mock-up as a PNG, plus a 2x crop named with "_zoom" of the region given.

Laying a vine along a curve: sample the quadratic Bezier B(t) = (1-t)^2 P0 + 2(1-t)t P1 + t^2 P2 at 400 steps and measure its arc length L.
- Segments: put a segment centre every 38 px of arc length, starting 22 px from P0 and stopping before L - 30. Cycle thorns_seg_1, _2, _3 in that order, each scaled to 44 px wide and rotated to the curve's direction at its centre.
- Tip: thorns_tip.png scaled to 44 px wide, rotated to the curve's direction at t = 1, centred on the point 18 px back along the curve from P2.
- Bud: thorns_bud.png scaled to 44 px wide, not rotated, centred on P0.
- Order: paste the segments, then the tip, then the bud.

12. mock_A_lash.png on base-c-f193.png. Direction A at the bite, straight across.
    - The vine runs from P0 = (884, 518), the plant card's bottom point, through the control point P1 = (962, 560), to P2 = (850, 604).
    - Then paste thorns_impact_1.png, 52 px wide, centred on (846, 598).
    - Nothing pasted may come within 52 px of (884, 676), the centre of the "-2" star. Nothing may touch the plant card's two number discs, centred near (841, 461) and (925, 461), radius 20.
    - Zoom region: x 700 to 1100, y 300 to 760.
13. mock_A_lethal.png on base-d-f322.png. Direction A, a diagonal lash that kills.
    - The vine runs from P0 = (886, 518) through P1 = (975, 522) to P2 = (990, 598), so it travels along the dark lead strip between the two boards and then strikes down onto the grasshopper card's upper-left face.
    - Then paste thorns_impact_1.png, 60 px wide, centred on (986, 592).
    - Nothing pasted may come within 52 px of (1041, 675), the centre of the "-2" star, or touch the plant card's number discs at (841, 461) and (925, 461).
    - Zoom region: x 780 to 1180, y 300 to 760.
14. mock_B_prick.png on base-c-today-f178.png. Direction B at the moment the attacker lands on the thorns.
    - Paste thorns_bristle_2.png, 52 px wide, rotated with Image.rotate(-42, expand=True, resample=BICUBIC) so its thorns point down-left, centred on (862, 507), along the plant card's lower-left edge.
    - Paste it again, rotated with Image.rotate(42, expand=True, resample=BICUBIC) so its thorns point down-right, centred on (906, 507), along the lower-right edge.
    - The thorns overlap the attacker's top edges: that is intended.
    - Then paste thorns_prick.png, 56 px wide, centred on (884, 498).
    - Zoom region: x 700 to 1100, y 300 to 700.
15. mock_B_bristle.png on base-c-f172.png. Direction B's warning during the attacker's hold.
    - The same two bristles as item 14 (thorns_bristle_2.png), at the same points and rotations, so the full row of thorns shows with nothing over it.
    - Nothing else.
    - Zoom region: x 700 to 1100, y 300 to 760.
