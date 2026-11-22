# Pass 2, round 1: Opus, craft lens

Lens: the glass and lead, the card frame and tiers, colour and light, depth, calm or noise, and whether people would screenshot it. I looked at the renders at full size, except `keywords-off` for A and E, and A `extra2`, which I did not open. Motion, timing, hover feel and sound: not judged.

## A: arched windows on teal

**1. Against the direction.** At rest the screen still labels zones: "Shop" title (`mid`, top centre), "Hand" (left panel), "Standings" (right panel), and "Next fight" under March Hare (standings row 5). In `fight`, "OPPONENT" (top right) and a "Fight" pill on the divider. Nothing explains a card. The tooltip sits beside the card and works as a hover state. Keyword reminders take the same left-panel slot in `hover-shop` and `hover-board`, out of the way. The frame is the calmest of the three: one lead bevel for every tier. Tiers read only from a small number square at the top point (`cards`). Unambiguous, but the T6 frame looks the same as the T1 frame. No next-opponent board.

**2. Eye order (`mid`).** 1) The shop row: pink and yellow art against a mid-teal field. 2) The board, in the same light and at the same saturation, so it competes. 3) The brown End turn. Shop first is right. The board should sit back, and it doesn't.

**3. Defects.**
- `mid`, shop controls: "Tier 5→6", "−3 next turn" and "10 at this price" are grey on teal, about 15 px, with weak contrast.
- `mid`, spells: they are about 90 px wide beside 165 px hexes, with their price coins outside on the right. They read as leftovers, not offers.
- `hover-board`: the tooltip covers most of Wing Commander and Blackberry Sprawl.
- The whole table is one flat teal. The lead lattice is too faint to give depth, so the cards float on a background with nothing behind them.

**4. Next round.** (1) Drop the board's art one step so the shop leads. (2) Give the frame a quiet tier tell you can read without the number, in the metal or the bevel. (3) Remove the zone headers.

## D: tavern table and paper

**1. Against the direction.** At rest: "Hand 1 of 7" (bottom bar), "Dame Farthing" plate, "Turn 9 / Recruit", the "1ST… NEXT · 5TH" lines in standings, and "Reserves in hand" in `fight`. No card text. The tooltip works as a hover state. The keyword shelf sits at the foot of the left lane in both `hover-shop` and `hover-board`, and `keywords-off` hides it. The frame is calmer: one smoky band with no colour. But the tier is shown as 1 to 6 white beads about 6 px across, and on Wing Commander they stack under its 4 charge pips (`mid`, back-left). That gives two dot rows to count on one card. No next-opponent board.

**2. Eye order (`mid`).** 1) The cream End turn panel (bottom right), the brightest object. 2) The large bright beige board felt, which outshines the glass. 3) The orange price coins on the shop row. The cards come after the furniture. Stained glass needs dark around it to glow, and here it sits on paper.

**3. Defects.**
- `mid`, Wing Commander: 5 tier beads and 4 charge pips stack, about 20 px apart.
- `mid`, shop: price coins overlap each frame's top-left shoulder and clip the lead.
- `mid`, standings: eight saturated red health discs are the noisiest thing on screen.
- `mid`, Upgrade: "3 short · −3 next turn" is about 13 px.
- `hover-shop`: the tooltip drops down onto the board and covers Squadron Leader.

**4. Next round.** (1) Make the board and shop surfaces dark so the glass carries the light. (2) Use a tier tell that doesn't collide with charge. (3) Calm the standings' red.

## E: forest at dusk

**1. Against the direction.** Almost no zone labels: the only text at rest is "Journal", "Turn 9", "Tier 5→6 / 3 gold short", Compost and Tide. Small keyword marks remain on every card face (bottom point). Icons, not text, but they tell a veteran what a known card does. The tooltip is pinned beside the card. The reminders stay bottom-anchored at the left over the oak (ending at y 712) in both `hover-shop` and `hover-board`. The frame is calmer and still glass. Tier shows as beads at the top point plus a metal came, but on `mid` the copper, bronze and gold cames look alike (Home Guard T3 against Wing Commander T5). Only the silver T4 stands out. `extra1` shows the opponent on hover with no board.

**2. Eye order (`mid`).** 1) The shop, warm on the dark wood. 2) The gold 20 coin. 3) The board, slightly dimmed. Fight March Hare is a clear fourth. This is the right order, and the only one of the three that gets it.

**3. Defects.**
- `mid`, every card: keyword marks of about 12 px under the stat discs can't be told apart.
- `mid`, shop: tier beads sit tight under the price-tag chain at the top point, so the two crowd.
- `mid`, right edge: the leaderboard portraits are about 55 px, with health hexes covering their lower left.
- `mid`: "+19" (bottom right) is far from the gold coin (top left).
- `first`: the hint box overlaps the third and fourth empty slots.

**4. Next round.** (1) Make the tier came read at a glance: more contrast between the steps, or fewer steps. (2) Thin the lead in the forest backdrop where it sits behind cards, because the leaded trees add line noise. (3) Move +19 next to the gold.

## 5. Rank

1. **E.** The only one where light does the work: a dark scene, warm shop, dimmed board and vignette. The `after` "Fell" greyscale is the most screenshot-worthy frame in the set.
2. **A.** The cleanest card frame and a correct hover model, but flat teal and shop and board at equal weight.
3. **D.** Good structure, but the cream surfaces outshine the glass, and the tier beads are the weakest tier tell.

**Borrow:**
- From A: its single lead frame, plain and the same for every tier.
- From D: the fight view, where only the blow being struck is lit and everything else steps down.
- From E: dimming the board one step against the shop, and the dark vignetted scene that lets the glass glow.

**Disk:** created the empty folder `/data/ui-ideation/tmp/council-opus-craft` (0 bytes). Nothing else written.
