# Thorns look: art direction

**The element:** when a unit with Thorns is attacked, a briar of leaded glass whips out of it and strikes the attacker, which flinches (direction A, the pick). The alternative is a row of glass thorns along the defender's edges that the attacker strikes into (direction B). A thrown-thorn dart is drawn as a cheap fallback (direction C).

**Why** (the owner, 24 Nov): "a thorny vine whipping out and striking them. Or the unit hitting and then flinching … we're trying to communicate it using the same language as an attack, when it's not an attack". He called these ideas, not specs. The reference study, the options with frame beats, the pick and the family map are in [DESIGN.md](DESIGN.md).

Nothing here has been drawn yet. The image prompt is [`tools/art/prompts/thorns-look.md`](../../../../tools/art/prompts/thorns-look.md).

**Base frames:** the real fight at 1920 × 1080, in `/data/fight-anim-work/thorns-look/base/`, cut from films of the comparison fight's moments (c) and (d):

| File | Film and frame | What it shows |
|---|---|---|
| `base-c-f172.png` | `best.mp4` f172 | Horde-runner raised at home in its hold, the Nettle Sprout at rest above it. Nothing else on screen. |
| `base-c-f193.png` | `best.mp4` f193 | The same, with the red "−2" burst at full size on the attacker (Health 3). The Sprout is back at rest. |
| `base-d-f322.png` | `best.mp4` f322 | The lethal case. Green Recruit raised, diagonal to the Sprout, with "−2" on it (Health 0). |
| `base-c-today-f178.png` | `today.mp4` f178 | Horde-runner one frame from contact with the Sprout. No burst. |

## 1. What the pieces are

| Piece | Direction | What it is | Size at game scale (1080p) |
|---|---|---|---|
| **Bud** | A | The knot where the vine leaves the card: three short leaves and a twist of stem round two thorns | 44 px |
| **Vine segments** (3 variants) | A | One length of bramble cane, a glass piece with a thorn on each side, laid end to end along a curve with a lead joint between each | 44 × 22 px each, stem 12–14 px thick |
| **Tip** | A | The striking end: the cane narrows into a hooked curl with one big thorn leading | 44 × 22 px |
| **Impact 1 and 2** | A | Where the thorn bites: bone thorns driven into a small dark russet star. Frame 2 is four frames later, scattering | 52–60 px |
| **Bristle 1 and 2** | B, C | A row of five or six thorns along a short stem, half grown and fully grown. Laid along one card edge | 64 × 26 px |
| **Prick flare** | B | The moment of contact on the thorns: a dark russet star pierced by three bone thorns | 60 px |
| **Dart** | C | One flying thorn, long and pointed | 36 × 12 px |

The attacker's **flinch** needs no art: it is motion only (DESIGN.md section 4).

## 2. How a glass vine is built

- **Like a real leaded window.** A vine in a church window isn't one long piece of glass. It is a run of short pieces with lead joints between them, and each leaf or thorn is its own piece. So the vine is made of **segments**: Godot lays them end to end along a curve and turns each one to follow it. The lead joint at each end of a segment hides the seam. This also lets one vine stretch from 80 px to 700 px with no new art.
- **Thick outer lead, thin inner lead**, as on the cards and in the combo look. Lead #16120e.
- **Few, big pieces.** Each segment is one stem piece and two thorn pieces. The bud is about five pieces. A thorn is a single triangular piece, never a thin line.
- **Lit from behind.** Each piece has a soft glow and a little streak or seed bubble, with at most one darker shade per piece.
- **It reads as a silhouette when small.** The thorns stick well clear of the stem, so the outline is jagged even at 22 px.

## 3. Colours

They are taken from the existing palette and the sibling looks, and checked against the base frames.

| Use | Colour | Why |
|---|---|---|
| Lead | #16120e | The cards' and the combo look's lead |
| Cane glass | mid #8a3a22, light streak #c0623a, dark #4e1d12 (russet) | Bramble canes are red-brown. **Not green:** green is the gain colour in [buff-look](../buff-look/DESIGN.md), and it would also sink into the tier-2 frame (yellow-green) and the Nettle Sprout's lime art. Browner and darker than the damage burst's red (#ff6a4a → #a5150f) |
| Thorns | bone #f2e6c4, shading to the cane's russet at the base | Rose and bramble thorns: pale tips, red-brown base. Bone is the brightest value on the dark board, so the thorns carry the silhouette |
| Bud leaves | deep, dull green #2a5228 and #3f6a30, three small leaves only | Says "plant" without making the vine read as green |
| Impact and prick | bone thorn pieces driven into a small dark russet star (#4e1d12 with #c0623a edges). **No white or gold core** | Its own lane: the combo splat is warm white-gold (#fff6dc, #ffd98a) and the burst is red |

- **Never:** the burst's red, gold (combo), bright green (gains), magenta, pink or purple (the key colour).
- **Check on the mock-ups:**
  - russet cane over an orange card. The Horde-runner is orange-brown, so the lead outline and the bone thorns must carry it there.
  - the tip right beside the red burst. It must read as a different thing.

## 4. Where things go, and what they must not do

- **The vine leaves the defender's point that faces the attacker.** That is the bottom point of an enemy card and the top point of yours, the rule just settled for which point leads an attack.
- **The tip strikes the attacker's upper face,** beside the red burst and never on top of it. The burst stays the one place the number is read.
- **Nothing covers an Attack or Health roundel,** on either card.
- **Drawn above the cards** for its whole life (about 20 f). Gone by the strike.
- **The defender card never travels.** It pulses in place: a glow and a scale pulse (GUIDELINES V2). Today's lift toward the attacker and its jab are dropped.
- **No words, no frames, plates or panels round any piece, no screen shake, and no dimming or tint on the board or the art.**
- Nothing new is drawn on the card face itself.

## 5. Motion, piece by piece (direction A)

All frames are counted from the start of the hold (DESIGN.md section 4).

- **Bud:** scales 0 → 1.1 → 1.0 over f0–f2. It closes, scaling to 0, over f17–f20.
- **Vine:** segments appear one by one behind the tip as it passes (f5–f10). They are removed from the tip end back over f12–f19.
- **Tip:** follows the curve in 6 f, speeding up, and turns to the curve's tangent every frame.
- **Curve:** a quadratic Bézier, bulging to the side with more empty board, by about 0.3 of the straight distance.
- **Impact:** frame 1 for f10–f11, frame 2 for f12–f15, fading out by f16.
- **Lethal:** the vine stays full until the fall begins, then recoils over 8 f.

## 6. Directions

**A. Lash (my pick).** Bud, chained segments, tip and impact. The vine curls out of the defender's facing point and snaps onto the attacker's upper face.
- It is a line from cause to effect, drawn in the tribe's own material, along a path no attack takes.
- Risks: crossing other cards on a back-row attack, and being seen often with a Guard Lone Hawthorn.

**B. Prick.** A bristle grows along the defender's two facing edges during the hold. The attacker strikes, stops on the thorn tips, and gets the prick flare.
- It is local: everything happens where the eye already is.
- Risks: cause and hit share one spot, and the two-step contact can read as a stutter.

**C. Volley.** The same bristle flings three darts.
- Cheap.
- Risks: it reads as shooting, and it overlaps the projectile look planned for trigger damage.

## 7. Open for the owner, with the pictures

- Is a vine drawn across the board for about a third of a second acceptable, even across other cards?
- A or B?
- Does the russet cane read against orange and red cards?
