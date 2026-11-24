# L1: the card is a window

**The idea.** Each card is a small leaded window: a plain dark lead border, and the picture is the glass. The screen is the dim room the windows sit in, so the cards are the brightest things on it, and light does the jobs a frame used to do.

**Tier in the shop.** The shop is a stone wall of arched openings, like a ruined woodland chapel's high windows. Each unit stands in an opening lit from behind in its tier's colour; the light pours round the card and pools on the sill. Higher tiers get stronger light, not only a different colour: tier 1 is faint grey daylight, tier 6 a deep red blaze. The card itself never changes. Large, calm light reads without an icon.

**Tier on the board.** Not shown, as in TFT. It shows on hover.

**Golden.** Still: the lead border and the Attack and Health rims turn to bright gilt, and the glass glows warmer and brighter, casting a pool of its own colours on the table. In motion: a slow glint runs along the gilt every few seconds. It reads because nothing else on screen is gold or lit that way.

**Regions are told apart by material, not ornament.** Shop: cool stone with lit openings. Board: a long dark oak table below, where the shop's light lands. Hand: a narrow leather ledge at the foot. Gold, turn and the leaderboard: tall narrow lancet windows at each side, plain lead and dim glass. A second version swaps the wall for a glazier's beam with lanterns, and the table for a flagstone dais.

**The fight.** Wall and table go. The armies face each other on open ground before a large, dim stained-glass picture of a place: a bluebell glade, a frosted upland, a rainy oak wood, one per fight. The backdrop stays quiet so the units stay the lit things.

**What I'd tell the owner to change.**
- Keep the hexagon: it is a lancet pane's shape and suits this idea.
- Keep the familiar colour order, but make tier 5 amber-orange (many RPGs' "legendary"), not yellow, so gold belongs to golden alone.
- Quieten today's art: figure vivid, background glass darker and less saturated. Bright backgrounds everywhere are why every frame so far failed.
- Drop tier marks from the card face.

## What the pictures show

Pictures: `/data/bramble-art/uiid-looks/L1/`. Sheet: `/data/ui-ideation/looks/L1/sheet.png`. See first: `l1-buy-c` (the whole buy screen), `l1-cards` (one unit at every tier, then normal and golden), `l1-board-glance` (seven units, two golden), `l1-fight-c` (the fight).

**Golden on the board: works.** The gilt border plus a warm pool of light on the table picks out the golden cards at once in `l1-board-glance` and `l1-buy-c`, and the art keeps its own colours. Shrunk to 112 px wide it still reads; in `l1-buy-d`, at about 70 px, it still shows but only just. One way failed: in `l1-buy-a` and both fight batches the painter flooded the whole picture gold, which reads but buries the art. Gilt lead only.

**Tier in the shop: works, and strongly.** A glowing arch round the card reads at a glance, higher tiers feel richer, and the card itself needn't change (`l1-cards`). In the screens the painter also tinted the shop cards' glass; that is not needed and should go.

**Tier 5 or 6 against golden.** Red tier 6 is never confused with golden. Orange tier 5 is told apart by its place and the shape of its light (a whole lit arch in stone, against a thin gold rim on wood), not by colour: the orange and the gold are close. That holds as long as golden cards never appear in the shop. If they can (a triple reward, say), tier 5 should move further from gold, towards a deep copper red, or golden needs its motion to be told apart.

**Stained glass, border not busy: works.** A plain lead border makes each card a small window, and the side lancets and the fight's window carry the feeling. Two weak spots: a fight backdrop of bright glass swallows the cards (`l1-fight-b`), so the backdrop must be dimmer than the cards (`l1-fight-c` gets this right); and the painter's figures drifted cute and cartoony, unlike the approved warrior art. Judge the setting, not these figures.

**Card art.** The middle card in `l1-art-mid` is the one to make: a quiet place behind a vivid figure, still built of glass. Flat backgrounds (right) lose the glass.

## How it would be built

- **Screen backgrounds:** a buy-screen backdrop (stone wall with arches, oak table, leather ledge) and one window per fight, each dim and quiet.
- **Region frames:** two lancet columns (plain lead, dim glass) holding the panels.
- **Shop arch light:** one white glow-and-pool sprite tinted per tier in the engine, behind the card, with strength and size rising by tier and rays added at tier 6.
- **Card frame at 112 px:** one plain dark lead hexagon about 4 px wide, with two lead-rimmed roundels. Golden swaps it for a gilt version and adds a warm pool sprite under the card. No tier art on the card.
- **Card art:** redone with quieter backgrounds, as the middle card in `l1-art-mid`.

## Motion and light (not judged)

From stills these are guesses. Shop arches breathe slowly, tier 6 strongest. A glint runs along a golden card's gilt every few seconds, and its pool of light flickers a little. When a unit becomes golden, the lead lights up from the bottom point to the top. In a fight, a hit flashes the struck card's glass from behind.
