# Take N: round 1, judged

Renders are in `/data/ui-ideation/frames/N/`:
- `sheet.png`: tiers at 112 and 128 px, blank and with art.
- `sheet-2.png`: the board, the spells and the hover card. These did not fit on one 1920 × 1080 sheet.
- `large.png`: tiers 1–6 and golden, at 290 px.
- `compare.png`: art to border against today's frame and the references.

Cut frames are in `cut/`.

## What works at 112 px

- The art leads. The upper frame is quiet, and the top point carries nothing.
- Tier colour reads at a glance in the base: grey, green, blue, purple, yellow, red.
- Golden reads at once on every tier, because the whole outline turns gold. Golden tier 5 still separates from normal tier 5, because the normal card's upper lead is dark.
- The ivory discs and their numerals are clear at 112 px.

## What falls short

See "What I would still fix" in `spec.md`.

## Against the study's ten rules

- **Followed:**
  - 1: the art is 78% of the card.
  - 3: ornament sits in one place, the base, and the top is plain.
  - 4: rank is the colour of the base.
  - 9: from round 2 nothing is under 6 px, since the beads go.
  - 10: golden changes the metal and keeps the glass.
- **Rule 2 (rim at least 5 px):** the band is 6–7 px at 112 px, but round 1 drew it as two thin lines. Round 2 asks for one solid came.
- **Rule 5 (a silhouette change for top tiers): not followed.** The card's outline is fixed. Top tiers grow the bottom ornament instead, which reads at 112 px for tiers 5 and 6.
- **Rule 6 (a lead bar across the card): not followed.** A bar would cut through the art. The outer came running unbroken round the card does that job.
- **Rule 7 (the glass ends on a knot or boss):** partly followed. The glass ends in a tapered point tucked under the outer came. Tier 1 had a flat end, which round 2 fixes.
- **Rule 8 (frame glass quieter than the art): not followed.** The owner wants the tier colours kept at full strength.

## Rendering

The page is `frame.html`, with one view per hash: `#sheet`, `#board`, `#large`, `#compare`. It was rendered with Playwright's chromium headless shell, using `--no-sandbox` for local files only.

## Round 2 (method change)

The image tool twice placed the lead and the discs by its own judgement. Round 2's lead was solid, but tier 1's was thin, and the discs ran from 34 to 54 units across tiers. So `assemble_r2.py` now does three things:
- Takes the upper lead from one generated card (tier 4, or golden tier 4) for every tier.
- Repeats its plain side lead down under each tier's own glass.
- Lays one roundel, cut from tier 2's and recoloured to each tier's glass, at one place and size.

The glass, ornament and gilt are still each tier's own generated picture. Round 1's renders are in `r1/`.
