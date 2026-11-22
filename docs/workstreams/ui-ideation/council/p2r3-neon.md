# Pass 2, round 3 — Council review (Gemini Neon)

*Lens: whole screen as player and designer together. Layout only (no art, no dimming).*

## A — The great window, refit

1. **Card size.** Board (140×250) and fight (112×200) read crisply. Shop units (144×257) are too wide alongside controls and spells, squeezing gaps to 20 px. The hand (74×132) stays bent around the narrow left light in a cramped 3+3+1 stack.
2. **Gaps and packing.** `mid` (36×36, un-nested) beats `mid-b` (62 across, 42 interlocked): `mid` separates front and back rows with even gutters, while `mid-b` reintroduces uneven diagonal tension and merges rows. Across zones, tight shop (20 px) and hand (10 px) clash with the airy board.
3. **The scene.** Filters are gone and the window feels architectural again, though slate-teal panes blend slightly into sage glass. Bright amber `End turn` pulls focus despite 20 gold unspent.
4. **Defects.**
   - `mid`, `first` (shop): 20 px gaps crowd Unit 1 against controls, weakly separating spells.
   - `mid` (left light): Seek's `3` coin touches the slot below.
   - `fight`, `after` (top centre): Gorger's peak nearly touches the arch medallion.
   - `mid`, `first` (bottom right): lit `End turn` steals focus.
5. **Next round.**
   1. Trim shop units (~128×228) or relocate controls so shop gutters match the board and spells group apart.
   2. Move the hand into one horizontal row.
   3. Unlight `End turn` with unspent gold; drop the fight grid ~12 px.

## D — The glazier's bench

1. **Card size.** Shop (118×210), spells (Ø112) and fight (112×200) fit cleanly. Board cards (112×200) over-corrected too small for the huge light table; hand slots (67×120) are tiny on a wide bench. Un-re-decided: the oversized table and pinching tier numerals into the narrow bottom tip.
2. **Gaps and packing.** Shop spacing (40 across, 80 to spells) leads all three. `mid` beats `mid-b` only because `mid-b` (160 px tall, 64 px gaps) shrinks cards into unreadable specks. Yet `mid`'s nested 32 px honeycomb clumps the board; un-nested ~128×228 rows would read better.
3. **The scene.** Filters are gone and the sunlit bench has joy. Still, the vast icy-white table pulls the eye to the board before the shop.
4. **Defects.**
   - `mid`, `mid-b` (shop, board): bottom-tip tier numerals are too small to read comfortably.
   - `mid`, `hover-*` (bench): Seek lacks a cost token, hiding its price.
   - `first` (shop): Unit 2's highlight overlaps Unit 3's coin.
   - `mid`, `fight` (table): ~65% bare white margin steals focus from the shop.
5. **Next round.**
   1. Enlarge board cards (~128×228), un-nest rows, scale or warm the table so the shop leads.
   2. Move tier numerals from the bottom tip.
   3. Grow hand cards (~86×154), restore Seek's cost token, clear Unit 3's coin in `first`.

## E — Glass in the forest

1. **Card size.** Best primary sizing: shop (126×225), spells (⌀126), board (134×240) and fight (120×215) read effortlessly, with tier numerals set cleanly in the top lead cap. Only the hand (63×112, 8 px gaps) stays bent beside the low back row.
2. **Gaps and packing.** `mid` beats `mid-b`. Un-nested 28×28 gutters keep rows crisp, 56 px before spells groups offers, and ~65 px below coins separates zones without bars. `mid-b` (118×210, honeycomb) shows lovely clearing air, but interlocking merges rows and crowds Wing Commander's Renown near Famine-caller's Attack.
3. **The scene.** Filters are gone and the clearing has real joy—sunbeams, fireflies and leaded moss sing. Light and layout lead the eye right: (1) shop and coins, (2) clearing board, (3) controls and unlit `Fight March Hare`.
4. **Defects.**
   - `mid`, `mid-b`, `hover-*` (hand): 63×112 slots cramp over a redundant log; Seek lacks a cost token.
   - `mid`, `fight` (gutters): protruding Renown badges eat half the gutters.
   - `after` (middle row): Holly Knight's `3` nearly hits Eighth Plague's Renown `2`.
   - `after` (bottom left): `Big loss -13` crowds the 7-pip tally bar.
5. **Next round.**
   1. Tuck Renown and `after` ranks inside the top shoulder.
   2. Lift the board ~20 px, drop the log, grow hand cards (~82×146), show Seek's cost.
   3. Clear the `after` plaque above the tally bar.

## 6. Ranking (layout as they stand)

1. **E** — Best overall layout: balanced card scale, crisp un-nested rows, natural shop-to-board eye order and genuine woodland joy, held back mainly by the cramped hand and protruding Renown badges.
2. **A** — Cleanest un-nested board and four-row fight grid with strong legibility, but boxed in by the triptych that squeezes the shop, forces a 3+3+1 hand, and lets lit `End turn` steal first focus.
3. **D** — Joyful sunlit workshop with the cleanest shop-row spacing, but over-shrunk nested board cards huddle inside a glaring oversized white light table with pinched tier numerals and an undersized, unpriced hand.

## 7. One spacing rule for pointed-top hexagon cards

Keep rows **staggered half a slot and un-nested** (never interlocked):
- **Gap across (within a row):** `0.25W` (one quarter of card width).
- **Gap down (between rows of the same board, tip-to-tip):** `0.25W` — equal to the gap across; tapered hex tips create natural diagonal breathing pockets while keeping front and back rows unmistakably separate (`0.20W` across and down fits 4-row fights).
- **Sub-group break (units to spells):** `0.50W` (2× the intra-row gap).
- **Between zones (shop coins to board, or opposing armies in fight):** `0.50W–0.60W` clear of coins and badges.

**Best render:** `/data/ui-ideation/concepts/E/p2r3/mid.png` shows this full hierarchy best on one screen (even un-nested `0.21W` board gutters, `0.44W` unit-to-spell break, and `~0.5W` shop-to-board band), with `/data/ui-ideation/concepts/A/p2r3/mid.png` showing the roomier `0.26W` board gutter cleanest.

From stills, motion, timing, hover feel and sound are not judged.

**Disk:** `/data/ui-ideation/tmp/council-neon` (0 bytes; empty scratch directory).
