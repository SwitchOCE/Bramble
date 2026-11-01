# Hearthstone Battlegrounds: rules and systems

**State described:** patch **36.6.3** (1 Oct 2026), mid-way through **Season 14, "Dark Gifts of Dalaran"** (began 4 Aug 2026 with 36.2). Aberrations joined the pool in 36.6.1 (22 Sep 2026). Patch 37.0.0 shipped around 13–26 Oct 2026 (the wiki patch list gives 13 Oct; the HearthstoneJSON build used in [content-library.md](content-library.md) is dated 26 Oct). I did not review its Battlegrounds changes.

Written 27 Oct 2026 as a baseline for Bramble's rulebook. The owner will mark where Bramble differs. Read it together with [patch-history.md](patch-history.md) (how each rule got here), [keywords.md](keywords.md) (glossary) and [content-library.md](content-library.md) (card data).

**Labels**
- **UNVERIFIED**: I found no source. The claim comes from memory or general community knowledge.
- **SIM**: taken from the open-source Firestone battle simulator, the engine behind the Firestone app's win-odds overlay. I read a mirror, [bwang22/hs_sim](https://github.com/bwang22/hs_sim) (last updated Feb 2026, files under `simulation/`). Its code comments cite replays and messages from Blizzard designer Mitchell Loewen. The simulator is a reverse-engineered model, not Blizzard's code, but it is the most detailed public account of combat order.
- **INFERRED**: my conclusion from the wording of a source.

## Sources used throughout

| Key | Source |
|---|---|
| WIKI | Hearthstone Wiki, Battlegrounds page, last edited 14 Apr 2026: https://hearthstone.wiki.gg/wiki/Battlegrounds |
| DUOS | Hearthstone Wiki, Battlegrounds Duos: https://hearthstone.wiki.gg/wiki/Battlegrounds_Duos |
| P36.2 | 36.2 patch notes, 3 Aug 2026: https://hearthstone.blizzard.com/en-us/news/24290432 |
| S14 | Season 14 announcement: https://hearthstone.blizzard.com/en-us/news/24290433 |
| ABR | Aberrations announcement, 12 Sep 2026: https://hearthstone.blizzard.com/en-us/news/24302091 |
| P36.6 | 36.6 patch notes, updated 29 Sep 2026: https://hearthstone.blizzard.com/en-us/news/24294373/366-patch-notes |
| P36.6.3 | 36.6.3 patch notes, 1 Oct 2026: https://hearthstone.blizzard.com/en-us/news/24303864/3663-patch-notes |
| P34.2 | 34.2 patch notes, Dec 2025: https://hearthstone.blizzard.com/en-us/news/24244423/34-2-patch-notes-battlegrounds-arena-and-gameplay-updates |
| S9 | Season 9 announcement (damage cap, hero rerolls): https://hearthstone.blizzard.com/news/24159389/announcing-battlegrounds-season-9 |
| P33.2 | 33.2 patch notes (Rally, matchmaking): https://hearthstone.blizzard.com/en-us/news/24223019/33-2-patch-notes |
| P28.2 | 28.2 patch notes (Tavern spells): https://hearthstone.blizzard.com/en-us/news/24008697/28-2-patch-notes |
| P26.2 | 26.2 patch notes (Venomous, Windfury, Magnetic): https://hearthstone.blizzard.com/en-us/news/23935322/26-2-patch-notes |
| P25.2 | 25.2 patch notes (Undead, dual types): https://hearthstone.blizzard.com/en-us/news/23892225/25-2-patch-notes |
| SIM | Firestone simulator mirror: https://github.com/bwang22/hs_sim |
| GOLDEN | Golden stat rule (designer Dominic Calkosz, about May 2021): https://outof.games/news/3091-debuffs-in-battlegrounds-golden-minions-when-created-to-always-have-at-least-their-base-stats/ |
| KW | Hearthstone Wiki keyword descriptions: https://hearthstone.wiki.gg/wiki/Ability |

---

## 1. Lobby

- **Players:** 8 players play 1v1 rounds until one is left ([WIKI]).
- **Odd player counts:** when the number of living players is odd, one player fights **Kel'Thuzad**, a dummy hero with 0 health. He uses the board and Tavern Tier of the most recently eliminated player, assigned at the start of the Recruit Phase. If someone concedes mid-phase, Kel'Thuzad uses that board instead ([WIKI]).
- **Turn limit:** a game-length limit exists, working as in constructed Hearthstone ([WIKI]). The exact value is UNVERIFIED.
- **Bots:** since Season 6 (28.2), bots fill some lobbies for new and low-MMR players ([P28.2]).
- **Duos:** 4 teams of 2. See §16.

## 2. Heroes, health and armor

**Selection**
- Each player is offered **2 heroes, or 4 with the Battlegrounds Season Pass**. No hero is offered to two players in the same lobby ([WIKI], [S14]).
- Each offered slot can be rerolled once for 1 Battlegrounds Token, so a player has 0–2 rerolls (0–4 with the Pass). Season Pass+ makes the first reroll free. A reroll can't produce a hero already offered or one banned in the match ([WIKI], [S9]).
- The hero choice timer is **70 seconds**. 34.2 restored it to 70 "now that Buddies and Anomalies are gone" ([P34.2]).
- Heroes whose power depends on a tribe are banned from lobbies without that tribe ([17.4 notes](https://hearthstone.blizzard.com/en-us/news/23440114); [ABR] lists the bans for the Aberration lobby).
- New heroes are guaranteed to be offered for 2 weeks after release ([P36.6.3]).

**Health and armor**
- Heroes start with **30 health**. Patchwerk starts with 60 ([WIKI]).
- Each hero has a **fixed armor value** set by Blizzard to balance hero strength. Higher-tier heroes get less armor. Armor absorbs damage before health. The values are published in patch notes and change often, e.g. 36.2 lists Cariel 14, Edwin 15, Rakanishu 10 ([P36.2]).
  - Solo and Duos have separate values ([P34.2]).
  - Separate low-rank values existed from Season 5 to at least Season 11. Whether low-rank values still exist is UNVERIFIED.
- The current range is roughly 0–19 for Solo (UNVERIFIED; 0–19 was the published range in Season 8).
- See [patch-history.md](patch-history.md) for how armor went from random tiers to fixed values.

## 3. Turn structure and timers

Each round is a **Recruit Phase** (shopping) and then a **Combat Phase** ([WIKI]).

- **Recruit timer:** 60 seconds in round 1, then +15 seconds per round, up to **120 seconds**. The recruit timer starts when combat starts, so a short combat leaves more shopping time ([WIKI]).
- **Temporary extensions:** Blizzard often adds 5 seconds per turn at the start of a season or when a big system launches, for players to learn it (see [patch-history.md](patch-history.md)).
- **Combat speed-up:** since 31.6 (Feb 2025), combat animations speed up the longer a combat runs, then slow near the end. Duos has a higher maximum speed-up ([31.6 notes](https://hearthstone.blizzard.com/en-us/news/24179332), [P34.2]).
- **Turn-numbered events** (current or recent):

| Turn | Event |
|---|---|
| 1 | Tier 1 shop; 3 gold |
| 3+ | Dark Gift button available (Season 14) |
| 4 | Quest offer, in seasons with Quests (24.2, 28.6, 33.2) |
| 6 | Lesser Trinket offer (Seasons 8, 10, 13, 14); Minor Timewarp (Season 12) |
| 8 | Reach 10 gold; damage cap rises to 15 |
| 9 | Greater Trinket offer; Major Timewarp (Season 12) |

## 4. Gold

- **Income:** you have **3 gold on turn 1**, +1 each turn, up to **10**. Unspent gold is lost at the end of the turn ([WIKI]).

| Turn | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8+ |
|---|---|---|---|---|---|---|---|---|
| Gold | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |

- **Going above 10:** since 24.2 (Aug 2022), gold can go above 10 during the Recruit Phase, for example by selling. The start-of-turn cap is still 10 ([24.2 notes](https://hearthstone.blizzard.com/en-us/news/23831411/24-2-patch-notes)).
- **Raising the cap:** some effects raise the maximum. Corrupted Coin raises it by 2 if discarded ([ABR]); the quest reward Untold Riches gave +7 ([P33.2]).
- **Other gold sources** (all card- or hero-specific):
  - selling minions (1 gold each, see §5);
  - **Tavern Coin**, a Tier 1 Tavern spell: "Gain 1 Gold." Since 34.2, many effects give Tavern Coins instead of gold ([P34.2], [content-library.md](content-library.md));
  - delayed gold, e.g. Private Investigator, "Activate (1): Gain 2 Gold next turn" (card data);
  - Pirate and gold-spend payoffs ("After you spend 7 Gold…");
  - hero powers.
- **Health as a currency:** some cards and heroes let you pay health instead of gold. Malchezaar makes two Refreshes each turn cost health; the Tavern spell Hasty Excavation cost health ([P28.2]).

## 5. The Tavern (Bob's shop)

### 5.1 Tiers and upgrade costs

- Tavern Tiers run from **1 to 6**. **Tier 7** exists only through special effects (see §15.8) ([WIKI]).
- Each turn you don't upgrade, the upgrade cost drops by 1, down to a minimum of 0 ([WIKI]). The minimum of 0 is INFERRED.
- Since 34.2 (Dec 2025), Solo upgrade costs are ([WIKI], [P34.2]):

| Upgrade to | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|
| Base cost (Solo) | 5 | 7 | 8 | 11 | 11 |

- **Example:** reaching Tier 2 on turn 2 costs 4, because the 5 dropped by 1 on turn 2. That uses all 4 gold.
- **Duos:** upgrades to Tiers 4–6 cost 2 more than Solo ([DUOS], from 29.2). Combined with 34.2's +1 in both modes, that gives 5/7/10/13/13. This is INFERRED; I found no table.

### 5.2 Shop size

Since 34.2, the shop refills by **total cards, not minions**. One slot is normally a Tavern spell ([P34.2], [P28.2]).

| Tavern Tier | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| Cards offered | 4 | 5 | 5 | 6 | 6 | 7 |
| of which minions | 3 | 4 | 4 | 5 | 5 | 6 |

- Tier 7 shop size is UNVERIFIED.
- **Frozen shops:** a frozen shop keeps its cards, and only the empty slots refill. Since 34.2, a frozen shop that already holds enough cards (spells included) gets no extra minions ([P34.2], [WIKI]).
- **Which cards appear:** the shop offers minions of your Tavern Tier or lower, drawn from the shared pool ([WIKI]). Each draw is weighted by the copies left in the pool, so a minion others have bought shows up less ([WIKI]: bought minions "reduce the chance" of that minion appearing for others). The exact per-tier weighting is UNVERIFIED.

### 5.3 Actions and prices

| Action | Cost | Notes |
|---|---|---|
| Buy a minion | 3 gold, any tier | Goes to hand ([WIKI]). |
| Sell a minion | +1 gold | Tokens and generated minions also sell for 1, unless a card changes its sell price ([WIKI]). |
| Refresh (reroll) | 1 gold | No limit. Free refreshes come from effects; the Refresh button shows how many you have ([WIKI], [P34.2]). |
| Freeze | Free | Toggle up to 5 times per Recruit Phase ([WIKI]). The frozen shop carries into next turn. |
| Upgrade | See §5.1 | |
| Tavern spell | Its own cost | See §8. |
| Play a minion | Free | Max **7** on the board ([WIKI]). |

- **Hand limit:** 10 cards (UNVERIFIED for Battlegrounds specifically; it is the Hearthstone standard). The Timewarped Tavern could temporarily raise it ([P34.2]).
- **Positioning:** you reorder minions freely during the Recruit Phase. Board order is the main tactical lever in combat (§11).

## 6. The shared minion pool

- **One pool for the lobby:** all 8 players draw from the same pool ([WIKI]).
- **Copies of each minion** in the pool ([WIKI], citing designer Mitchell Loewen's posts of Oct 2024: https://x.com/LoewenMitchell/status/1841922013826273496):

| Tier | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|
| Copies of each minion | 15 | 15 | 13 | 11 | 9 | 7 | 5 |
| Copies of each Tavern spell | 5 | 7 | 9 | 11 | 9 | 7 | — |

- **Distinct minions per tier:** the wiki (Apr 2026) lists 24/37/45/62/56/35/13 for Tiers 1–7, across all tribes. The 37.0 card data gives 26/41/53/69/62/38/14 ([content-library.md](content-library.md)). A lobby only uses its 5 tribes plus neutrals, so the pool in a given game is smaller.
- **Removing and returning copies:**
  - Buying removes a copy; selling returns it ([WIKI]).
  - Minions taken by Discover are also removed from the pool ([WIKI], citing https://www.reddit.com/r/BobsTavern/comments/dst4tz/questions_about_battleground_rules/f6wc5r8/).
  - Minions sitting in a shop are held out of the pool until that shop is refreshed or the turn ends. This is UNVERIFIED but widely assumed.
  - Selling a golden minion returns 3 copies: UNVERIFIED.
  - An eliminated player's minions go back to the pool: UNVERIFIED.
- **Generated minions:** tokens and created minions (summons, "get a random X") do not come from the pool. INFERRED from the pool rules above.

## 7. Tribes (minion types) per lobby

- **Tribes in rotation (36.6.3):** Beast, Demon, Dragon, Elemental, Mech, Murloc, Pirate, Quilboar, Undead and **Aberration** (new in 36.6.1). **Naga** are "temporarily rotated out", along with Naga-only heroes and cards ([ABR], [P36.6]).
- **Five tribes per lobby:**
  - Each lobby uses 5 tribes chosen at random. With 10 tribes in rotation, each appears in about 50% of lobbies. 36.6.3 says Aberrations now have "the standard 50% chance to appear in lobbies" ([P36.6.3]).
  - "5 of N" became explicit in 17.4 (Pirates, 2020). 25.2 kept "the same number of types per game" while excluding one more ([P25.2]).
  - That the count is still exactly 5 is INFERRED from the 50% figure and those notes.
- **New tribes are guaranteed** in every lobby for a launch window: 2 weeks originally, cut short for Aberrations. Blizzard now expects "a one-week guarantee" for new tribes ([P36.6.3]).
- **Lobby rules:**
  - Beasts and Dragons could not share a lobby from 30.2 (Aug 2024) "due to an unwanted interaction". Whether that rule is still active is UNVERIFIED.
  - Single cards can be banned from some lobbies, e.g. Dark Paradox "Cannot appear in lobbies with Undead" ([ABR]).
  - Heroes tied to an absent tribe sit out (§2).
- **Dual-type minions** are in the pool if either of their tribes is in the lobby ([P25.2]).
- **Neutral minions** (no tribe) are always in the pool. **"All"-type minions** (Amalgadon-style) count as every tribe. Six are in the current pool ([content-library.md](content-library.md)).
- **Scoreboard:** shows each opponent's majority tribe and count, or "Mixed Minions" on a tie ([WIKI]).

## 8. Tavern spells

Tavern spells were introduced in Season 6 (28.2, Dec 2023) and made permanent in 29.2 ([P28.2]; [29.2 notes](https://hearthstone.blizzard.com/en-us/news/24077473/29-2-patch-notes)).

- **Offer:** one shop slot per refresh is a spell of your tier or lower ([P28.2]).
- **Cost:** varies by spell. Examples: Tavern Coin 1, Golden Touch 5; some spells cost health ([P28.2]).
- **Use:**
  - A bought spell goes to hand and is cast during the Recruit Phase. Most target a minion or the Tavern.
  - Spells are single use and can't triple. A frozen spell stays frozen ([P28.2]).
- **Pool:** spells have their own copy counts (§6) and are rotated each season like minions ([P36.2]).
- **Other spell sources:**
  - **Spellcraft** spells (temporary; see [keywords.md](keywords.md)).
  - **Blood Gems** (Quilboar).
  - **Bounties:** Pirate-only Tier 3 spells from 33.2. Current status UNVERIFIED.
  - Golden Touch: "Make a random minion in the Tavern Golden."
  - Tier 7 Tavern spells (31.6).

## 9. Triples and golden minions

- **Forming a triple:** when you hold **3 copies of the same normal minion** across your board and hand, they combine into one **golden** version in your **hand** ([WIKI]).
  - Since 19.6 (Feb 2021), when several minions are summoned at once, all summons finish before any triple forms ([patch 19.6](https://hearthstone.wiki.gg/wiki/Patch_19.6.0.74257)).
  - Tokens have golden versions, so token triples can form ([WIKI]).
  - Timewarped cards triple only with other Timewarped cards ([P34.2]).
  - A few cards triple from 2 copies, e.g. First Mate Pip (24.2).
- **Stats:**
  - The golden minion has double base stats and keeps every buff and debuff from the three copies ([WIKI]).
  - It always has at least its base golden stats. Attack and health are checked separately, and a net negative is ignored ([GOLDEN]).
  - Example: three 1/1-debuffed 3/3s make a 6/6.
- **Golden text:** a golden minion usually doubles the numbers in its text (+1/+1 becomes +2/+2) or triggers twice. Golden Spellcraft minions give golden spells with double effect ([Spellcraft](https://hearthstone.wiki.gg/wiki/Spellcraft)). The exact rule is per card: golden text is written separately. Some goldens differ in other ways ([WIKI]: "sometimes have stronger abilities").
- **Triple Reward:** playing the golden card adds a **Triple Reward** spell to hand. It Discovers a minion from the **next Tavern Tier**, or Tier 6 if you are at 6 ([WIKI]; launch article https://hearthstone.blizzard.com/en-us/news/23156373).
  - Whether the reward uses your tier when the spell is cast or when the triple formed: UNVERIFIED. Community consensus is your tier at cast.
  - Whether it reaches Tier 7 in Tier 7 lobbies: UNVERIFIED.
- **Other ways to get goldens:**
  - Golden Touch (Tavern spell).
  - Lockboxes, which hold golden minions (Season 14).
  - Hero powers and trinkets that make minions golden.

## 10. Discover

- **Choice:** Discover offers a choice, normally 1 of 3 ([KW]).
- **Pool:** in Battlegrounds the options come from the lobby's minion pool, and the chosen minion is removed from it ([WIKI]). A bug fix for Ethereal Evidence "ignoring tribe bans" (25.0) confirms Discovers normally respect lobby tribes; see [patch-history.md](patch-history.md).
- **Tier:** set by the effect ("from Tier X", "of your Tier or lower", "next Tier"). Primalfin Lookout and Nat Pagle can't Discover or generate minions above your Tavern Tier, and Primalfin can't Discover itself ([WIKI]).
- **Unknowns:**
  - Whether the 3 options are always distinct cards: UNVERIFIED (believed yes).
  - Whether unchosen options go back to the pool: UNVERIFIED (believed yes).
- **Discover-like systems with their own rules:** Dark Gifts (§15.1), Trinket offers (4 options), Quest offers (3 pairs).

## 11. Combat

Combat is automatic. Neither player makes any decisions. **Boards are copied into combat.** Afterwards your Recruit-Phase board returns as it was: combat tokens disappear, and only effects marked "permanently" (or that change the recruit board directly) carry over ([WIKI]: "Boards return to their starting state after combat … permanent Recruit Phase enchantments remain").

### 11.1 Who attacks first

- The player with **more minions** attacks first. A tie is decided at random ([WIKI]).
- SIM: this is measured on the boards entering combat, before Start of Combat effects.
  - The simulator recomputes it after Start of Combat only if delayed summons happened.
  - Illidan's hero power forces his side to start.
  - Real-game behaviour beyond the basic rule is UNVERIFIED.

### 11.2 Start of Combat

Start of Combat resolves in fixed phases, in this order (SIM, `start-of-combat/start-of-combat.ts`; the comments cite designer Mitchell Loewen and say the order changed in 30.6, Oct 2024):
1. Quest rewards
2. Anomalies
3. Trinkets
4. "Pre-combat" hero powers (e.g. The Lich King)
5. Illidan's hero power. His left- and right-most minions attack; the source is https://x.com/LoewenMitchell/status/1737588920139825335.
6. All other Start of Combat hero powers
7. Secrets
8. Minions: first Start of Combat effects that trigger from hand, then those on the board.

Details:
- **Minions phase (SIM):** a random player resolves **all** of their Start of Combat minions left to right, then the other player does. A Nov 2025 comment, citing a replay, says they do not alternate.
- **Hero power phases (SIM):** player order within a phase is random.
- **Snapshot (SIM):** Start of Combat minion effects use the board as it was before the hero power phases.
- **Old rule:** before this phased order, hero power order was a coin flip. Designer Dominic Calkosz explained the phases as protecting planned positioning: https://twitter.com/DCalkosz/status/1488361384320528388.

### 11.3 The attack loop

- **Alternation:** the two sides take turns making **one attack each**, starting with the first attacker ([WIKI]).
- **Choosing the attacker:** on each side, the attacker is the **left-most minion that hasn't attacked in the current cycle** and can attack ([WIKI]: "left to right, repeating"; SIM `getAttackingEntity`).
  - Minions with **0 Attack** are skipped ([WIKI]).
  - Once every minion on a side has attacked, the cycle resets and starts again at the left.
- **Left-of-pointer rule (SIM):** when a minion attacks, every minion to its **left** is flagged as having attacked. A minion summoned to the left of the current attacker waits for the next cycle.
- **Summons replacing the dead (SIM):** a minion summoned where a dead minion stood takes the "has attacked" status of the minion to its **right**.
  - So if a minion attacks and dies, its Deathrattle tokens usually attack **next**, before the minion that was originally next. The guides agree ("a summoned minion will then become the next in line to attack").
  - If the dead minion had not yet attacked (it died defending), its tokens likewise join the queue at its position.
- **Windfury:** the minion makes 2 attacks in a row, picking a new target for each. It stops if it dies after the first (SIM).
- **"Attacks immediately":** a minion that gets this (some tokens, Avenge or "after" effects, e.g. P-0UL-TR-0N, Yo-Ho-Ogre) jumps the queue and attacks next. The normal order resumes after (SIM).
- **Stalemate:** if neither side has a minion with Attack above 0, combat ends as a draw ([WIKI]; SIM).
- **Runaway combats:** if combat runs absurdly long, the client ends it. Blizzard has also capped specific loops: 30.0.2 destroys Adaptive Amalgam and Immortal Prelate after 30 consecutive loops ([forum](https://us.forums.blizzard.com/en/hearthstone/t/3002-hotfix-patch/132227)). The simulator gives up after 400 attacks (SIM). The general client limit is UNVERIFIED.

### 11.4 Targeting

- **Random target:** an attacker picks a random living enemy minion. If the enemy has any **Taunt** minions, it picks at random among those ([WIKI]).
- **Stealth:** Stealthed minions can't be chosen until they attack ([KW]).
- **Card exceptions:** some minions override targeting, e.g. Zapp Slywick and Merciless Mammoth attack the lowest-Attack enemy (SIM `getDefendingEntity`).
- **Heroes can't be attacked.** Combat is minion against minion. Hero damage comes only after combat (§12) or from specific effects.

### 11.5 Resolving one attack

The order below comes from SIM `doFullAttack`:
1. "When attacked" effects of the defender.
2. "Whenever this attacks" effects of the attacker, including **Rally**.
3. **Damage exchange.** Attacker and defender deal damage equal to their Attack to each other **at the same time**. In standard Hearthstone, the attacker's damage triggers resolve before the defender's ([Combat](https://hearthstone.wiki.gg/wiki/Combat)).
   - **Divine Shield** absorbs one instance of damage completely.
   - **Venomous** destroys the first minion it damages each combat.
   - **Cleave**-style effects ("Also damages the enemies next to whomever this attacks") hit the target and its neighbours at the same time.
4. "After this attacks" effects of minions (e.g. Overkill-type "after this attacks and kills a minion, deal the excess to an adjacent enemy", Wildfire Elemental).
5. **Death phase** (§11.6).
6. "After attack" effects of trinkets.

### 11.6 Deaths

- **When minions die:** a minion dies when its health is 0 or less. Deaths are checked after each damage event, and all minions at 0 die together (SIM `processMinionDeath`).
- **Death order** (SIM `deathrattle-orchestration.ts`, quoting Mitchell Loewen):
  1. "After a minion kills"-type triggers, then "whenever a minion dies" triggers.
  2. Dying minions resolve **one at a time, left to right**. Loewen's wording is summoning order, "which in most cases would be left to right" (https://x.com/LoewenMitchell/status/1750792974383173676).
  3. For each dying minion, in order:
     - its own (natural) Deathrattle;
     - then Deathrattles granted by enchantments;
     - then every friendly **Avenge** counter advances by 1, triggering if it reaches its number.
     - Then the next dying minion.
  4. "After a friendly minion dies" effects.
  5. **Reborn** triggers only after **all** Deathrattles and Avenges are done.
  6. Effects that trigger on Reborn.
  7. New deaths caused by any of this start another pass.
- **Conflicting wiki note:** the wiki's Avenge Secret page says that in standard Hearthstone, Avenge checks when the death resolves, before Deathrattles. That is the constructed Secret, not the Battlegrounds keyword. For the Battlegrounds keyword, the designer-quoted order above (Deathrattle first, then Avenge progress) is the better source.
- **Both sides losing minions at once:** which side resolves first is UNVERIFIED. The simulator picks at random. Standard Hearthstone uses play order ([Deathrattle](https://hearthstone.wiki.gg/wiki/Deathrattle)).

### 11.7 Summoning in combat

- **Position:** Deathrattle and Reborn summons appear **at the dead minion's position**. Other summons appear next to their source, usually to the right (SIM `spawns.ts`; [WIKI]: newly summoned minions join the order).
- **Full board:** the limit is **7 minions**. A summon that doesn't fit is lost. A few effects explicitly wait for space ("summon when space"), and the simulator models them (SIM `summon-when-space.ts`).
  - Player complaint about Start of Combat summons failing when Deathrattles have already filled the board: https://us.forums.blizzard.com/en/hearthstone/t/can-we-get-some-uniform-behavior-in-bgs/133904
- **Magnetic** can't be used in combat. It is a Recruit-Phase action.

### 11.8 Reborn specifics

- **What returns:** the minion comes back as a **fresh copy of its card with 1 Health**. Buffs (enchantments) are lost. Golden status is kept, because the card is the golden card ([Reborn](https://hearthstone.wiki.gg/wiki/Reborn); SIM respawns the card ID).
- **Exceptions:** some cards return with full stats, e.g. Sinrunner Blanchy (SIM).
- **Once per combat:** the returned copy has no Reborn. The keyword is restored next combat because the recruit board resets.

### 11.9 End of combat, ties and damage

- **End:** combat ends when one or both boards are empty ([WIKI]).
- **Tie:** if both boards are empty, or only 0-Attack minions remain, nobody takes damage ([WIKI]).
- **Win:** the winner deals damage to the loser (§12).

## 12. Hero damage, damage cap, armor and elimination

- **Formula:** the winner's damage is their **Tavern Tier + the total tiers of their surviving minions** ([WIKI]).
  - Tokens count as Tier 1 ([WIKI]); the simulator uses each card's own tier.
  - Golden minions count their normal tier (SIM).
  - Example: Tier 5 with three surviving Tier 6 minions deals 5 + 18 = 23.
- **Damage cap (Solo)** since 31.2 (Dec 2024), "to allow games to progress more evenly, without big bursts of damage in the early game" ([S9]):
  - turns 1–3: **5**;
  - turns 4–7: **10**;
  - turn 8 onward: **15**.
  - The cap is removed once you are in the **Top 4**.
  - Duos was excluded from this change. The Duos cap rule is UNVERIFIED.
  - I found no later change, but its continuation into 2026 is UNVERIFIED.
- **Armor:** absorbs damage first; then health drops (§2).
- **Elimination:** a hero at 0 health is out.
  - In the 2021 15-cap rule, deaths were only checked at the start of each Recruit Phase ([21.2 notes](https://hearthstone.blizzard.com/en-us/news/23712592/21-2-patch-notes)). Placement among players eliminated in the same round is UNVERIFIED.
  - Final placement is 1st to 8th.

## 13. Keywords and timing words

The full glossary, with rules text and two-row ideas, is in [keywords.md](keywords.md).

**Current keywords:**
- Taunt, Divine Shield, Windfury, Reborn, Venomous, Stealth, Magnetic.
- Battlecry, Deathrattle, Avenge (X), Rally, Start of Combat.
- Spellcraft, Choose One, Discover, Activate.
- "At the end of your turn" / End of Turn.
- Blood Gem, Bonus Keyword.
- Tribe mechanics: Deity, Lockbox, Fishbait, Fodder, Chromadrake.

**Retired:**
- Poisonous (replaced by Venomous in 26.2).
- Mega-Windfury (removed 26.2).
- Overkill and Frenzy (no minions in the current pool, per [content-library.md](content-library.md)).

**Durations** (from card wording; the exact engine semantics are INFERRED):

| Wording | Lasts |
|---|---|
| "this combat" | Until the combat ends. Combat stats are lost anyway when the board resets. |
| "permanently" | A combat effect that also applies to the minion on your recruit board. The usual way combat scaling survives. |
| "this game" | A player-level modifier that also affects future cards, e.g. "Give minions in the Tavern +2/+2 this game", or tribe-wide stat counters. Shown on the hero or the cards. |
| "this turn" / "until next turn" | Ends at the end of the Recruit Phase, or at the start of the next one. Spellcraft spells leave your hand at the end of your turn ([Spellcraft](https://hearthstone.wiki.gg/wiki/Spellcraft)). |
| Tavern-wide buffs | Apply to minions currently in the shop and/or future shop minions ("in the Tavern … this game"). Elementals, Demons and spells use them. |

## 14. Tribe identities (current pool)

These summaries come from card text in [content-library.md](content-library.md) and the patch notes. The numbers are examples, not rules.

| Tribe | Main mechanics |
|---|---|
| Beast | Deathrattle summons. Beetle tokens and Beetle buffs. **Fishbait** (Season 14): a Tavern card replaced by a Fishbait that your left-most Beast attacks during the Recruit Phase, with a reward for the minion that "takes the bait" ([S14]; Lurking Lionfish text). |
| Demon | Spending hero health. Consuming Tavern minions for their stats. **Fodder** tokens added to your pool for Demons to consume (Season 13). |
| Dragon | Rally. Start of Combat. Keeping combat stats. **Chromadrakes** (5 colours; removed from the Tavern pool in 36.2, now only generated by effects) ([P36.2]). |
| Elemental | Buffing minions in the Tavern. Playing many Elementals. Refresh-based effects. |
| Mech | Magnetic, Divine Shield, Deathrattle. "Volumizer" magnetics. |
| Murloc | Battlecries (triggering them extra times), buffing cards in hand. |
| Pirate | Gold and gold-spent counters. Tavern Coins. Bounties (Season 11). **Lockbox** (Season 14): holds a golden minion that unlocks on a later turn; getting another Lockbox opens it sooner ([S14]; Bilgewater Breakout text). |
| Quilboar | **Blood Gems**: a spell giving +1/+1 by default, which Quilboar effects improve. Rally. |
| Undead | Reborn. Avenge. Attack buffs that last the whole game. |
| Naga | **Spellcraft**. Rotated out since 22 Sep 2026. |
| Aberration | **Discard** as a cost or trigger. **Deity**, rules after 36.6.3: one Deity per game, C'Thun or Y'Shaarj at random. Each friendly Aberration death in a combat advances it; after **4** deaths (was 3) the Deity joins that combat. Deities are Tier 1 (were Tier 3). In combat, C'Thun splits its stats among your other minions, and Y'Shaarj's Deathrattle resummons the first 2 Aberrations that died ([ABR], [P36.6.3]). |

## 15. Seasonal and extra systems

Status as of 36.6.3. **Active** means in the live game.

| System | Status | Summary |
|---|---|---|
| Trinkets | **Active** (Seasons 8, 10, 13, 14) | Buy one of 4 offered trinkets. **Lesser on turn 6, Greater on turn 9.** They last the whole game. Base cost 0–6 gold, changed by synergy. Offers are weighted by hero, lobby tribes and warband ([30.2 notes](https://hearthstone.blizzard.com/en-us/news/24122902/30-2-patch-notes), [S14]). |
| Dark Gifts | **Active** (Season 14) | From turn 3, pay 3 gold to Discover 1 of 3 minions, each with a unique Dark Gift. Once per turn, at most 3 per game. Offers improve each turn. 43 gifts ([P36.2], [S14]). |
| Activate | **Active** (Season 14) | Pay the listed gold in the Recruit Phase to use an ability, once per turn, e.g. "Activate (1): Give another minion +3/+3" ([P36.2]; card data). |
| Quests | Inactive (24.2, 28.6, 33.2) | Turn 4: choose 1 of 3 Quest–Reward pairs. The quest's requirement scales with the reward's strength and your hero's armor. |
| Anomalies | Not confirmed active in Season 14 (UNVERIFIED) | One random lobby-wide rule change per game. They have repeatedly returned mid-season (27.2, 31.6, 32.4.2, 33.6.2, 34.6, 35.6). Since 33.6.2 an Anomaly won't repeat within 3 of your games. A 36.2 bug fix mentions the "Greater Pouches" Anomaly ([P36.2]). |
| Buddies | Inactive (22.2, 25.6, 29.6, 33.6) | A hero-specific minion bought with a Buddy Meter or Buddy Button. Some trinkets still grant Buddies ([P36.2] bug fix). |
| Timewarped Tavern | Inactive (Season 12 only) | A special shop on turns 6 and 9 with its own currency, Chronum ([P34.2]). |
| Tier 7 | Conditional | Only via the Secrets of Norgannon Anomaly, Thorim's hero power (60 gold spent since 34.2), or specific rewards and trinkets ([27.2 notes](https://hearthstone.blizzard.com/en-us/news/23987537/27-2-patch-notes), [P34.2]). Tier 7 has 5 copies per minion. |
| Darkmoon Prizes | Retired (2020–21) | Discover a free prize every 4 turns. |
| Bounties | Pirate lobbies (Season 11) | Current status UNVERIFIED. |

### 15.1 Dark Gifts in more detail

- Some Dark Gifts first appear on later turns. 36.6.3 moved Spell Siphon from turn 4 to 5 and Transcendence from turn 7 to 8 ([P36.6.3]).
- Tras'tath's hero power lets you reserve a Tier 5 minion with a Dark Gift ([S14]).
- How a gift attaches to its minion, and whether it survives tripling: UNVERIFIED.

### 15.2 Hero powers

There are about 120 heroes ([content-library.md](content-library.md)). They fall into these broad kinds (INFERRED from hero data and patch notes):
- **Active, paid:** 0–3 gold typically, once per turn (Sylvanas and Scabbs 3 gold, Tess 2 gold since 34.2).
- **Passive.**
- **Start of Combat**, resolved in the phased order of §11.2.
- **End of turn or start of turn** triggers.
- **Counter or threshold:** "after you buy N cards", e.g. Edwin, Saurfang, Ragnaros in [P36.2].
- **Gold-spent milestones**, e.g. Thorim at 60 gold.
- **Once per game.**
- **Every N turns**, e.g. Rakanishu, every 3 turns since 36.2.
- **Mini-economies:** the StarCraft heroes (31.6) unlock and upgrade buildings.
- **Second hero powers:** offered by the Minor Timewarp in Season 12.

## 16. Duos

Sources: [DUOS] and [29.2 notes](https://hearthstone.blizzard.com/en-us/news/24077473/29-2-patch-notes).

- **Teams:** 4 teams of 2. Each player has their own board, tier and gold.
- **Health:** shared, starting at 30. Team armor is both heroes' armor added together.
- **Passing:** send cards to your teammate through the **Portal** for 1 gold each. Some cards make passes free or pass extra copies.
- **Teammate's board:** you can view it, and a marker shows when a card would complete a triple for them.
- **Upgrades:** Tiers 4–6 cost 2 more than Solo.
- **Combat:**
  - One warband fights at a time. When it is wiped, the teammate's warband enters and continues against whatever remains.
  - If the first warband beats both enemy warbands, the teammate's warband is summoned to add damage.
  - SIM: only enough of the teammate's minions to fill the board to 7 count toward damage.
  - **Who goes first:** since 30.0, each combat has a 75% chance to swap which teammate fights first. The same teammate never goes first more than 3 times in a row.
- **Exclusive content:** Duos-only heroes, minions, spells and trinkets. Some heroes are excluded (Murloc Holmes "leads to frustrating gameplay with the team system").
- **Rating:** separate rating and leaderboard. Abandoning your partner before Top 2 costs MMR, unless you queued with a friend.
- **Damage cap:** different from Solo (§12). The details are UNVERIFIED.

## 17. Matchmaking, placement and rating

- **Opponents:**
  - While all 8 players are alive, you face every opponent once before facing anyone again.
  - After someone is eliminated, you won't face the same opponent within 3 rounds (was 2) ([P33.2]).
  - The original 2020 rule was no repeat opponent, or Kel'Thuzad, within 3 rounds unless only 2 players remain ([WIKI]; 16.2).
- **Seeing your next opponent:** the scoreboard shows the next opponent during the Recruit Phase (UNVERIFIED wording; it is standard UI).
- **Rating:**
  - Finishing **1st–4th counts as a win** and raises MMR ([WIKI]).
  - Visible rating has floors every 500 points from 2,000 to 6,000. Players below 6,500 get a progression bonus ([18.4 notes](https://hearthstone.blizzard.com/en-gb/news/23523062/184-patch-notes)).
  - Ratings reset each season ([P36.2]).
  - A hidden MMR drives matchmaking: https://playhearthstone.com/en-us/news/23239989
- **Parties:**
  - Matchmaking uses the party's highest rating.
  - Small parties are disabled at very high rating (18.6; see [patch-history.md](patch-history.md)).

## 18. Engineering-relevant facts

These are details a rules engine has to decide.

- **Combat is fully determined by the two boards** (plus heroes, trinkets and hand for Start of Combat), so it can be simulated. That is why third-party odds tools exist (SIM).
- **Randomness enters at a few points:**
  - who attacks first on a tie;
  - each target choice;
  - random effect targets;
  - which player resolves first within a Start of Combat phase;
  - possibly which side's deaths resolve first.
- **Stat overflow:** 21.8 fixed a bug where a minion's health got so large it was deleted from the warband. 36.2 condenses numbers with more than 4 digits ([P36.2]).
- **Infinite loops:** Blizzard caps specific loops (30 iterations in 30.0.2; stat-loop fixes in 33.6.2; a failed fix in [35.0.1](https://us.forums.blizzard.com/en/hearthstone/t/3501-hotfix-patch/158123/1)).
- **Timing ambiguities players notice:** Start of Combat summons blocked by full boards, and inconsistent trigger order ([forum](https://us.forums.blizzard.com/en/hearthstone/t/can-we-get-some-uniform-behavior-in-bgs/133904)). The simulator code is full of comments saying "not sure about this ordering", which shows how much of the order is undocumented.

## 19. Open questions (UNVERIFIED)

1. What Battlegrounds changes 37.0.0 made (Oct 2026).
2. Whether exactly 5 tribes are still used per lobby, and whether the Beasts/Dragons separation still applies.
3. Whether the Solo damage cap (5/10/15, removed at Top 4) is unchanged in 2026, and what the Duos cap is.
4. The current Duos upgrade costs (5/7/10/13/13 is inferred).
5. Pool details: whether shop minions are withheld from the pool, how many copies a sold golden returns, whether eliminated players' minions return, and whether Discover options are distinct.
6. Which player's deaths resolve first when both sides lose minions in the same attack.
7. How the Triple Reward handles Tier 7.
8. Whether Anomalies are active in Season 14 after 36.6.
9. The exact turn limit and client combat timeout.
