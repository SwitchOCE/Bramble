# The L1 look: the buy screen and the card

The design record of the game's buy screen and card. The owner chose the look, L1 ("the card is a window"), on 24 Nov 2026 and approved its buy screen for building on 25 Nov (L42, L44). It is lead and stained glass, as the [art direction](../art-direction/README.md) requires.

| File | What it is |
|---|---|
| [buy-screen-l1.md](buy-screen-l1.md) | The build spec: every place, size, colour and light of the buy screen and the card, each tagged as the owner's decision, the approved mock-up's, or a proposal. `assets/glass/l1/layout.json` cites it by section, and its test requires every entry to. |
| [decisions-l1.md](decisions-l1.md) | The owner's decisions L1 to L51, with their words, and the earlier rows they cite. |
| [buy-screen-l1.jpg](buy-screen-l1.jpg) | The approved mock-up the spec was read from. |
| [buy-screen-l1.rects.json](buy-screen-l1.rects.json), [make-rects.mjs](make-rects.mjs) | Every element the mock-up draws, as rectangles on the 1920 x 1080 stage, and the script that read them out of the mock-up page. A record: nothing in the game or its tests reads the rects, and the script needs the mock-up page, which lives on `ideation/ui-ux`, so it cannot be rerun from here. |

The mock-up page itself, the look's working notes and the build plan are on the branch `ideation/ui-ux`, under `docs/workstreams/ui-ideation/` (`looks/L1/`, `build-plan-l1.md`).

## What the game draws from it

- **The card** is drawn in code (`src/glass/glass_card.gd`, `src/glass/l1_card_face.gd`): one lead frame, the same at every tier and on every screen. No tier frame pictures. Its numbers are in spec section 6; card art is made to fit it by the [card art recipe](../art-direction/card-art-recipe.md).
- **The buy screen** (`src/screens/recruit/`) reads its places from `assets/glass/l1/layout.json`, a hand-kept file, and its painted pieces from `assets/glass/l1/`. Its stand-ins (the states spec section 11 leaves undesigned) keep the earlier look and its numbers.
- **Light** (the tier light in the shop's arches, golden cards, lanterns, End turn) is drawn by the engine, never painted into a picture (L38; spec section 9).

## What is still two-sided

The fight screen keeps the earlier look's room (the stone window, its hero and leaderboard), and it, the shared overlays and the buy screen's stand-ins read the generated `assets/glass/layout.json`, which `tools/glass/pull_mockups.py` pulls from the old mock-ups branch (`design/glass-mockups`). The fight screen draws the new card. Until it has its own design in this look, both layout files are live: don't delete the old pull or the files it writes (`assets/glass/layout.json`, `card_data.json`, `frames/`), and don't take the buy screen's numbers from them. `tools/glass/compare.py` compares scenes with the old mock-ups, so it no longer applies to the buy screen.

## Open

What this look leaves undesigned is in the spec's section 11 and in the [review queue](../review-queue.md) (the L1 look section).
