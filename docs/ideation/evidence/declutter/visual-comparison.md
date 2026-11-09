# Visual comparison: Bramble against Battlegrounds, Hearthstone, Galaxy, TFT, Marvel Snap and Super Auto Pets

## Bottom line
- **Our art isn't the problem.** The flat storybook animals and the cream-and-wood palette are consistent. The problem is what sits on top of the art. Our recruit screen shows about 125–135 text and number labels, and combat shows about 105. Battlegrounds recruit shows about 40, nearly all numbers. Galaxy shows 35–55, and Hearthstone constructed about 25.
- **Each of our units carries 6–7 labels.** These are a slot code, name strip, ×2 badge, tier badge, keyword chip, attack and health, plus buff chips. Units in the other games carry two stats and at most one icon or word.
- **The other games teach through motion and inspect-on-demand.** We teach through permanent chips, dashed target lines, banners and text panels. That is what note 9e complains about.
- **Visual tier:** Bramble 4/10 (art 6, UI 3). Galaxy 7, Super Auto Pets 6, Battlegrounds, TFT and Snap 9, Hearthstone 10.

## 1. Layout: where things sit and how much screen each takes

| Game (image) | Board | Shop | Hand | HUD | Opponents | Empty or decorative space |
|---|---|---|---|---|---|---|
| **Bramble recruit** (redbreast-label 1688×780) | Centre-left, front 4 / back 3, ~22% (25% with hero) | Top band, 5 units + 2 spells, ~20% | Centre-right box with the "Birds away" panel below it, ~7.5% | Right column: gold panel and 4 large leaf buttons, ~17.5% | Top strip of 8 two-line pills, ~8% | ~20%, flat tan |
| **Bramble combat** (wording2 1920×1080) | Centre, mirrored 4/3, ~46% of width | – | – | Right ~17%: fighting, speed, pause, skip | Name on the right edge | Left 28% of width is three text panels: "This hit", combat log, keyword glossary |
| **Battlegrounds recruit** (Tavern_Phase; 2026 frames match) | Middle row; tokens ~9–12% | Row under Bob, ~6% for tokens; tavern area ~33% with frame | Hidden at the bottom edge until used | Upgrade, refresh and freeze as small cost coins around Bob (~4%); coins bottom-right; timer rope | Left portrait column, ~7%; next opponent ringed red | ~40%, decorated playmat |
| **Battlegrounds combat** (Combat_Phase) | Two rows centre, ~20% | – | – | One "Combat" plaque | Same left column | ~50% playmat |
| **Galaxy shop and combat** (g2, g4) | Centre column, 3 front / 2 back per side, ~24% | The same top rows hold the shop: 3 units + spell | – | Treasures as tiny cards in corners; turn badge | 2 large portraits on the left, ~7% | Inspector on the right takes ~26%; starfield ~40% |
| **TFT** (Set 18 mobile; PC from memory) | 3D hex board ~65–70% | Mobile: a drawer you open. PC: bottom strip (Set 15 strip image) | Bench below the board | Stage and timer top centre; Buy XP bottom-left; trait list on the left (PC) | HP list on the right edge, ~5% | 3D scenery |
| **Marvel Snap** | 3 lanes centre, ~45% | – | Fanned at bottom centre | Energy orb left; end turn bottom-right | Avatar top-right | Heavy themed backdrop |
| **Super Auto Pets** | Team on the upper track | Shop on the lower track | – | One top bar with 4 counters, ~8% of height | – | ~60% landscape |
| **Hearthstone constructed** | Playmat ~60% | – | Fan at bottom right | Mana bottom-right; deck right edge | Hero top centre; history icons on the left | Decorated board corners |

What follows from the table:
- **Our units are not small.** They are ~150 px at 1688 wide (8.9% of width). Battlegrounds tokens are ~115 px at 1470 (7.8%) and Galaxy cards ~130 px at 1920 (6.8%). The board doesn't need more space; it needs less on it.
- **Negative space is what makes their boards readable.** They leave about 40% decorated or dark space and we leave about 20%, all flat tan.
- **Galaxy is our closest structural match:** shop above, a rowed crew below, inspector on the right. Our reader screen already looks like it, with an inspector at about 18%. But we keep every label on the board as well, so the information appears twice.
- **No other game shows a text panel during combat by default.** Hearthstone has a small history icon column; Battlegrounds has nothing.

## 2. Information density
I counted each text string and number badge in one screenshot. Counts are rough, ±10%.

| Screen | Labels | Words vs numbers | Static indicators |
|---|---|---|---|
| Bramble recruit (redbreast-label) | ~134 | ~60 word labels | 10 acorn pips, dotted ring path, nest line, Pass-end tag, 7 keyword chips, 7 ×2 badges, 7 slot codes, SHOP/FRONT/BACK |
| Bramble lobby (strong-field) | ~125 | Includes tutorial text: "Bought units wait here. Drag one to an empty slot." | "In 1/1", "+2/+2", "Pass end" chips; "Board 7/7"; "Tribe bonus" |
| Bramble reader (Reel-Mistress) | ~130 | "+3/+3 · 2" chips replace unit names; "Tap an empty slot to play it" | Same as recruit |
| Bramble combat | ~105 | About 10 lines of log prose, a keyword glossary, before/hit/after maths | 6 dashed target lines, ATTACKING and TARGET banners, "B3 EMPTY" and "F4 EMPTY" |
| Battlegrounds recruit 2026 (frame165) / 2023 full | ~40 | ~95% numbers; 0–2 words | Tier stars on shop tokens only; skull or bolt icons |
| Battlegrounds combat | ~30 | Numbers only, plus "Combat" | Damage starbursts, which disappear after the hit |
| Galaxy shop (g2) | ~35, plus 3 in the inspector | Names, stats, one-word tags | Rarity gem |
| Galaxy combat (g4) | ~55, plus the inspector | Names, stats, tags; damage numbers | Rarity gems |
| TFT mobile planning | ~25 (PC adds ~35 in shop and trait list) | Almost no words on the board | HP and mana bars, stars, item icons |
| Marvel Snap | ~30 | Rules text only on the 3 location tiles | – |
| Super Auto Pets shop | ~20 | Text only in the selected pet's tooltip | Shop slot pips |
| Hearthstone constructed | ~25 | Numbers only on the board | – |

## 3. How keywords, triggers and targets are shown

| Game | Keywords | Triggers | Targets |
|---|---|---|---|
| **Bramble** | A text chip on every unit ("Start of Combat", "Quarry", "Cleave", "Shy", "Homecoming") placed over the art, often over the face | Static chips ("Pass end", "In 1/1", "+3/+3·2"); log prose | Permanent dashed lines from every Quarry unit, ATTACKING and TARGET banners, a before/hit/after panel |
| **Battlegrounds and Hearthstone** | Changes to the token itself: Taunt frame, Divine Shield bubble, Reborn translucency, a skull icon for Deathrattle, a bolt icon for triggers. Text appears only on hover: the card enlarges with keyword tooltips (frame70) | The icon flashes and an animation plays | The attacker physically lunges at the target; no lines |
| **Galaxy** | One small word under the name (Pirate, Hunt, Hoard 6, Farewell) and a rarity gem; full text in the right-side inspector | Floating "+8" or "-22" numbers and starbursts | Lunge and starburst |
| **TFT** | Trait icons on shop cards and in the left trait list; nothing on board units except items and stars | Ability visual effect when the mana bar fills | Animation and projectiles |
| **Marvel Snap** | Card art and name logo; location rules printed (they change the rules) | Large visual effects when a card resolves | Effects travel to the target |
| **Super Auto Pets** | Tooltip for the selected pet only | A buff projectile flies to the pet it buffs | Bounce animation |

## 4. Visual quality tier (1–10)

| Game | Tier | Why |
|---|---|---|
| Hearthstone constructed | 10 | Tactile 3D board, consistent painterly art, rich effects; the benchmark. |
| Battlegrounds | 9 | Same engine and polish; busier now with trinkets, Activate and spell layers, but the board stays to numbers and icons. |
| Marvel Snap | 9 | The best effects and card treatments in the genre; motion carries the rules. |
| TFT | 9 | Polished 3D with readable silhouettes; the HUD is dense but kept to the screen edges. |
| Once Upon a Galaxy | 7 | Strong painterly card art and a clean layout with one inspector; generic starfield, mobile-style frames, few effects. |
| Super Auto Pets | 6 | Simple flat vector art, fully consistent and very readable; low production, but it commits to its style. |
| **Bramble (now)** | **4** (art 6, UI 3) | Pleasant, consistent illustration and palette, but the UI looks like a debug overlay: text on every surface, chips over faces, tan on tan with no depth, clipped labels, no effects. |

Defects visible in our screenshots:
- **Clipped labels in combat:** "Rainbo", "On attac", "Quarry F…", and the TARGET banner is crossed by a target line.
- **Chips cover faces:** "Take reward" over the ermine, "Start of Combat" over Fetch.
- **Missing name:** B2's name strip is blank in `ui-after-away-tray-1920x1080.png`.
- **Names replaced:** "+3/+3 · 2" chips take the place of names in the reader screenshot.
- **Unclear wording:** "0 + starting survivors" under End turn.

## 5. The ten most valuable changes, by impact

1. **Board units show art and two stats only.** Remove the slot code, name strip, ×2 badge, tier badge, keyword chip and buff chips from owned and enemy units. Keywords become a frame treatment or one small icon, as Battlegrounds does with skull, bolt and shield, or Galaxy does with one word. This removes about 50 labels from each screen and uncovers the faces.
2. **Combat reads through motion, not annotation.** Delete the dashed target lines, the ATTACKING and TARGET banners, the "This hit" panel and the combat keyword glossary. The attacker lunges, a damage starburst lands on the target, stats tick down, and the trigger icon pulses on the unit that fired. The combat log moves to a closed drawer.
3. **One inspector, opened on demand.** Names, rules text, tribe, buff history and golden state live only in the reader panel. On phone it opens on press-and-hold (a hold popup); on PC it can stay docked, as Galaxy's does.
4. **Teaching text moves to the tutorial (note 9e).** Remove "Bought units wait here…", "Tap an empty slot to play it", "Ring size 1.25", the SHOP/FRONT/BACK labels, "Board 7/7", "Tribe bonus" and the End-turn subtitle.
5. **The opponent strip becomes a compact portrait rail.** Show portrait and HP, with the next opponent enlarged and names on hover, like Battlegrounds' left column or TFT's right list. This removes about 30 labels and frees the top band for the shop.
6. **Changing status becomes a small counter or a passing effect.** The six-line "Birds away" panel becomes a small turn-count bubble on the away slot or egg. "Pass end", "In 1/1" and "+3/+3·2" become numbers that float up when gained and then fade; the stat already includes them. Buffs fly from source to target, as in Super Auto Pets.
7. **Card frame redesign.** Art fills 65–70% of the face; stats sit in fixed corners; tier stars and names appear only on shop cards and in the inspector; nothing overlaps a face. Galaxy's card is the closest model to our flat style.
8. **Depth and hierarchy.** Give the shop its own surface (a market stall or hedgerow counter) and the board a darker, mossy playmat. Add shadows and hover lift so cream cards stand out from the background, and leave about 35–40% calm space.
9. **Consolidate the HUD.** Refresh, freeze and tier-up become compact cost buttons next to the shop, as Battlegrounds does around Bob. End turn stays large. Gold becomes one counter with pips; tier and turn share one small chip. This gives back most of the 17.5% right column.
10. **Rows, Ring and Nest shown as objects, not labels or lines.** Front and back should read from the 4/3 shape alone; Galaxy's 3/2 needs no labels. The Ring is a ring token on its slot that slides when it moves; the nest is a nest graphic under the slot. Drop the dotted gold path that links all the units.

To stop the labels creeping back, two optional additions:
- A screenshot check that counts on-screen text nodes and fails above a budget, for example 40 on recruit and 30 in combat.
- A standing side-by-side comparison sheet in each UI evidence folder.

## Sources

### Our screenshots
- `/home/alex/code/Bramble-ideation/docs/ideation/evidence/wave1/redbreast-label/ui-after-overview-1688x780.png`
- `/home/alex/code/Bramble-ideation/docs/ideation/evidence/wave1/ui-followup/ui-after-away-tray-1920x1080.png`
- `/home/alex/code/Bramble-ideation/docs/ideation/evidence/wording2/combat_mid_1920x1080.jpg`
- `/home/alex/code/Bramble-ideation/docs/ideation/evidence/wave1/reader-reel_mistress-golden-1688x780.png`
- `/home/alex/code/Bramble-ideation-tribes2/docs/ideation/evidence/strong-field/lobby_1688x780.png`

### Reference images (each in its own folder; viewed)

| Local file | Source URL | Date / note |
|---|---|---|
| /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/visual/bg-wiki-4/Tavern_Phase.png | https://hearthstone.wiki.gg/images/Tavern_Phase.png | Battlegrounds full recruit screen, uploaded 27 Aug 2023; the white labels were added by the wiki |
| /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/visual/bg-wiki-2/Combat_Phase.png | https://hearthstone.wiki.gg/images/Combat_Phase.png | Battlegrounds combat, uploaded 25 Aug 2023 |
| /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/visual/bg-wiki-3/Battlegrounds_Rules_1.png | https://hearthstone.wiki.gg/images/Battlegrounds_Rules_1.png | Rules shown outside the game screen (relevant to 9e) |
| /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/visual/bg-s14-4/frame70.jpg and frame165.jpg | https://bnetcmsus-a.akamaihd.net/cms/content_entry_media/cd/CD3H0O5MYC4D1784755936040.gif | Season 14 GIF, July 2026: hover keyword tooltips; 2026 recruit board |
| /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/visual/bg-s14-10/frame34.jpg and frame102.jpg | https://bnetcmsus-a.akamaihd.net/cms/content_entry_media/w9/W9PLK8PE2BCZ1784581627490.gif | Season 14, July 2026: full 2026 screen with a Discover overlay |
| /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/visual/bg-s14-6/EX8HMUNBJM4J1784581745238.png | https://bnetcmsus-a.akamaihd.net/cms/content_entry_media/ex/EX8HMUNBJM4J1784581745238.png | Season 14: big stats shortened to "1k" (relevant to the stat-scale note) |
| /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/visual/hs-appstore-5/hs5.jpg | https://is1-ssl.mzstatic.com/image/thumb/PurpleSource221/v4/17/2d/11/172d11da-8a89-5c59-2d2c-ed56edb1ea00/ef332d11-0726-4b38-9341-b1bce4661ab0_HS_AppStore_Updates_Screenshot_6_2688x1242_RN01.jpg/1600x739bb.jpg | Hearthstone constructed; current App Store listing, capture date unknown |
| /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/visual/hs-appstore-6/hs6.jpg | https://is1-ssl.mzstatic.com/image/thumb/PurpleSource221/v4/95/c2/ec/95c2ec1a-5a0d-27e2-97f7-1f727be1693e/42a2a357-f897-4fac-983e-509711ee5e14_HS_AppStore_Updates_Screenshot_7_2688x1242_RN01.jpg/1600x739bb.jpg | Same |
| /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/visual/hs-appstore-1/hs1.jpg and hs-appstore-2/hs2.jpg | https://is1-ssl.mzstatic.com/image/thumb/Purple211/v4/85/c7/9d/85c79d05-122c-9386-1cc4-cd0af39ab90a/6f0600c3-83fd-4f28-8b72-c073b6dcb27a_bl_hs_2688x1242_set03_s02_JW.jpg/1600x739bb.jpg ; https://is1-ssl.mzstatic.com/image/thumb/Purple211/v4/cf/65/2f/cf652f72-34d2-aa8c-0dbb-d17904959e5d/f3b8d518-0646-49dd-a06b-9c2b140143ef_bl_hs_2688x1242_set03_s03_JW.jpg/1600x739bb.jpg | Marketing composites |
| /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/visual/galaxy-1/g1.jpg … galaxy-6/g6.jpg | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/3062740/{2750107d89d59b3c432ffc860a5859d8e96b221f, ee9a842abee6a924cd4e5e1e5b2df39ae80150f8, bc33f385a17c0879b0df311e6f910fabe2b1acc4, fd83f857e6552aaab5264488a156dccb12a584be, ef13ed57d613bae14e1858387abebd7ad68e3b15, d9c7d5744812d053013b578ca4deb6d9ccfb70a3}/ss_{same hash}.1920x1080.jpg | Steam listing assets dated about 27 Sep 2026. g2 is the shop, g4 is combat |
| /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/visual/tft-appstore-1/tft1.jpg … tft-appstore-5/tft5.jpg | https://is1-ssl.mzstatic.com/image/thumb/PurpleSource221/v4/50/85/e7/5085e741-2ff0-d8aa-0d1b-3b93407f31d8/TFT_ST1826_ASO_ScreenshotUpdates_01_2208x1242_UPDATED_v001_SCha.png/1600x900bb.jpg (02–05: same pattern; exact URLs in each folder's .url file) | Set 18 (2026) mobile, with mascot overlays |
| /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/visual/tft-wikipedia-2/Teamfight_Tactics_Set_15_Shop.png | https://upload.wikimedia.org/wikipedia/en/e/ea/Teamfight_Tactics_Set_15_Shop.png | Set 15 PC shop strip, Oct 2025 |
| /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/visual/tft-wikipedia-1/Teamfight_Tactics_Gameplay.jpg | https://upload.wikimedia.org/wikipedia/en/b/b4/Teamfight_Tactics_Gameplay.jpg | Low resolution (421 px) |
| /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/visual/snap-1/s1.jpg, snap-2/s2.jpg, snap-3/s3.jpg | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1997040/{7f1670ed0cc90cb56894f0652c7185b2f87d18a5, d47d1038edc8a0c2d0fe121008050d4c01adfe0d, 19ca9629dd7846507d6fe0f8374fda8f290d19d8}/ss_{same hash}.1920x1080.jpg | Steam listing assets dated about Jun 2026 |
| /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/visual/sap-1/p1.jpg, sap-2/p2.jpg, sap-3/p3.jpg | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1714040/ss_{ce4c7db7a9a1375a17cb7727dec8e6c4078bed62, f61be4caff97d77b7df02bcdadee2687232e991f, b349668fe7de40d36b1a8aedb1070d3e6ca74078}.1920x1080.jpg | Assets about Apr 2023, older than asked for; marketing banners hide the bottom bar |

### What I couldn't get
- **Battlegrounds:** no clean full-screen 2026 recruit or combat capture. The full screens are from Aug 2023, and the 2026 GIF frames are partial but show the same layout.
- **TFT:** no full PC planning screen with the trait list and shop together. The PC TFT layout described above is from memory, not from a captured image.
- **Galaxy:** capture dates are unknown, though the listing is current.
- **Video:** none watched. No Jeef or XQN VODs were used.

All images are under `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/visual/`, one per folder, each with a `.url` file beside it. Contact sheets are in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/sheets/`. The images are not in the repo; only this written comparison is.

This step covers note 9f's visual comparison only. The Quilboar and "trivariate scaling" request in note 9g is not covered here.