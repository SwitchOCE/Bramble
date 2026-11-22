## 1. Gaps

| Board | Upright sides (px) | ↘ edges (px) | ↗ edges (px) | Equal within 2 px? |
|---|---:|---:|---:|---|
| A `mid` | 28 | 28 | 28 | Yes |
| A `fight`, March Hare | 28 | 28 | 28 | Yes |
| A `fight`, player | 28 | 28 | 28 | Yes |
| D frame sheet | 25–26 | 29–30 | 29–30 | No, up to 4.7 px apart |
| E frame sheet | 27 | 27 | 27 | Yes |

Measured between occupied card bodies, square to each facing edge, with cast shadows and overlaid badges excluded. Values in the gap columns are rounded to whole pixels.

## 2. A unit shape

| Zone | Width × height (px) | Width ÷ height |
|---|---:|---:|
| Shop | 112 × 200 | 0.56 |
| Recruit board | 112 × 200 | 0.56 |
| Fight | 112 × 200 | 0.56 |
| Hand, unit-slot outline | 84 × 150 | 0.56 |

Seek is the occupied hand slot and renders as an 84 × 84 px circle.

## 3. Frame proportion at 112 px wide

| Concept | Coloured-glass footer, fraction of 200 px height | Lead, fraction of visible trim |
|---|---|---:|
| A | 31–32% (62–65 px from a nominal one-third cut) | ≈48–54% across tiers 1–6 (T3 ≈52%) |
| D | 31–32% (62–65 px from a nominal one-third cut). Tiers 4–6 also have a thin tier-coloured inner line that brings the colour span to 94–95% of card height. All six have a separate coloured tier disc. | ≈46–59% across tiers 1–6 (T3 ≈59%) |
| E | 31% (63 px from a nominal one-third cut) | ≈60–63% across tiers 1–6 (T3 ≈61%) |

Area uses frame paint with the pane, shadows and overlaid badges excluded. A and D reuse flattened art in the footer, so their lead estimates count its dark pixels below 0.03 relative luminance as cames.

## 4. A `mid` ground, round 5 versus round 3

| Place | Round-5 difference |
|---|---|
| Central pane, x353–1567 | A straight 13 px crossbar at y381 replaces the bar at y444. A second 13 px crossbar appears at y851 above the hand. |
| Central pane edges | Mullions move inward from x339 and x1581 to x353 and x1567. The curved leadwork follows the new edges at the head of the pane. |
| Central pane corners | The upper boughs move 15 px inward and 5 px down and scale from 0.78× to 0.74×. The lower boughs move 13 px inward and 27 px up. |
| Side panes | Each pane widens from 296 to 310 px. The top rosettes move 7 px toward the centre. The left horizontal seam moves from y566 to y534 and the right seam from y653 to y696. |

## 5. A defects

- `hover-spell`, x869–1194, y227–362. The Sharpen tooltip covers both stats and the 3-gold price on each of Sweetbriar and Shrew Cutpurse, hiding six numbers.
- `hover-shop` and `keywords-off`, x758–1083, y132–296. The Home Guard tooltip covers both stats on Hayloft Aunt and Sweetbriar and the Attack on Shrew Cutpurse, hiding five numbers.
- `after`, x803–1117, y952–997. Two card-detail lines appear at rest, giving Golden Gorger’s 38 Attack and 57 remaining Health and Holly Knight’s increase from 12 to 24 Attack.

**Disk** [/data/ui-ideation/tmp/check-sol](/data/ui-ideation/tmp/check-sol), 33,025,110 bytes for measurement scripts, render crops, geometry and browser scratch data.
