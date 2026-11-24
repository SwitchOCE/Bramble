# Combo look: art direction

The element: when one trigger hits the same card many times, show a count (×N), the running total, and a small hit splat on each stacked hit. The owner's words (24 Nov): "a ×11 if something triggers 11 times, and you can see the cumulative damage. But you also get this little hit splat whenever the speed-up triggers", and from 18 Nov: "Combo ×3, ×4 … rises up at increasing pace." He called these ideas to look into, not firm steering.

Nothing here has been drawn yet. The image prompt is [`tools/art/prompts/combo-look.md`](../../../../tools/art/prompts/combo-look.md). The mock-ups' base frames are the real fight at 1920 × 1080: `/data/fight-anim-work/combo-look/base/` (CB7's best film, frames 237 and 244: the 8th hit, −40, and the 9th and 10th hits together, −50).

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
