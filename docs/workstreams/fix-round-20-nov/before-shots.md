# Before shots on dev: Bramble playable build, origin/dev 5d697e07, 20 Nov 2026

The JPEGs are in `media/before/`, kept in Cloudflare R2: `python tools/assets/assets.py pull docs/workstreams/fix-round-20-nov/media`. The same pull gets the 32 card art candidates (`media/art-masters/`, `a-` and `b-` per card).

All shots are at 1920x1080 in one look session (20261120-144903-ae66ed), run from the detached worktree /data/worktrees/fix-round-dev. The b01 to b10 shots come from one real game (seed 224125) in a Badger-only lobby ("Only" under Badger). The b11 and b12 shots come from a Mouse-only game started afterwards. No fixtures or debug hooks were used. For mid-drag shots I pressed and moved the mouse with `xdotool` on the session's display (`scratchpad/hold-dev.sh`), took a shot, then released.

Differences from main that show in these shots: turn 1 starts with 5 gold. Pigeon and Mouse cards show Supply and Charge pips. Brock Cub is 2/6 and Hedge Knight 2/8. The plan used knights, not cubs, for the triple.

| File | What it shows | How it was reached |
|---|---|---|
| b01a-before-triple-hand6.jpg | Hand 6/7 (cub, 4 Sharpen spells, cub) and two Hedge Knights on the board. A third knight from the shop is held over empty slot 1. All knights glow with the triple glow. | Turn 3: last turn's shop frozen, 2 spells bought. |
| b01-hand-full-triple.jpg | Just after release, the knight lands in slot 1. The hand still reads 6/7. | 2.5 s after release. |
| b01c-golden-forming.jpg | The triple forming: the three knights gather and the hand reads 7/7. | About 3.5 s after release. |
| b01c2-golden-revealed.jpg | The golden 4/16 Hedge Knight revealed on the board, hand 7/7. | About 11 s after release. |
| b01b-triple-reward-missing.jpg | The result: the golden knight is in the hand (far right, gold frame), the hand is 7/7 and the board is empty. The Triple Reward is nowhere and no message says it was lost. The same as main. | About 21 s after release. Code: `recruit.gd:789-808`. |
| b02-full-hand-buy.jpg | Hand 7/7 and an empty board, mid-drag of a shop knight over slot 1. No slot lights up. | Right after b01b. |
| b02b-full-hand-buy-released.jpg | After release: "hand is full" shows and the knight flies back to its shop place. Gold stays at 6. | 3 s after release. |
| b03-hand-to-occupied.jpg | Hedge Knight from the hand, held over the occupied slot 1 (cub 2/6). The six empty slots light amber; the occupied one does not. | Turn 1. |
| b03c-hand-to-occupied-settled.jpg | After release: "choose an empty slot" shows and the knight is back in the hand. | 3.5 s after release. Main's b03b (the moment of release) is not shown separately, because the 0.5 s shot still showed the held frame. |
| b04-triple-highlight.jpg | One cub on the board and two in the shop. All three glow with the strong triple glow. The two shop knights glow too (two shop copies). | Turn 1: bought one cub onto slot 1. |
| b04b-match-highlight.jpg | One cub on the board and one in the shop. The shop copy has the soft glow (MATCH); the board copy has none. | Bought a second cub, then sold it. |
| b05-fight.jpg | Mid-fight: an enemy knight lunges into the cub. No skip button; the footer says "Space or click to skip". | Turn 1's fight, about 4 s in. |
| b06-recruit.jpg | The whole recruit screen at turn 3: gold 10, tier-up 1→2 for 5, refresh 1, "10 left at this price", freeze, "Next turn +11", tier-up drop "−3", End turn, Hand 4/7 (cub, 2 spells, cub), two knights on the board, frozen shop of 3 knights plus a new cub and 2 new spells. | Start of turn 3, after skipping the fight with Space. |
| b07-card-closeup.jpg | Brock Cub enlarged with its tooltip header "TIER 1 · UNIT · SELLS FOR 1", Fury 1 and Grudge, scaled 2x. | Pillow crop of b08b. |
| b08-tooltip.jpg | Hovering Hedge Knight in the shop: "TIER 1 · UNIT · COSTS 2", Guard and Fury 1 lines, then boxes for Guard, Fury 1 and outnumbered (which mentions Squires). The same as main. | Turn 1. |
| b08b-tooltip-grudge.jpg | Hovering Brock Cub on the board: Fury 1 and Grudge, with boxes for Fury 1, Grudge ("+1 Health…") and outnumbered. | Turn 1. |
| b09-board-keywords.jpg | Board: golden knight 4/16 (Guard and Fury 2 marks), cub 3/8 and cub 2/6 (Fury 1 and Grudge marks), and knight 2/8 (Guard and Fury 1). The cubs glow (a cub is still in the shop). Keywords show only as small round marks under each card. | Turn 3, after playing the golden and cubs from the hand and buying a knight. |
| b09b-board-keywords-crop.jpg | The board row from b09, cropped and scaled 2x. | Pillow crop. |
| b10-shop-gold.jpg | The gold meter and tier-up button, then the "10 left at this price", refresh and freeze buttons, scaled 2x. | Two crops from b06 joined. |
| b10b-shop-gold-wide.jpg | The same area uncropped, with the shop row between, to show the real spacing. | Crop from b06. |
| b11-no-art-card.jpg | A Mouse recruit screen at tier 2. Shop place 3 is Hayloft Aunt (T2, 2/9, costs 3), drawn as the plain lattice stand-in panel with a green tribe rim. Its neighbours have art. | Mouse-only game, turn 2: upgraded to tier 2 and refreshed once. |
| b11b-no-art-tooltip.jpg | Hovering Hayloft Aunt: the enlarged stand-in panel and its tooltip "Hand-me-down. Recruit: Add a Cousin to your hand." with boxes for Hand-me-down and Cousin. "Recruit:" has no box. | Same screen. |
| b12-spell-tooltip.jpg | Extra: hovering a hand spell, "Sharpen · SPELL · COSTS 1 · Give a friendly unit +2/+2.", with the stand-in thorn-crown spell art every spell shares. | Turn 3 of the Badger game. |

Not taken: Pigeon Home Guard and Quartermaster (T3 and T4) would need several more turns. Hayloft Aunt shows the same stand-in panel.
