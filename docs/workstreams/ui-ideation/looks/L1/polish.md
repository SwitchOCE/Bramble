# L1 polished buy screen: the plan

## Layout (1920 × 1080, cards 173 × 250, one 20 px gap)

- **Shop, top.** Five unit niches centred on the screen, and one smaller round spell (about 120 px) at each end.
- **Board** four over three, centred. **Hand** full size, half below the screen's edge; a pointed-at card rises whole.
- **Left pier: what you watch.** "Turn 9" on a plaque (the one word). The scoreboard of eight portraits with health: you ringed pale gold, your next opponent ringed red, the knocked-out player grey stone. At the foot: your hero and health, then the Compost and Tide plates, then the library and the cog.
- **Right pier: what you act on.** Level with the shop: tier up (the shop's tier as a numeral and a cost coin; a discount shows the old price struck through above the new one), refresh (a cost coin, and a small numeral for refreshes left at this price), freeze. Below them, largest on that side: gold, with "+12" beside it. End turn at the bottom.
- **Can't afford.** The price coin turns dull pewter. The art is untouched.

## Depth

Each card is a slab of leaded glass: its lower edge shows a few pixels of lit glass edge under the lead, with a tight soft shadow below. A pointed-at card gets a larger, softer shadow, offset further. The wall's niches are recessed, with a stone reveal and an inner shadow. No light shapes on the table.

## Materials and order

Everything uses the cards' materials: lead, glass, stone and gilt. Eight painted pieces are ordered in prompts-4.txt: the pier, two blank roundels, the coin, a plate, the table's edge, the sill and a calmer oak. Icons and light are code.

## Zones

The screen is a church interior: a stone shop wall framed by two windows. Each zone has its own material.

- **Left and right columns: tall lancet windows** of dim diamond quarries (from the earlier build), slate-blue on the left (watch) and moss green on the right (act). A pointed head `l1z-head-*` (244 × 244) sits on a stacked quarry tile `l1z-quarry-*` (244 wide, about 366 tall each), with a lead transom in code over each join.
- **Shop: stone wall** (`l1r-wall`, reused) with five pointed arches `l1z-arch` (each about 228 × 342 round a 188 × 300 opening). The recess is black; code lights it in the tier colour.
- **Left wing:** the spells hang like suncatchers on `l1z-hanger` (about 150 × 225): iron, not stone.
- **Right wing:** the three buttons sit on a slate tablet `l1z-board` (the wing's size).
- **Board and table sides:** one oak top (`l1p-oak-top`, reused).
- **Hand:** the table edge and leather ledge (`l1p-table-edge`, `l1r-leather`, reused).
- **Player health:** a red glass panel `l1z-health`, 212 × 110.

Free textures from the internet (stone, oak) would be photographic and clash with the painted pieces; I'd only use them as reference.

## Heart, hero and End turn

**Pieces.** Health: `l1h-heart` at about 130 × 130 under the gold coin, number in code. Hero: `l1h-hero-frame` at 212 × 144, at the foot of the left column, its top level with the hand ledge. A raised lead-and-gilt tile; pressed, it drops 2 px.

**End turn options** (each 144 px):
- **A. Red roundel, crossed swords** (`l1h-end-swords`). Gold left: steady. Nothing left to do: a slow glow. Fight starting: the swords flash.
- **B. Your next opponent in a red ring** (`l1h-end-ring`, portrait in code, line-drawn swords over it). Gold left: the portrait sits quiet. Done: the ring glows. Fight starting: the swords cross over the face.
- **C. Red glass shield, crossed swords** (`l1h-end-shield`). States as A. The shape sets it apart from every round button.
- **D. A bronze bell** (`l1h-end-bell`) that you ring for the fight. Gold left: still. Done: it glints. Fight: it swings. Part of the room, but less obvious as a button.

**Pick: A**, with B's swords-over-face as its fight-starting moment. Clear at a glance, red for fight, and it matches the other glass buttons. The scoreboard already marks the opponent, so B repeats that.

## Shop level on the wall

**Ideas.** (1) The stonework grows more ornate per level: six steps of carving can't be told apart at a glance, and the detail would be noise behind the cards. (2) Six wall lanterns, one more lit per level: it reads, but small flames sit close to the tier light and add glow near the cards. (3) **Six carved bosses** in the six spandrels, one more gilded per level. I'd build (3): it is quiet, with no light of its own, it is a count rather than a colour, so it can't be confused with the tier light, and it uses the wall's own stone. Lanterns ordered too, to compare.

**Pieces.** `l1s-rosette-stone` and `l1s-rosette-gilt`, 44 × 44, centred in each spandrel: above each colonnette and beside the outer arches, about y 34, with x on the six colonnettes. At level n, the n leftmost bosses are gilt. The tier-up numeral stays: 1–4 gilt bosses read at a glance, while 5 and 6 need a moment's look.

**Level-up** (not judged): the next boss turns from stone to gold, and a single soft glint runs along the arch rims from left to right. Tier light is unchanged.
