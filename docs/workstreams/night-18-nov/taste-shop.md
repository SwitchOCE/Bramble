# Shop — briefs 1 and 3

## Taste calls

- **Coin:** needed a clearer gold drawing and number. Weighed a milled coin with bold sans figures, a faceted face with Alegreya, and a sunburst with lower-set Alegreya. Chose A for the larger open numerals; the three candidates are in `tests/screens/shop_coins.tscn` and the media sheet. `GoldCoin.SELECTED` and its sizing constants keep this reversible.
- **Attack / Health:** the existing cream discs could read as price coins. Weighed keeping the discs with new colours against changing their silhouette. Chose an amber-brown diamond and a red shield with light numbers, everywhere unit cards draw; the coin keeps its gold meaning. Colours and shapes live together in `GlassCard`.
- **Tags / spell shoulder:** used the approved 44 px hanging unit coin and the spell's left shoulder, with the 176 × 68 px shop buttons and 46 px button coins. The geometry follows the approved `geom(54)` exactly: shop top 138.5, board top 486.5, hand top 980. Constants live in `RecruitShop`.
- **Hand spells (review correction):** gold coins on hand spells were an unapproved difference from the mock-up. Restored the original cream cost disc, including its font, size and left-shoulder position; only shop offers receive gold coins. The regression test buys a spell and checks that its coin becomes a cream disc in hand.
- **Refresh count:** weighed words against pips. Chose “X left at this price”, 19 px above Refresh, as the mock-up shows; it reads an exact remaining count and still handles late-turn price steps. The value comes from `Rules`, including tunable thresholds.
- **Sell cue:** uses the approved dim shop overlay and “Sell for” with a 58 px numbered coin, appearing while a board unit is carried into the existing sell area. The value comes from the rules' view, so Created copies add zero. The first film exposed the card covering the value, so the caption now sits on the opposite side, with a 20 px middle dead band to keep it steady. Position and sizes live in `RecruitShop`; no selling routes were added.

## Scope and questions

- Encountered the board-only sale route (rulebook 4.3.7) and board-only movement (7.2.4); left both for the rule-gap branch as instructed. The sell cue uses the actual board unit's value; it doesn't estimate a value from tier alone.
- Play effects on recruit, recruit effects on non-buy arrivals, and Triple Reward timing remain the known deferred rule gaps. Nothing in these prices or the displayed sell value depends on changing them.
- Free and effect refresh grants have no shipped caller yet. A Refresh whose rule query is reduced to zero now leaves the paid counter alone (4.4.5); no content or new refresh-grant API was introduced.
- Question for later: the approved page omits the existing activated-ability buttons. Where should they sit after the keyword work? Their current controls remain so the actions stay available.
- The approved page has no full-screen `?shot` mode. `tests/screens/shop_reference.html` embeds that unedited page and hides its presentation around the stage. Brief 4 now switches duplicate glow on in that adapter; keyword marks and the Cards button remain in the reference and are recorded comparison differences.

## Verification

Initial implementation: `e86b3db7`. PR 121 review fixes: `0663a429` (hand spell) and `393e9ca0` (dead code and notes). All three comparisons below were rerun from the clean committed tree at `393e9ca0eb17386b2655930149ef943f351befbb`, the final code revision. The following evidence commit changes this report only. No files under `docs/design/mockups/` changed.

| Check | Result |
|---|---|
| Every unit tier | UI integration checks core prices 2–7 for tiers 1–6 |
| Every shipped spell | Shop offers: Sharpen 1, Seek 3, Forage 5, with left-shoulder coins. Hand spells retain the original cream cost discs. |
| Can't afford | Checks at 2 gold; a later change to 20 brightens unit and spell coins, while card art stays bright |
| Tier up | 176 × 68 button, 46 px cost coin; hidden at tier 6 |
| Sell value | Mixed-origin golden: 6 for two Bought tier-6 copies; all Created: 0; caption clears on release and focus loss |
| Refresh | Walks 17 paid refreshes: prices 1 → 2 → 3 at paid counts 10 and 15; asserts the remaining count at every step; free refresh at counts 9 and 14 leaves gold/count unchanged; next turn resets to 10 and price 1 |
| Coin candidates | Three drawings/fonts/placements side by side, at 46 px and enlarged; 1, 7, 26 and 120; same-coin Attack/Health before and after |
| 1920 × 1080 compare | Mean 4.58/255; 3.09% of pixels differ by >32; all 144 regions in `compare-1920/result.json`; commit `393e9ca0`, clean tree |
| 1366 × 768 compare | Mean 7.73/255; 5.92% of pixels differ by >32; all 144 regions in `compare-1366/result.json`; commit `393e9ca0`, clean tree |
| 1366 × 768 can't-afford | Mean 7.71/255; 5.89% of pixels differ by >32; all 144 regions in `poor-1366/result.json`; commit `393e9ca0`, clean tree |
| Quality gate | `./scripts/check.sh`: all 11 steps passed on `393e9ca0`; 365 resources compiled; 727 tests, 11,869 assertions; 15 games / 683 fights across both soaks, zero violations; six planted faults caught. Focused regressions: 15 tests / 1,024 assertions. Asset regeneration check passed. |

Capture provenance is in `review-comparisons.json`, alongside the three `result.json` files. Each `result.json` names `393e9ca0`, records an unchanged reference adapter, and contains all 144 regions.

Media root: `media/shop/` (in Cloudflare R2). `coin-candidates-and-stats-1920.png`, `before-1920.png`; each compare folder contains the reference, game, stacked and difference PNGs. `shop-sell-60fps.mp4` contains 132 frames at 60 fps (2.2 s), filming the real controller selling a Bought tier-6 unit for 3: balance 8 → 11. The value stays beside the carried card. Frame-labelled strips, `sell-cue-1920.png`, `after-sale-1920.png` and `sell-cue-1366.png` sit beside it. All look captures reported zero game errors or warnings.

Differences from the approved page:

- The original hand-spell gold coins were a mismatch; the review fix restores the cream disc. The existing hand fan still tilts its spell, whereas the mock-up draws that spell upright and slightly lower. This pre-existing placement difference remains; the cost-disc choice is now tested explicitly.
- Activated-ability buttons still appear on board cards, whereas the mock-up omits them. Their existing actions stay available; placement awaits the later keyword work.
- The chosen detailed coins and angular Attack/Health settings follow the owner's addendum. Keyword marks and the Cards button remain deferred, and the historical shop-only captures had duplicate glow switched off. Brief 4 now switches it on.

Named-region review at 1920 × 1080 (same brightness-weighted measure as compare.py):

| Area (x,y,w,h) | Mean /255 | Pixels >32 | Explanation |
|---|---:|---:|---|
| Gold / tier (380,180,196,170) | 12.85 | 10.17% | Chosen detailed coin and sans figures; larger tier-up structure matches reference |
| Refresh / freeze (1346,150,194,200) | 9.01 | 5.19% | Chosen coin, button typography and icon rendering |
| Hanging tags (580,386,760,62) | 9.58 | 8.27% | Chosen detailed coin replaces the mock-up coin |
| Spell prices (792,12,318,158) | 6.75 | 3.35% | Chosen coin on the same shoulder |
| Board / hand (650,480,620,600) | 11.93 | 9.07% | Required new combat-number settings; deferred keyword marks, existing ability buttons and hand-spell placement |
| Left window / hero (0,0,240,1080) | 1.20 | 0.35% | Renderer / text edges |
| Right window / End turn (1680,0,240,1080) | 2.06 | 1.20% | Deferred Cards button; renderer / text edges |

Worst grid regions: H8 25.77, I8 25.07, J9 23.68. H8 and I8 cover back-row stats and ability buttons; J9 covers the hand and its existing spell tilt/placement. Inspected stacked/difference images as well as numbers. These differences include the requested combat-number change and deferred keyword marks and Cards button. The current activated-ability buttons also remain, as listed above. Duplicate glow was switched off for these historical shop-only captures; brief 4 now switches it on. The layout positions match the approved Tags geometry.

The approved shop page SHA-256 is `611fabe7f12523bbef2612933388fc71a1156cad0b397a4843d98dacfc214ef7`.

## Needs the owner's eyes

Coin drawing, the optical number placement at laptop scale, the new combat-number settings, and the sell cue's feel. Pixel scores and tests can't judge those preferences, sound, or the owner's display and hardware.

Final checks used `XDG_CONFIG_HOME=/tmp/n18-shop-config XDG_DATA_HOME=/tmp/n18-shop-data FEEL_TMP=/tmp/n18-shop-feel LP_NUM_THREADS=2` to keep runtime files inside permitted paths and limit software-renderer threads. No action was denied; external media writes, display sessions and the commit were approved. Review follow-up is for PR 121; no history was rewritten.
