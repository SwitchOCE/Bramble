# Combo look: art direction

The element: when one trigger hits the same card many times, show a count (×N), the running total, and a small hit splat on each stacked hit. The owner's words (24 Nov): "a ×11 if something triggers 11 times, and you can see the cumulative damage. But you also get this little hit splat whenever the speed-up triggers", and from 18 Nov: "Combo ×3, ×4 … rises up at increasing pace." He called these ideas to look into, not firm steering.

The mock-ups' base frames are the real fight at 1920 × 1080: `/data/fight-anim-work/combo-look/base/` (CB7's best film, frames 237 and 244: the 8th hit, −40, and the 9th and 10th hits together, −50).

- **Round 1** (sections 1–4 below): three directions drawn as Codex glass sprites from [`tools/art/prompts/combo-look.md`](../../../../tools/art/prompts/combo-look.md); pictures in `/data/bramble-art/combo-look-1/`. Its reference study still holds. Where round 2 differs from its craft answers, round 2 holds.
- **Round 2** (section 0): four takes on direction A, drawn with Pillow in the game's own font, so they show exactly what the game would draw. Pictures and script in `/data/bramble-art/combo-look-2/`. The prompt for the one drawn piece it might need is [`tools/art/prompts/combo-look-2.md`](../../../../tools/art/prompts/combo-look-2.md). Its type, beat and first-hit rule still hold.
- **Round 3** (section 00): the owner chose A1. Four one-change variants of A1 (slant, tilt, a backing splat, slant plus backing), each on the red card and on a blue one. Pictures and script in `/data/bramble-art/combo-look-3/`.

## 00. Round 3

### The owner's reaction to round 2 (24 Nov, dictated, filler removed)

> "I think I actually prefer A1. A1 is probably my favourite. On King Speck, the colour looks… maybe it needs a backing hit splat of its own. For some reason I feel like in fighting games these things are rotated a bit, the text on a slant, to make it clear that it's not the same [as the other numbers]. Am I imagining that? I'm not sure. It looks wrong to me, but I can't quite pin down why. I don't have all the answers on this; I'm trying to figure out what I like myself."

So A1 is the base: a white count beside the star's upper right, 36 px, 4 px lead outline, the small spark on the rim. Round 2's pick of A3 no longer holds.

### Is he imagining the slant?

Mostly not. A quick check, not measured from footage:
- A font study of the fighting-game look says its in-game text "leans toward bold, often italicized or condensed sans styling" ([Made Good Designs on Marvel vs. Capcom's type](https://madegooddesigns.com/?p=11462)). The same page says Capcom has never published its UI fonts, so this is a description, not a spec.
- From memory, not re-checked: Marvel vs. Capcom 2 and The King of Fighters show "N HITS" in heavy, slanted figures; Guilty Gear Strive's counter and its "COUNTER" call-outs are slanted and skewed. Street Fighter's counters have mostly been upright.
- Backing shapes, also from memory, are rarer on the count itself and show up on notices: Street Fighter 6's "Punish Counter" and Strive's "COUNTER" sit on a coloured slab. The HUD pages that would settle it ([Dustloop, Strive HUD](https://www.dustloop.com/w/GGST/HUD), [SuperCombo, SF6 HUD](https://srk.shib.live/w/Street_Fighter_6/HUD)) blocked our fetches.

**Why slant works:** every other number on the board is upright Alegreya (the damage star, Attack, Health). A slant marks the count as a different kind of number without a new font or colour. That is likely what "it's not the same" means.

### Variants (each changes one thing from A1)

| | Change | Detail |
|---|---|---|
| **A1** | (control) | as round 2 |
| **Slanted type** | italic slant | the glyphs sheared 12°, the top leaning right. Godot can do this with `FontVariation.variation_transform`; no new font file. |
| **Tilted count** | whole count rotated | 7° anticlockwise, so it rises to the right. |
| **Backing splat** | a splat of its own behind the count | a blunt 12-point burst, wider than tall, 3 px lead edge, gold glass (#ffde78 centre to #e8961e edge, the round-1 hit glass), never the damage star's red. 17 px past the text each side. |
| **Slant + backing** | both | |

Each is shown on King Speck (the red card, as filmed) and on the left blue attacker. For the blue card, the game's own damage star is cut pixel for pixel from the film and placed on its art at the same spot. Every mock-up shows the 8th hit (×8, −40) and the last hit (×10, −50). Files: `R0`–`R4` `_red_x8`, `_red_x10` (full board) and `_red_*_zoom`, `_blue_*_zoom` (2×). Contact sheet at real game size: `/data/bramble-art/combo-look-3/contact_sheet.png`.

### What the pictures show

- **The colour complaint is the red card.** On the blue card's dark purple art, plain white A1 already reads. On King Speck's orange and gold art, the white sits on light glass and only the lead outline holds it.
- **Slant alone** separates the count from the damage number, but it doesn't help the contrast on red.
- **Tilt** reads as a placement accident more than a style at this size; the slant does the same job better.
- **Backing** fixes contrast on every card, because the count always sits on its own glass. The risk: two jagged shapes side by side can read as two damage stars. The gold and the blunter points keep them apart at game size, but only just.
- At ×10 the backing reaches 15–25 px past the card's edge, into the gap and onto the neighbour's frame.

**Pick: slant + backing.** It reads the same on every card, and the slant plus the gold make it clearly not a second damage number. If the backing feels like too much in motion, slant alone is the next best.

### Open for the owner

- Slant, backing, both, or neither?
- If the backing stays: is a jagged splat right, or should it be a simpler shape (a lozenge or a roundel) so it can't be taken for a second damage star?
- Is reaching past the card's edge at ×10 acceptable, or should the count move inward and overlap the star more?

## 0. Round 2

### The owner's reaction to round 1 (24 Nov, dictated, filler removed)

> "I'm not sure that the colour needs to be like that. I said fighting games, but I didn't mean to take that much inspiration: the entire colour being divided into multiple different tiles and stuff. I think someone's gone way too heavy on the fighting games. I meant the concept, not necessarily the execution. It's hard for me to tell, but the banner I hate, I do know that. We need stuff that has good visual clarity. And I do think these things might need to pop better, and where they sit will matter. I don't think down off the card is good. I think I agree that A is the best, but it still doesn't necessarily read clearly."

And later the same day:

> "I think maybe you might need multiple hits to trigger a combo. I think a single hit probably shouldn't, but I'm not sure. I'll evaluate it when you show it to me."

**What that means for round 2.**
- Keep A's idea: the count beside the damage star, on the card being hit.
- Drop B's banner and C's place off the card.
- Glyphs split into many coloured panes are out. Clarity and pop come first; glass style is no reason to make a number harder to read.

### Type

- **Font: the game's own.** Alegreya at weight 900 with lining figures (`lnum`). It is the font of the damage star's number and of the Attack and Health numbers (`GlassPieces.display_font`; `card.num.weight` 900; `fight.css .hit b`: 900, 36 px, white, a 5 px #3a0806 stroke). The × is Alegreya's own multiplication sign (U+00D7), at 0.8 of the digit size, centred on the digits' middle.
- **Solid fill, one colour.** No pane splits, no gradient.
- **Lead is the outline, not the fill.** A 4 px #16120e stroke outside the glyph, plus a soft dark shadow 2 px down (70 %, 2.5 px blur), so the edge holds on pale glass as well as on the dark board.
- **Size.** Digits at 36 px, the same size as the damage number (cap height 23 px). A2 tests 46 px. Below about 26 px digits won't read in 5-frame gaps (round 1).
- **Colour.** White, like the damage number, so count and total read as one thing. A2 tests solid gold #ffcf40, which separates the count from the total and from the red star. The warm card art in the base frame is the hardest case for both; the lead outline is what carries them.

### Placement (all on or touching the card)

- **Beside the star** (A1, A2): left edge tucked onto the star's upper-right points. At two digits it pokes 15 px (A1) to 30 px (A2) past the card's right edge, into the 12 px gap and the neighbour.
- **Above the star** (A3): centred on the star's top point, its bottom 5 px into the point. Count over total reads as one stack, "×10 / −50". It stays inside the card at two digits.
- **Top corner of the card** (A4): on the frame's top-right shoulder, about 80 px from the star. Clear of the art, but a second place to look.
- Every placement stays clear of the Attack and Health roundels.

### Burst: simpler, never over the number

- **Spark** (A1, A2): one four-ray glint, a single piece of warm white glass (#fff6dc) in a thin lead line, 42 px (58 px on the last hit). It sits on the star's upper-left rim, away from the number and the count, and moves round the rim from hit to hit. The mock-ups draw it as a plain polygon; the glass version is in the round-2 prompt.
- **Rim flash** (A3): the damage star's own outline flares warm white, outside the star only. Nothing new is drawn on the art, and the engine can draw it from the star's polygon.
- **None** (A4): the count's own pop is the hit.

### The beat (60 fps, frames after each hit)

- **The first hit is a plain hit:** the damage star as today, with no count and no burst. The count and the burst start from the second hit (the owner's note above; he will judge it when he sees it).
- **Each later hit:**

| Frame | 0 (impact) | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|---|
| Count scale | 1.45 | 1.25 | 1.12 | 1.04 | 1.0 | 1.0 | 1.0 |
| Count halo (warm white, outside the lead) | 100 % | 70 % | 35 % | 0 | | | |
| Spark size / opacity | 0.7 / 100 % | 1.0 / 100 % | 1.0 | 1.0 | 0.9 / 75 % | 0.75 / 45 % | 0.6 / 20 % |
| Rim flash | 100 % | 100 % | 80 % | 55 % | 30 % | 12 % | 0 |

  The pop settles in 4 frames, so at the fastest 5-frame gaps each hit lands on a resting count.
- **Last hit:** count scale 1.6, 1.35, 1.18, 1.06, then 1.0; the halo holds at full for 3 frames and fades over 2; the spark is the 58 px one and the rim flash 7 px wide. Then count and total hold together for 30 frames and fade together over 8, as in round 1.
- Beat strips for every variant: `beat_<variant>_x8.png` and `beat_<variant>_x10.png`, frames 0–6 at 2×.

### Variants

| | Changes from A1 | 8th hit | End (×10) |
|---|---|---|---|
| **A1 Beside, white** | (baseline) count beside the star's upper right, white, 36 px, spark | `A1_x8.png` | `A1_x10.png` |
| **A2 Beside, big gold** | solid gold; 46 px digits | `A2_x8.png` | `A2_x10.png` |
| **A3 Above the star** | count above the star; rim flash instead of the spark | `A3_x8.png` | `A3_x10.png` |
| **A4 Top corner** | count in the card's top-right corner; no burst | `A4_x8.png` | `A4_x10.png` |

Each has a `_zoom` version (2×, x 700–1100, y 250–560). All side by side at real game size: `/data/bramble-art/combo-look-2/contact_sheet.png`.

**Pick: A3.** Count over total is one stack in the one place the eye already is, it never leaves the card or touches a neighbour, and the rim flash adds nothing new on the art and never covers the number. A2 shows the count reads better at 46 px and in gold; if A3's white count feels too quiet next to the total in motion, A3 can take A2's size and colour.

### Open for the owner

- Which placement, and white or gold?
- Should a single hit stay plain, with the count from the second hit? (Mock-ups and beat assume yes.)
- Spark, rim flash or no burst?
- Round 1's three questions in section 4 still stand.

## 1. Reference study

Battlegrounds and Galaxy were measured frame by frame in our research. The rest are described from general knowledge of the games; most public pages were blocked or vague and nobody re-checked footage, so treat those rows as leads, not measurements.

| Game | Where the count sits | Count and total | Single hit splat | Pace | End |
|---|---|---|---|---|---|
| **Battlegrounds** ([research](../research/battlegrounds.md), T3: [youtu.be/cRVjjXEnd0I?t=1570](https://youtu.be/cRVjjXEnd0I?t=1570)) | No count | None. Each cycle puts its own yellow star with "−1" on every card it hits | The same damage star as a normal attack, ~60 f | Cycles speed up about 2× over a long chain | Nothing special |
| **Once Upon a Galaxy** ([research](../research/galaxy-and-others.md), [youtu.be/4_uOk8CZu0Y](https://youtu.be/4_uOk8CZu0Y)) | No count seen | One large white number star per hit, ~1 s | The number star is the splat | n/a | n/a |
| **Street Fighter 6** ([SRK wiki HUD page](https://srk.shib.live/w/Street_Fighter_6/HUD); [Attack Data damage reset, patch 202405](https://shacknews.com/article/139959/street-fighter-6-version-202405-patch-notes)) | **Attacker's** side, under the bars | Count in matches; combo damage only in Training's Attack Data | Flash plus paint and ink splashes on the victim, a few frames | By the hits, not the counter | Counter lingers, fades |
| **Guilty Gear Strive** ([Dustloop HUD](https://www.dustloop.com/w/GGST/HUD); [Kotaku](https://kotaku.com/guilty-gear-strive-is-too-stylish-for-its-own-good-1847050371)) | Big counter on the attacker's side | Large stylised count; colour carries meaning | Large graphic sparks | Pops each hit | The counter was contentious (Kotaku). **Too big a counter turns into chrome.** |
| **Tekken 8** ([HotSpawn on the 2025 update](https://www.hotspawn.com/?p=83275)) | Side of screen | Combo count added to live matches in 2025, alongside counter-hit notices | Sparks on the victim | n/a | n/a |
| **Marvel vs. Capcom** ([StrategyWiki](https://strategywiki.org/wiki/Marvel_vs._Capcom/Gameplay)) | Attacker's side, large | "N HITS" bounces bigger as it climbs; damage only in training | Big bright multi-coloured sparks | The bounce shows rhythm | Announcer at milestones |
| **Slay the Spire** ([tck.mn on its mechanics](https://tck.mn/blog/a-slay-the-spire-puzzle/mechanics)) | Above the target | Intent written "10×3"; each hit drops its own number | Slash plus number, scattered | Fixed gaps | No total |
| **Balatro** ([analysis, B. Crosley](https://blakecrosley.com/guides/design/balatro)) | Each trigger's call-out sits by its **source** card. The running total is in a fixed side panel | Total updates after every trigger | A small "+4" tag that wiggles; the source bounces | Faster retriggers; shake grows | Total flies to the score; big scores catch fire |
| **Marvel Snap** | On the location (target) | The location's power ticks and pulses on each change, and small +N floats appear on cards | Pulse of the number | n/a | The winning total glows |
| **Teamfight Tactics** | Over the unit hit | No count or total; one floating number per hit, coloured by damage type, bigger for crits | The number is the splat, ~0.5 s, rising | n/a | n/a |
| **Hades** ([community damage guide](https://docs.google.com/document/d/1eWrbcMIPSAkFhfDHOtOKEmcYxGfHE5ctP2hBehXUEU4/export?format=pdf)) | Over the target | Hits from the same source merge into one bigger rising number | Flash and hit-stop | n/a | n/a |

Common advice ([Bugnet](https://bugnet.io/blog/how-to-build-a-damage-number-system), [gamejuice](https://gamejuice.pages.dev/articles/damage-numbers-satisfying-feedback)): fast hits on one target add up in one rising number. Our re-popping burst already does.

**What this tells us.**
- Fighting games keep the count away from the victim, by the attacker's bars, because the action moves around the screen.
- Card games keep everything on the card, because cards don't move.
- No game we looked at shows the count and the running total together, as one thing on the target. That is the owner's idea, and it fits a board game better than a side-of-screen counter.
- The splat is always the smallest, shortest-lived thing on screen, and it never carries a number once a total exists.

## 2. Craft answers

**Where.** On the target, riding the existing burst. The count, the total and the splat all move with the target as it shakes. A fixed corner counter would put the eye on two places 700 px apart. Our board has cards 12 px apart in every direction, so "beside the card" means on a neighbour's face, and "above" means on the back-row card. The one place that is the target's own is the target. The count stays in the upper half, clear of the Attack and Health roundels (from about 0.72 H down). **It overlaps the card's art.** Today's burst does too, but it is still new, so the owner must say yes to a picture.

**How big, with 250 px cards.** The total stays as it is: a 92 px star with a 36 px numeral. The count is smaller than the total: the × is 20 px, and the digits are 28 px at ×2, stepping up to 36 px by ×8 and above. "×10" is then about 64 px wide. The splat is 40 / 52 px, and 72 px on the last hit. Digits under about 26 px won't read in 5-frame gaps.

**One element or three.** Two:
- **A tally** (the total plus the count), built as one unit.
- **The splat**, which is separate and lives only a moment.

The total leads, because Health is what the player tracks; the count is a satellite.
- The count starts at the second hit. The first hit is a plain burst.
- When two hits land together, it jumps (×8 → ×10).
- The word "COMBO" or "HITS" never appears.

**What a hit splat is in glass.** A burst of light breaking a pane: a white-gold core with five to seven leaded shards flying off. It differs from today's damage burst on purpose:

| | Hit splat | Today's damage burst |
|---|---|---|
| Number | None | Carries it |
| Colour | Warm white and amber, never red | Red |
| Shape | Broken, open pieces | One closed star plate |
| Life | About 10 frames | 36 frames |
| Placement | Jittered round the burst's rim | Centred on the card |

The other two directions replace the shards with a crack star or a light flare.

**Colours.**
- **Lead and total:** as today. Lead #16120e; burst red #ff6a4a → #a5150f; a white numeral with a #3a0806 edge.
- **Count:** gold silver-stain glass (#fff2c4 / #ffd98a / #d88a17). It separates from the red burst and from the red and blue tier frames on both sides.
- **Splat:** core #fff6dc, shards #ffd98a and #f4a23a.
- **Check:** gold is near the tier-5 frame and End turn's amber; test on a gold card.

**Motion with the pace.** Hits come 18, 14, 10, 7, 6, 5, 5, 5 frames apart, then two land together.
- **Each hit:** the burst re-pops as now (3 frames in, 5 to settle). The count re-pops from ×1.3 to ×1.0 over 4 frames and climbs about 3 px. As the gaps shrink, the count "rises up at increasing pace" by itself.
- **The splat:** pops in 2 frames, holds 4, then its shards drift out 10–16 px and fade over 4. At 5-frame gaps, two splats overlap. That overlap is the "stacking" feel, capped at three alive.

**How it ends.**
- The last hit gets the large splat, and the count pops to ×1.35.
- The glass of the tally brightens for 4 frames, as if the light behind it flared.
- Then the total and the count hold together for 30 frames and fade together over 8.
- There is no screen shake and nothing outside the target.

**What it must not do.**
- Cover the Attack or Health roundels.
- Sit on a neighbour's face.
- Read as a panel: no plate, box, bar or frame round the count, which is loose glyphs.
- Show any words.
- Dim or tint the board.
- Outlive the total.
- Show on a single hit.

## 3. Directions

**A. Tally on the star (my pick).** Gold leaded glass glyphs "×N" clip to the red burst's upper-right points, tilted a few degrees, and grow a step with each hit. A shard splat breaks off at a different point round the burst's rim on each hit. Everything sits within the target's upper half, and the eye never leaves the star. Risks: it crowds the art, and at two digits the tally pokes about 15 px past the card's right edge.

**B. Banderole.** The count is painted in brown grisaille on a little cream scroll ribbon above the burst. That is how real windows carry words, so it is the most "stained glass" answer. Each hit crazes the glass: a crack star, drawn as lead lines, with light flaring through it. Risks: a scroll is a container, so it may read as a label and slip towards UI chrome. The painted figures are thin at 20 px. Cracks on a card can also read as the card being damaged for good.

**C. Call-out.** A big, slanted, amber "×N" sits beside the target's lower outer corner, half over the gap between the boards: fighting-game style, on the side the hits come from. A four-ray light flare marks each hit. It is the loudest and the most like the owner's fighting-game memory. Risks: it covers the neighbouring slot, is a second place to look, and at 44 px nears Strive's "too big".

**Pick: A.** The tally is one thing, in the place the eye already is, and the owner already likes the re-popping total. The splat answers "fighting-game hit splat" in glass without adding a new place to look. If A feels too quiet in motion, C's count size and B's crack splat can swap in, because the parts are separate sprites.

## 4. Open for the owner (with the pictures)

- Is anything new on the target's art acceptable, even for a second?
- Should the splat show on every repeated hit, or only once the combo speeds up?
- When one trigger hits several cards each cycle (Battlegrounds T3), should each card show its own ×N, or should only the first?
