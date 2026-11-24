# L3: start from nothing

## The idea

In the shop a unit is a pane of glass hanging in the light; once bought, it steps out of its pane and stands on the board as a cut-out glass figure with no frame at all. Tier is light around the shop pane, golden is the figure's own lead and glow, and the stained-glass feeling comes from the glass and the setting, not a border.

## Tier, in the shop

Shop units are hexagonal panes hung against bright sky, each casting its tier's light: a halo, and a coloured pool on the counter below. The light grows stronger as tier rises, from clear daylight at tier 1 (almost no halo) to a deep red bloom at tier 6. The colour is large and sits outside the picture, so the art can't drown it. The border is plain lead.

## On the board

Tier doesn't show; inspect a unit to see it, as in TFT. Each unit is a full-body glass cut-out standing on a hexagonal frosted-glass tile, with two small roundels at its feet.

## Golden

The figure's lead turns bright gold, its glass warms to amber, a gold halo surrounds it, and its tile glows gold. Normal figures keep dark lead and no glow. In motion (not judged from stills), a slow band of sunlight sweeps across the figure every few seconds, and a glint runs along the gold lead.

## World and regions

The shop is a travelling glazier's stall in a forest clearing. Light tells the regions apart:

- **Shop:** light shines through it.
- **Board:** a dark mossy stone floor, lit from above.
- **Controls and leaderboard:** carved into the stall's oak uprights; the leaderboard is a column of round portrait medallions.

Hand cards stay small panes.

## Fight

The two armies of figures face each other on stone. Behind them hangs a huge, dimmed stained-glass landscape, a different one each fight. Dying figures shatter into shards.

## What I'd change

- **Hexagon:** drop it for board units; keep it for panes, hand and tiles.
- **Art:** each figure needs a cut-out layer without its background.
- **Tier 5:** move it from yellow to orange (WoW's legendary colour), so gold means only golden.
- **Tier colours:** keep the order, with brightness rising alongside it. Picture 8 also tests brightness alone.
- **Thin tier borders:** stop using them.

---

# Stage 2: what came out

Pictures: `/data/bramble-art/uiid-looks/L3/`. Sheet: `/data/ui-ideation/looks/L3/sheet.png` (best buy screen, fight, card sheet and board close-up).

**See first:** `look-L3-buy-clearing-2.png`, `look-L3-fight-downs-2.png`, `look-L3-board-glass.png`, `look-L3-cards.png`.

## What worked and what did not

**Golden on the board: works.** Gold lead, a gold halo and a glowing gold tile pick out both golden units at once, in every picture, small or large (`board-close`, both buy screens, both fights). It is the strongest result here. One catch: in `board-glass` the warm sunset light makes the normal figures glow too, so golden stands out less than under neutral light. The board's light must stay cool or white, so that gold is the only warm glow.

**Tier in the shop: works.** A coloured halo round each pane, plus a pool of the same light on the counter, reads at a glance even with full-colour art (`buy-clearing-2`, `cards`). It reads best against a calm, pale background: the misty birches in `buy-clearing-2` beat the autumn sky in `buy-clearing`. Tier 5 in orange sat apart from the golden units' gold in every picture.

**Tier by brightness alone: did not work.** In the lower row of `tier-light`, tiers 1–2 look poor, but 3–6 can't be told apart, because each unit's own colours get in the way. Keep the rarity colours. Brightness rising with tier is a bonus, not a replacement.

**Cut-out figures against framed panes on the board: figures win, with a cost.** The framed board (`buy-panes`) is busier, its regions blur into the shop, and golden panes blend in where the art is already warm. The figures give a calm board, a clear split between shop and board, and a more striking golden.

**Do the figures read as glass?** In batch 1, no: they looked like painted cartoon stickers. In batch 2, mostly yes. In `board-glass` and `fight-downs-2` the glass texture, the rim light and above all the coloured glass shadows on the stone sell it. In `buy-clearing-2`, at smaller size, they slip back towards stickers, with only faint shadows. The coloured shadow does most of the work and must be strong at game size.

**A whole environment: works.** Light tells the regions apart, with no boxes: light shines through the shop, the board is lit stone, and the controls sit on the oak uprights. Each fight has its own place: the downs are calm, and the briar thicket is too red and loud.

**What falls short:**
- The screen is busy at the edges (props, carved leaves, banners); cut them.
- Facing armies need back views of every unit (`fight-downs-2`), which doubles the art.
- Numerals are generated, not exact.

## How it would be built

Layers, back to front:
1. A fight backdrop: one dimmed stained-glass landscape per biome.
2. The stone floor.
3. The shop rack and sky.
4. Oak uprights carrying the controls and leaderboard medallions.
5. Hexagonal frosted tiles.
6. Units.
7. Light effects: tier halos and counter pools, coloured shadows, the golden glow.

**The shop pane at 112 px:** today's hexagon art in a 2–3 px dark lead border, with no coloured border, plus a separate halo sprite (additive, tinted by tier) and a light pool on the counter.

**The board figure at 112 px tall:** each unit needs a second art layer, the figure cut out with a thick lead outline (about 3 px) and no background, plus a back view if the armies are to face each other. The coloured shadow is the figure's own art, squashed and blurred along the floor in light mode, so it costs nothing extra. Golden swaps the lead tint to gold, warms the glass and adds a halo sprite and a gold tile.

**Hand cards** are small panes, lying flat.

## Motion and light (not judged)

None of this can be seen from stills:
- **Shop:** halos breathe slowly, stronger at high tier, and a pane sways a little on its hook when the shop rolls.
- **Golden:** a band of light sweeps across the figure every few seconds and a glint runs along the gold lead.
- **Light:** the coloured shadows shift as the light moves.
- **Buying:** the pane's picture lifts out of its frame and the figure lands on its tile.
- **Death:** dying figures shatter into shards.
