# Hearthstone Battlegrounds: system-level patch history

**What this is:** a dated timeline of Battlegrounds **system** changes from launch (Nov 2019) to patch 36.6.3 (1 Oct 2026). It covers economy, pool, tribes, armor, damage caps and the seasonal systems. Card balance changes are left out unless they changed a system. A section at the end lists lessons for Bramble.

The current rules are in [rules.md](rules.md).

**Labels**
- **UNVERIFIED**: no source found.
- **REVERTED**: a later patch undid the change.
- Reason quotes are Blizzard's own words and are kept short.

**How it was compiled:** official patch notes at hearthstone.blizzard.com and playhearthstone.com, Hearthstone Wiki patch pages, and press coverage (HearthstoneTopDecks = HTD, Hearthpwn, BlizzardWatch). It was compiled 27 Oct 2026.
- The wiki's "Battlegrounds/Patch changes" page stops at about 21.0, so later entries come from the individual notes.
- Patch 37.0.0 (Oct 2026) was not reviewed.

---

## Launch baseline (15.6, Nov 2019)

- **Dates:** closed beta 5 Nov 2019, open beta 12 Nov, full launch with Descent of Dragons 10 Dec 2019 (patch 16.0) ([launch article](https://hearthstone.blizzard.com/en-us/news/23156373)).
- **Format:**
  - 8 players and 24 heroes.
  - Each player was offered **2 heroes, or 3** if they had bought 20 Descent of Dragons packs.
  - 4 tribes (Beast, Demon, Mech, Murloc), all in every lobby.
- **Economy:**
  - Minions cost 3 gold, refresh 1, sell for 1. Freeze was free.
  - Gold started at 3, rose by 1 per turn to a maximum of 10, and did not carry over.
  - The tier-up cost dropped by 1 each turn you didn't upgrade.
  - A triple made a golden minion that kept its buffs and gave a Discover from the next tier.
- **Upgrade costs:** T2 5 is confirmed. T5 9 is confirmed for before 22.2. T3 7, T4 8 and T6 10 are UNVERIFIED but consistent with later values ([wiki](https://hearthstone.wiki.gg/wiki/Battlegrounds)).
- **Pool copies per tier:** **18/15/13/11/9/6** ([HSReplay, Apr 2020](https://articles.hsreplay.net/2020/04/15/battlegrounds-guide-april-2020/)).
- **Shop slots:** 3/4/4/5/5/6 by tier ([wiki](https://hearthstone.wiki.gg/wiki/Tier-related)).
- **Damage:** Tavern Tier plus the tiers of surviving minions, with no cap.
- **Kel'Thuzad** handled odd player counts. That he existed from launch is UNVERIFIED.

## 2019–2020

| Date | Patch | Change | Reason or notes | Source |
|---|---|---|---|---|
| 19 Nov 2019 | server | First **hero rotation** (4 in, 4 out). Heroes have rotated every patch since. | | [wiki](https://hearthstone.wiki.gg/wiki/Battlegrounds/Patch_changes) |
| 5 Dec 2019 | — | Accidental MMR change (bug). | | [wiki](https://hearthstone.wiki.gg/wiki/Battlegrounds) |
| 21 Jan 2020 | 16.2 | **Matchmaking:** no repeat opponent, or Kel'Thuzad, within 3 combat rounds unless only 2 players remain. The rule shipped in the client and went live with a server patch on 29 Jan. The scoreboard started showing each opponent's majority tribe. | Repeat opponents felt bad. | [notes](https://news.blizzard.com/en-gb/article/23239995/galakronds-awakening-16-2-patch-notes-january-21) |
| 26 Feb 2020 | 16.4 | **Dragons** added as the 5th tribe, still all tribes in every lobby. **Pool copies: T1 18→16, T6 6→7**. Trigger animations cut from 0.8 s to 0.2 s. | Too many Mechs compared with other tribes. | [notes](https://hearthstone.blizzard.com/en-gb/news/23312587/), [GamesBeat](https://gamesbeat.com/hearthstones-battlegrounds-adds-dragons-in-massive-16-4-update/). The copies change is credited to designer Puffin via a podcast: [doc](https://www.docs.google.com/document/d/e/2PACX-1vQ8lv5cf5SQUL2jsqSdB4-3sPLspfvjQxPgTn4jieIz8V55FMEC1YawQ7rK7vYQ3rfFX1MeX00SFybh/pub); wiki cites https://twitter.com/puffinplays/status/1234560852881096706 |
| 5 Mar 2020 | server | Bug fixes: refresh showed one fewer minion than intended; the Triple Reward offered only 2 options; Replicating Menace desynced combat. | | [wiki](https://hearthstone.wiki.gg/wiki/Battlegrounds/Patch_changes) |
| 17 Mar 2020 | 16.6 | **Tavern Pass** ($19.99 or 2,500 gold) gives the 3rd and 4th hero choices. Base offer stays 2. | Perks without "purchase card packs". | [notes](https://hearthstone.blizzard.com/en-us/news/23319440) |
| 9 Jun 2020 | 17.4 | **Pirates** added (6th tribe). **Each lobby now uses 5 of 6 tribes**, the first tribe exclusion. Heroes tied to an absent tribe sit out. Pirates guaranteed for a while. | Heroes sit out "to keep things fair". | [notes](https://hearthstone.blizzard.com/en-us/news/23440114) |
| Jul 2020 | 17.6 | Pirates no longer guaranteed. **Amalgadon** added (T6, "All" type). | | [notes](https://news.blizzard.com/en-us/article/23469099/17-6-patch-notes) |
| 8 Sep 2020 | 18.2 | **Parties:** up to 4 players can queue together; 5–8 get a private lobby. Micro Mummy pulled for a crash. | | [wiki](https://hearthstone.wiki.gg/wiki/Battlegrounds/Patch_changes) |
| 29 Sep 2020 | 18.4 | **Elementals** added (7th tribe, guaranteed at first). **Rating overhaul:** visible rating reset to 0; up to +300 per top-4 finish; no losses below 2,000; floors every 500 from 2,000 to 6,000; bonus gains below 6,500. Hidden MMR kept. | "Similar to the progression system" of Ranked. | [notes](https://hearthstone.blizzard.com/en-gb/news/23523062/184-patch-notes) |
| Nov 2020 | 18.6 | **Party rules:** no rating from games within your own party; matchmaking uses the party's highest rating; 2–4 player parties disabled above 10,000. | Stops parties being used to farm rating. | [wiki](https://hearthstone.wiki.gg/wiki/Battlegrounds/Patch_changes) |
| 17 Nov 2020 | 19.0 | **Battlegrounds Perks** ($14.99 or 2,000 gold): 4 hero choices, sold separately from the Tavern Pass. | | [news](https://playhearthstone.com/news/23534413) |
| 15 Dec 2020 | 19.2 | **Darkmoon Prizes:** every 4 turns, Discover a 0-cost prize from 4 escalating pools. Ratings now reset once per expansion. | To "add a new twist to every Battlegrounds match". | [notes](https://hearthstone.blizzard.com/en-us/news/23584141), [wiki](https://hearthstone.wiki.gg/wiki/Darkmoon_Prize) |

## 2021

| Date | Patch | Change | Reason or notes | Source |
|---|---|---|---|---|
| 19 Feb 2021 | 19.6 | **Triple timing:** "all minions will now summon first before any triples are generated." Darkmoon Prizes end (**REVERTED** in part by 20.8). | Fixes order-dependent triples during multi-summons. | [wiki](https://hearthstone.wiki.gg/wiki/Patch_19.6.0.74257) |
| 4 May 2021 | 20.2 | **Quilboar** added (8th tribe), **still 5 tribes per lobby, so 3 excluded**. Introduces **Blood Gems** ("spells that give a friendly minion +1/+1") and **Frenzy**. | | [notes](https://news.blizzard.com/en-us/article/23665634/20-2-patch-notes) |
| 3 Jun 2021 | 20.4 | Quilboar no longer guaranteed. | | [wiki](https://hearthstone.wiki.gg/wiki/Patch_20.4.0.84593) |
| 2 Jul 2021 | 20.8 | Darkmoon Prizes return in **1 of every 4 games**, with better odds for players in the bottom half. | Variety plus catch-up. | [wiki](https://hearthstone.wiki.gg/wiki/Patch_20.8.0.86601) |
| ~May 2021 | design statement | Golden stats: "All +/- stats carry over, BUT you'll get at least base Golden stats." | Debuffed copies made goldens weaker than base. | [outof.games](https://outof.games/news/3091-debuffs-in-battlegrounds-golden-minions-when-created-to-always-have-at-least-their-base-stats/) |
| 31 Aug 2021 | 21.2 | **"Battlegrounds revamp":** **damage cap of 15 per combat until the first player dies** (deaths checked at the start of the Recruit Phase). **Avenge (X)** keyword. **37 minions out, 37 in**, the first big pool rotation. Darkmoon Prizes removed for good. +5 s on turns 3–9. | No official reason for the cap; press read it as preventing early knock-outs. Timers: "so that everyone has time to get familiar with the new content". | [notes](https://hearthstone.blizzard.com/en-us/news/23712592/21-2-patch-notes), [preview](https://hearthstone.blizzard.com/en-us/news/23714527) |
| 16 Nov 2021 | 21.8 | **Armor** introduced. Each hero starts with random armor from its tier: T1 0, T2 2–5, T3 3–6, T4 4–7, T5 5–8, T6 6–9, T7 7–10 (strongest heroes get least). Bug fixed: a minion's health could grow so large it was deleted. | "Help balance and spice up the Tavern." | [wiki](https://hearthstone.wiki.gg/wiki/Patch_21.8.0.126451), [Armor](https://hearthstone.wiki.gg/wiki/Battlegrounds/Armor) |

## 2022

| Date | Patch | Change | Reason or notes | Source |
|---|---|---|---|---|
| 25 Jan 2022 | 22.2 | **Buddies.** Each hero has its own Buddy, never in the shop, earned through a **Buddy Meter** that fills in combat. It fills faster at low tiers and is capped per round; filling it gives 1 Buddy, then 2. **Armor disabled.** Hero selection 70 s. **T5 upgrade 9→11** (**REVERTED** in 23.2). | Armor off "while we try out the new Buddy System". | [notes](https://hearthstone.blizzard.com/en-us/news/23765270/22-2-patch-notes) |
| 3 Mar 2022 | 22.4.3 | Buddy Meter now fills against Kel'Thuzad and against opponents who are dead or disconnected. | The meter stalled when opponents left. | [notes](https://hearthstone.blizzard.com/en-us/news/23765274/22-4-3-patch-notes) |
| 17 Mar 2022 | 22.6 | **Armor returns** (same tiers). Friend of a Friend (Discover a Buddy) pulled in 22.6.1, and about 30 heroes changed armor tier. | | [wiki](https://hearthstone.wiki.gg/wiki/Patch_22.6.0.133923) |
| 10 May 2022 | 23.2 | **Season 1, "Rise of the Naga".** Battlegrounds now runs in **Seasons**. **Naga** (9th tribe) and **Spellcraft** added; still 5 tribes per lobby, so 4 sit out. **Buddies removed.** **T5 back to 9.** Armor tiers rebalanced. Amalgadon removed. | Buddies out for "less complication going on overall" and to make room for Naga. Amalgadon out because endgame boards had become "very similar". | [notes](https://hearthstone.blizzard.com/en-us/news/23784375/23-2-patch-notes), [BlizzardWatch](https://blizzardwatch.com/?p=153867) |
| 30 Aug 2022 | 24.2 | **Season 2.** **Quests** added. On turn 4 you pick 1 of 3 Quest–Reward pairs; easier rewards come with easier quests, and requirements scale with the hero's armor tier. **Gold can exceed 10 during the turn.** The **Battlegrounds Track and Season Pass** (+2 hero choices) replace Perks. Patchwerk's health 40→60. First goldens made from 2 copies (Pip). | Quest difficulty scales so rewards stay balanced against hero strength. | [notes](https://hearthstone.blizzard.com/en-us/news/23831411/24-2-patch-notes), [Quest](https://hearthstone.wiki.gg/wiki/Quest_(Battlegrounds)) |
| 29 Nov 2022 | 25.0 | Fixes: Golden Hammer stripped golden status from goldens; Ethereal Evidence ignored tribe bans. Dual-type minions appear in card data around this patch. | | [notes](https://hearthstone.blizzard.com/en-us/news/23882860/25-0-patch-notes) |

## 2023

| Date | Patch | Change | Reason or notes | Source |
|---|---|---|---|---|
| 17 Jan 2023 | 25.2 | **Season 3: Undead** (10th tribe). Undead in 100% of lobbies for weeks 1–2, 75% for weeks 3–4. **Dual types:** a dual-type minion is in the pool if either of its tribes is. **"Same number of types per game"**, so one more tribe is excluded. **Quests removed.** **Damage cap of 15 now lasts until both a hero has died and turn 8.** Armor tiers shown on the scoreboard. +5 s on turns 5+ (temporary). | No reason given for removing Quests (HTD read it as a rotation). | [notes](https://hearthstone.blizzard.com/en-us/news/23892225/25-2-patch-notes) |
| 14 Mar 2023 | 25.6 | **Buddies return** with a **Buddy Button** instead of the meter. Cost by Buddy tier is 11–21 gold, minus 3 per combat won or tied and 2 per combat lost. At most 2 presses (1 copy, then 2). | "Plan ahead and choose when is the right time." | [announcement](https://hearthstone.blizzard.com/en-us/news/23913672/battlegrounds-is-bringing-back-buddies) |
| 9 May 2023 | 26.2 | **Season 4.** **Buddies removed.** **Venomous replaces Poisonous.** **Mega-Windfury removed** (golden Windfury is just Windfury). **Magnetic works with a full board.** **T5 = 11** "not reverting"; the patch that set it back to 11 after 23.2 is UNVERIFIED. **Armor becomes fixed per hero** (no random range), with a second value for high-MMR lobbies; values up to about 19. Tribes phased in over 2 weeks. | Windfury: "more in line with other keywords … open up more design space." Magnetic: remove "negative play experiences." No reason given for Venomous. | [notes](https://hearthstone.blizzard.com/en-us/news/23935322/26-2-patch-notes), [HTD](https://www.hearthstonetopdecks.com/hearthstone-26-2-patch-notes/) |
| 22 Aug 2023 | 27.2 | **Season 5: Anomalies.** One random lobby-wide rule per game, with new ones added weekly. **Tier 7** introduced, reachable only through the Secrets of Norgannon Anomaly or Thorim's hero power. 5 copies of each, 14 minions. Per-hero armor with low-MMR and high-MMR values. | Armor: "high winrate disparities between lower-MMR and higher-MMR players." | [notes](https://hearthstone.blizzard.com/en-us/news/23987537/27-2-patch-notes), [HTD preview](https://www.hearthstonetopdecks.com/announcing-battlegrounds-season-5/) |
| 2023 (patch UNVERIFIED, possibly 27.4) | — | Damage cap "now persists for all players until the Top 4", instead of ending at the first death. | | wiki patch-note entry, found via search on [Battlegrounds/Hero](https://hearthstone.wiki.gg/wiki/Battlegrounds/Hero) |
| 5 Dec 2023 | 28.2 | **Season 6: Tavern Spells.** 42 spells across Tiers 1–6, with copies 5/7/9/11/7/5. One spell slot per refresh, at your tier or lower. Variable costs, some paid in health. Spells can't triple. **Anomalies removed.** **T5 11→10.** **Bots** in low-MMR lobbies. Vol'jin redesigned. | Vol'jin "has been a design space limiter". | [notes](https://hearthstone.blizzard.com/en-us/news/24008697/28-2-patch-notes) |

## 2024

| Date | Patch | Change | Reason or notes | Source |
|---|---|---|---|---|
| 13 Feb 2024 | 28.6 | **Quests return** for the rest of the season, plus tribe spells (e.g. Boon of Beetles). New rewards appear twice as often. | | [notes](https://hearthstone.blizzard.com/news/24056184/28-6-patch-notes) |
| early 2024 | design statement | **Start of Combat hero power order:** pre-combat powers, then Illidan, then the rest. Earlier, hero power order was a coin flip. | Fixed order protects planned positioning. | https://x.com/LoewenMitchell/status/1737588920139825335 ; earlier: https://twitter.com/DCalkosz/status/1488361384320528388 |
| 16 Apr 2024 | 29.2 | **Season 7: Duos launches.** 4 teams of 2 with shared health (30) and summed armor. Pass cards through a Portal for 1 gold. Upgrades to T4–T6 cost +2. Teammates' warbands fight in sequence. Separate rating. **Tavern spells made permanent.** **Quests removed.** | Murloc Holmes excluded: "frustrating gameplay with the team system". | [notes](https://hearthstone.blizzard.com/en-us/news/24077473/29-2-patch-notes), [Duos wiki](https://hearthstone.wiki.gg/wiki/Battlegrounds_Duos) |
| 2 May 2024 | 29.2.3 | **Duos gets its own armor values**, about 2–3 below high-rank Solo. | | [HTD](https://www.hearthstonetopdecks.com/hearthstone-29-2-3-patch-notes/) |
| 17 Jun 2024 | 29.6 | **Buddies return**, and come to Duos for the first time. | | [notes](https://hearthstone.blizzard.com/en-us/news/24108513/29-6-patch-notes) |
| 16 Jul 2024 | 30.0 | **Duos first fighter:** each combat has a 75% chance to swap which teammate fights first, and the same teammate never goes first more than 3 combats in a row. | | [Duos wiki](https://hearthstone.wiki.gg/wiki/Battlegrounds_Duos) |
| Jul 2024 | 30.0.2 | Adaptive Amalgam and Immortal Prelate are destroyed after 30 consecutive loops. | Stops infinite combats. | [forum](https://us.forums.blizzard.com/en/hearthstone/t/3002-hotfix-patch/132227) |
| 20 Aug 2024 | 30.2 | **Season 8: Trinkets.** A Lesser offer on turn 6 and a Greater on turn 9, 4 options each. Base cost 0–6 gold. Weighted by hero, lobby tribes and warband. **Buddies removed.** **Beasts and Dragons can't share a lobby.** Armor in 3 columns: high rank, low rank, Duos. | Beasts and Dragons split "due to an unwanted interaction". | [notes](https://hearthstone.blizzard.com/en-us/news/24122902/30-2-patch-notes) |
| Oct 2024 | 30.6 | More than 30 new trinkets, including Duos-only ones. **Start of Combat phase order revised** (per the simulator's notes, citing Loewen). By this date pool copies are **15/15/13/11/9/7/5**; the 16→15 change at T1 isn't in any patch note I found (UNVERIFIED date). | | [HTD](https://www.hearthstonetopdecks.com/new-trinkets-minions-coming-to-battlegrounds-in-patch-30-6/), https://x.com/LoewenMitchell/status/1841922013826273496, [simulator](https://github.com/bwang22/hs_sim) |
| 3 Dec 2024 | 31.2 | **Season 9.** **Trinkets removed.** **Hero rerolls** with Battlegrounds Tokens: each slot once, first free with Pass+. **Solo damage cap: 5 (turns 1–3), 10 (turns 4–7), 15 (turn 8+), removed at Top 4.** Duos unchanged. | Cap: "allow games to progress more evenly, without big bursts of damage in the early game." Rerolls were criticised as "P2W" ([HTD](https://www.hearthstonetopdecks.com/hearthstone-31-2-patch-notes/)). | [notes](https://hearthstone.blizzard.com/en-us/news/24163459/31-2-patch-notes), [S9](https://hearthstone.blizzard.com/news/24159389/announcing-battlegrounds-season-9) |

## 2025

| Date | Patch | Change | Reason or notes | Source |
|---|---|---|---|---|
| 18 Feb 2025 | 31.6 | **Anomalies return**, in Duos for the first time; "less popular" ones cut. **Combat speed-up** over time. Tier 7 Tavern spells. StarCraft heroes with their own mini-economies. | Speed-up: "to even out longer combat phases!" | [notes](https://hearthstone.blizzard.com/en-us/news/24179332) |
| 29 Apr 2025 | 32.2 | **Season 10.** **Trinkets return** with an "updated offering system" that offers type-synergy trinkets more often. Anomalies removed. **Rally** keyword (the wiki dates it to 32.2.0.219846). Minion frames now show the tribe through class colours. | Frames let cards "better serve the gameplay". | [notes](https://hearthstone.blizzard.com/en-us/news/24198086), [Rally](https://hearthstone.wiki.gg/wiki/Rally) |
| May 2025 | 32.2.1 / 32.2.2 | No duplicate Greater trinket offers. "Pivot" trinkets (cheap Greater trinkets for a tribe you aren't playing) removed. | | [HTD 32.2.1](https://www.hearthstonetopdecks.com/hearthstone-32-2-1-patch-notes/), [HTD 32.2.2](https://www.hearthstonetopdecks.com/hearthstone-32-2-2-patch-notes/) |
| 12 Jun 2025 | 32.4.2 | **Trinkets and Anomalies together** for the first time, leaving out "some of the more disruptive" Anomalies. | | [notes](https://hearthstone.blizzard.com/en-us/news/24205944/32-4-2-patch-notes) |
| 5 Aug 2025 | 33.2 | **Season 11.** **Quests return** (turn 4). **Pirate Bounties** (Pirate lobbies only). **Matchmaking:** while everyone is alive you face each opponent once before any repeat; after a death, repeats are avoided for 3 rounds (was 2). Maximum combat speed-up lowered. Trinkets and Anomalies removed. In-game Guide added. | | [notes](https://hearthstone.blizzard.com/en-us/news/24223019/33-2-patch-notes) |
| 29 Sep 2025 | 33.6 | **Quests removed, Buddies return.** Armor reworked "due to the removal of Quests and the addition of Buddies". Hero tribe restrictions loosened. | Make "Hero selection … a more interesting decision". | [notes](https://hearthstone.blizzard.com/en-us/news/24232759/33-6-patch-notes) |
| 9 Oct 2025 | 33.6.2 | **Anomalies return.** **An Anomaly won't repeat within 3 of your games.** Secrets of Norgannon held back "until we've had a chance to adjust the Tier 7 minion pool." Refresh effects can't offer "the Tier 7 roll" before turn 7. Infinite stat-gain loops fixed. | No-repeat rule: so you "experience a wider variety". | [notes](https://hearthstone.blizzard.com/news/24240524) |
| 2 Dec 2025 | 34.2 | **Season 12: Timewarped Tavern.** A Minor Timewarp on turn 6 and a Major on turn 9, each with 5 cards. You get 2 **Chronum** per visit and cards cost 1–2. No freeze or refresh. Timewarped cards triple only with each other. **T4→5 and T5→6 cost +1 in Solo and Duos (now 5/7/8/11/11).** **The shop refills by card count:** 4/5/5/6/6/7. Many gold effects now give **Tavern Coins** instead. Buddies and Anomalies removed; mulligan timer back to 70 s. Thorim's Tier 7 threshold 55→60 gold. | Mulligan timer reverted "now that Buddies and Anomalies are gone". | [notes](https://hearthstone.blizzard.com/en-us/news/24244423/34-2-patch-notes-battlegrounds-arena-and-gameplay-updates) |

## 2026

| Date | Patch | Change | Reason or notes | Source |
|---|---|---|---|---|
| 9 Feb 2026 | 34.6 | **Anomalies return**, including Timewarp ones. Armor rebalanced in 34.6.1. | | [wiki](https://hearthstone.wiki.gg/wiki/Patch_34.6.0.235290) |
| 14 Apr 2026 | 35.2 | **Season 13, "Cataclysm Calls."** **Trinkets return** with an "enhanced system" for synergy offers. **Fodder** (Demons). **Chromadrakes** (Dragons, 5 colours). Anomalies and the Timewarped Tavern removed. | | [notes](https://hearthstone.blizzard.com/en-us/news/24271853/35-2-patch-notes), [announcement](https://hearthstone.blizzard.com/en-us/news/24244885/announcing-battlegrounds-season-13-cataclysm-calls) |
| 2 Jun 2026 | 35.6 | Anomalies return mid-season. | | [wiki patch list](https://hearthstone.wiki.gg/wiki/Patches) |
| 4 Aug 2026 | 36.2 | **Season 14, "Dark Gifts of Dalaran."** **Dark Gifts:** from turn 3, 3 gold, once per turn, at most 3 per game. **Activate** keyword. **Lockbox** (Pirates). **Fishbait** (Beasts attack during the Recruit Phase). **Venomous** becomes "…each combat". Chromadrakes leave the Tavern pool. Numbers over 4 digits are condensed. Trinkets kept. 96 minions out, 62 new, 31 back. | Venomous: Fishbait means minions attack during the Recruit Phase, so the keyword must "remain effective once combat begins." Condensed numbers "keep your warband readable". | [notes](https://hearthstone.blizzard.com/en-us/news/24290432), [announcement](https://hearthstone.blizzard.com/en-us/news/24290433) |
| 22 Sep 2026 | 36.6.1 | **Aberrations** (new tribe): discard synergies and a **Deity** (C'Thun or Y'Shaarj at random) that joins after 3 Aberration deaths in a combat. In every lobby for 2 weeks. **Naga rotated out** with their heroes and cards. The wiki dates the release to 36.6.0 on 15 Sep. | | [announcement](https://hearthstone.blizzard.com/en-us/news/24302091), [notes](https://hearthstone.blizzard.com/en-us/news/24294373/366-patch-notes) |
| 1 Oct 2026 | 36.6.3 | **Deities need 4 deaths** (was 3) and move from Tier 3 to Tier 1. **The Aberration guarantee ends early**: they now have "the standard 50% chance to appear in lobbies". New tribes will get a one-week guarantee from now on. Boosted trinket rates for new trinkets end. | Guarantee: "can make games feel a bit too repetitive." Tier 1: "reduce hero damage taken from Aberrations." | [notes](https://hearthstone.blizzard.com/en-us/news/24303864/3663-patch-notes) |
| Oct 2026 | 37.0.0 | Released (the wiki gives 13 Oct). Battlegrounds content UNVERIFIED. | | [wiki patch list](https://hearthstone.wiki.gg/wiki/Patches) |

---

## Summary tables

### Upgrade cost to reach each tier (Solo)

| Period | T2 | T3 | T4 | T5 | T6 | Source |
|---|---|---|---|---|---|---|
| Launch to 22.2 | 5 | 7* | 8* | 9 | 10* | *UNVERIFIED |
| 22.2 (Jan 2022) | 5 | 7 | 8 | **11** | 10 | 22.2 notes |
| 23.2 (May 2022) | 5 | 7 | 8 | **9** | 10 | 23.2 notes (revert) |
| By 26.2 (May 2023) | 5 | 7 | 8 | **11** | 10 | 26.2 notes |
| 28.2 (Dec 2023) | 5 | 7 | 8 | **10** | 10 | 28.2 notes |
| 34.2 (Dec 2025) to now | 5 | 7 | 8 | **11** | **11** | 34.2 notes; wiki |

All costs drop by 1 per turn you don't upgrade. Duos adds +2 to T4–T6 (since 29.2).

### Pool copies of each minion

| Period | T1 | T2 | T3 | T4 | T5 | T6 | T7 |
|---|---|---|---|---|---|---|---|
| Launch | 18 | 15 | 13 | 11 | 9 | 6 | — |
| 16.4 (Feb 2020) | 16 | 15 | 13 | 11 | 9 | 7 | — |
| 27.2 (Aug 2023) | 16? | 15 | 13 | 11 | 9 | 7 | 5 |
| By Oct 2024 to now | 15 | 15 | 13 | 11 | 9 | 7 | 5 |

### Tribes

| Patch | Tribes available | Tribes per lobby |
|---|---|---|
| Launch | Beast, Demon, Mech, Murloc | all 4 |
| 16.4 | + Dragon | all 5 |
| 17.4 | + Pirate | 5 of 6 |
| 18.4 | + Elemental | 5 of 7 |
| 20.2 | + Quilboar | 5 of 8 |
| 23.2 | + Naga | 5 of 9 |
| 25.2 | + Undead | 5 of 10 (INFERRED from "excludes one more type") |
| 36.6.1 | + Aberration, Naga out | 5 of 10 (INFERRED from "standard 50%") |

### Armor

| Patch | Rule |
|---|---|
| 21.8 (Nov 2021) | Random value from the hero's tier range, 0 to 10 |
| 22.2 | Disabled for Buddies |
| 22.6 | Back on |
| 23.2 | Tiers rebalanced |
| 25.2 | Tier table restated and shown on the scoreboard |
| 26.2 (May 2023) | Fixed value per hero, with a second high-MMR value; up to about 19 |
| 27.2 | Low-MMR and high-MMR values |
| 29.2.3 | Duos values added |
| 30.2 | Three columns: high rank, low rank, Duos |
| 33.6 | Reworked when Quests left and Buddies came back |
| 34.2 and 34.6.1 | Rebalanced, with Solo and Duos values |

### Damage cap

| Patch | Rule |
|---|---|
| Launch to 21.2 | No cap |
| 21.2 (Aug 2021) | 15 until the first player dies |
| 25.2 (Jan 2023) | 15 until a hero has died **and** it is turn 8 |
| 2023 (UNVERIFIED patch) | 15 until Top 4, for all players |
| 31.2 (Dec 2024) to now | Solo: 5 / 10 / 15 by turn (1–3 / 4–7 / 8+), removed at Top 4. Duos: UNVERIFIED |

### Seasonal systems (on and off)

| System | On | Off |
|---|---|---|
| Darkmoon Prizes | 19.2 (Dec 2020) | 19.6 (Feb 2021) |
| | 20.8 (Jul 2021, 1 game in 4) | 21.2 (Aug 2021) |
| Buddies | 22.2 (Jan 2022) | 23.2 (May 2022) |
| | 25.6 (Mar 2023) | 26.2 (May 2023) |
| | 29.6 (Jun 2024) | 30.2 (Aug 2024) |
| | 33.6 (Sep 2025) | 34.2 (Dec 2025) |
| Quests | 24.2 (Aug 2022) | 25.2 (Jan 2023) |
| | 28.6 (Feb 2024) | 29.2 (Apr 2024) |
| | 33.2 (Aug 2025) | 33.6 (Sep 2025) |
| Anomalies | 27.2 (Aug 2023) | 28.2 (Dec 2023) |
| | 31.6 (Feb 2025) | 32.2 (Apr 2025) |
| | 32.4.2 (Jun 2025) | 33.2 (Aug 2025) |
| | 33.6.2 (Oct 2025) | 34.2 (Dec 2025) |
| | 34.6 (Feb 2026) | 35.2 (Apr 2026) |
| | 35.6 (Jun 2026) | Season 14 status UNVERIFIED |
| Tavern Spells | 28.2 (Dec 2023) | Permanent from 29.2 |
| Duos | 29.2 (Apr 2024) | Permanent |
| Trinkets | 30.2 (Aug 2024) | 31.2 (Dec 2024) |
| | 32.2 (Apr 2025) | 33.2 (Aug 2025) |
| | 35.2 (Apr 2026) | Still on in Season 14 |
| Timewarped Tavern | 34.2 (Dec 2025) | 35.2 (Apr 2026) |
| Tier 7 | 27.2 (Aug 2023) | Conditional; held back in 33.6.2 |
| Dark Gifts and Activate | 36.2 (Aug 2026) | Still on |

### Keyword changes

| Patch | Change |
|---|---|
| 20.2 | Blood Gems, Frenzy added |
| 21.2 | Avenge added |
| 23.2 | Spellcraft added |
| 26.2 | Venomous replaces Poisonous; Mega-Windfury removed; Magnetic works on a full board |
| 32.2 | Rally added |
| 36.2 | Activate added; Venomous becomes per combat |
| 36.6.1 | Deity added |

---

## Lessons for Bramble

### Systems that caused problems (with evidence)

1. **Combat timing is the biggest source of bugs and confusion.**
   - Triples formed mid-summon until 19.6.
   - Players report inconsistent order between Start of Combat and Deathrattles, and summons lost to full boards ([forum](https://us.forums.blizzard.com/en/hearthstone/t/can-we-get-some-uniform-behavior-in-bgs/133904)).
   - Hero power order went from coin flips to fixed phases, then changed again in 30.6.
   - The best public model of combat, the Firestone simulator, is full of "not sure about this ordering" comments ([deathrattle-orchestration.ts](https://github.com/bwang22/hs_sim)).
   - **Lesson:** write a formal, numbered resolution order before any card is designed, publish it, and give every trigger kind a named slot.
2. **Infinite loops and runaway stats.**
   - A minion's health grew so large it was deleted (fixed 21.8).
   - 30.0.2 had to cap two specific loops at 30.
   - 33.6.2 fixed infinite stat-gain loops; the 35.0.1 loop fix didn't work ([forum](https://us.forums.blizzard.com/en/hearthstone/t/3501-hotfix-patch/158123/1)).
   - 36.2 had to condense numbers over 4 digits.
   - **Lesson:** build iteration caps, integer limits and a display format into the engine. Bramble's escalating reroll costs are the same idea, applied to the economy.
3. **Content swings that touch hero damage.**
   - Aberrations went from Tier 3 to Tier 1 Deities to "reduce hero damage taken" (36.6.3).
   - Damage caps were added and reworked four times (21.2, 25.2, 2023, 31.2).
   - **Lesson:** keep the hero-damage formula and caps as tunable parameters, separate from content.
4. **Seasonal systems that kept coming and going.**
   - Buddies were added and removed 4 times, Quests 3 times, Anomalies 6 or more times.
   - Each change forced armor and timer changes: armor was disabled for Buddies (22.2), reworked when Quests left and Buddies returned (33.6), and the mulligan timer was tied to Buddies and Anomalies (34.2).
   - **Lesson:** this is exactly the "game-warping modifier" layer in [architecture-notes.md](../../design/architecture-notes.md). Modifiers must be removable without breaking balance knobs like armor, so make those knobs depend on which modifiers are active.
5. **Cross-tribe interactions.**
   - Beasts and Dragons were banned from sharing a lobby because of "an unwanted interaction" (30.2).
   - Card-level lobby bans: Dark Paradox and Undead; Rafaam and Aberration lobbies.
   - **Lesson:** the lobby builder needs an exclusion-rule system (pairs of tribes, card×tribe bans, hero×tribe bans). The owner's "pick N from a pool with inclusion and exclusion rules" building block covers this.
6. **Keyword drift.**
   - Poisonous was strong enough to replace with Venomous (26.2). Venomous then had to become "each combat" once Fishbait added Recruit-Phase attacks (36.2).
   - Mega-Windfury was removed for "design space".
   - Magnetic on a full board was a "negative play experience".
   - **Lesson:** when combat-like actions can happen outside combat, keyword lifetimes need an explicit scope (this combat, this turn, this game).
7. **Information and complexity load.**
   - Timers were extended at nearly every season launch.
   - Buddies left partly for "less complication".
   - The mulligan timer was tied to the number of systems in play.
   - **Lesson:** Bramble's two rows already add a lot to read. Budget how many systems are live at once.
8. **Monetised selection hurts trust.**
   - Paid extra hero choices (Perks, then the Season Pass) and token rerolls were criticised as pay-to-win ([HTD 31.2](https://www.hearthstonetopdecks.com/hearthstone-31-2-patch-notes/)).
   - This matters if Bramble ever charges for picks.
9. **Duos multiplied edge cases.**
   - Teammate-scoped effects leaked, e.g. a free refresh applied to both players, and Untold Riches' max gold applied to the teammate.
   - Disconnect and abandonment rules were needed.
   - A players' forum thread called Duos "currently unplayable" (undated) ([forum](https://us.forums.blizzard.com/en/hearthstone/t/duo-battlegrounds-is-currently-unplayable/145358)).
   - **Lesson:** every effect needs an explicit owner scope (self, team, lobby).
10. **Opponents who leave.**
    - The Buddy Meter stalled against dead or disconnected opponents (22.4.3).
    - Kel'Thuzad ghost rules and the "most recently defeated board" exist only because of uneven player counts.

### What each system was introduced to solve

| System | Problem it addressed (stated or clearly implied) |
|---|---|
| No repeat opponents (16.2), opponent cycle (33.2) | Facing the same player over and over felt unfair |
| Kel'Thuzad ghost | Odd number of living players |
| 5-of-N tribes per lobby (17.4) | Pool dilution as tribes were added; variety between games |
| Tribe guarantees at launch | Make sure players see new content (later shortened because it got "repetitive") |
| Pool copies per tier | Contested builds; T1 18→16 and T6 6→7 rebalanced early and late game |
| Tier-up discount per turn | Lets players choose between tempo and tiering; makes skipping turns a valid strategy |
| Shared pool | Contesting and reading the lobby ("hate-buying") |
| Triples with Discover from tier+1 | Reward for focus; a catch-up and power spike |
| Damage cap (21.2, 31.2) | Early snowball eliminations; "big bursts of damage in the early game" |
| Armor (21.8, per-hero from 26.2) | Hero power balance without redesigning powers; MMR-dependent strength gaps (27.2) |
| Darkmoon Prizes, Quests, Anomalies, Trinkets, Dark Gifts | Variety ("a new twist to every match"); Prizes and Anomaly no-repeat also aimed at catch-up and variety |
| Buddies | A hero-specific build path; button version for planning |
| Tavern spells | A gold sink and flexible power outside minions |
| Seasonal pool rotations (21.2+) | Stale, "very similar" endgame boards |
| Combat speed-up (31.6) | Long combats eating Recruit time |
| Rating floors (18.4) | A Ranked-like sense of progress |
| Venomous over Poisonous (26.2) | Poisonous was too efficient against large boards (INFERRED; no reason stated) |
| Golden minimum stats (~2021) | Debuffed copies made tripling a downgrade |
| Tavern Coins instead of raw gold (34.2) | Gold becomes a card that can be held and counted (INFERRED; no reason stated) |
