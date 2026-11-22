# Round 2 frame measurements

Measurements use the fitted PNGs at a 112 × 200 px card size, with the origin at the card box’s top left. Area shares use the filled silhouette at 50% alpha. The transparent opening counts as art, the stat discs are the light numeral faces, and tier glass includes its panes and ring insets. Glass and metal shares are estimates from RGB masks. Ornament dimensions are visible width × height for the smallest separate piece by area, excluding stat hardware and solder joints.

Side and slope widths are median thicknesses across the upper straight sections and perpendicular to the top slopes. Joins are fractions down the card. The measured row is where over 30% of the outer 0.6–5.0 px side strip first has RGB channel spread above 100 or mean RGB above 150. Positive steps mean the join rises, using the mean of the left and right joins. [Take M fitting code](/home/alex/.t3/worktrees/Bramble/ideation-ui-ux-dce1598bde386004/docs/workstreams/ui-ideation/frames/M/fit2.py)

Mean absolute pixel differences use each fitted frame composited over the same blank dark fill, resized to 112 × 200, and measured within the pair’s combined silhouettes, including the blank art opening. The scale is 0–255. Gilt colours are mean sRGB from the upper metal between y = 10 and 100 px. Glass colours are mean sRGB from the tier glass mask. ΔE is CIE76 in D65 Lab, and ΔL* is gilt minus glass.

## Take M

Area cells give normal / golden percentages. Lead widths are normal left / right in px.

| Tier | Art | Metal | Glass | Discs | Upper sides | Top slopes |
|---|---:|---:|---:|---:|---:|---:|
| 1 | 72.6 / 71.2 | 16.9 / 18.0 | 5.7 / 6.0 | 4.9 / 4.8 | 6.2 / 5.2 | 6.4 / 5.9 |
| 2 | 69.7 / 69.8 | 19.8 / 19.1 | 5.0 / 5.7 | 5.5 / 5.4 | 6.7 / 6.2 | 7.9 / 7.7 |
| 3 | 70.6 / 70.2 | 17.7 / 18.2 | 6.9 / 6.7 | 4.9 / 4.9 | 5.8 / 5.9 | 5.8 / 5.9 |
| 4 | 67.8 / 67.5 | 19.2 / 19.5 | 8.3 / 8.2 | 4.7 / 4.7 | 6.5 / 6.6 | 8.4 / 8.6 |
| 5 | 67.6 / 66.3 | 17.3 / 18.2 | 9.8 / 9.9 | 5.4 / 5.6 | 5.8 / 6.2 | 8.1 / 8.3 |
| 6 | 68.6 / 68.6 | 16.9 / 16.3 | 10.4 / 10.6 | 4.2 / 4.5 | 6.8 / 6.9 | 7.0 / 7.2 |

Upper lead varies by tier on both the sides and the slopes. Golden widths also vary, spanning 5.8–6.9 px on the sides and 5.5–8.7 px on the slopes.

| Tier | Join L / R | Step up, px | Attack diameter @ centre | Health diameter @ centre | Smallest ornament, px |
|---|---:|---:|---|---|---|
| 1 | .7045 / .7050 | — | 23.9 @ (22.1, 155.7) | 23.9 @ (89.6, 155.7) | 4.3 × 4.4, apex bead |
| 2 | .6715 / .6715 | 6.7 | 25.1 @ (23.0, 154.0) | 25.1 @ (88.9, 154.0) | 3.8 × 3.7, apex bead |
| 3 | .6255 / .6295 | 8.8 | 23.5 @ (22.2, 151.8) | 23.6 @ (89.6, 152.0) | 4.4 × 4.1, apex bead |
| 4 | .6155 / .6160 | 2.4 | 23.4 @ (21.6, 152.2) | 23.4 @ (90.1, 152.2) | 3.9 × 6.5, left side lozenge |
| 5 | .5820 / .5820 | 6.8 | 24.7 @ (22.2, 150.4) | 24.7 @ (89.4, 150.3) | 3.7 × 3.8, apex bead |
| 6 | .5560 / .5625 | 4.6 | 22.1 @ (21.9, 155.0) | 22.2 @ (89.4, 155.0) | 4.7 × 4.3, apex bead |

The normal disc diameters span 3.0 px across tiers. Centre x spans 1.4 px at attack and 1.2 px at health. Centre y spans 5.4 px at either disc. They exceed the 1 px tolerance. Within each tier, the golden disc differs from its normal counterpart by at most 0.9 px in diameter and 0.2 px on either centre axis.

**Greyscale mean absolute difference, normal frames** · 1–2 **11.2** · 2–3 **11.0** · 3–4 **7.7** · 4–5 **13.9** · 5–6 **16.1**

| Tier | Gilt RGB | Glass RGB | ΔE | ΔL* | Normal–golden difference, RGB / grey |
|---|---|---|---:|---:|---:|
| 1 | 184, 155, 90 | 184, 182, 179 | 37.3 | −8.8 | 18.5 / 20.5 |
| 2 | 204, 168, 85 | 150, 186, 24 | 41.3 | 0.0 | 18.8 / 21.3 |
| 3 | 196, 160, 87 | 5, 124, 236 | 107.5 | +15.1 | 15.0 / 16.9 |
| 4 | 185, 149, 77 | 170, 46, 233 | 133.5 | +16.2 | 16.5 / 18.6 |
| 5 | 180, 146, 76 | 216, 148, 15 | 30.3 | −4.1 | 15.6 / 17.6 |
| 6 | 207, 167, 68 | 219, 56, 18 | 60.7 | +20.8 | 15.2 / 17.4 |

Tiers below ΔE 20 **0 of 6**.

## Take N

Area cells give normal / golden percentages. All six tiers have the same upper widths within each state. Normal lead is 7.3 / 7.4 px at the sides and 9.2 / 9.5 px at the slopes. Golden gilt is 7.2 / 7.7 px at the sides and 9.1 / 9.1 px at the slopes.

| Tier | Art | Metal | Glass | Discs | Join L / R | Step up, px | Smallest ornament, px |
|---|---:|---:|---:|---:|---:|---:|---|
| 1 | 68.6 / 68.6 | 20.5 / 20.7 | 7.3 / 7.1 | 3.7 / 3.6 | .7255 / .7260 | — | 8.3 × 10.7, base diamond |
| 2 | 70.3 / 70.3 | 19.6 / 18.9 | 6.5 / 7.2 | 3.7 / 3.6 | .7020 / .7020 | 4.8 | ≈18 × 14, lower corner pane beside disc |
| 3 | 68.5 / 68.5 | 19.9 / 19.7 | 7.9 / 8.2 | 3.7 / 3.6 | .6785 / .6790 | 4.7 | 4.3 × 17.1, upper side petal |
| 4 | 67.6 / 67.6 | 19.2 / 18.9 | 9.5 / 10.0 | 3.7 / 3.6 | .6610 / .6605 | 3.6 | ≈19 × 8, lower-slope petal |
| 5 | 68.7 / 68.5 | 18.9 / 19.2 | 8.7 / 8.7 | 3.7 / 3.6 | .6765 / .6780 | −3.3 | 9.6 × 5.9, upper-left petal in base flower |
| 6 | 67.6 / 67.6 | 19.1 / 17.8 | 9.7 / 11.1 | 3.7 / 3.6 | .6340 / .6335 | 8.7 | 5.6 × 5.6, base bead |

The disc faces match within 1 px across all tiers and both states. Every normal tier measures 20.91 px in diameter at (21.66, 156.79) and (90.46, 156.79). Every golden tier measures 20.66 px at (21.67, 156.66) and (90.47, 156.66).

**Greyscale mean absolute difference, normal frames** · 1–2 **8.3** · 2–3 **5.3** · 3–4 **4.9** · 4–5 **8.3** · 5–6 **9.5**

| Tier | Gilt RGB | Glass RGB | ΔE | ΔL* | Normal–golden difference, RGB / grey |
|---|---|---|---:|---:|---:|
| 1 | 211, 184, 143 | 194, 191, 183 | 20.3 | −1.3 | 23.3 / 24.9 |
| 2 | 211, 184, 143 | 126, 174, 16 | 58.1 | +10.5 | 21.4 / 22.9 |
| 3 | 211, 184, 143 | 9, 112, 228 | 95.0 | +27.5 | 22.6 / 24.1 |
| 4 | 211, 184, 143 | 175, 29, 221 | 120.0 | +30.2 | 22.7 / 23.9 |
| 5 | 211, 184, 143 | 230, 149, 14 | 51.1 | +7.9 | 21.6 / 22.9 |
| 6 | 211, 184, 143 | 206, 34, 23 | 72.4 | +31.5 | 21.5 / 22.8 |

Tiers below ΔE 20 **0 of 6**. Tier 1 is 0.3 above the cutoff with this mask.

## Comparison

The normal art opening spans 67.6–72.6% in M and 67.6–70.3% in N. The study gives 68% art, 27% frame and 5% discs for today’s Bramble frames. The study’s framed Magic examples give 37–42% art and its Battlegrounds board token gives about 80%. Lead accounts for approximately 62–80% of M’s normal lead-plus-glass area and 66–75% of N’s. [Frame study, section 1](/home/alex/.t3/worktrees/Bramble/ideation-ui-ux-dce1598bde386004/docs/workstreams/ui-ideation/frames/study.md)

## Defects

**M**

- Tier 1, upper slopes in both states. The opening extends beyond the art clip, exposing about 53 px² of background in normal and 58 px² in golden, up to 1.9 px deep.
- Tier 3, under the apex in both states. The same gap exposes about 26 px² in normal and 18 px² in golden, up to 1.3 px deep.
- Tier 6 normal, under the apex. The gap exposes about 7 px² of background, up to 0.6 px deep.
- Tier 3, glass immediately below both side joins in both states. The fitted vertical scale is 0.457× left and 0.576× right. Horizontal scale is 1.000×.
- Tiers 3 and 6 normal, apex beads. The fitted outline clips about 13% and 10% of the source bead’s coloured area, respectively.
- Tier 4, outer silhouette in both states. At 50% alpha the visible bounds are 111.2 × 197.5 px, or 0.5630 wide to 1 tall. That is 0.6 px wider than 0.56 at the measured height. [M at 300 px](/data/ui-ideation/frames/M/r2/large.png)

**N**

- Tiers 1, 3 and 4, above both stat discs in both states. An exposed arc of the original rim extends outside the 12.8 px radius stamp. Maximum protrusions are 2.8, 2.8 and 3.0 px, respectively.
- Tiers 2, 5 and 6, above both stat discs in both states. The original rim extends beyond the stamp by up to 1.1, 2.1 and 1.5 px, respectively. [N at 290 px](/data/ui-ideation/frames/N/r2/large.png)

At 50% alpha, the art clip extends 0 px² outside the outer silhouettes in both takes. N’s visible bounding boxes are 112 × 200 px in all 12 frames.

**Disk** · [Scratch directory](/data/ui-ideation/tmp/check-sol-frames), 5,460,989 bytes total. Diagnostic images 5,448,869 bytes across 19 files. [Measurement script](/data/ui-ideation/tmp/check-sol-frames/measure.py) 7,871 bytes. [Defect script](/data/ui-ideation/tmp/check-sol-frames/defects.py) 2,458 bytes. [Detail script](/data/ui-ideation/tmp/check-sol-frames/extra.py) 1,791 bytes. [Empty scratch file](/data/ui-ideation/tmp/check-sol-frames/inspect.py.tmp) 0 bytes.
