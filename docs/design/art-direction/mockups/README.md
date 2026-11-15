# Mock-ups in lead and stained glass

Higher-fidelity screens built from the real pieces: the six locked tier frames, fighter art made by the card art recipe, and Attack and Health drawn on each tier's own discs. Plan: [../../../workstreams/glass-mockups.md](../../../workstreams/glass-mockups.md). Nothing here is decided; the owner judges it.

Open `recruit.html` or `cards.html` straight from disk in a browser. The switches above the recruit screen choose the card size, the leaderboard and a pinned hover. `?shot` hides them.

## Screens

| Shot | What it shows |
|---|---|
| [recruit-212.jpg](shots/recruit-212.jpg) | Recruit screen, cards 212 px tall (the first mock-up's card height) |
| [recruit-250.jpg](shots/recruit-250.jpg) | The same with cards 250 px tall |
| [recruit-250-leaderboard-hover.jpg](shots/recruit-250-leaderboard-hover.jpg) | 250 px, leaderboard shown, a board card hovered |
| [recruit-212-leaderboard-hover.jpg](shots/recruit-212-leaderboard-hover.jpg) | 212 px, leaderboard shown, a shop card hovered |
| [card-sheet.jpg](shots/card-sheet.jpg) | Every tier at both sizes and at 2x, one- and two-digit numbers |

## How a card is made

`card.js` makes every card, at any size:

1. **Art:** the Codex picture moved into card space with the recipe's fixed crop (`tools/art/mockups/prep_assets.py`), clipped on screen to the recipe's art polygon. Never fitted by hand.
2. **Frame:** the tier's PNG from `frame-lab/final/`, on top.
3. **Numbers:** Attack on the left disc, Health on the right, centred on that tier's own disc and sized from its radius, from `frame-lab/final/roundels.json`.

`prep_assets.py` also checks that every frame's window lies inside the art polygon (no gaps on any tier); all six pass. The art session checked each of the 24 pictures against the guide (every edge within 6 px).

`assets/card-data.js` holds the disc positions and the art polygon so the pages work without a server. Rebuild the assets after a frame or the art changes:

```
python tools/art/mockups/prep_assets.py <folder of run folders of 1024 x 1536 pictures> --window <the recipe's tools/art/glass-art/window.json>
```

Screenshots: `tools/art/mockups/shot.sh <page> "<query>" <out.png> [height]` (headless Edge, 1920 wide).

## Stand-ins

- **Spells:** no spell frame exists yet. The two shop spells are the recipe's spell picture in a plain lead outline with a cost disc.
- **Names, numbers and hover text:** placeholders. The art is the art session's test set (12 subjects, two runs each, from `window-art-test/margin-8` on the Optiplex), not decided units.
- **The window, stone, buttons, portraits, empty slot, Ring slot, the hero's two chips and the fanned hand** are the first glass mock-up's, with the window redrawn to fit the new card sizes. The hand count reads /10, the rulebook's hand limit (7.1.1); the first mock-up said /7.

## Sources

The first mock-up's page and assets: Optiplex `/data/bramble-art/stained-glass/glass/`. The fighter PNGs: Optiplex `/data/bramble-art/stained-glass/window-art-test/margin-8/out/`.
