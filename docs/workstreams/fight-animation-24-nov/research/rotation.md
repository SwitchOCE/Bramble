# How attacking cards turn and tilt, measured (R4, 24 Nov 2026)

Measured frame by frame from the same public videos and the same attacks as R1 (`battlegrounds.md`) and R2 (`galaxy-and-others.md`): 9 Battlegrounds attacks and 6 Once Upon a Galaxy attacks. Frames are 60 fps frames; "contact" is frame 0 (Battlegrounds: the scale-pop frame, which is R1's contact frame; Galaxy: the furthest frame toward the target, which is R2's). Angles are on screen, **positive = clockwise**. Per-frame numbers: `rotation_angles.csv`, next to this file. Footage, frames and crops stay in `/data/fight-anim-ref/`.

## What each game does

**Battlegrounds does not turn the attacker at all.** In all 9 attacks (straight, diagonal and across the whole board) the card stays upright to within 0.3° through the lift, the hold and the strike, and its outline stays a true rectangle (opposite edges equal to within 1%): no in-plane turn and no 3D tilt. The lift toward the camera is a pure scale-up (×1.15). The only turn-like motion is a short **3D knock just after contact**: for frames +1 to +9 the card's outline goes slightly out of square, its side edges leaning up to 6–7° and its top edge up to 8° while the top edge gets about 7% shorter than the bottom one, then it settles. It leans the same way whatever the attack's direction, so it is a fixed jolt, not aiming. Cards crossing the board also lean up to 3.5° from the camera's own perspective; that is not animation.

**Once Upon a Galaxy turns the card to point along its path, and tips it in 3D.**
- **In-plane turn (the flat axis):** on diagonal attacks the card turns 23–44°, which is **89–104% of the angle of its path** (path from the wind-up's furthest-back point to contact). Straight attacks: 0°. The end facing the target leads: the top for a card attacking upward, the **bottom for a card attacking downward**, so an enemy card in the top row points its bottom at its target.
- **When:** the turn starts on the wind-up's first frame and grows steadily (about 1.3–2.5° a frame) through the whole wind-up, reaching its full angle 3–4 frames into the travel (about 12 frames before contact). It holds through the travel, easing back 1–3.5° by contact. After contact it unwinds **slower than the card moves home**: 10 frames after contact 65–100% of the turn is still there, so the card lands back in its slot still turned and straightens there, by about +25 frames (read by eye: the number star covers the card).
- **3D tilt (about the card's own horizontal axis):** the leading end tips away from the viewer, the trailing end toward. It shows as a trapezoid: the leading edge is 8–12% shorter than the trailing edge (top/bottom edge ratio 1.10–1.14 for cards attacking down, 0.88–0.92 for cards attacking up). It builds through the wind-up, holds through the travel and fades over about 10 frames after contact. During the travel the card also gets **shorter along its own length**: height against width falls from 1.0 to **0.67–0.78 at contact** and is back to about 0.95 by +5 to +8. Read as a tip, that is about 40–45° at contact (estimate; see doubts).
- **No turn about the vertical axis:** left and right edges stay equal (ratio 0.97–1.03).

**Targets don't turn in either game.** Galaxy's target is knocked straight back along the hit line and stays upright (turn under 2.5°, within measuring noise). Battlegrounds' target is hidden under the white flash and the damage star from contact on, so its reaction can't be measured.

**Which axis** (the owner asked): in game-engine terms it is mostly the **flat, in-plane axis** (rotation about the axis pointing out of the screen; "roll" for a card lying on a table seen from above). That is Galaxy's big visible turn. Galaxy adds a **tip about the card's own horizontal axis** ("pitch": the leading end dips into the table). Neither game turns the card about its vertical axis. The 3D feel the owner remembers is Galaxy's; Battlegrounds gets its depth from the lift toward the camera and the scale pop, not from turning.

### Key numbers

| | Battlegrounds | Once Upon a Galaxy |
|---|---|---|
| In-plane turn, diagonal attack | **0°** (±0.3°) | **23–44°**, 89–104% of the path angle |
| In-plane turn, straight attack | 0° | 0° |
| Which end leads | n/a | the end facing the target (top going up, bottom going down) |
| Turn starts | n/a | wind-up's first frame (about −30) |
| Turn full | n/a | 3–4 frames into the travel (−13 to −12) |
| At contact | n/a | about 90% of the full turn (89–95%) |
| Straight again | n/a | about +25 (65–100% still there at +10) |
| 3D tilt before contact | none (edges equal within 1%) | leading edge 8–12% shorter; length 0.67–0.78 of width at contact |
| 3D tilt after contact | a jolt at +1 to +9: edges lean up to 6–8°, one edge 5–7% shorter | fades by about +8 |
| Target turns | can't see (flash) | no (under 2.5°); knocked straight back |

## Per-attack table

Turn = mean of the two edge directions (CSV `inplane_deg`). "Lean of side edges" and "lean of top and bottom edges" are measured separately (CSV `edges_v`, `edges_h`); equal means a true turn, unequal means the outline is out of square (3D or camera perspective). T/B = top edge ÷ bottom edge; L/R = left ÷ right; H/W = height ÷ width, each against the card at rest. Path angle: for Galaxy, the turn that would point the leading end exactly along the path from the wind-up's furthest-back point to contact; for Battlegrounds, from rest to contact.

| ID | Source and moment | Attack | Path angle | Turn: lift/wind-up | Turn: hold and strike/travel | At contact | After contact | 3D tilt | Notes |
|---|---|---|---|---|---|---|---|---|---|
| A1 | Savjz 2022, [youtu.be/sOiaEv25Fgc?t=33](https://youtu.be/sOiaEv25Fgc?t=33), fr 2009–2053 | up, near | +15° | 0° (±0.2) | 0° (±0.2) | −0.3° | +1: −1.9°; +2: side edges −7° | none before contact; +1 to +2 L/R 1.01–1.04 | lost under flash from +3 |
| A2 | Savjz 2022, [?t=75](https://youtu.be/sOiaEv25Fgc?t=75), fr 4497–4541 | diagonal up-right, 1.35 h | +53° | 0° | 0° (side edges −0.5° max) | −0.6° | +1 to +3: −2.0 to −2.6°, side edges to −4° | +1 to +3: L/R 1.07–1.17, T/B 1.07 | lost from +5 (locks on the identical card next to it) |
| A3 | Savjz 2022, [?t=76](https://youtu.be/sOiaEv25Fgc?t=76), fr 4600–4616 | diagonal down-right | 49° off straight down | (template taken at the hold) | 0° (±0.1) | n/m | n/m | strike: T/B up to 1.03 | template includes the damage star that rides on the card |
| A4 | Stormrage Bros 2020, [youtu.be/M11gKHV4whs?t=894](https://youtu.be/M11gKHV4whs?t=894), fr 53067–53108 | across the whole board, 4.6 h | +77° | −0.3 to −0.9° | side edges drift 0 → −3.5°, top/bottom edges −0.5 to −1.1° | −0.3° | n/m | lift L/R 0.94–0.99, T/B 0.93–0.99 (match 0.85–0.94) | the drift grows as the card moves right of the screen's middle: camera perspective, not a turn |
| A5 | Bros 2020, [?t=902](https://youtu.be/M11gKHV4whs?t=902), fr 53512–53554 | up-left, near | −30° | 0° (±0.1) | 0° (±0.1) | −0.9° | +1: −2.5° | +1: L/R 1.06, T/B 1.05 | lost from +2 |
| A6 | Sevel 2026, [youtu.be/X3cr8nyi_-s?t=785](https://youtu.be/X3cr8nyi_-s?t=785), fr 47151–47192 | down, near | ~37° off straight down (mostly the scale pop) | 0° (±0.1) | 0° | −0.5° | **+3 to +7: side edges −4 to −6°, top/bottom edges +6 to +8.5°** (out of square, mean turn under 1.5°); square again by +10 | +3 to +8: T/B 0.93–0.97, L/R 1.05–1.06, H/W 0.94 | the cleanest look at the post-contact knock |
| A7 | Sevel 2026, [?t=782](https://youtu.be/X3cr8nyi_-s?t=782), fr 46953–46984 | down, near | 0° | 0° (±0.2) | 0° | n/m | n/m | none | flash covers from contact |
| A8 | ItzElegy 2025, [youtu.be/HxC68n9hcUU?t=226](https://youtu.be/HxC68n9hcUU?t=226), fr 13559–13602 | down, near | 0° | 0° (±0.1) | 0° | 0° | +2 to +4: side edges −3.6 to −5.4° (match 0.59–0.71, rough) | +3: L/R 1.13 (rough) | star covers from +2 |
| A11 | Sevel 2026, [?t=127](https://youtu.be/X3cr8nyi_-s?t=127), fr 7650–7666 | far diagonal down-right, 2.4 h | 69° off straight down | (template taken at the hold) | ≤1° | n/m | n/m | strike: L/R grows to 1.10, T/B to 1.07 as it crosses the board | likely camera perspective (see doubts) |
| G-A1 | LSV 2026, [youtu.be/4_uOk8CZu0Y?t=327](https://youtu.be/4_uOk8CZu0Y?t=327), fr 19626–19665 | straight down (enemy card) | −1° | top/bottom edges 0°; side edges 0 → −5.6° | side edges −6 → −10°, top/bottom edges 0° | side −10°, top/bottom 0° | side edges −8 → −4° by +10 | T/B 1.11 at wind-up end, 1.12–1.14 in travel; H/W 0.70 at contact, 0.96 by +8 | the side-edge lean with level top and bottom edges is the 3D tip seen off the screen's middle (card 140 px left of it), not a turn |
| G-A2 | LSV 2026, [?t=328](https://youtu.be/4_uOk8CZu0Y?t=328), fr 19734–19773 | diagonal up-right (our card) | **+25.4°** | 0 → +20° (linear) | +22 → **+26.5°** at −12, +25 at contact | +25.2° | +22 (+3), +16 (+10); about +8 at +19 and ≤5 at +25 by eye | T/B 0.94 at wind-up end, 0.91–0.93 in travel; H/W 0.77 at contact | |
| G-A3 | LSV 2026, [?t=331](https://youtu.be/4_uOk8CZu0Y?t=331), fr 19873–19911 | straight down (enemy card) | 0° | 0° (±0.2) | 0° | −0.1° | 0° | T/B 1.11 at wind-up end, 1.12–1.15 in travel; H/W **0.68** at contact, 0.93 by +7 | card on the screen's middle column, so no side-edge lean: confirms G-A1's lean is perspective |
| G-A4 | LSV 2026, [?t=334](https://youtu.be/4_uOk8CZu0Y?t=334), fr 20027–20065 | diagonal up-right (our card) | +25.7° | 0 → +18° | +23° at −12, +21° at −2 | n/m (−2: +20.8°) | +20 (+2), +16 (+9) | T/B 0.92 at wind-up end, 0.88–0.91 in travel; H/W 0.75 at −2 | wind-up start hidden under a treasure pop-up; template from the same card in G-A3 |
| G-A5 | LSV 2026, [?t=368](https://youtu.be/4_uOk8CZu0Y?t=368), fr 22119–22158 | diagonal down-left (enemy card) | +25.8° | 0 → +18° | +23° at −13, +21° at contact | +20.8° | +20 to +21 through +9 | T/B 1.09 at wind-up end, 1.08–1.15 in travel; H/W **0.67** at contact | video repeats frames in pairs here |
| G-A7 | Rowan Ribbit 2026, [youtu.be/KpKgQAe_Jsg?t=39](https://youtu.be/KpKgQAe_Jsg?t=39), fr 2382–2421 | diagonal down-right (enemy card) | **−44.3°** | 0 → −33° | **−43°** at −12, −40° at contact | −39.9° | −39 (+1), −29 (+9); still about −15° at +18 by eye | T/B 1.08 at wind-up end, 1.08–1.10 in travel; H/W 0.75 at contact | the largest turn measured; R2 had hit its ±40° search limit here |

Targets: Galaxy G-A1 (Davy Jones) and G-A3 (Black Jack) were tracked through the hit: knocked straight back 0.3–0.35 h, turn under 2.5° (within noise), slight trapezoid T/B 0.93–0.97 (match 0.6–0.8, rough). G-A7's target (Mysterious Egg) checked by eye: pushed back along the hit line, text stays level. Battlegrounds' targets (A1, A2, A6, A7) are covered from contact by the flash and then the damage star.

## Godot feasibility

**What we have.** `GlassCard` (`src/glass/glass_card.gd`) is one `Control` that draws everything in `_draw()`: the art as a textured polygon, the tier's frame as one texture (the lead lines are in that raster), the stat settings as polygons and lines, the numbers with `draw_string`, plus child `Control`s for its shadows (`card_shadow.gdshader`). Filtering is linear with mipmaps. `FightMotion._attack` today leans 6° in the wind-up and swings to −3° in the travel; `_hit` leans the target 4°.

**`card_carry.gd`'s approach can carry what the footage shows.** It sets `rotation` (a lean on a spring) and a non-uniform `scale`: `scale.x` narrows the card to fake a turn toward edge-on, `scale.y` shortens it to fake a pitch (`PITCH_MAX` 0.11). On a `Control`, scale applies along the card's own axes before the rotation, so a card turned 40° still shortens along its own length without shearing (checked in the throwaway test below). For the attack that gives:
- Galaxy's aim: `rotation` toward the path angle, ramped through the wind-up, held through the travel, unwound after contact behind the position. Our hex's points lead naturally.
- Galaxy's foreshortening: `scale.y` down to about 0.7 of `scale.x` at contact, back by about +6 frames. That is a bigger range than card_carry uses (0.11), so it is a new constant, not card_carry's value.
- Battlegrounds' post-hit knock: approximately, as a quick few-degree rotation wobble plus a small `scale.y` dip. The real thing is out of square, which a `Control`'s rotation and scale can't make.

**What it can't do:** the trapezoid (Galaxy's leading edge 8–12% shorter) and Battlegrounds' out-of-square knock. Both need a projection. `Control` has no skew property, and skewing inside `_draw()` with `draw_set_transform_matrix` would leave the shadow children behind.

**If the trapezoid is wanted, a shader on the card does it; no SubViewport needed.** A `canvas_item` shader on the `GlassCard`'s material: `vertex()` projects each vertex through a tip angle and a focal length, and passes `UV × w` and `w` to `fragment()`, which divides them back (perspective-correct texturing). Throwaway test in the scratch folder (Godot 4.7.2, OpenGL, a tier-1 frame, an art picture and two numbers, tipped 45° and turned 30°): lead lines stay straight and the art stays registered with the frame. **Without the correction it breaks the glass look**: each triangle is textured flat, so the frame's lead lines bend along the quad's diagonal and the art slides against the frame (the art polygon and the frame are split into triangles differently). Costs and catches:
- One `ShaderMaterial` on the moving card only; trivial GPU cost (it only breaks 2D batching for that card).
- `fragment()` re-samples `TEXTURE` itself, so one shader covers the art, the frame, the stat settings and the numbers. That works because the project's fonts are plain (no `.import` file turns on MSDF). If MSDF fonts are adopted later, the numbers would need MSDF handling in the shader.
- The shadow children have their own material and would stay flat. They are blurred, so that may not show; otherwise they need the same projection.
- Not checked: whether `set_glow`/`_apply_glow`'s filter path composes with a custom material.

The other routes are worse: a SubViewport per moving card (render to texture, then project one quad) gives exact perspective too, but needs reparenting the card for the attack, an extra render target and care with alpha fringes at the lead edge; a 3D card (Sprite3D or a mesh) is a much bigger change.

**Glass look under plain rotation and scale:** fine. Mipmapped linear filtering keeps the lead lines clean at any angle. Shortening to 0.7 thins the lead lines across the card's length by the same 30%, which is what real foreshortening does; the numbers squash for about 0.2 s.

## Method

- **Frames:** extracted with ffmpeg at the source rate into `/data/fight-anim-ref/r4/frames/` (PNG, 720p), windows around each of R1's and R2's attacks. Our frame numbers match R1's and R2's: every contact landed on their frame (±0).
- **Tracking:** a template cut from the card at rest (Battlegrounds: an ellipse inside the oval portrait, so the red ring and stat gems are left out; Galaxy: the art and name plate, or the name plate and stats when a damage star sat over the art). Each frame, OpenCV's ECC alignment (`findTransformECCWithMask`, OpenCV 5.1) fits a full **perspective (homography) warp** from the template to the frame, starting from the previous frame's warp plus its velocity; when that fails, a coarse search over turn (±48°) and scale (0.85–1.55) restarts it. The card's rectangle is pushed through the warp to get its four corners on screen.
- **From the corners:** the direction of the top and bottom edges and of the side edges (separately), the edge-length ratios (top ÷ bottom, left ÷ right), and height ÷ width, all against the rest frame. A true in-plane turn moves both edge directions equally; a 3D tip or a camera's perspective moves them differently or makes opposite edges unequal.
- **Quality:** each frame's ECC correlation is in the CSV note ("match"). Rows under 0.80, and frames where the tracker locked onto a neighbour (A2 from +5: the identical card next to it; A3 from contact; A6 from +13: an overlay), are written as "not measured".
- **Checked by eye:** quad overlays on A2, A6, G-A3 and G-A7, and plain crops of G-A2 and G-A7's settle (sheets in `/data/fight-anim-ref/r4/sheets/`).
- **Throwaway Godot test:** `scratchpad/gtest/` (a four-card render under xvfb). Not in the repo.

## Doubts

- **Galaxy's 40–45° tip is an estimate.** Two measurements agree on it: the length shrinks to 0.67–0.78 of the width at contact (an arccos of about 40–48°), and G-A1's side edges lean 10° while its top and bottom stay level. That lean is what a 45° tip looks like 140 px off the screen's middle through a camera with about a 40° field of view, and G-A3, on the middle column, shows no lean, as it should. But during the wind-up the trapezoid grows (T/B to 1.11) while height ÷ width stays at 1.0–1.08, which a pure tip doesn't do. So part of the shortening in the travel may be a squash along the path rather than a tip. The two look alike on screen, and the measured shapes (edge ratio, height ÷ width) are what to reproduce either way.
- **Battlegrounds' post-hit knock** is clean only in A6 (match 0.94). In A1, A2, A5 and A8 only its first 1–3 frames are visible before the flash and the star cover the card, and partial cover can bend a fit. Its sign is the same in all five, and the A6 quad overlay shows the out-of-square shape plainly, so I believe it exists; its size (6–8° of edge lean, 5–7% edge difference) rests mostly on A6.
- **Camera perspective vs animation in Battlegrounds:** A4's side-edge drift to −3.5° and A11's edge ratios of 1.07–1.10 grow steadily as the card crosses the board, which is what a perspective camera does to a flat card that moves off the middle. I can't rule out a tiny deliberate tilt mixed in.
- **Galaxy's settle after +10** is read by eye under the number star (±5°, ±3 frames).
- **G-A4's template** came from the same card in the same slot 150 frames earlier (G-A3), because a treasure pop-up covered it before its own attack. Its wind-up start is estimated.
- **Battlegrounds' targets** can't be measured: the flash and the star cover them. "Targets don't turn" is shown for Galaxy only.
- **A3 and A11** were tracked from a template taken during the hold (a damage star covered the card at rest). The hold is flat in every other clip, so their angles are still against upright, but their lift wasn't measured.
- **Speed-ups:** A12 (Battlegrounds' sped-up late fight) couldn't be tracked under its board effects, so whether turning changes in sped-up fights is unknown.
- Galaxy's footage is from May and August 2026. Not checked against the current version.
