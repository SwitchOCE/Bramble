# Battlegrounds strategy by era

**Status: research for the pre-development design pass, 2 November 2026.** This is the by-era study the owner approved in [sources/2026-11-02-pre-development-design-pass.md](../../design/sources/2026-11-02-pre-development-design-pass.md) ("A by-era study of tribe strategies: Yes, build it"). It maps each Battlegrounds tribe's strategies in each era and sorts them into the owner's flavours.

The owner's flavours, from the same note:

- **ECO**: "lots and lots of small actions that generate money but don't give a large amount of stats".
- **WIDE**: "summoning lots of units and having a deep board: lots and lots of small units with high ability to trade".
- **SCAM**: "units ... with the ability to kill units much larger than themselves".
- **SCALE**: comps that "attempt to scale" through a trigger (death, overflow summon, battlecry, spell, magnetize and so on). Each SCALE comp is also marked **TALL** ("one or two really big units") or **MED-WIDE** ("a bunch of medium-sized units").

**Labels.** **[data]** comes from the card library, a script run or a cited source. **[judgement]** is my reading. Which comp was "the main one" in an era is always [judgement]: the library shows what was in the pool, not what won. Where a guide from the time names the comps, it is cited.

---

## 0. How this was built

- **Pool history [data]:** `data/minions.json` (`pool_periods`, sampled monthly from Dec 2019 to Oct 2026) and `data/builds.json`. I took one snapshot build per era, listed what entered and left the pool, and tagged card text with simple patterns. The script is throwaway and not in the repo; the patterns are in section 6.
- **Systems [data]:** [patch-history.md](patch-history.md).
- **Comps:** card text from the library, two guides from the time ([HearthstoneTopDecks, Nov 2019](https://www.hearthstonetopdecks.com/hearthstone-battlegrounds-guide-best-strategies-compositions/); [HSReplay, Apr 2020](https://articles.hsreplay.net/2020/04/15/battlegrounds-guide-april-2020/)), official patch notes, and my own knowledge of the game. Web searches for comp guides from 2022 to 2026 found only thin or SEO pages, so the later comp lists are mostly [judgement] built on [data] pool membership and card text.
- **Card tiers** in the tables are the library's tiers. A card's text and tier come from the **last** build it was in the pool, so an early card may show a later rework (section 6).

---

## 1. The trend in one table [data]

One snapshot build per row. "Econ-word" is minion text that matches the economy pattern in section 6: any mention of gold, Tavern Coins, refreshes, cost cuts, "free", or spending gold. That is economy-related text broadly, not gold-making minions: it includes triggers that only mention gold ("after you spend 5 Gold, give your Pirates +3/+1") and refresh-triggered buffs, and the pool counts include Duos-only cards. For the current pool it is 26 of 303; [economy-text-by-era.md](economy-text-by-era.md) §7 counts 10 of 273 minions that actually make or save gold or refreshes, and [effect-taxonomy.md](../../design/effect-taxonomy.md) 9 of 273. "Broad" adds card generation (Get, Discover, Blood Gems) and shop-side buffs (stats on minions in the Tavern). "Permanent" is text with "this game", "wherever" or "permanently". Source: snapshots of `data/minions.json`; spells from `data/spells.json`, whose pool flags start in Mar 2024.

| Era (snapshot build, date) | Pool minions | Econ-word minions | Broad econ share | Tribes with 2+ econ-word minions | Permanent-scaling text | Shop or spell-pool buffs | Venomous/scam text | Econ Tavern spells in pool |
|---|---|---|---|---|---|---|---|---|
| A Launch (38377, Dec 2019) | 84 | 0 (0%) | 1% | none | 1% | 0 | 2 | no spells |
| B Dragons (44582, Mar 2020) | 105 | 0 (0%) | 2% | none | 1% | 0 | 2 | no spells |
| B Pirates + Elementals (63160, Oct 2020) | 143 | 3 (2%) | 8% | Pirate | 2% | 1 | 3 | no spells |
| C Quilboar (86314, Jun 2021) | 143 | 6 (4%) | 20% | Pirate | 3% | 2 | 3 | no spells |
| D Revamp (126807, Nov 2021) | 145 | 8 (6%) | 26% | Elemental, Pirate | 7% | 4 | 3 | no spells |
| E S1 Naga (143410, Jun 2022) | 166 | 10 (6%) | 25% | Elemental, Naga, Pirate | 5% | 4 | 3 | no spells |
| E S2 Quests (154203, Oct 2022) | 170 | 10 (6%) | 26% | Elemental, Naga, Pirate | 6% | 7 | 3 | no spells |
| F S3 Undead (170824, Mar 2023) | 193 | 12 (6%) | 26% | Elemental, Naga, Pirate | 9% | 8 | 4 | no spells |
| F S4 Venomous (179020, Jun 2023) | 196 | 16 (8%) | 30% | Demon, Elemental, Pirate | 11% | 11 | 5 | no spells |
| G S5 Anomalies (186852, Sep 2023) | 203 | 20 (10%) | 33% | Demon, Elemental, Pirate | 9% | 15 | 6 | no spells |
| G S6 Tavern spells (193128, Jan 2024) | 211 | 20 (9%) | 34% | Demon, Elemental, Pirate | 8% | 15 | 5 | not flagged yet |
| G S7 Duos (202360, Jun 2024) | 233 | 20 (9%) | 33% | Elemental, Pirate | 12% | 19 | 4 | 7 of 51 |
| H S8 Trinkets (208182, Sep 2024) | 244 | 22 (9%) | 34% | Demon, Elemental, Naga, Pirate | 14% | 18 | 5 | 7 of 54 |
| H S9 (214839, Jan 2025) | 261 | 26 (10%) | 35% | Demon, Elemental, Naga, Pirate | 15% | 19 | 7 | 8 of 59 |
| H S10 Rally (223184, Jun 2025) | 267 | 24 (9%) | 38% | Demon, Elemental, Naga, Pirate | 18% | 27 | 7 | 8 of 61 |
| H S11 Bounties (228587, Sep 2025) | 271 | 19 (7%) | 38% | Elemental, Naga, Pirate | 14% | 26 | 7 | 9 of 68 |
| I S12 Timewarp (234747, Jan 2026) | 267 | 33 (12%) | 43% | Demon, Elemental, Mech, Naga, Pirate, Undead | 17% | 28 | 5 | 12 of 73 |
| I S13 Cataclysm (242566, May 2026) | 272 | 30 (11%) | 44% | Demon, Elemental, Mech, Naga, Pirate, Quilboar | 17% | 29 | 5 | 12 of 77 |
| J S14 Dark Gifts (250339, Aug 2026) | 275 | 28 (10%) | 45% | Demon, Elemental, Naga, Pirate, Quilboar | 17% | 29 | 4 | 11 of 76 |
| J Aberrations (255790, Oct 2026) | 303 | 26 (9%) | 44% | Demon, Elemental, Naga, Pirate, Quilboar | 16% | 31 | 4 | 12 of 76 |

What the table says:

1. **Minions with economy words stayed a small slice [data].** They rose from 0% to about 10% by Season 5 (Aug 2023) and stayed between 7% and 12% after that.
2. **The broad economy grew more than tenfold [data].** Card generation and shop-side buffs went from 1% to about 44% of the pool. This, not raw gold, is most of what "everybody has economy" means in the minion pool (section 4.3).
3. **More tribes carry economy text [data].** One tribe had two or more econ-word minions in 2020 (Pirates). Five or six do in 2026.
4. **Permanent scaling took over [data].** "This game", "wherever this is" and "permanently" went from 1% of cards to 16–18%.
5. **Scam stayed small [data].** Venomous, Poisonous, Leeroy-style and "destroy" text was 2 to 7 cards in every era, never more than about 3% of the pool.

---

## 2. Eras

Ten eras, cut at system changes in [patch-history.md](patch-history.md). Each table is the main comps per tribe. "Key cards" lists the library tier. **Engine** is what turned actions into a win.

### Era A: Launch, 4 tribes (Nov 2019 – Feb 2020)

**Context [data]:** 84 minions; Beast, Demon, Mech, Murloc, all in every lobby; no gold-making minions in the pool. Economy came from hero powers and the tier-up discount, not from minions.

| Tribe | Comp | Flavour | Key cards (tier) | Engine |
|---|---|---|---|---|
| Mech | Deathrattle and Divine Shield Mechs | WIDE + SCALE (death), TALL carry | Junkbot (5), Cobalt Guardian (3), Kangor's Apprentice (6), Mechano-Egg (4), Security Rover (4), Annoy-o-Module (4), Foe Reaper 4000 (6) | Junkbot gains +2/+2 per friendly Mech death, so the fight feeds one big unit. Taunt and shields protect it ([HTD 2019](https://www.hearthstonetopdecks.com/hearthstone-battlegrounds-guide-best-strategies-compositions/)). |
| Beast | Summon Beasts | WIDE + SCALE (summon), MED-WIDE | Mama Bear (6), Rat Pack (2), Scavenging Hyena (1), Pack Leader (3), Goldrinn (6), Savannah Highmane (4), Cave Hydra (4) | Mama Bear buffs every summoned Beast; Goldrinn's Deathrattle buffs the whole board. |
| Demon | Wrath Weaver and Floating Watcher | SCALE (play a Demon / take damage), TALL | Wrath Weaver (1), Floating Watcher (4), Mal'Ganis (5), Annihilan Battlemaster (4), Soul Juggler (3), Voidlord (5) | Spends **hero health as a currency**. HSReplay says Mal'Ganis let Weaver "go infinite" ([HSReplay 2020](https://articles.hsreplay.net/2020/04/15/battlegrounds-guide-april-2020/)). |
| Murloc | Battlecry buffs | SCALE (battlecry), MED-WIDE + SCAM | Coldlight Seer (3), Rockpool Hunter (1), Murloc Warleader (2), Old Murk-Eye (2), Toxfin (4), Gentle Megasaur (6), Brann Bronzebeard (5) | Each Battlecry buffs others; Brann doubles them; Toxfin and Megasaur add Poisonous and shields late. |
| Neutral | Menagerie | SCALE (end of turn), MED-WIDE | Lightfang Enforcer (5), Zoobot, Menagerie Magician, Brann (5) | Lightfang buffs one minion of each tribe each turn. |
| Neutral | Scam pieces | SCAM | Maexxna (Beast, 6), Toxfin (4), Zapp Slywick (6) | Poisonous kills any size; Zapp picks off small attackers. |

### Era B: Dragons, Pirates, Elementals (Feb 2020 – Apr 2021)

**Context [data]:** Dragons 16.4, Pirates 17.4 (first tribe exclusion, 5 of 6), Elementals 18.4. Pool 105 → 143. The **first gold-making minions** appear with Pirates and Elementals.

| Tribe | Comp | Flavour | Key cards (tier) | Engine |
|---|---|---|---|---|
| Dragon | Kalecgos Dragons | SCALE (battlecry), MED-WIDE | Kalecgos (6), Razorgore (5), Twilight Emissary (2), Cobalt Scalebane (4), Murozond (5) | Each Battlecry buffs all Dragons. Razorgore grows per Dragon each turn and can go TALL. HSReplay calls Kalecgos the "main way Dragons will win". |
| Dragon / mixed | Divine Shield | SCALE (shield lost), TALL | Drakonid Enforcer (4), Nadina the Red (6), Bronze Warden (2), Holy Mackerel (Murloc, 6) | Each lost shield grows Enforcer. Nadina's Deathrattle restores shields. |
| Pirate | Eliza Pirates | SCALE (attack), MED-WIDE | Dread Admiral Eliza (6), Southsea Captain (2), Ripsnarl Captain (2), Seabreaker Goliath (5) | Each Pirate attack buffs the whole board during combat. |
| Pirate | Golden Pirates and gold | ECO + SCALE, TALL | Cap'n Hoggarr (5), Freedealing Gambler (2), Deck Swabbie (1), Goldgrubber (3), Salty Looter (3) | The **first economy tribe**: Hoggarr gives gold per Pirate bought, Gambler sells for 3. Goldgrubber grows per golden minion. |
| Elemental | Nomi Elementals | ECO (shop-side) + SCALE (play), MED-WIDE | Nomi (neutral, 5), Lil' Rag (4), Majordomo Executus (4), Party Elemental (2), Sellemental (2), Refreshing Anomaly (4), Lieutenant Garr (6) | Many cheap Elementals are bought and sold. Nomi makes every later Elemental in the shop bigger, so gold buys more stats. Garr and Majordomo can go TALL. |
| Beast | Deathrattle Beasts | WIDE + SCALE (death) | Monstrous Macaw (4), Ghastcoiler (6), Goldrinn (6), Rat Pack (2), Baron Rivendare (5) | Macaw retriggers Deathrattles mid-fight; Baron doubles them. |
| Demon | Juggler Demons | SCAM-adjacent + WIDE | Soul Juggler (3), Imprisoner (1), Imp Mama (6), Annihilan (4) | Each Demon death deals 3 damage to enemies. HSReplay calls it "extremely favored" against Divine Shield. |
| Murloc | Mackerel Murlocs | SCALE (shield), MED-WIDE + SCAM | Holy Mackerel (6), Toxfin (4), Brann (5), Felfin Navigator (3) | Shield refresh plus Poisonous. HSReplay: Mackerel "almost always ensures a win". |
| Mech | Divine Shield Mechs | WIDE, defensive | Deflect-o-Bot (3), Annoy-o-Module (4), Kangor's (6) | HSReplay: weaker after Cobalt Guardian left. |
| All | Amalgadon menagerie | SCALE, MED-WIDE | Amalgadon (6), Lightfang (5) | All-tribe minions feed menagerie effects. |

### Era C: Quilboar and Blood Gems (May – Aug 2021)

**Context [data]:** 20.2 added Quilboar and Blood Gems ("spells that give a friendly minion +1/+1"). 28 minions left the pool (Holy Mackerel, Gentle Megasaur, Zoobot, Floating Watcher and others). Broad economy jumped from 8% to 20%, mostly Blood Gem generation.

| Tribe | Comp | Flavour | Key cards (tier) | Engine |
|---|---|---|---|---|
| Quilboar | Charlga Gems | SCALE (spell), MED-WIDE | Charlga (6), Bannerboar (3), Thorncaller (3), Razorfen Geomancer (1), Dynamic Duo (4) | Blood Gems are a second currency of stats in hand. Charlga plays them on the whole board each turn. |
| Quilboar | Aggem Gems | SCALE (spell), MED-WIDE across tribes | Aggem Thorncurse (6) | A gem on Aggem spreads to one minion of each type. |
| Quilboar | Bristleback Knight carry | TALL | Bristleback Knight (5) | Windfury, Divine Shield and shield regain on one gemmed unit. |
| Quilboar | Gold into gems | ECO → stats | Captain Flat Tusk (6) | "After you spend 4 Gold, get a Blood Gem": the first **gold-spent engine**, the shape Tethys and Rogers later use. |
| Demon | Eat and grow | ECO + TALL | Soul Devourer (3), Bigfernal (4), Ring Matron (4) | Devourer eats a friendly Demon for its stats **and 3 gold**. |
| Neutral | C'Thun package | SCALE, TALL | Acolyte of C'Thun (2), Champion of Y'Shaarj (4) | Taunt-triggered buffs. |
| Others | As Era B, smaller pool | | | Nomi Elementals, Pirates and Deathrattle Beasts carried on. |

### Era D: Revamp, Avenge and Buddies (Aug 2021 – Apr 2022)

**Context [data]:** 21.2 rotated 37 out and 37 in, added Avenge and the 15-damage cap. Armor came in at 21.8; Buddies ran from Jan to May 2022.

| Tribe | Comp | Flavour | Key cards (tier) | Engine |
|---|---|---|---|---|
| Demon | Tavern-eating Demons | ECO (shop-side) + TALL | Insatiable Ur'zul (5), Famished Felbat (5), Kathra'natir (3) | Demons **consume shop minions** for their stats, so stats come from the shop, not the board. Kathra'natir makes the hero Immune, so health-costing Demons play for free. |
| Mech | Divine Shield Mechs | SCALE (shield), TALL-ish | Grease Bot (4), Holy Mecherel (6), Mechano-Tank (4), Omega Buster (6) | Grease Bot makes each shield break a permanent buff. |
| Beast | Leapfrogger chain | WIDE + SCALE (death) | Leapfrogger (2), Sewer Rat (2), Reanimating Rattler (4), Palescale Crocolisk (5), Goldrinn (6) | Each Leapfrogger death passes the Deathrattle on, so buffs snowball through a fight. |
| Dragon | Start of Combat Dragons | SCALE, MED-WIDE | Prized Promo-Drake (4), Prestor's Pyrospawn (4), Tarecgosa (2), Kalecgos (6) | Combat-start buffs; Tarecgosa keeps combat gains. |
| Pirate | Card-flow Pirates | ECO (card gen) → SCALE | Peggy Brittlebone (4), Nosy Looter (6), Tony Two-Tusk (5), Briny Bootlegger (3), Eliza (6) | Peggy turns each card added to hand into Pirate stats. Tony makes golden Pirates. |
| Murloc | Avenge Murlocs | SCALE + SCAM | Swolefin (3), Saltscale Honcho (2), SI:Sefin (5) | SI:Sefin hands out Poisonous on Avenge. |
| Elemental | Nomi and refresh | ECO (refresh, shop-side) | Recycling Wraith (4), Refreshing Anomaly (4), Nomi (5), Dazzling Lightspawn (4) | Wraith makes each Elemental play cheapen the next refresh. |
| Neutral | Avenge value | ECO (card gen) | Witchwing Nestmatron (4), Master of Realities (5), Archdruid Hamuul (6) | Avenge generates cards. Hamuul refreshes the shop into your main type. |

### Era E: Naga and Spellcraft, then Quests (May 2022 – Jan 2023)

**Context [data]:** 23.2 (Season 1) added Naga and Spellcraft, removed Buddies and Amalgadon; 24.2 (Season 2) added Quests and let gold go above 10 during a turn.

| Tribe | Comp | Flavour | Key cards (tier) | Engine |
|---|---|---|---|---|
| Naga | Spellcraft wide | SCALE (spell), MED-WIDE | Shoal Commander (3), Lava Lurker (2), Tidemistress Athissa (6), Waverider (3), Glowscale (5) | Each Naga hands you a free spell every turn: **card generation as economy**. Athissa turns every spell into a permanent buff for all Naga. |
| Naga | Myrmidon carry | TALL | Corrupted Myrmidon (5), Lava Lurker (2) | Start of Combat doubles its stats; permanent spells feed it. |
| Neutral | Leeroy | SCAM | Leeroy the Reckless (5) | Deathrattle destroys whatever killed it. Back in the pool from 2022 to now. |
| Neutral | Quest era value | ECO | Tavern Tipper (1), Tortollan Blue Shell (4), Treasure-Seeker Elise (4), Ball of Minions (4) | Small gold, catch-up gold (Blue Shell sells for 5 after a loss) and sell-to-buff. |
| Murloc | Battlecry retrigger | SCALE (battlecry) | Young Murk-Eye (6), Brann (5), Primalfin Lookout (5) | Murk-Eye retriggers adjacent Battlecries each turn. |
| Demon | Eat the shop | ECO (shop-side) + TALL | Picky Eater (1), Legion Overseer (3), Ur'zul (5) | Shop-side consumption grows. |
| Dragon | End of turn Dragons | SCALE (end of turn), MED-WIDE | Nether Drake (4), Amber Guardian (3), Razorgore (5) | Every Dragon grows each turn. |
| Quilboar, Pirate, Elemental | As Era D | | | Quests gave every hero a second goal and reward line: the first economy for everyone delivered by a system, not a tribe. |

### Era F: Undead, dual types, then Venomous and gold Pirates (Jan – Aug 2023)

**Context [data]:** 25.2 (Season 3) added Undead and dual types and removed Quests. 26.2 (Season 4) rotated 73 in and 70 out, replaced Poisonous with Venomous, and let Magnetic work on a full board. Econ-word minions doubled (8 → 16), and 9 of the 16 were Pirates.

| Tribe | Comp | Flavour | Key cards (tier) | Engine |
|---|---|---|---|---|
| Undead | Attack Undead | SCALE (global counter), MED-WIDE | Nerubian Deathswarmer (2), Anub'arak (3), Eternal Knight (2), Hungering Abomination (5), Possessive Banshee (4) | "Your Undead have +1 Attack this game (wherever they are)": **buffs that live on the tribe, not the board**. |
| Undead | Reborn | SCALE (reborn), MED-WIDE | Jelly Belly (3), Sinrunner Blanchy (5), Titus Rivendare (neutral, 5) | Each Reborn trigger grows Jelly Belly; Titus doubles Deathrattles. |
| Pirate | **Gold Pirates** | ECO → SCALE (gold spent/gained), MED-WIDE | Fleet Admiral Tethys (6), Record Smuggler (5), Underhanded Dealer (3), Gunpowder Courier (4), Lovesick Balladist (4), Southsea Busker (1) | Smuggler adds 2–4 gold a turn; Tethys gives a Pirate per 10 spent; Dealer and Courier turn gold into stats. This is **the first engine that can loop** inside a turn. |
| Mech | Magnetic Mechs | SCALE (magnetize), TALL | Polarizing Beatboxer (6), Utility Drone (6), Scrap Scraper (5), Accord-o-Tron (3), Lullabot (1) | Magnetics stack onto one or two bodies. Beatboxer copies every magnetize onto itself. Accord-o-Tron is a magnetic that makes 1 gold a turn. |
| Beast | Summon doubling | WIDE + SCALE (summon) | Banana Slamma (4), Rylak Metalhead (4), Octosari (5), Humming Bird (2), Baby Krush (5) | Slamma doubles each summoned Beast's stats; Octosari's tentacle grows per summon. |
| Demon | Health as gold | ECO + SCALE (hero damage) | Malchezaar (3), Tichondrius (5), Imposing Percussionist (4) | Malchezaar makes refreshes cost health. Tichondrius buffs Demons whenever the hero takes damage. |
| Murloc | Hand and Venomous | SCALE (hand) + SCAM | Choral Mrrrglr (6), Bassgill (3), Operatic Belcher (5), Scourfin (3) | Stats stored in hand, then pulled into play; Venomous (one use) is the scam. |
| Elemental | Play-count Elementals | SCALE (play), MED-WIDE | Rock Rock (6), Gusty Trumpeter (5), Upbeat Upstart (4), Nomi (5) | Every Elemental played buffs the board. |
| Quilboar | Gem engines | SCALE (spell), MED-WIDE / TALL | Bongo Bopper (5), Bristlebach (6), Charlga (6) | Bopper plays gems on itself each turn (TALL); Bristlebach spreads them (WIDE). |

### Era G: Anomalies, Tier 7, Tavern spells, Duos (Aug 2023 – Aug 2024)

**Context [data]:** 27.2 Anomalies and Tier 7; 28.2 Tavern spells (made permanent in 29.2); 29.2 Duos and Pass. Shop or spell-pool buff cards: 11 → 19.

| Tribe | Comp | Flavour | Key cards (tier) | Engine |
|---|---|---|---|---|
| Pirate | Gold Pirates plus spells | ECO → SCALE | Tethys (6), Smuggler (5), Admiral Eliza Goreblade (6), Plunder Pal (3) | Gold loop of Era F plus Tavern spells. Goreblade buffs the board permanently per Pirate attack. |
| Naga | Spell-count Naga | SCALE (spell), MED-WIDE | Slitherspear (6), Athissa (6), Lava Lurker (2) | Tavern spells give Naga a second fuel source beyond Spellcraft. |
| Elemental | Shop-buff Elementals | ECO (shop-side) + SCALE | Living Azerite (5), Nomi (5), Emergent Flame (4), Bejeweled Duelist (2) | Each Tavern spell makes shop Elementals bigger, so later buys carry more stats. |
| Demon | Shop and spell Demons | ECO (health, shop-side) | Bazaar Dealer (5), Man'ari Messenger (5), Felboar (5), Ur'zul (5), Champion of Sargeras (7) | Spells paid in health; shop-wide buffs; eating the shop. |
| Undead | Permanent attack | SCALE (global counter), MED-WIDE | Champion of the Primus (5), Eternal Knight (2), Archlich Kel'Thuzad (5), Moroes (5) | More "this game" Undead counters. |
| Beast | Deathrattle Beasts | WIDE + SCALE (death) | Goldrinn (5), Silithid Burrower (5), Spiked Savior (5), Magnanimoose (5), Papa Bear (7) | Goldrinn returns; Burrower grows itself and buffs Beasts. |
| Dragon | Attack-trigger Dragons | SCALE (attack), MED-WIDE + SCAM | Roaring Recruiter (3), Hoarding Hatespawn (6), Amber Guardian (3) | Hatespawn steals 10/10 from the biggest enemy: a scam on a tall body. |
| Mech | Magnetic, Zilliax modules | SCALE (magnetize), TALL | Beatboxer (7), Utility Drone (6), Zilliax modules (2) | Pick-your-own magnetic modules. |
| Quilboar | Gem value | SCALE (spell) + ECO | Sanguine Champion (6), Three Lil' Quilboar (5), Snarling Conductor (4) | "Your Blood Gems give an extra +X": **the gem itself improves**, a global counter. Snarling Conductor discards a spell for 4 gold. |

### Era H: Trinkets, sub-themes, Rally, Bounties (Aug 2024 – Dec 2025)

**Context [data]:** Trinkets (30.2), Season 9 rotation (+103 / −86), Rally keyword (32.2), Pirate Bounties and Quests (33.2). Rotations of 90–107 minions each season. Each tribe now gets a **named sub-theme**: Beetles, Ballers, Volumizers (Era I), Bounties.

| Tribe | Comp | Flavour | Key cards (tier) | Engine |
|---|---|---|---|---|
| Beast | **Beetles** | WIDE + SCALE (global counter) | Forest Rover (2), Buzzing Vermin (1), Nest Swarmer (5), Turquoise Skitterer (5) | Deathrattles summon Beetles; "Your Beetles have +X this game" buffs every future Beetle. |
| Elemental | **Ballers** and sell value | ECO (sell actions) → SCALE | Fire Baller (2), Snow Baller (2), Gathering Stormer (2), Refreshing Anomaly (4) | Each Baller sold buffs the board and improves future Ballers: **the owner's ECO flavour exactly**, many small sells for value. |
| Naga | Spell-count Naga | SCALE (spell count), MED-WIDE | Thaumaturgist (2), Darkcrest Strategist (5), Showy Cyclist (5), Groundbreaker (6) | "Improved by every 3 spells you've cast this game": one global counter feeds many cards. |
| Pirate | Gold and max gold | ECO → SCALE | Doubloon Grifter (4), Dual-Wield Corsair (5), Grace Farsail (3), Gunpowder Courier (4) | Max gold goes up (Grifter); gold-spent thresholds turn spending into stats. |
| Pirate (S11) | **Bounties** | ECO (card gen) → SCALE | Sky Admiral Rogers (6), Proud Privateer (5), Shipwrecked Rascal (5), Bigwig Bandit (4) | Rogers gives a Bounty per 9 gold spent; Privateer casts Bounties twice. The owner names this as an engine that "is able to go infinite". |
| Quilboar | Rally and gems | SCALE (attack trigger, spell), MED-WIDE | Bonker (4), Glowgullet Warlord (2), Dreaming Thornweaver (4), Gem Rat (3), Turbo Hogrider (6) | Rally (on attack) plays gems; gem strength is a global counter. |
| Demon | Tavern-eat and spells | ECO (health, shop-side) + TALL | Furious Driver (5), Archimonde (5), Big Brother (4), Silent Enforcer (5), Lord of the Ruins (6) | Eat the shop; spells cheapened by hero damage. |
| Mech | Satellites | SCALE (magnetize), TALL | Moonsteel Juggernaut (6), Dr. Boom's Monster (6), Holo Rover (6), Super Constructor (5) | End of turn magnetic generation; Boom's Monster counts every magnetize this game. |
| Murloc | Bonus keywords | SCALE (battlecry), MED-WIDE + SCAM | Hackerfin (5), Implant Subject (3), Bile Spitter (5), Primitive Painter (6) | Keyword variety scales Hackerfin; Bile Spitter spreads Venomous. |
| Undead | Team counters | SCALE (death, global) | San'layn Scribe (4), Wisp in the Shell (5), Carapace Raiser (5), Eternal Knight (2) | Scribe grows per Scribe died this game. |
| Dragon | Rally Dragons | SCALE (attack), MED-WIDE | Selfless Sightseer (5), Amber Guardian (3), Roaring Recruiter (3) | Sightseer raises **max gold**: a Dragon economy card. |

### Era I: Timewarp and Cataclysm (Dec 2025 – Aug 2026)

**Context [data]:** 34.2 (Season 12) added the Timewarped Tavern, raised T5 and T6 upgrade costs, made the shop refill by card count, and turned many gold effects into **Tavern Coins** (Shell Collector, Greedy Snaketongue, Briny Bootlegger, Friendly Saloonkeeper and some hero powers; [34.2 notes](https://hearthstone.blizzard.com/en-us/news/24244423/34-2-patch-notes-battlegrounds-arena-and-gameplay-updates)). 35.2 (Season 13) added Fodder (Demons) and Chromadrakes (Dragons). Econ-word minions peaked here at 33 (12%), across six tribes.

| Tribe | Comp | Flavour | Key cards (tier) | Engine |
|---|---|---|---|---|
| Elemental | **Refresh Elementals** | ECO (refresh) → SCALE (shop-side) | En-Djinn Blazer (4), Waveling (3), Air Revenant (5), Acid Rainfall (6), Stone Age Slab (7) | "After the Tavern is Refreshed this game, give a random minion in it +10/+10": **every refresh buys stats**. Elementals had 7 econ-word minions, the most they ever had. |
| Mech | **Volumizers** | SCALE (magnetize, global), TALL | Red, Blue, Green Volumizer (2), Auto Accelerator (3), Conveyor Construct (4), Junk Jouster (6) | "Your Volumizers have +X this game (wherever they are)". |
| Pirate | Gold Pirates return | ECO → SCALE | Tethys (6), Industrious Deckhand (4), Cannon Corsair (5), Visionary Shipman (5), Minted Corsair (1) | 11 econ-word Pirates, the most of any tribe in any era. Tavern Coins replace raw gold in places. |
| Demon | **Fodder** | ECO (shop-side) + TALL | Woodland Defiler (4), Laboratory Assistant (2), Twisted Wrathguard (6), Consummate Conqueror (6), Flaming Enforcer (4) | Fodder tokens appear in later refreshes for Demons to eat. **Refreshes become meals**. |
| Dragon | **Chromadrakes** | SCALE (spell-pool), MED-WIDE | Chromadrakes (3), Draconic Warden (5), Incubation Researcher (4), Twilight Broodmother (5) | Each colour makes Tavern spells stronger this game. |
| Beast | Summon carry | WIDE + SCALE, TALL support | Stalwart Kodo (7), Hunting Tiger Shark (4), Silithid Burrower (5) | Kodo gives its stats to each summon. |
| Undead | Spell attack | SCALE (spell, global) | Forsaken Weaver (6), Wintergrasp Ghoul (5), Eternal Summoner (5) | Each Tavern spell gives Undead attack this game. |
| Murloc | Mrrglton pair | SCALE (battlecry), MED-WIDE | Mama Mrrglton (3), Papa Mrrglton (3), Choral Mrrrglr (6) | Each Mrrglton improves the next. |
| Quilboar | Gems on everything | SCALE (spell), MED-WIDE | Earthsong Shaman (6), Vinespeaker (5), Hired Ritualist (4), Bristlebach (6) | Gems spread over the whole board; Hired Ritualist turns a gem into 2 gold once per turn. |

### Era J: Dark Gifts, Activate, Lockbox, Fishbait, Aberrations (Aug 2026 – now)

**Context [data]:** 36.2 (Season 14) added Dark Gifts, the Activate keyword (pay gold for an effect during the Recruit Phase), Lockbox (Pirates), Fishbait (Beasts attack during the Recruit Phase) and per-combat Venomous; 96 minions out, 62 new, 31 back. Aberrations arrived in 36.6.1 with discard synergies and a Deity that joins after 4 Aberration deaths. Naga rotated out in 36.6.1, though the library still flags them in the pool (section 6).

| Tribe | Comp | Flavour | Key cards (tier) | Engine |
|---|---|---|---|---|
| Aberration | Deity | TALL (one huge unit) + SCALE (discard, spell) | Mindbender Ghur'sha (5), Harbinger Aph'lass (6), The Shadow of Doubt (6), Cutthroat K'Thir (4), Sha of Fear (7), Joyous (1) | Most buffs go to the Deity. Activate (0) cards discard spare cards for value. |
| Pirate | **Lockbox and golden Pirates** | ECO (card gen, golden) → SCALE | Bilgewater Breakout (2), Locked-up Mutineer (3), Enterprising Escapee (5), Maritime Extortionist (4), Hooktusk (6), Sky Admiral Rogers (6) | Lockboxes open into golden minions on later turns; Extortionist grows per golden played. Gold-spent thresholds remain (Rogers, Escapee). |
| Beast | **Fishbait and Rally** | SCALE (attack), WIDE | Snarky Shark (4), Lurking Lionfish (2), Wolf Pup (3), Cage Gnawer (4), Deathstrider (6) | Beasts attack in the shop for rewards. Snarky Shark's sale refreshes the Tavern: a **free refresh** source. |
| Beast | Beetles return | WIDE + SCALE (global) | Forest Rover (2), Turquoise Skitterer (5), Ravaging Scorpid (6) | As Era H. |
| Demon | Activate tavern-eat | ECO (shop-side) + TALL | Soulkeeping Jailer (4), Deft Deserter (5), Insatiable Ur'zul (5), Trapped Clapper (3), Malchezaar (3) | Pay 1–2 gold to buff or eat the whole shop. |
| Quilboar | Choose One | ECO (refresh, max gold) + SCALE (spell), MED-WIDE | Thorned Trailblazer (3), Sly Infiltrator (3), Snare Trapper (4), Turbo Hogrider (6), Veteran Brigand (6), Victorious Geomant (6) | Sly Infiltrator gives 2 free refreshes; Snare Trapper raises max gold; Trailblazer combines both modes. |
| Elemental | Refresh and Ballers | ECO → SCALE (shop-side) | En-Djinn Blazer (4), Waveling (3), Air Revenant (5), Air Baller (4), Unbound Tempest (6) | As Era I, plus Ballers. |
| Murloc | Hand stats | SCALE (spell, hand), TALL-ish | Twilight Tidehunter (4), Shamanic Tidecaller (5), Choral Mrrrglr (6), Futurefin (7), Kelp Keeper (4) | Spells on Murlocs grow minions in hand, then Choral absorbs the hand. |
| Mech | Volumizers and Satellites | SCALE (magnetize), TALL | Spark Snapper (5), Glambot (4), Resourceful Robot (5), Auto Reveille (6), Utility Drone (6) | Every play or spell magnetizes something. |
| Undead | Reborn | SCALE (reborn), MED-WIDE | Barrier Banshee (5), Snazzy Phantom (6), Dead Bellringer (4), Eternal Tycoon (5) | Reborn triggers grow the board. |
| Dragon | Rally and spells | SCALE (attack, spell-pool) | Crimson Vindicator (6), Blue Whelp (3), Bronze Timewalker (4), Hopebringer (5) | Rally buffs plus stronger Tavern spells. |
| Neutral | Scam and set-stats | SCAM | Leeroy (5), Deadly Spore (3), Tyrael (6, set to 50/50), Sin'dorei Straight Shot (4) | Few cards; Venomous now resets each combat. |

---

## 3. Tribe lines across eras [judgement on [data]]

The same tribe tends to keep one or two engine shapes for years, with the cards rotated.

| Tribe | Core shape that persists | Economy role | Tall or wide | Scam |
|---|---|---|---|---|
| Beast | Summon and Deathrattle (Rat Pack → Leapfrogger → Beetles → Rally Beasts) | Almost none until Snarky Shark (2026) | WIDE, with summon-buff payoffs | Maexxna early only |
| Demon | Turn a non-gold resource into stats: hero health (Weaver, Malchezaar, Bazaar Dealer), then shop minions (Ur'zul, Fodder, Jailer) | Health as gold since launch; econ-word minions from 2023 | TALL | Soul Juggler damage early |
| Mech | Deathrattle and shields (2019–22), then magnetize onto one body (2023 on) | Accord-o-Tron (magnetic gold) | TALL from 2023 | None |
| Murloc | Battlecry buffs, then buffs stored in hand | Card generation only | MED-WIDE | The longest scam line: Toxfin, Megasaur, SI:Sefin, Belcher, Bile Spitter |
| Dragon | Battlecry/end-of-turn buffs, then shields, then Start of Combat and Rally, then Tavern-spell power | Max gold (Selfless Sightseer) | MED-WIDE | Red Whelp, Hatespawn |
| Pirate | Attack-trigger buffs (Eliza), golden minions, **gold made and spent** | **The economy tribe in every era since 2020** | MED-WIDE | None |
| Elemental | Play-count and shop-side buffs (Nomi), refresh economy, sell value (Ballers) | **The refresh tribe** (Refreshing Anomaly in the pool every era since Sep 2020) | MED-WIDE, some TALL (Garr, Majordomo) | None |
| Quilboar | Blood Gems as a stat currency in hand; gems improve this game | Gem generation; occasional gold (Flat Tusk, Snare Trapper, Sly Infiltrator) | MED-WIDE, occasional TALL (Bopper, Knight) | None |
| Naga | Free spell per minion per turn; spell-count counters | Card generation; Tavern Coins (Shell Collector) | MED-WIDE, one TALL (Myrmidon) | None |
| Undead | Global "this game" attack counters; Reborn | Little | MED-WIDE | None |
| Aberration | One Deity carries; discard for value | Card churn | TALL | None |

---

## 4. Cross-era patterns

### 4.1 Archetype shapes that recur

1. **Health or the shop as a second currency [data].** Demons have always turned something other than gold into stats: hero health in 2019 (Wrath Weaver), refreshes paid in health in 2023 (Malchezaar), shop minions from 2021 (Ur'zul) to 2026 (Fodder, Soulkeeping Jailer). Hero health is self-bounding: a player who spends too much dies.
2. **Death and summon chains [data].** Every era has a Beast line (and often Mech or Undead) where deaths make more bodies and buffs pass along. It is always WIDE.
3. **One carry body [data].** Junkbot (2019), Bristleback Knight (2021), Corrupted Myrmidon (2022), Beatboxer and Volumizers (2023–26), the Deity (2026). Magnetic Mechs have been the steady TALL tribe since 2023.
4. **Retriggers [data].** Brann (Battlecries twice) has been in the pool almost the whole time. Baron/Titus double Deathrattles; Drakkari Enchanter doubles end-of-turn; Young Murk-Eye and Kelp Keeper retrigger Battlecries. Retriggers are what turned free refreshes into loops (content-guardrails G1).
5. **Global counters replaced board buffs [data].** "This game" and "wherever this is" text went from 1% to 16–18% of the pool. Undead attack (2023), gem strength, Beetles, Volumizers, Ballers, "every 3 spells", "your Tavern spells give an extra +1/+1". These counters can't be lost by selling a minion, so the player can churn the board for value without losing scaling.
6. **Buying stats from the shop [data].** Shop and spell-pool buffs went from 0 to 31 cards. Nomi (2020) was the prototype; by 2026 Elementals, Demons, Dragons and the neutral spell-buffers all do it. Here economy and scaling merge: each gold spent buys a bigger minion or spell.
7. **Scam is always present and always small [data].** 2 to 7 cards per era. Poisonous was replaced by one-shot Venomous (26.2), then Venomous became per combat (36.2). Leeroy (2022 on) and stat-setting (Tyrael) took part of the role. Only Murlocs carried scam as a tribe theme, and never as their only win.
8. **Named sub-themes inside a tribe [data].** From late 2024 each tribe gets a token family with its own counter (Beetles, Ballers, Volumizers, Bounties, Fodder, Chromadrakes, Lockbox). The tribe stays; the sub-theme rotates each season.

### 4.2 Which tribes always carry economy

- **Pirates [data]:** 2 or more econ-word minions in every snapshot from Oct 2020 to now, peaking at 11 (Jan 2026). Their engines are **gold-spent thresholds**: Flat Tusk 4 (Quilboar, 2021), Courier 5, Dual-Wield 5, Escapee 6, Rogers 9, Tethys 10.
- **Elementals [data]:** the refresh tribe. Refreshing Anomaly has been in the pool every month since Sep 2020; Recycling Wraith (2021–24); refresh-triggered shop buffs from Dec 2025 (Waveling, En-Djinn Blazer, Acid Rainfall).
- **Demons [data]:** health as gold, and shop-eating. Two or more econ-word minions in most snapshots from 2023.
- **Naga [data]:** card generation every turn, plus Tavern Coins.
- **Quilboar [data]:** a parallel currency (Blood Gems), plus a few gold and refresh cards.
- **Beast, Mech, Murloc, Undead, Dragon [data]:** almost no gold economy at any time. Each has one or two neutral-looking econ cards at most (Accord-o-Tron, Selfless Sightseer, Snarky Shark).

### 4.3 "Everybody has economy" today, against older eras

What the owner likes about the current patch ("I think it's a better situation where everybody has them") shows up in the data as follows:

| | 2019–2020 | 2023 (S4) | 2026 (S14) |
|---|---|---|---|
| Minions with economy-related text (econ-word, section 1) [data] | 0–3 | 16 (8%) | 26–28 (9–10%) |
| Tribes with 2+ econ-word minions [data] | 0–1 | 3 | 5 |
| Broad economy share (gold + card gen + shop-side) [data] | 1–8% | 30% | 44–45% |
| Economy Tavern spells [data] | none | none | 11–12 of 76 |
| System-level economy [data] | Tier-up discount only | Hero powers; gold above 10 (24.2) | Tavern Coins, Activate costs, Trinkets, Dark Gifts, hero powers |

**Reading [judgement]:**

- "Everybody has economy" is **not** "every tribe makes gold". Minions with economy-related text grew only modestly. What grew is (a) economy outside tribes (Tavern spells, Tavern Coins, Trinkets, neutral cards like Wanderer Cho and Tortollan Blue Shell) and (b) economy dressed as each tribe's own currency: gems, spells, Fodder, Lockboxes, Ballers.
- Each tribe gets a **different kind** of economy: Pirates spend gold, Elementals refresh, Demons spend health and eat the shop, Quilboar and Naga make cards, Mechs get free magnetics. This keeps tribes distinct while everyone gets the fun of extra resources.
- The old eras show the opposite: one or two tribes had economy (Pirates, Nomi Elementals) and everyone else played for stats. Pirates were often a forced pick for players who wanted a long turn.

### 4.4 The engines that looped, and what limited them

| Engine | Era | Loop | What limited it in Battlegrounds |
|---|---|---|---|
| Wrath Weaver + Mal'Ganis | 2019–21 | Demons played for free health | Weaver and Watcher reworks; Mal'Ganis left in 21.2 [data] |
| Free refresh + Brann retriggers | various | Refresh anomaly + golden Brann | Rule fixes; Bramble guardrail G1 already covers this |
| Tethys + Record Smuggler + gold-to-stat Pirates | 2023–24, back 2025–26 | Spend 10 → Pirate → gold → spend | Turn timer only [judgement]; Tethys out of the pool Nov 2024 – Dec 2025 [data] |
| Rogers + Proud Privateer + Bounties | Aug–Nov 2025, Apr 2026 on | Spend 9 → Bounty (cast twice) → gold or stats | Turn timer only [judgement] |
| Refresh-triggered Elementals | Dec 2025 on | Each refresh buffs a shop minion | Each refresh still costs gold, so it runs out; free refresh cards extend it |
| In-combat stat loops | 2024–25 | Adaptive Amalgam, Immortal Prelate | Hard cap of 30 loops (30.0.2) [data] |

---

## 5. What this means for Bramble [judgement]

Bramble has no turn timer, only the refresh action escalates, and the best engines should see about 20–30 shops in a turn. Against that:

1. **Gold-spent thresholds are the risky shape.** Every Pirate loop above is "after you spend N gold, get X", where X gives gold back or a card worth more than N. With no timer, only content can bound this. Options for the content guardrails: the threshold rises each time it triggers ("(9 Gold left!)" becomes 10, 11, ...), the reward can't make gold, or the trigger is once per turn. I'd suggest the first: it keeps the Tethys feeling and makes the turn end by itself.
2. **Refresh-paid engines fit Bramble well.** Elemental-style "each refresh buffs the shop" is bounded by escalating refresh cost already. It is the cleanest way to give a long, fun turn.
3. **Health as a currency self-bounds.** Demon-style "pay health instead of gold" ends when the player gets scared of dying. It is a good no-timer economy, if hero damage is tuned with it.
4. **Global "this game" counters suit async play.** They are easy to snapshot for asynchronous fights (rulebook 2.1.4 delta) and they let players churn the board without losing scaling. HSBG moved most scaling there over seven years.
5. **Give each tribe its own currency, not the same gold.** That is how HSBG reached "everybody has economy" without every tribe being a gold tribe.
6. **Scam is a spice, not a tribe.** HSBG kept it at 2–7 cards for seven years and nerfed it twice. Bramble positioning rules give a natural home for it (back-row assassins), but it should stay a small slice.
7. **The tall/wide split is mostly per tribe.** In HSBG, Mechs, Demons and Aberrations go TALL; Beasts, Undead, Quilboar and Naga go WIDE; Murlocs and Dragons go medium-wide. With 10 Bramble tribes, about 3 tall, 4 wide and 3 mixed would match.

---

## 6. Limits

- **Monthly sampling [data].** `builds.json` has one build per month. A card in the pool for less than a month may be missed, and "first seen" can be up to a month late.
- **Text is the last version [data].** Every card's `text` and `tier` come from the last build it was in the pool. An early card can show a later rework (for example Kalecgos now reads "+2/+2" after any Battlecry). The pattern counts in section 1 inherit this.
- **Crude tagging [data].** Patterns: econ-word `gold|tavern coin|refresh|cost(s) N less|free|instead of gold|max gold|spend|spent`; card gen `get a/an/N|add a|discover|blood gem`; shop-side `in the tavern|minions in your|tavern spells give an extra|your blood gems give`; permanent `this game|wherever|permanently`. They miss some cards (Deck Swabbie's "Reduce the Cost of upgrading" escaped the econ-word pattern) and over-count others (Blood Gem generation counts as economy).
- **Naga still flagged [data].** The 37.0.0 build still flags 24 Naga in the pool, though 36.6.1 rotated Naga out. The pool flag doesn't model tribe rotation. Era J treats Naga as gone.
- **Spells.** `spells.json` pool flags start in Mar 2024 (build 197064), so Tavern spell counts before then are blank, not zero.
- **Comps are [judgement].** The library shows what was available, not what players won with. Win rates by comp were not available here; HSReplay and Firestone hold them behind accounts.
- **Duos-only cards** are included in pool counts from 29.2.
- **Not reviewed:** hero powers, Trinkets, Quests, Anomalies, Buddies and Dark Gifts as economy sources. They carry much of today's economy (section 4.3) and deserve their own count.

## Sources

- Card library: [data/minions.json](data/minions.json), [data/builds.json](data/builds.json), [data/spells.json](data/spells.json), described in [content-library.md](content-library.md).
- System timeline: [patch-history.md](patch-history.md).
- HearthstoneTopDecks, "Hearthstone Battlegrounds Guide – Best Strategies / Compositions", 14 Nov 2019: https://www.hearthstonetopdecks.com/hearthstone-battlegrounds-guide-best-strategies-compositions/
- HSReplay, "Battlegrounds guide, April 2020": https://articles.hsreplay.net/2020/04/15/battlegrounds-guide-april-2020/
- Patch notes 33.2 (Bounties, Rally): https://hearthstone.blizzard.com/en-us/news/24223019/33-2-patch-notes
- Patch notes 34.2 (Tavern Coins, Volumizers): https://hearthstone.blizzard.com/en-us/news/24244423/34-2-patch-notes-battlegrounds-arena-and-gameplay-updates
- Patch notes 35.2 (Fodder, Chromadrakes): https://hearthstone.blizzard.com/en-us/news/24271853/35-2-patch-notes
- Patch notes 36.2 (Dark Gifts, Activate, Lockbox, Fishbait, Venomous): https://hearthstone.blizzard.com/en-us/news/24290432
