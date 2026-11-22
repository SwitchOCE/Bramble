# Pass 2, round 3: Opus, player lens (hundredth game)

Seen at full size: `mid`, `mid-b`, `fight`, `hover-board` for A, D and E; `hover-spell` for A and E. Not opened in time: `first`, `after`, `hover-shop`, `keywords-off`, `cards`, and D's `hover-spell`. Motion, timing, hover feel and sound: not judged.

## A

1. **Card size.** Shop 144 and board 140 are both right for reading stats at a glance. The hand at 74 px wide is too small: it's half the board's width, set in a 3+3+1 grid that's still bent around the narrow left column.
2. **Gaps.** A 36 px gap across and down reads evenly. The empty space is in the wrong place, though: about 270 px of empty table on each side of the board, while the back row sits about 30 px off the window's bottom edge and the left column has a dead band at y≈300–540. `mid` beats `mid-b`: in `mid-b` the back row's tier tabs poke between front cards, so rows stop scanning as rows.
3. **Scene.** The filters are gone. The joy is only partly back: the window is a single tone. The eye goes to End turn first (the one warm object), then the shop, then the board. For buying, the shop should come first.
4. **Defects.** `hover-spell`: the tooltip covers shop units 4–5's Attack and Health while you compare. `mid`: the six empty hand slots are solid dark panes, heavier than the one real hand card, and read as face-down cards. `mid`: spell 2's right edge sits about 10 px from the window frame.
5. **Next.** Move the hand out of the side column and give it room. Spread the board wider and lift it off the bottom edge. Open tooltips away from the row being compared.

## D

1. **Card size.** At 112 the board is too small for its table: it fills about 45% of the width and leaves a blank sheet around it. The shop at 118 is slightly larger than the board. The hand at 67, dashed on the bench, is the quietest hand of the three.
2. **Gaps.** One 32 px gap, nested rows. Nesting merges the board into one honeycomb, so I find a slot by counting, not at a glance. `mid` beats `mid-b` (smaller cards, so numerals and coins crowd), but the answer is bigger than `mid`, not smaller.
3. **Scene.** No filters. The frame (stone, leaves, wood) has joy, but the two main panels are flat pale fills, so the empty space is dead rather than restful. The eye goes to the portrait and the gold coin first, the shop second and the board third.
4. **Defects.** `mid`: the tier numerals at the bottom point are about 13 px and sit between the stat discs, slow to read. `fight`: the enemy back row's points touch the front row's tier marks (about 10 px apart). `mid`: the price coins overlap the cards' top-left corners.
5. **Next.** Grow the board cards to fill the table. Un-nest the rows. Give the panels something lit to lead the eye, not a flat sheet.

## E

1. **Card size.** Right. The board (134) is larger than the shop (126), which suits where you place and compare. Fight at 120 fills the height. The hand at 63 is too small: once art is back, a Discovered unit will be hard to tell at that size.
2. **Gaps.** A 28 px gap across and down, rows offset but not interlocked, so it scans cleanly. `mid` beats `mid-b`: the honeycomb in `mid-b` merges the rows, as the designer says.
3. **Scene.** The filters are gone and the joy is back: fireflies, and a shaft of light that falls on the board's clearing. The layout and the light agree. The eye goes to the gold coin first, the shop row second and the board third, which is the right order for buying.
4. **Defects.** `fight`: the enemy back row's tier tabs are about 40 px from the top edge while the sides are empty. `mid`: the hand bar's right end (x≈700) almost meets the back row's left card (x≈730). `mid`: the Seek socket sits over hand slot 1's outline. `hover-spell`: the tooltip covers shop units 4–5's stats.
5. **Next.** A bigger hand with clear air between it and the board. Lower the fight a little, or shrink it slightly. Tooltips should not cover the row you are comparing.

## Rank (layout)

1. **E.** The biggest board, even gaps, and the scene's light leads to the board.
2. **A.** Clean rows and clear zones, but its empty space sits on the board's sides instead of where things are cramped.
3. **D.** The best hand, but cards too small in big flat panels, and nested rows.

## One spacing rule

One gap, equal across and down, of about 0.2–0.25 of the card's width. Rows are not interlocked: the back row of three is centred under the front four, so the half-step offset happens on its own. Between zones (shop to board, army to army) leave at least half a card width. See **E `mid`**: 28/134 ≈ 0.21 across and down, and shop to board about 0.8 card widths. A's `fight` shows the army-to-army gap well: 68/112 ≈ 0.6.

**Disk:** created the empty folder `/data/ui-ideation/tmp/council-opus-player` (0 B). Nothing else written besides this file.
