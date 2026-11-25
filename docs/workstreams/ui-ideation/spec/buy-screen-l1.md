# Build spec: the L1 buy screen

Step 0 of `build-plan-l1.md`. Written 25 Nov 2026 by a design sub-agent of `ideation/ui-ux`, for the Codex workers who build the screen in Godot. **The owner sees this spec before any worker starts.**

## How to use this spec

The design is the mock-up `looks/L1/screen.html?view=polish&room=zones`. Its picture is `/data/ui-ideation/looks/L1/c/c8-spec.png`. (The numbers were first read out against `c7-chosen.png`; three things were then corrected in the page by the orchestrator, the rects re-made, and this spec patched: the tier-up icon, ten refresh beads, and a pewter coin on any price above your gold.) Every number here was read out of that page. You should not need the page's code.

| Plan step | Read |
|---|---|
| All steps | 1 Ground rules, 2 The grid, 3 Pieces, 4 Where the numbers live, 11 Not designed |
| 1 The room and the layout | 5 |
| 2 The card | 6 |
| 3 The shop | 7 |
| 4 The columns | 8 |
| 6 Light | 9 |
| 7 The fight screen | 10 |

Each number carries a tag:

- **O** an owner's decision (with its row in `owner-decisions.md`, L1 to L44).
- **M** drawn in the mock-up the owner approved as a whole ("Everything else is basically perfect", L42; go-ahead L44). Not a separate decision: the owner may still change it.
- **P** a proposal from this spec, to make the build possible. Change it freely.

All positions are on the fixed 1920 x 1080 stage, x right and y down from the top left, in pixels. A rectangle is written `(x, y, w, h)`.

## 1. Ground rules

- The screen plays exactly as it does today. Only its look and places change. No rule, balance or input change (plan).
- **Light is an engine effect, not a picture (O, L38).** Every glow in the mock-up is a stand-in drawn with blurred shapes. Build each as a light, shader or particles, tinted at run time. Never bake a glow into a texture. Section 9 lists them. Until step 6, draw each light as a plain stand-in (a flat tinted shape at the strength given), or not at all.
- **Don't design what this spec doesn't show.** A state in section 11 keeps today's look and behaviour, moved only as far as it must be, until the owner decides. Name it `STAND-IN` in the code, as the game already does.
- **Overflow goes to modals, pop-outs and toasts (O, L35, L36).** The owner's words: "We need to be less focused on how everything fits into one screen and being willing to handle overflow with modals." Don't squeeze a new thing onto the main screen; leave it where it is today and list it.
- The fight screen is fitted, not redesigned (plan, step 7).
- Card-face changes beyond section 6 need the owner's picture-and-yes first.

## 2. The grid

| Rule | Value | Tag |
|---|---|---|
| Stage | 1920 x 1080, letterboxed in any other window shape as today (`GlassScreen._fit`) | M (unchanged) |
| Card | 140 x 250, ratio 0.56 | O (L24) |
| Card points | regular-hexagon angles: point rise = 140 x tan 30° / 2 = 40.4 | O (L8) |
| Side columns | 244 wide each: left x 0 to 244, right x 1676 to 1920 | M |
| Middle | x 244 to 1676 (1432 wide); everything is centred on x = 960 | M |
| Shop wall | y 0 to 350 | M |
| Table (the board) | y 350 to 898 | M |
| Table front edge | y 898 to 924 | M |
| Hand ledge | y 924 to 1080 | M |
| Gap between cards | 20 on the board and in the hand | M |
| Gap between arches | 18 (neighbours share one colonnette) | M |

The screen in words: a church interior. A stone shop wall with five pointed arches, one unit in each, lit from behind in the unit's tier colour. Two spells hang on a chain in the wall's left wing; the three shop buttons sit on a slate tablet in its right wing. Below, a dark oak table holds the board, four over three. The hand rests on a leather ledge at the foot, half below the screen. Each side is a tall, dim lancet window: slate-blue on the left (what you watch: turn, scoreboard, your hero), moss green on the right (what you act on: gold, health, counters, library, settings, End turn).

## 3. Pieces

The painted pieces are in `/data/ui-ideation/looks/L1/pieces/` (34 files, 7.1 MB). They go into `assets/glass/l1/` (plan). The screen uses 20 of them (4.1 MB):

| Piece | File size (px) | Drawn at | Used for |
|---|---|---|---|
| `l1r-wall.jpg` | 1254 x 1254 | tiled 360 x 360 | shop wall |
| `l1p-oak-top.jpg` | 1254 x 1254 | tiled 420 x 420 | table |
| `l1p-table-edge.jpg` | 2172 x 724 | 26 tall, width to scale, repeated across | table front edge |
| `l1r-leather.jpg` | 2084 x 320 | stretched to 1432 x 156 | hand ledge |
| `l1z-quarry-slate.jpg`, `l1z-quarry-moss.jpg` | 488 x 732 | tiled 244 x 366, down the column from y 244 | column glass (left, right) |
| `l1z-headglass-slate.png`, `l1z-headglass-moss.png` | 488 x 488 | 244 x 244 | column heads with their glass (L40) |
| `l1p-pier.jpg` | 887 x 1774 | 244 wide, height to scale | stone behind the heads; the column's two side strips |
| `l1z-arch.png` | 520 x 802 | 224.1 x 326.7 | each shop arch |
| `l1s-lantern-lit.png`, `l1s-lantern-dark.png` | 176 x 339 | 34.3 x 66 | shop level |
| `l1z-hanger.png` | 400 x 3416 | 36 wide (307 tall) | bracket and chain for the spells |
| `l1z-board.png` | 420 x 630 | stretched to 161 x 326 | slate tablet for the shop buttons |
| `l1p-roundel-slate.png` | 598 x 600 | 88 (shop buttons), 72 (library), 64 (settings) | round glass buttons |
| `l1p-coin.png` | 592 x 600 | 42, 44, 46, 112 | costs and gold |
| `l1p-plate.png` | 600 x 165 | 184 x 50 (turn), 124 x 44 (auras) | lead plates |
| `l1h-hero-frame.png` | 520 x 341 | 224 x 154 | your hero's frame |
| `l1h-heart.png` | 320 x 306 | 132 x 126 | your health |
| `l1h-end-swords.png` | 340 x 341 | 144 x 144 | End turn |

Not used by this screen (don't import unless asked): `l1h-end-bell`, `l1h-end-ring`, `l1h-end-shield` (End turn options not chosen), `l1p-roundel-amber`, `l1p-sill`, `l1r-lancet`, `l1r-oak`, `l1r-fight-bluebell`, `l1r-fight-oak` (fight backdrops, not designed at this card size), `l1s-rosette-gilt`, `l1s-rosette-stone` (bosses, not chosen: L43), `l1z-head-slate`, `l1z-head-moss` (inputs to the headglass pieces), `l1z-health` (replaced by the heart, L31).

How each zone piece was cut out and where its openings sit: `looks/L1/zone-pieces.py`. The pieces have transparent grounds and no glow painted in.

Fonts: every word and numeral in the mock-up is Alegreya Sans Bold (`assets/glass/fonts/AlegreyaSans-Bold.ttf`, already in the game).

Icons are line drawings in code. Their SVG paths are in section 13.

## 4. Where the layout numbers live

**Recommendation (P): a new hand-kept file, `assets/glass/l1/layout.json`, read by a small reader (say `L1Layout`, beside `GlassPieces`). Don't hand-edit `assets/glass/layout.json`.**

Why:

- `assets/glass/layout.json` is generated. `tools/glass/pull_mockups.py` writes the whole file from a pinned commit of the old mock-ups branch (`design/glass-mockups`), and records its SHA-256 in `assets/glass/source.json`.
- `tests/glass/test_glass_pieces.gd` (`test_files_match_the_hashes_the_pull_recorded`) checks every pulled file against that hash. A hand edit fails it. Updating the hash by hand hides a real drift, and the next re-pull silently overwrites the edit.
- The fight screen and the other screens still read `layout.json`. Their numbers must not move.
- The new numbers don't come from the old mock-ups, so they can't be pulled. The repo already keeps hand-kept values outside `layout.json` for this reason (`GlassPieces.STAND_IN_ICONS`).
- The pull script never deletes files it didn't write, so a new folder under `assets/glass/` is safe beside it.

Shape: the same as `layout.json`, so the habits carry over. One entry per number: `{"value": ..., "from": "buy-screen-l1.md §7"}`. A test checks that every key the code reads exists and names its section. Rules the spec gives as formulas (the arch row, the board's nesting, the hand row) stay formulas in code, with their inputs in the file. Number keys after the spec's parts (`shop.arch.w`, `board.row_step`, `right.gold.d` and so on).

## 5. Step 1: the room and the layout

### The room

Drawn in this order, back to front. All of it replaces `StoneWindow` (`src/glass/stone_window.gd`, built by `GlassScreen._add_window`) on the buy screen, and the vignette (`GlassScreen._add_vignette`): the mock-up has no vignette over the screen.

| Part | Rect | How it is drawn | Tag |
|---|---|---|---|
| Shop wall | (244, 0, 1432, 350) | `l1r-wall.jpg` tiled 360; over it a vertical gradient from rgba(10,13,18,0.55) at the top to rgba(10,13,18,0.38) at the foot | M |
| Wall foot course | (244, 340, 1432, 10) | vertical gradient #5a5f63 to #33373a | M |
| Table | (244, 350, 1432, 548) | `l1p-oak-top.jpg` tiled 420; over it an elliptical vignette (70% x 80% of the area, centred at 50%, 45%): clear inside 40%, rgba(0,0,0,0.38) at the rim | M |
| Wall's shadow on the table | (244, 350, 1432, 40) | gradient rgba(0,0,0,0.6) at the top to clear | M |
| Hand ledge | (244, 924, 1432, 156) | `l1r-leather.jpg` stretched to fill, brightness 0.55 | M |
| Table front edge | (244, 898, 1432, 26) | `l1p-table-edge.jpg` 26 tall, repeated across; shadow below it (0, 8, blur 12, rgba(0,0,0,0.6)) | M |

**Each side column** (left at x 0, right at x 1676; left uses `slate` pieces, right `moss`):

| Part | Rect (left column) | How | Tag |
|---|---|---|---|
| Glass | (0, 244, 244, 836) | quarry tile, 244 x 366 per tile, first tile's top at y 244; dimmed: brightness 0.5, saturation 0.9 | M, O (L40) |
| Transoms (lead bars) on the tile joins | (0, 239, 244, 10), (0, 605, 244, 10), (0, 971, 244, 10) | vertical gradient #3a4043, #15191a at 60%, #0c0e0f; shadow (0, 2, blur 3, rgba(0,0,0,0.5)) | M, O (L40) |
| Head stone | (0, 0, 244, 244) | `l1p-pier.jpg`, 244 wide | M |
| Head glass | (0, 0, 244, 244) | `l1z-headglass-*.png`, dimmed as the glass | M, O (L40) |
| Side strips (stone mullions) | (0, 244, 12, 836) and (232, 244, 12, 836) | `l1p-pier.jpg` at 244 wide; each casts a 4 px soft shadow inwards | M |
| Shade towards the middle | (0, 0, 244, 1080) | horizontal gradient: rgba(0,0,0,0.45) at the edge next to the middle, clear by 22% of the width | M |

The head glass piece is made so its lead lattice continues the tile below it without a break (the owner: "as if it's continuously panes of glass", L40). Keep the tile's first row at y 244 or the lattice breaks.

### Every element's new place

Today's element, where it goes, and the section that draws it. Nothing new is added in step 1: each element keeps its present art in its new place (plan). The rects are the mock-up's; a today's element of another size is centred in the new rect.

| Element | Today (file, function) | New rect | Section |
|---|---|---|---|
| Shop units 0 to 4 | `RecruitScreen.shop_xy`, `_want_shop` | card at (478 + 206 i, 52, 140, 250) | 7 |
| Shop spells 0, 1 | `RecruitScreen.spell_xy` | disc at (283, 46 + 156 k, 116, 116) | 7 |
| Shop backings | `RecruitShop.build_slots` | the arches (section 7); no backing behind spells | 7 |
| Unit price tag | `RecruitShop.dress_card`, `price_tag` | coin 42 at (nx + 73, 307), under the arch | 7 |
| Spell price | `RecruitShop.dress_card` | coin 44 at the disc's lower right | 7 |
| Tier-up button | `RecruitShop.build_buttons` (`Button_tier`) | roundel 88 at (1538, 24) | 7 |
| Refresh button | same (`Button_refresh`) and the "n left at this price" readout (`RefreshCounter`) | roundel 88 at (1538, 127); readout becomes beads | 7 |
| Freeze button | same (`Button_freeze`) | roundel 88 at (1538, 231) | 7 |
| Gold | same (`Button_gold`, `GoldValue`) | coin 112 at (1742, 34) | 8 |
| Next turn's income | `RecruitButtons._income_badge` (`NextTurnIncome`) | "+12" text at (1738, 152, 120, 34) | 8 |
| Board slots 0 to 6 | `RecruitScreen.slot_xy`, `SlotLayer`, `GlassSlot` | see below | 5, 11 |
| Hand | `RecruitScreen.hand_place`, `_want_hand` | see below | 6 |
| Turn | `GlassScreen._build_hero` (`Turn`) | plate (30, 16, 184, 50) | 8 |
| Scoreboard | `GlassScreen._build_leaderboard` (hidden until Tab) | always shown, left column, portraits at (72, 82 + 103 i, 84, 84) | 8 |
| Your hero | `GlassScreen._build_hero` (`Hero`, `HeroHealth`, hero name) | frame (10, 920, 224, 154) | 8 |
| Your health | `GlassScreen._build_hero` (`HeroHealth`) | heart (1732, 232, 132, 132) | 8 |
| Counters | `GlassCounters.build`, `plate_xy` | medallions in the right column | 8 |
| Card library | `CardsButton` (`src/screens/browser/cards_button.gd`, at `BrowserLook.BUTTON_AT` (1763, 64)) | roundel 62 at (1694, 790) | 8 |
| Settings | `SettingsCog` (`src/game/ui/settings_cog.gd`, `AT` (94, 72), made in `src/main/main.gd`) | roundel 62 at (1840, 790), on the buy screen only | 8 |
| Past boards | the game's Past boards button (`src/game/game_controller.gd`) | roundel 62 at (1767, 790), between the library and settings; until step 4 it may stay where step 1 put it | 8 |
| End turn | `RecruitButtons.build_end_turn` (next opponent's portrait, its health, "End turn" words) | (1726, 894, 144, 144) | 8 |

Kept as they are today, in a place to be decided (section 11): the hand's count and Reserve marks (`RecruitCounts.build_hand_count`, `build_reserve_limit`), the waiting pile (`RecruitWaitingPile`), the message area (`GlassScreen._build_message`), the tier-up discount readout (`TierUpDrop`).

### The position functions tests rely on

Keep these names; they return the new places. About 220 buy-screen tests find things through them (plan).

| Function | Returns (top left) |
|---|---|
| `shop_xy(i)` | (478 + 206 i, 52) |
| `spell_xy(k)` | (283, 46 + 156 k); the disc is 116 x 116 |
| `slot_xy(i)`, front row i = 0 to 3 | (650 + 160 i, 386) |
| `slot_xy(i)`, back row i = 4 to 6 | (730 + 160 (i - 4), 612.9) |
| `hand_place(i, n)` | (960 - (140 n + 20 (n - 1)) / 2 + 160 i, 955, turn 0) |
| `card_box()` | 140 x 250 (unchanged) |

### The board's rule

Four over three, centred on x = 960, every card exactly on its slot (O, L7; M).

- Front row: left edge 960 - (4 x 140 + 3 x 20) / 2 = 650; cards 160 apart.
- Back row: offset half a step (80) to the right; its top is the front row's top plus `row_step`.
- `row_step` = h - p + c x 20 = 250 - 40.4 + 0.866 x 20 = **226.9**, where p is the point rise and c = (1 - sin θ / 2) / cos θ with θ = 30° (the point's slope). The back row nests into the gaps between the front row's points.
- Board height = row_step + 250 = 476.9. The board is centred between the wall's foot (350) and the table edge (898): top = round(350 + (548 - 476.9) / 2) = **386**.
- Nothing is drawn on the table: no slot backings in the mock-up (M). Empty slots are in section 11.

## 6. Step 2: the card

The card is drawn in code (plan choice 3), the same everywhere: shop, board, hand and fight. It replaces the tier frame pictures (`GlassPieces.frame(tier)`, drawn in `GlassCard._draw`) and the golden stand-in rim (`GlassCard.golden`).

**No tier mark on the card (O, L3: "Tier on the board on hover only").** The card never changes with tier. In the shop, tier is the arch's light (section 7).

### Shape and lead

| Part | Value | Tag |
|---|---|---|
| Outline | hexagon (70, 0), (140, 40.4), (140, 209.6), (70, 250), (0, 209.6), (0, 40.4) | O (L8, L24) |
| Lead border | 5 px wide (max(4, round(0.034 w))), following the outline | M |
| Lead colour | linear gradient at 150°: #4a4f4c, #232726 at 30%, #0e1110 at 70%, #262a29 | M |
| Window (art) | the outline inset 5 px; ground #0e1211 | M |
| Art crop | the art file is 560 x 1000; the window shows source x 28 to 532, y 52 to 952 (504 x 900), scaled by 0.2778 to cover the card box | M |
| Glass bevel | over the art: rgba(0,0,0,0.28) at the top fading out by 9% of the height; clear to 88%; then rgba(255,240,210,0.10) at the foot | M |

### Attack and Health

| Part | Value | Tag |
|---|---|---|
| Disc | 34 px circle (round(0.24 w)) | M |
| Attack at | (9.1, 188.5) in the card | M |
| Health at | (96.9, 188.5) in the card | M |
| Face | radial gradient centred at 40%, 35%: #fbf3df, #e6d6b4 at 60%, #c9b48d | M |
| Rim | 3 px #1c201f, then 1 px #555b58 | M |
| Numeral | 20 px, colour #2a2118, nudged down 0.04 em | M |
| Numeral above its printed value | #1f6b34 (dark green) | P (25 Nov: the game's pale green can't be read on the cream disc; same meaning, darker tone) |
| Numeral below its printed value, or hurt | #b02a1c (dark red) | P (same reason) |

The discs are the same on every card, at every tier (the game's per-tier disc places in `card_data.json` stop applying).

### Depth: the slab

Each card is a slab of glass a few pixels thick (L9: "a bit more of a 3D feel"; M).

| Part | Resting | Raised (a hand card pointed at) |
|---|---|---|
| Shadow | the outline offset (1, 7), black at 0.7, blur 5 | offset (6, 26), black at 0.5, blur 18 |
| Edge | the outline offset (0, 5), gradient #2a2f2d to #0b0d0c | same |
| Lit line on the edge | the outline offset (0, 3), rgba(170,190,185,0.22) | same |

These are shadows and solid shapes, not light: build them as drawn. (The game's `card_shadow.gdshader` may serve.)

### Golden

| Part | Value | Tag |
|---|---|---|
| Lead becomes gilt | linear gradient at 143°: #9a5e25, #ffe39a at 16%, #c08636 at 33%, #f2c467 at 55%, #8d521f at 78%, #ffdf8f | O (L1 look: "the lead border and the Attack and Health rims turn to bright gilt"), M |
| Stat rims | 3 px #d9a24a, then 1 px #fff0b8 | M |
| Slab edge | gradient #7a4a18 to #3e240b; lit line rgba(255,214,140,0.55) | M |
| Halo behind the card | light: section 9, G1 | O (L38) |
| Rim glow and twinkle | light: section 9, G2 and G3 | O (L38) |

Golden on the board is drawn in the mock-up (two cards). Golden in the hand or elsewhere is not (section 11).

### A spell in the hand

A disc as wide as a card (140), its top level with the cards' tops (y 955) (M; L34 asked to see it, and the owner did not change it: L42).

| Part | Value |
|---|---|
| Disc | 140 circle, lead ring 6 px (max(3, round(0.04 d))), same lead gradient as a card |
| Hit area | the disc itself (a 140 circle), for pointing and dragging |
| Art | the spell's art in a 128 circle; the window shows source x 90 to 470, y 320 to 700 of the 560 x 1000 file |
| Slab | as a card's, with circles: shadow (1, 7) 0.7 blur 5; edge (0, 5) |
| Raised | top at y 900 (whole disc in view); shadow (1, 22) 0.5 blur 16 |

### The hand

Full size, half below the screen's edge (O, L10). Cards 20 apart in a flat row, centred on x = 960 (M). Today's fan (each card turned) goes: `hand_place` returns turn 0.

| State | Top of card | Shown |
|---|---|---|
| Resting | y 955 | top 125 of 250 |
| Pointed at (unit) | y 822 | the whole card, its foot 8 px above the screen's edge, as the game does today (`RecruitTips.HAND_LIFT_FOOT`) |
| Pointed at (spell disc) | y 900 | the whole disc |

A raised card draws above everything else on the screen. In the mock-up the 7 places hold 6 units and a spell (x 410 to 1510).

## 7. Step 3: the shop

### The arches

Five arches, one per shop unit, centred on x = 960 (M; O, L28: "the arches bigger than the cards themselves").

| Rule | Value | Tag |
|---|---|---|
| Opening | 188 x 294: the card plus 24 each side, 30 above the card's top point, 14 below its foot | O (L28), M |
| Openings' left edges | nx = 454 + 206 i (i = 0 to 4); 18 apart | M |
| Opening top | y 22; foot y 316 | M |
| Card in it | (nx + 24, 52) | M |
| Opening shape | a pointed arch: sides rise to y = 22 + 104.7, then two arcs of radius 0.56 x 188 = 105.3 meet at the top centre (the left arc's centre is on the springing line, 105.3 in from the left side; the right arc mirrors it) | M |
| Recess | the opening grown 4 px each side and at the top: (nx - 4, 18, 196, 298), dark #0b0e0f, lit from behind (section 9, S1); inner shadow: (9, 12, blur 14, rgba(0,0,0,0.7)) and (-4, 0, blur 7, rgba(0,0,0,0.35)) | M |
| Painted arch | `l1z-arch.png` at (nx - 17.9, 1.4, 224.1, 326.7); its opening sits at 8.0% from its left, 6.3% from its top, 83.9% wide, 90.0% tall, laid exactly on the opening | M |
| Cost coin | 42 at (nx + 73, 307): centred under the card, its centre at y 328 | M; O (row 42: "small tags under the cards, with the number inside the coin") |

Recess, then painted arch, then the light on the card, then the card, then the coin.

### Shop level on the wall: lanterns

Six lanterns in the gaps between the arch heads (O, L43: "Lanterns are good"). At level n, the n leftmost are lit. The number on the tier-up button stays (L43).

| Rule | Value | Tag |
|---|---|---|
| Centres | x = 445 + 206 i (i = 0 to 5): over each colonnette and beside the outer arches | M |
| Size | 34.3 x 66, top at y 0, centred on x | M |
| Lit | `l1s-lantern-lit.png`, with a light (section 9, S3) | O (L43) |
| Dark | `l1s-lantern-dark.png` | O (L43) |
| Shadow | (0, 3, blur 3, rgba(0,0,0,0.75)) | M |

The picture shows level 5: five lit, the sixth dark.

### The spells (the left wing)

Two discs one over the other, no arch and no shelf (O, L27), hung from an iron bracket and chain (M).

| Part | Value | Tag |
|---|---|---|
| Disc | 116 circle at (283, 46) and (283, 202); lead ring 5 px; art as the hand spell | M |
| Light behind | section 9, S2 (the spell's tier colour) | M, O (L38) |
| Cost coin | 44, its centre on the disc's rim at the lower right (45°): (360.1, 123.1) and (360.1, 279.1) | O (L26), M |
| Disc shadow | (0, 4, blur 4, rgba(0,0,0,0.6)) | M |
| Hanger | `l1z-hanger.png` 36 wide at x 318.7: the piece's top from y 2 down to y 104 (the upper disc's centre), then the piece from its row 60 (at that scale) from y 104 down to y 260 (the lower disc's centre); behind both discs; shadow (2, 3, blur 2, rgba(0,0,0,0.6)) | M |

**The view state needs each spell's tier** for its light. Today `ViewAdapter._unit` (`src/game/view_adapter.gd`) returns a spell before adding `tier`. Adding it is data the content already has, not a rule change (P).

### The tablet and the three buttons (the right wing)

The shop's buttons on its right (O, L13; L23), on a slate tablet (M), on its centre line and evenly spaced (O, L37: "the big button should be centred").

| Part | Value | Tag |
|---|---|---|
| Tablet | `l1z-board.png` stretched to (1501, 8, 161, 326); shadow (0, 4, blur 5, rgba(0,0,0,0.6)) | M |
| Buttons | `l1p-roundel-slate.png`, 88; centred on x 1582; gaps of 15.5 above, between and below: tops at y 24, 127, 231 | O (L37), M |
| Button shadow | (0, 4, blur 5, rgba(0,0,0,0.65)) | M |
| Cost coin | 46, its centre on the button's rim at the lower right; top-left (1590.1, 76.1) for tier up, (1590.1, 179.1) for refresh. Costs hang off the circle without moving it | O (L26, L37) |
| Tier up | top to bottom: the market-stall icon the owner chose on 18 Nov (row 47; `GlassPieces.STAND_IN_ICONS["shop_up"]`), 40 px, #fbf3dc line, its centre 6 px above the button's centre; the shop's level as a numeral, 22 px, #fbf3dc, centred, its centre 63 px below the button's top | M |
| Refresh | refresh icon 42 px, centred | M |
| Refreshes left | beads on an arc over the refresh button (below) | O (L37: no text; centred on the circle), M |
| Freeze | snowflake icon 42 px, centred | M |

**Refresh beads (M).** One bead per paid refresh left at this price. Centre of the arc: the button's centre (1582, 171). Radius 53 (button radius + 9). Ten beads of 11 px (the rules give ten refreshes at the first price), evenly spread from 180° to 360° (0° = right, angles clockwise on screen, so 270° is straight up). Lit beads first, from the left. Lit: radial #fff6d8, #f0c468 at 55%, #a9741f, with a light (section 9, S4). Spent: radial #4a5258 to #1c2124 at 70%. Each has a 2 px #15191a ring. The picture draws ten beads, seven lit. Later price steps give five beads on the same arc (section 11).

**Can't afford (M).** A price above your gold is a pewter coin: the coin greyscale, brightness 0.62, contrast 0.9; numeral #1d1f20 with no shadow. The art is untouched. In the picture, with 4 gold, the 5-cost spell and the 9-cost tier up are pewter (settled: L47).

### Coins

`l1p-coin.png` scaled to the coin's size. Numeral: Alegreya Sans Bold at 0.56 x the coin's diameter, colour #5a3606, a 1 px light line under it (#ffe9a8), raised by 0.02 x the diameter (the coin's face sits above its middle; L41). Shadow (0, 3, blur 3, rgba(0,0,0,0.6)).

## 8. Step 4: the columns

### Left column: what you watch

| Part | Rect | How | Tag |
|---|---|---|---|
| Turn | (30, 16, 184, 50) | `l1p-plate.png`; "Turn 9", 24 px, #efe6d0, letter-spacing 0.02 em; shadow (0, 3, blur 4, rgba(0,0,0,0.6)) | M |
| Scoreboard rows | portrait 84 at (72, 82 + 103 i), i = 0 to 7 | the player's portrait, round; 4 px #15191a ring, then a 3 px ring: #4d5356 normal, **#e8d49a you**, **#c4553c your next opponent** | O (L14, L19, L23), M |
| Health on each | a heart 50 x 50, its centre on the portrait's rim at the lower right and 2 px down: top-left (96.7, 138.7 + 103 i) | `l1h-heart.png` (the same piece as your own health), drawn to fit; numeral 21 px #fff4ea with a dark red shadow, its centre 2 px above the heart's | O (L26, L47: "I would like the circles on the portraits changed to heart symbols") |
| Next opponent mark | crossed swords, 32 px, at (portrait x + 96, portrait y + 4) | line icon, #e0866e, stroke 2.2 | M (plan choice 5) |
| Knocked out | the portrait greyscale at brightness 0.45; no health heart | | M |
| Your hero | frame (10, 920, 224, 154): `l1h-hero-frame.png` | its top level with the hand ledge (O, L31) | O (L31), M |
| Hero portrait | in the frame's opening: (22.3, 933.5, 199.8, 127.2) (the opening is 5.5% in from the left, 8.8% from the top, 89.2% wide, 82.6% tall) | the portrait covers the opening, focused at 50% across, 28% down; corners 4; a faint inner light line (2 px, rgba(255,236,190,0.25)) and shade at the foot (rgba(0,0,0,0.35), 18 px up, blur 22) | M |
| Hero pressed | drops 2 px (polish.md, not drawn) | | M (text only) |

The scoreboard is always shown (plan choice 4); Tab and the hero click no longer need to toggle it on the buy screen. Rows are in the state's `players` order. The mock-up shows no place numerals and no hero name: both go (section 11 lists them for the owner).

### Right column: what you act on

| Part | Rect | How | Tag |
|---|---|---|---|
| Gold | coin 112 at (1742, 34) | numeral 58 px, raised 0.035 x 112 | O (L41: "a little bit too big", "in the centre"), M |
| Next turn's income | (1738, 152, 120, 34) | "+12": 26 px, #f0d68a, centred; shadow (0, 2, blur 3, #000) | M |
| Your health | (1732, 232, 132, 132) | `l1h-heart.png` contained (132 x 126, centred); numeral 52 px, #fff4ea, shadow (0, 2, blur 3, #5a120a), raised 0.06 em | O (L31) |
| Counters | 4 medallions, 80 each, at (1701, 398), (1803, 398), (1701, 500), (1803, 500) | below | O (L36) |
| Auras plate | (1736, 610, 124, 44) | `l1p-plate.png`; a row, gap 8: four-point star 24 px (#f0d68a, outline #4a3608), the count 24 px #efe6d0, a small right-pointing triangle 14 px #cfc6b0 | O (L36), M |
| Card library | roundel 62 at (1694, 790) | book icon 34 px | O (L15), M |
| Past boards | roundel 62 at (1767, 790) | a clock with a turning-back arrow, 32 px, #fbf3dc line 2.2: `M4.5 12a7.5 7.5 0 1 0 2.4-5.5`, `M4 4.5v4h4`, `M12 8v4.2l2.8 1.8` | P (in the game today; the mock-up had left it out) |
| Settings | roundel 62 at (1840, 790) | cog icon 32 px | M |
| End turn | (1726, 894, 144, 144) | `l1h-end-swords.png` contained; shadow (0, 4, blur 5, rgba(0,0,0,0.65)) | O (L33, L42), M |

**Counters (O, L36).** "Only your highest counters or most recently changed things could show up ... It's fine to have something and X more and you click on a button and it pops out a modal or a tooltip."

- At most four medallions show. While all of a player's counters fit, each keeps its own place and they never swap. Only when there are more than four does the rule choose which four show: the most recently changed first, then the highest (L36); the four shown still sit in their fixed order (P, 25 Nov, after the step 4 review). Places fill left to right, then the next row.
- The plate under them appears only when the player has more counters than the four shown, and then shows how many there are in all (section 11, item 25). It opens the auras panel, which is not designed: until it is, the plate opens nothing. Pressing a heap's medallion opens that heap's own panel, as today (Compost).
- A heap (a counter with `entries`, pressed to open) is a pointy-topped hexagon; any other counter is round (M).
- Medallion: a lead shape (gradient at 150°: #4d5356, #15191a at 40%, #0b0d0c), glass inset 5 px (radial at 40%, 30%, three colours per counter), a line icon 40 px (#fbf3dc, stroke 2), shadow (0, 4, blur 4, rgba(0,0,0,0.65)).
- Number: a cream badge, its centre on the medallion's rim at the lower right. 34 x 34 round; 52 x 34 for three digits, nudged 2.7 left. Radial #fffaf0 to #e9dcbb at 70%; rings 3 px #15191a and 1 px #6a6f70; numeral 20 px #2a2016.
- The mock-up's four (stand-ins, not the game's counters): green heap (#7da35c, #3f6a2c, #1f3a16; leaf), blue (#6fa3c8, #2f6490, #143454; waves), orange (#d58a4e, #9a4a1c, #4e220a; flame), purple (#9a82c4, #5a4390, #2a1c52; hourglass).
- A changed number pops, as today (`GlassCounters._pop`).

**End turn (O, L33; option A, M).** Red glass roundel with crossed swords. It is no longer the next opponent's portrait: the scoreboard marks the opponent (plan choice 5). Its states are in section 9 (E1) and section 11.

## 9. Step 6: light

Every row is an engine effect (O, L38: "There needs to be some sort of lighting effect in Godot rather than some sort of static asset. And the twinkles on the gold borders are going to fall into the same kind of bucket."). The mock-up's values are where to start, not targets: the engine's look will differ, and the owner judges it filmed, in motion. Motion, timing, hover feel and sound are **not judged** from the mock-up.

### Tier colours and strengths

The owner: tier light "can be pretty subtle", tier 6 "a bit more than what our tier four is, and a bit less than what our tier five is, in terms of lighting strength", "the scale should start at the same point from tier one" (O, L5). Tier 5 is orange, not yellow (O, L4), so gold belongs to golden alone.

| Tier | Colour | Strength a |
|---|---|---|
| 1 | #D6DEE8 (214, 222, 232) grey daylight | 0.30 |
| 2 | #68CD70 (104, 205, 112) green | 0.34 |
| 3 | #5496F0 (84, 150, 240) blue | 0.38 |
| 4 | #A870F0 (168, 112, 240) purple | 0.42 |
| 5 | #FF8C2C (255, 140, 44) orange | 0.52 |
| 6 | #EC4634 (236, 70, 52) red | 0.47 |

Each light below uses a share of a (opacity = share x a, capped at 1).

### The lights

| # | Light | Purpose | Where | Mock-up stand-in |
|---|---|---|---|---|
| S1 | Shop tier light | Shows each shop unit's tier without a mark on the card (L3, L5, L28) | Each arch: the recess lit from behind; a halo hugging the card; light spilling onto the wall round the arch; a pool on the opening's foot; a faint tint on the arch's stone | Recess: radial ellipse 80% x 64% centred 50%, 55%: 1.5a at the centre, 0.9a at 58%, 0.34a at the rim, over #0b0e0f. Halo: the card's outline grown 8 px, 1.8a, blur 9. Spill: the arch outline grown 9 px, 0.5a, blur 14. Pool: (nx, 312, 188, 20), radial from 50%, 10%: 1.2a to clear at 70%, blur 3. Stone tint: 0.34a, soft light, inside the painted arch only |
| S2 | Spell tier light | Shows a shop spell's tier | Behind each shop spell disc | Outer: circle 20 px wider than the disc, 0.7a, blur 20. Inner: circle 10 px wider, 1.8a, blur 7 |
| S3 | Lit lantern | Counts the shop's level (L43) | Round each lit lantern | Circle 52 centred (x, 40), rgba(255,206,120,0.5), blur 10 |
| S4 | Lit bead | Refreshes left at this price | Round each lit bead | 6 px glow, rgba(255,214,130,0.7) |
| G1 | Golden halo | Marks a golden unit from across the board | Behind a golden card | The outline grown 7 px, rgba(255,196,96,0.8), blur 8 |
| G2 | Golden rims | Gilt catches light | Round the Attack and Health discs of a golden card | 6 px glow, #ffd27a |
| G3 | Golden twinkle | A slow glint runs along the gilt every few seconds (L1 look) | Along the gilt lead | A still four-point star, 21 px, at the card's upper right shoulder (140, 40.4): white core #fffbe8, glow #ffe08a. The owner names this as an effect (L38) |
| E1 | End turn | Says when you have done everything, and when the fight starts | The End turn button | Not drawn. polish.md (art director, option A): gold left: steady; nothing left to do: a slow glow; fight starting: the swords flash (and, borrowed from option B, swords cross over the opponent's face) |

**Motion the notes ask for (not judged):** the arches breathe slowly, tier 6 strongest; the golden glint every few seconds and its light flickering a little; when a unit becomes golden, the lead lights from the bottom point to the top (look.md).

**Lights the game already has, kept:** the duplicate glow (`GlassDuplicateGlow`), the triple foil (`card_triple_foil.gdshader`), the hovered card's glow (`GlassTips` "hot"). How they look on the new frame is not designed (section 11).

**How to judge.** Agents can't judge light or motion (`docs/AGENT-BLIND-SPOTS.md`). Film each with `tools/feel` at 60 fps and give it to the owner. In the screenshot compare (`tools/look`), mask the lit areas, or workers copy the stand-ins (plan): the arches and the wall round them (436 to 1484, 0 to 350), the spells (233 to 449, 0 to 368), the lanterns (row y 0 to 90), the beads (1520 to 1645, 108 to 168), and each golden card's halo (the card grown 23 px each side).

## 10. Step 7: the fight screen

- Change on the fight screen only what steps 1 to 4 break (plan). No new fight design: the fight at this card size is not designed (L35).
- The card (section 6) changes there too: same frame, discs, golden and slab. A fight board card has no tier light.
- `GlassScreen._build_hero`, `_build_leaderboard`, `_add_window` and `_add_vignette` are shared with the fight screen (`src/screens/fight/fight_screen.gd`). Put the new buy-screen versions in the recruit screen (override), so the fight keeps its stone window, left-light hero, Tab leaderboard and vignette.
- `SettingsCog` is made once in `main.gd` for both screens. Give it a place per screen: (1818, 790) at 64 on the buy screen, today's (94, 72) on the fight.

## 11. States: designed and not designed

### Designed (drawn in the mock-up or written in its notes)

| Element | State | Look | Tag |
|---|---|---|---|
| Shop unit | tier 1 to 6 | the arch's light in the tier's colour and strength (S1) | O (L5), M |
| Shop level | 1 to 6 | n leftmost lanterns lit; the numeral on tier up | O (L43) |
| Any price | above your gold | pewter coin | M |
| Board unit | golden | gilt lead and rims, halo, twinkle | O (look), M |
| Hand card | pointed at | raised to y 822 (spell 900), wholly on the screen, larger shadow, above all | O (L10), M |
| Scoreboard row | you / next opponent / knocked out / other | ring #e8d49a / ring #c4553c and swords / grey, no health / ring #4d5356 | M |
| Counters | four or more | four shown (most recent first, then highest), the plate gives the count and opens the rest | O (L36) |
| Counter number | one, two, three digits | badge 34 round, or 52 x 34 | M |
| Refresh | refreshes left at this price | beads, lit for each left | O (L37), M |
| Hero | pressed | drops 2 px | M (text only) |

### Not designed: ask the owner before building

Until the owner decides, each keeps today's look and behaviour, as close to its old place as the new layout allows, marked `STAND-IN`. **Ask** marks one that conflicts with an earlier owner decision.

**The shop**

1. **Frozen shop.** Today: frost over each shop card (`GlassParts.add_frost`) and on the freeze button. Not drawn.
2. **An empty arch** after a buy (the state's `null` place), and an empty spell place. Lit or dark, coin or not: not drawn. **Pick (P, orchestrator, 25 Nov): an empty arch stays dark, with no tier light and no coin; an empty spell place shows the bare chain.**
3. **Tier up at level 6.** The state then has no `upgrade_cost` and today the button goes. What the tablet's top place shows: not drawn. **Pick (P): the button stays, shows 6 and carries no coin; all six lanterns are lit.**
4. **Settled (L47): the tier-up discount shows only when the button is pointed at** (in its hover tip: today's "−n next turn" words). Nothing marks it on the tablet.
5. **Settled: the tier-up icon** is the owner-selected market-stall icon (row 47), as the game draws it today. The mock-up's chevron was a stand-in and is gone.
6. **The refresh beads after the first price step.** Ten beads are drawn for the first step (10 paid refreshes, `GameConfig.refresh_first_step_after`). Later steps give 5 (`refresh_step_length`): show five beads on the same arc (P). A free refresh (cost 0) and a refresh cost of two digits are not drawn.
7. **Settled (L47): can't afford greys only the coin.** Every price above your gold, on a card, a spell or a button, is a pewter coin; the art is untouched. This replaces row 27.
8. **A button whose action isn't legal** (freeze limit reached, no gold to refresh and so on). Today it is dimmed (`RecruitScreen.SHORT_DIM`). Not drawn.
9. **Two-digit costs** on tier up (12 to 26 before discounts). Not drawn.
10. **A shop card pointed at or carried away from its arch.** Not drawn.

**The board and the card**

11. **Empty board slot,** and a slot with a buff, keyword or Renown (today `GlassSlot`; row 38: an empty buffed slot shows its values where a card's Attack and Health would be). The mock-up draws nothing on the table.
12. **Lit drop targets and the drop preview** (`RecruitBoard`), and **the sell area** while a board card is carried (`RecruitShop.show_sell`).
13. **The card face's extras:** keyword pills (row 22), Charge and Supply pips (`CardPips`), the Worked mark, ability buttons (`RecruitButtons.add_ability_buttons`), numbers above or below the printed ones drawn green or red. Keep them on the new frame as today; any change needs the owner's picture-and-yes.
14. **Three-digit Attack or Health** in a 34 px disc. Not drawn.
15. **How tier shows on hover** for a board or hand card (L3). Until the light step: the hover detail's words name the tier, as today. **Pick (P): in the light step, a card pointed at gets its tier's halo, the same light that hugs a shop card (S1's halo), and nothing is drawn on the card.**
16. **Golden in the hand, in Discover or on the fight board.** Only the board is drawn. Whether the halo shows there: not drawn.
17. **Duplicate glow and triple foil** on the new frame (rows 28 to 31).
18. **A carried card** (today `CardCarry`'s tilt and float). Its shadow: not drawn.

**The hover detail**

19. **Settled (L52, which corrects the reading of L45): the card's hover detail is the card's enlarged copy and its words beside the pointed-at card, at the size it has on `dev`, never shrunk into a column. Keyword reminders are a separate thing in their own fixed, out-of-the-way place (a side column is allowed), visibly not part of the card's detail.** The first build stacked both in the left column; that was this spec's mistake.

**The hand**

20. **The hand's count, Reserve marks and the waiting pile** (row 56). No place in the mock-up. **Pick (P): today's count and marks at the right-hand end of the hand ledge (about x 1560 to 1660, y 940), the waiting pile beside them.**
21. **A hand card while its target is chosen,** and the message area ("Choose a target" and the game's messages; today on the old window's transom, which is gone). **Pick (P): messages are a toast centred on the table's front edge (y 898 to 924), above the hand; the owner named toasts as a way to handle overflow (L35).**
22. **A full hand.** Seven cards are drawn (six units and a spell); nothing marks the hand as full, and a card gained then goes to the waiting pile (item 20). **More than 7 cards in the hand** (a modifier could raise the limit; up to 9 fit inside the middle, 10 do not).

**The columns**

23. **Counters: none, and one to three.** Where they sit and what the plate shows with none. **Pick (P, orchestrator, 25 Nov): medallions fill the four places in order (upper left, upper right, lower left, lower right); with none, nothing is drawn there.**
24. **Each counter's medallion colour and icon.** The game's display table names only an emblem picture (`icon`, `assets/glass/ui/tr-<icon>.png`). Where the glass colour and line icon come from: not designed. **Pick (P): Compost is the green heap with the leaf and Tide the blue round one with the waves, as the mock-up draws them (section 8). Any other counter is a slate-glass medallion (#6f8597, #3a4f5e, #1a2731) carrying today's emblem picture at 40 px, marked `STAND-IN`.**
25. **What the auras plate counts,** and the panel it opens (out of scope; today's Compost panel stands in). **Pick (P): the plate shows only when the player has more counters than the four shown, and then counts all of them. The game has at most two counters today, so the plate does not appear in this build; build it, hidden, with a test that it appears at five. It opens nothing until the auras panel is designed.**
26. **Settled (L47): no place numerals and no hero names on the scoreboard.** The order shows the place; the name is on today's player hover card.
27. **Gold of two or three digits** in the 112 coin, and **health of three digits** in the heart. Not drawn.
28. **End turn's states** (E1): the art director's words only. "Nothing left to do" has no flag in the state; reading it from `legal_actions` (no buy, refresh or upgrade listed) is a proposal (P). **Pick (P): until the light step, one steady look for every state, and today's pressed feedback. No words on or under the button.**
29. **Settled: the scoreboard always shows on the buy screen.** Pressing your hero does nothing yet (it shows the pressed state only), and Tab does not hide the scoreboard here. The fight screen keeps today's Tab behaviour.
30. **Pointing at a scoreboard portrait** shows that player's name, and nothing else, on a small plate beside the column (L47: "the name appears when you point at a portrait"). The game had no such card before; it is new and small. No tier, no Health (the heart shows it).
31. **Level-up.** The art director's moment was written for the bosses (polish.md); none for the lanterns.

**Other**

32. **Discover, the Compost panel, the pause panel, the card library:** today's overlays, unchanged.
33. **Motion** (turn start, triple, buy and sell flights, hover raise): today's, not judged.
34. **Accessibility.** Tier in the shop is told by colour and strength alone. Colour-blind cues, keyboard use of the shop buttons and reduced motion are not designed.

## 12. Numbers each shape must hold

| Shape | Drawn with | Real range | Note |
|---|---|---|---|
| Stat disc 34 | up to 26 | 0 to 1,000,000,000 (`stat_max`) | 3+ digits: item 14 |
| Shop cost coin 42 | 3 | 1 to 3 for units | fits |
| Spell cost coin 44 | 1, 5 | spell prices | fits |
| Tier-up coin 46 | 9 | 0 to 26 | item 9 |
| Refresh coin 46 | 1 | 1, then +1 for every 5 paid after the first 10; 0 when free | item 6 |
| Gold coin 112 | 4 | 0 up; income has no ceiling | item 27 |
| Heart 132 | 11 | 0 to 40 (start) | fits; item 27 |
| Scoreboard health 44 | 31 | 0 to 40 | fits |
| Counter badge | 1 to 148 | any | 4+ digits not drawn |
| Turn plate | "Turn 9" | up to "Turn 50" (`round_limit`) | fits |

## 13. Appendix: icons

Line icons drawn in code on a 24 x 24 box, round caps and joins, no fill unless given. The game has its own icon set (`GlassPieces.icon`); where an icon already exists there (refresh, freeze), use the game's. See item 5 for tier up.

| Icon | Stroke | SVG path |
|---|---|---|
| Tier up (market stall, row 47) | #fbf3dc, 1.7 | the game's `GlassPieces.STAND_IN_ICONS["shop_up"]`: `M3 9h12l-1.5-4h-9z`, `M3 9a2 2 0 0 0 4 0a2 2 0 0 0 4 0a2 2 0 0 0 4 0`, `M4.5 11v8M13.5 11v8M3 19h12`, `M20.5 19V7M18 9.5l2.5-2.5 2.5 2.5` |
| Refresh | #fbf3dc, 2.6 | `M19 8a7.5 7.5 0 1 0 .8 6.5` and `M20 3v5.5h-5.5` |
| Freeze | #f4fbff, 2.2 | `M12 2.5v19M3.8 7.25l16.4 9.5M3.8 16.75l16.4-9.5` and `M9.3 4.3L12 7l2.7-2.7M9.3 19.7L12 17l2.7 2.7` |
| Book (library) | #fbf3dc, 2 | `M12 6.5C9.5 4.8 6.5 4.5 3.5 5v13c3-.5 6-.2 8.5 1.5 2.5-1.7 5.5-2 8.5-1.5V5c-3-.5-6-.2-8.5 1.5z` and `M12 6.5v13` |
| Cog (settings) | #fbf3dc, 2 | circle at (12, 12) r 3.2, and `M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1M16.6 16.6l2.1 2.1M5.3 18.7l2.1-2.1M16.6 7.4l2.1-2.1` |
| Crossed swords (scoreboard) | #e0866e, 2.2 | `M5 4l12 12M19 4L7 16`, `M14 18l4-4M10 18l-4-4`, `M17.5 17.5l2 2M6.5 17.5l-2 2` |
| Auras star | fill #f0d68a, outline #4a3608 1.2 | `M12 2.5l2.3 6.2 6.2 2.3-6.2 2.3L12 19.5l-2.3-6.2-6.2-2.3 6.2-2.3z` |
| Plate's "more" triangle | fill #cfc6b0 (10 x 10 box) | `M2.5 1.5l5 3.5-5 3.5z` |
| Counter stand-ins | #fbf3dc, 2 | leaf `M5 19c0-8 5-13 14-14-1 9-6 14-14 14z` and `M5 19l8-8`; waves `M3 9c2.5-2.5 4.5-2.5 6 0s3.5 2.5 6 0 4.5-2.5 6 0M3 15c2.5-2.5 4.5-2.5 6 0s3.5 2.5 6 0 4.5-2.5 6 0`; flame `M12 3c1 4 5 6 5 10a5 5 0 0 1-10 0c0-2 1-3 2-4 0 2 1 3 2 3 0-3-1-6 1-9z`; hourglass `M7 3h10M7 21h10M8 3c0 5 8 5 8 9s-8 4-8 9M16 3c0 5-8 5-8 9s8 4 8 9` |

## 14. Out of scope

From the plan: the auras panel (the plate shows the count and opens today's Compost panel), a new Compost panel, the card library's and settings' own screens (only their buttons move), a landing screen, the hero power, calmer card art (L6), the fight screen's design at this card size, and any rule or balance change.

## 15. How the numbers were made and checked

- `spec/make-rects.mjs` loads the page in headless Chrome over the DevTools protocol and writes `spec/buy-screen-l1.rects.json`: all 193 elements the page draws, by part name and role (piece, light, shadow, card, text, drawn), plus the raised hand card and spell (`hover=2`, `hover=6`). Rerun it with `node docs/workstreams/ui-ideation/spec/make-rects.mjs`.
- The formulas in this spec (arch row, board nesting, hand row, lanterns, beads, coins on rims) were read from the page's `polish()` and checked against the read-out rects.
- Checked against the picture on 25 Nov: a fresh render matches `c7-chosen.png` pixel for pixel. Nineteen rects were outlined on it and each lands on the thing it names: shop card 3, arch 5, the dark lantern, spell 2, the tablet, the refresh button, the tier-up coin, golden board card 7, the hand's spell, scoreboard row 5 and its health, the hero frame, gold, the heart, counter 3, the auras plate, the library, End turn and the table edge.
- Today's game was read on `dev` at `16da2ade` (`/data/worktrees/l1-dev-read`).
