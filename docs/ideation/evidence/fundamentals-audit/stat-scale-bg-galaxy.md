# Stat scale in Battlegrounds and Galaxy, turn by turn (reader: stat scale)

All numbers are board totals: Attack + Health summed over every unit on the board, unless a column says otherwise.
"Turn" = the player's turn / combat number (turn 1 = first fight). Bramble "round" is the same thing.

## Sources and method

1. **Firestone per-turn means (BG).** Firestone is a community deck tracker. Its public hero-stats file has, for every hero,
   the mean board total at each turn: `warbandStats[{turn, averageStats}]`.
   - URL: `https://static.zerotoheroes.com/api/bgs/hero-stats/mmr-{100,10,1}/last-patch/overview-from-hourly.gz.json`
     (pattern from `libs/battlegrounds/data-access/src/lib/meta-heroes/bgs-meta-hero-stats-access.service.ts` in github.com/Zero-to-Heroes/firestone).
   - Measured quantity: sum of ATK + HEALTH of the player's minions when the board is sent to combat
     (`rtstats-bgs-board-stats-parser.ts`, `buildTotalStats`). Mean over players still alive at that turn.
   - Older eras: Wayback Machine copies of the same file (Sep 2025, Mar, May, Jun 2026). Nothing older is archived.
   - Weighting: per-hero means weighted by the hero's game count (per-turn counts are not published).
   - Files: `web/hero-*.json.gz`, `web/wayback/*.json`. Script: `firestone_turns.py`.
2. **Firestone replays (BG, current patch 37.0, build 255790, 3-9 Nov 2026).** `https://static.zerotoheroes.com/api/bgs/bgs-perfect-games.json`
   lists the latest 1,000 "perfect games": 1st place without ever losing hero health (`isBgPerfectGame` in `replay-metadata-bulder.service.ts`).
   That is about 0.36% of games (1,000 in 5.5 days against about 51,000 uploaded games a day, `hero-100-past-seven` dataPoints 357,901).
   - Each entry has the final board (all 1,000 used). Each has a replay XML at `https://xml.firestoneapp.com/<replayKey>`.
   - I downloaded 150 replays with curl (2 s each, 1 s pause, deleted after parsing), parsed them with `scripts/parse_bg_replay.py`
     and kept 129 that start at turn 1 and match the game length.
   - Snapshot: both boards at the first attack of each combat (after Start of Combat effects).
   - The opponents of a perfect-game winner are ordinary lobby players at that turn (median MMR of the winners is 6,269; the all-player median MMR is 6,355).
     Ghost fights (opponent hero at 0 health) are dropped.
   - Python's default user agent got HTTP 403 on the replay host; curl's default worked. I did not spoof headers. A classifier blocked a header change.
3. **Bramble bot lobbies:** `/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/free_choice_plain.{rounds,players}.csv`
   (the benchmark had finished and renamed the files; 400 complete 8-seat lobbies, 48,773 round rows). Script `scripts/bramble_rounds.py`.
4. **VOD pilot:** yt-dlp 2026.10.26 + imageio-ffmpeg in `tools/venv`. One BG game, one Galaxy highlight video. Details in section 9.
5. **Card text:** `docs/research/battlegrounds/data/minions.csv` (current pool) and `content/units/*.json` (`set: slice`) on ideation/pass2.

## 1. Per-turn table (headline)

| Turn | BG ordinary board, median (p10-p90) | BG biggest unit, median | BG median unit | BG top 0.4% games (perfect winners) median (p90) | BG Firestone mean, all / top 1% MMR (Nov 2026) | BG Firestone mean, Sep 2025 | Bramble bots median (p90) | Confidence |
|---|---|---|---|---|---|---|---|---|
| 4 | 24 (11-40) | 10 | 7 | 34 (51) | 27 / 32 | 24 | 30 (36) | high |
| 6 | 62 (38-85) | 22 | 9 | 84 (143) | 74 / 86 | 53 | 52 (63) | high |
| 8 | 149 (83-343) | 54 | 17 | 269 (535) | 230 / 296 | 123 | 80 (98) | high |
| 10 | 714 (249-1,565) | 240 | 83 | 1,415 (4,682) | 1,008 / 1,840 | 305 | 107 (132) | medium-high |
| 12 | 2,598 (629-6,572) | 897 | 234 | 7,598 (29,844) | 3,505 / 6,454 | 759 | 133 (163) | medium-high |
| 14 | 7,980 (2,102-31,933) | 2,857 | 834 | 21,440 (141,333) | 6,850 / 9,544 | 1,751 | 155 (194) | medium (n=60 ordinary boards; only survivors) |

Read: an ordinary BG player at turn 12 in Nov 2026 has about 2,600 stats on board; the biggest unit is about 900 (450/450);
the middle unit is about 230 (115/115). A Bramble bot at round 12 has 133 in total, about 20 a unit.

Older eras (2019-2024): no per-turn data found. [judgement, low confidence] launch-era (2019-2020) late boards were in the
low hundreds of total stats (carries of 30/30 to 60/60); scaling text was 4-6% of the pool then against 32% now
(`docs/research/battlegrounds/power-analysis.md` section 5).

### Full replay tables (n per turn, all quantiles, top-1 share, units): `perfect_combats_table.txt`

## 2. The curve changes a lot by era (Firestone, all-MMR mean, weighted)

| Snapshot | Games | T4 | T6 | T8 | T10 | T12 | T14 | Growth per turn T8-T14 |
|---|---|---|---|---|---|---|---|---|
| Sep 2025 | 1,782,847 | 24 | 53 | 123 | 305 | 759 | 1,751 | x1.56 |
| Mar 2026 | 1,840,403 | 25 | 74 | 199 | 703 | 1,924 | 3,932 | x1.64 |
| May 2026 | 206,873 | 22 | 58 | 163 | 565 | 1,637 | 3,807 | x1.69 |
| Jun 2026 | 1,074,835 | 22 | 58 | 169 | 566 | 1,610 | 3,696 | x1.67 |
| Nov 2026 | 288,790 | 27 | 74 | 230 | 1,008 | 3,505 | 6,850 | x1.76 |
| Nov 2026, top 10% MMR | 29,655 | 32 | 89 | 298 | 1,463 | 4,954 | 8,414 | x1.74 |
| Nov 2026, top 1% MMR | 3,070 | 32 | 86 | 296 | 1,840 | 6,454 | 9,544 | x1.78 |

- Turns 4-6 barely move between eras (22-27 at T4). The late game moves 3-4x within 14 months (T12: 759 to 3,505).
- Skill: top-1% players have about 1.8x the mean board at T10-T12. Bots that play below human level will understate the curve by at least that much.
- Means sit above medians from T9 on (T12: mean 3,522 vs median 2,598 in the replay sample), because of the right tail.

## 3. Bramble bots, same measure

| Round | n | p10 | p50 | p90 | max | per unit (p50) |
|---|---|---|---|---|---|---|
| 4 | 3,200 | 24 | 30 | 36 | 50 | 5.8 |
| 6 | 3,200 | 42 | 52 | 63 | 89 | 7.6 |
| 8 | 3,200 | 65 | 80 | 98 | 129 | 11.7 |
| 10 | 3,196 | 85 | 107 | 132 | 183 | 15.7 |
| 12 | 2,869 | 106 | 133 | 163 | 226 | 19.7 |
| 14 | 1,874 | 118 | 155 | 194 | 256 | 23.4 |
| 20 | 428 | 159 | 220 | 290 | 422 | 34.4 |

- Winners' final boards: median 242, max 486 in 400 lobbies. Winners last a median 20 rounds (BG perfect games end at a median turn 14).
- Bramble gold income is the same as BG (`income_by_turn [3..10]`, `src/core/game_config.gd:40`).
- Stats per cumulative gold: Bramble 1.5 at R8, 1.5 at R10, 1.4 at R14. BG ordinary median: 2.8 at T8, 9.9 at T10, 28 at T12, 71 at T14.
  BG turns gold into ever more stats; Bramble converts at the rate of buying bodies, and the rate falls.
- Full table: `bramble_rounds.txt`.

## 4. Shape of the curve: how often boards run away

| Turn | BG ordinary median | ordinary boards >= 2x median | >= 3x | >= 10x | p90/p50 | top-0.4% winners: median, p90 (x ordinary median) | Bramble: >= 2x median | Bramble p90/p50 |
|---|---|---|---|---|---|---|---|---|
| 6 | 62 | 1% | 1% | 0% | 1.4 | 1.4x, 2.3x | 0% | 1.21 |
| 8 | 148 | 13% | 3% | 0% | 2.3 | 1.8x, 3.6x | 0% | 1.23 |
| 10 | 714 | 14% | 4% | 0% | 2.2 | 2.0x, 6.6x | 0% | 1.23 |
| 12 | 2,556 | 23% | 9% | 0% | 2.6 | 3.0x, 11.7x | 0% | 1.23 |
| 14 | 7,974 | 23% | 18% | 3% | 4.0 | 2.6x, 17.7x | 0% | 1.25 |

- BG: the tail opens at T8 and widens every turn. The top 0.4% of games run 2-3x the ordinary median, and their top tenth 7-18x.
  That matches the owner's "top 1% with 10x the stats" closely.
- Bramble bots: not one board in 400 lobbies reached 2x the round median at any round; max/median is 1.7-2.0 all game.
- Full table: `shape.txt`.

## 5. Concentration and what wins fights

- **Biggest-unit share** (biggest unit / board total), median, every turn from 6 to 15: 0.32-0.35 for ordinary boards and 0.33-0.36 for perfect winners.
  An even 7-unit board would be 0.14. BG boards are "one carry plus six supports", not flat and not all-in. Winners are not more concentrated than losers.
- **Final boards of the 1,000 perfect games:** biggest unit median 34% of the board; over 50% in 22% of games; even (<= 21%) in 13%.
- **One huge unit:** from T8 on, a unit holding >= 60% of the board is 7% of ordinary boards and 12% of winners' boards.
  Tall-against-wide fights (>= 60% vs <= 30% with 6+ units) are 54 of 796 fights (7%).
- **Fewer stats, still won:** the perfect winner (never took damage) had fewer board stats than its opponent in 14-26% of fights at every turn,
  and less than half in 1-8%. Examples: Beast Beetles won at T14 with 194 stats against 6,666; at T15 with 205 against 9,698.
  Deathrattle summons, Reborn, Divine Shield and Venomous are stats the snapshot cannot see. `underdog.txt`, `tall_wide.txt`.
- **Archetypes of perfect-game winners** (final board, median total, biggest-unit share, n): Demon boost-shop 36,373 (0.60, 36);
  Pirate discover 35,522 (0.20, 69); Elemental Azerite 33,581 (0.48, 40); Beast Lobster 30,520 (0.30, 171); Quilboar choose-one 28,831 (0.26, 36);
  Mech APM 25,203 (0.48, 43); Murloc handbuff 2,921 (0.34, 18); Aberration deathrattle 2,259 (0.34, 11); Beast Beetle 1,088 (0.30, 12).
  Comps that never lost a fight differ 35x in final stats. `perfect_final.txt`.
- **Biggest units seen:** 6,824 final units in the 1,000 perfect games: none at the 2,147,483,647 cap, 4 over 1 million, and 19 games (1.9%) with a unit over 100,000.
  The famous capped unit (forum post, 24 Aug 2023, Argent Braggart + Moira + Drakkari + Murk-Eye) lost to "a poison mob".

## 6. What drives BG growth, and what Bramble lacks

- BG printed buff sizes are small too: median +2 (tiers 1-2), +3 (tier 3), +4 (tier 4), +6 (tier 5), +4.5 (tier 6), A+H per buff. (`bg_buff_sizes.txt`)
- The growth comes from compounding text: 68 of 273 current solo-pool minions (25%) say "this game", "improve", "extra", "for each", "equal to" or similar.
  Examples: Blood Gems give an extra +1/+1 this game (Fearless Foodie, Sanguine Refiner, Sanguine Champion); Tavern spells give an extra +1/+1 this game
  (Shoalfin Mystic, Felfire Conjurer, Tranquil Meditative); "Improve your future Tasty Lobsters / Ballers"; Living Azerite (+4/+3 to Elementals in the Tavern per spell, this game);
  Maritime Extortionist (+7/+7 per golden played this game); doublers Brann, Drakkari, Titus; stat copiers Living Prison, Choral Mrrrglr, Unbound Tempest, Snazzy Phantom.
  Each buff is applied more often each turn, and each application gets bigger. That gives x1.6-1.9 per turn.
- Bramble slice (119 cards): buffs in text are +1/+1 or +2/+2 at every tier (the largest are two +8/+8 effects). About 7 cards grow permanently, all in +1/+1 steps,
  most with "up to", "once a fight" or "twice a fight". One card is second-order: Fairy Monarch ("Rings under your Fairies give +1/+1 more").
  Alderman Dozey's doubling is capped at +8/+8. Explicit buff caps: 2 cards (`permanent_buff_cap` 3 and 12).
- Bramble's early game matches BG (R4 30 vs BG 24; R6 52 vs 62). The gap opens at T7-T8, exactly where BG's compounding text starts to pay.

## 7. Galaxy

- Rules make numbers compound: every buff is permanent, including fight buffs (`docs/research/galaxy/rules.md:42`); 5 slots.
- Printed stats by rarity: Common 4, Uncommon 7, Rare 12, Epic 16, Legendary 35 (`power-analysis.md` section 6).
- Designer quote: Legendaries start at 20-30 stats and grow "into the hundreds or thousands" (`design-notes.md:82`).
- VOD point (Rowan Ribbit, "Season Bo Peep | 15 Jay Sparrow", youtube yNxxsivKlTY, Sep 2025, Legendary rank, 1st place):
  hovered units mid-run 7/7, 11/6, 14/14, then 56/48, 96/94, 115/101, 138/129; final board Apophis 912/893, Captain Hook 546/453,
  Hercules 329/314, Tsarmina 324/319, Innkeeper 197/184. Total 4,471; biggest unit 40%. The video is edited, so turns are unknown.
- No public per-turn Galaxy data found (galaxy-stats.com reports decklists only). Confidence: low.

## 8. Owner hypotheses, measured

| Claim | Verdict | Evidence |
|---|---|---|
| End-game units are commonly over 100/100 | Right for 2025-26 BG end game (T13+); era-dependent | Median unit T12 234 (117/117) and T14 834 in Nov 2026; Sep 2025 mean per unit T12 108, T14 250 |
| Mid-game units at 150/150 in many metas | Overstated except for the carry in the current meta | Biggest unit median T8 54, T10 240; median unit T10 83 |
| Our numbers are too small | Right, but the cause is compounding, not the tier budget | Bramble R12 133 vs BG 2,598; early game equal; Bramble has 1 second-order card vs 25% of BG's pool |
| Concentrating stats is always better | Right for vanilla bodies (breakpoints); incomplete for real boards | BG keeps 1/3 of stats in the carry; 14-26% of fights won with fewer stats; Beetles win with 1/30 of the stats |
| Top 1% at 10x the average is fine and inevitable | Matches BG | Top 0.4% games: p90 is 7-18x the ordinary median from T10 |
| Watch the frequency of snowballs | BG: 13-23% of ordinary boards are 2x the median from T8; Bramble bots: 0% | section 4 |

## 9. VOD pilot and a design for a full study

**What worked.**
- yt-dlp search and download work without a JS runtime (warning only). 20-minute BG game at 720p: 188 MB, 45 s. 6:44 Galaxy video: 78 MB.
- Bundled ffmpeg: contact sheets (1 frame per 10 s, 6x5 tiles of 320 px) in 21 s for 20 minutes. Crops of the board at 720p are legible: unit Attack/Health read reliably.
- Pilot BG reads (Podmates Gaming "Hearthstone Battlegrounds - No Commentary", youtube 0vKxLg0IZDk, low MMR):
  turn 2: own 2/2 vs 3/1; turn 6: own 8/11, 5/x, 3/1, 4/4 (about 40) vs 6 units of about 35; turn 7: own 12/x, 3/1, 5/5, 4/4, 3/5, 2/2 (about 60) vs about 60.
  This lower-rated game is well below the Firestone mean (74 at T6, 127 at T7).

**What did not.**
- Fixed timestamps miss: 3 of 4 picks on turns 1-4 landed on the "Combat" banner. Frames need banner detection plus about 1.5 s, or 2-3 frames per combat.
- Turn index must be counted from the start; edited videos (most Galaxy content) skip turns, so turns are unknown.
- Mid-fight frames show damaged Health (red numbers).

**Cost per game.** About 3 minutes wall clock, 200 MB transient disk (tmpfs is RAM here; delete the video at once), and 12-20 image reads (roughly 25-40k tokens) to locate combats and read 14 boards.
Compare the replay route: 2 s per game, no images, exact numbers for both boards, every turn.

**Full study design.**
- BG current era: use replays, not VODs. Pull the perfect-games list weekly for 4-8 weeks (each list is the latest 1,000; about 0.36% of games),
  parse all replays (about 30 minutes per 1,000), and record per combat: turn, both boards (card, A/H, golden, DS/Reborn/Venomous/Taunt), tier, hero health, fight result and damage.
  Opponents give ordinary boards; winners give the top-0.4% tail. Report median, p10/p90, biggest unit, biggest-unit share, and stats per cumulative gold.
- BG older eras (2020-2024): VODs. 3 full games per era for 6 eras (launch 2019-20, 2021 Darkmoon/buddies, 2022 quests, 2023 Undead/Naga, 2024 spells, 2025 trinkets) = 18 games.
  Prefer full unedited top-player VODs. Read the board 1.5 s after each Combat banner for turns 3-15. Record the same fields as above.
- Galaxy: 10-15 full runs from tournament VODs (NoLucksGiven, Decked Out Vods, LSV). Galaxy fights are short and the board is 5 slots; read at each fight start:
  turn, hearts, both boards' A/H, result. Budget: about 15 reads per run.
- Bramble side: add per-unit stats to rounds.csv (biggest unit, median unit) so the same measures compare directly; and run constructed setups at T8/T10/T12 per tribe.

## Files
- `perfect_combats_table.txt`, `perfect_final.txt`, `shape.txt`, `underdog.txt`, `tall_wide.txt`, `bramble_rounds.txt`, `bg_buff_sizes.txt`
- Parsed replays: `web/perfect_combats.jsonl` (129 valid of 150). Raw lists: `web/perfect.json`, `web/hero-*.json.gz`, `web/wayback/`.
- Scripts: `scripts/parse_bg_replay.py`, `scripts/batch_replays.py`, `scripts/analyse_combats.py`, `scripts/shape.py`, `scripts/underdog.py`, `scripts/tall_wide.py`, `scripts/bramble_rounds.py`, `scripts/bg_buff_sizes.py`, `firestone_turns.py`
- VOD frames: `vod/frames1/`, `vod/gframes/` (videos deleted).
