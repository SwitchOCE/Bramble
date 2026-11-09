# Bramble rulebook

**v0.4 draft, 2 Nov 2026 (HSBG and Galaxy mechanics are now examples, not Bramble mechanics; slot effects added, N9), baseline HSBG patch 36.6.3**

This is the full rule set for Bramble, written so the owner can find every place Bramble differs from Hearthstone Battlegrounds (HSBG) and so an engine can be built from it. HSBG is the default for systems (economy, shop, pool, turn flow, combat order) wherever the owner hasn't decided otherwise. Mechanics and keywords from HSBG and Galaxy appear only as [EXAMPLE]s of what the rules must handle. Bramble designs its own (N9). Every difference is tagged. A one-page list of all differences and open items is in [rulebook-deltas.md](rulebook-deltas.md).

No content is defined here: no units, tribes, cards or mechanics. Examples use placeholder names, or name an HSBG or Galaxy mechanic to show which rule it tests (chapter 11).

## Legend

Every numbered rule carries exactly one tag:

| Tag | Meaning |
|---|---|
| **[BG]** | Taken from Battlegrounds unchanged. |
| **[BRAMBLE]** | An owner decision that differs from Battlegrounds. The owner note is cited. |
| **[PROPOSED]** | A gap that Bramble's differences create, which the owner hasn't decided. It is filled with a proposed default, with the reason and any Once Upon a Galaxy precedent. Needs an owner decision. |
| **[OPEN]** | Genuinely undecided, with no default. |
| **[EXAMPLE]** | A mechanic from HSBG or Galaxy, kept to show what the rules must handle. Not a Bramble mechanic (N9). Example entries keep their numbers so other files can cite them. |

- **"(uncertain in HSBG — see rules.md §x)"** after a [BG] rule means the HSBG research marks that behaviour as UNVERIFIED, simulator-derived (SIM) or inferred. Bramble takes it as written until someone checks or changes it.
- **"(not in rules.md)"** after a [BG] rule means the rule is standard HSBG behaviour that the research file doesn't cover. It is general knowledge and worth confirming.
- Lines starting **Note:** are explanation, not rules, and carry no tag.
- Rules are numbered `section.subsection.rule`, e.g. 9.4.5. Cite them by number.

**Sources cited**

| Key | File |
|---|---|
| N1 | [owner-notes/2026-10-27-battlegrounds-direction.md](owner-notes/2026-10-27-battlegrounds-direction.md) |
| N2 | [owner-notes/2026-10-27b-board-answers-and-research.md](owner-notes/2026-10-27b-board-answers-and-research.md) |
| N3 | [owner-notes/2026-10-27c-packing-tokens-rows.md](owner-notes/2026-10-27c-packing-tokens-rows.md) |
| N4 | [owner-notes/2026-10-27d-combat-shape-decisions.md](owner-notes/2026-10-27d-combat-shape-decisions.md) |
| N5 | [owner-notes/2026-10-27e-economy-decisions.md](owner-notes/2026-10-27e-economy-decisions.md) |
| N6 | [owner-notes/2026-10-27f-power-budget-decisions.md](owner-notes/2026-10-27f-power-budget-decisions.md) |
| N7 | [owner-notes/2026-11-02-pre-development-design-pass.md](owner-notes/2026-11-02-pre-development-design-pass.md) |
| N8 | [owner-notes/2026-11-02d-refresh-schedule-and-free-refreshes.md](owner-notes/2026-11-02d-refresh-schedule-and-free-refreshes.md) |
| N9 | [owner-notes/2026-11-02e-mechanics-are-examples.md](owner-notes/2026-11-02e-mechanics-are-examples.md) |
| N10 | [owner-notes/2026-11-02f-new-effects-and-goldfish-designers.md](owner-notes/2026-11-02f-new-effects-and-goldfish-designers.md) (the owner's answers on the v0.4 rewrite) |
| BLO | [board-layout-options.md](board-layout-options.md), decision box (Option A, fixed slots, 27 Oct 2026) |
| rules.md | [../research/battlegrounds/rules.md](../research/battlegrounds/rules.md) (HSBG at 36.6.3) |
| keywords.md | [../research/battlegrounds/keywords.md](../research/battlegrounds/keywords.md) |
| patch-history.md | [../research/battlegrounds/patch-history.md](../research/battlegrounds/patch-history.md) |
| Galaxy | [../research/galaxy/rules.md](../research/galaxy/rules.md) and [design-notes.md](../research/galaxy/design-notes.md) |

Owner notes win over this rulebook if they disagree.

**Words.** This rulebook says *unit* for HSBG's *minion*, *shop* for the *Tavern*, and *tier* for *Tavern Tier*.

## Contents

1. Game overview and global rules
2. Lobby, heroes and matchmaking
3. Turn structure
4. Economy
5. The shared pool, tribes and types
6. Shop offers and Discover
7. Hand, playing units, triples and golden units
8. The board
9. Combat
10. Hero damage and elimination
11. Example mechanics
12. Durations and effect scopes
13. Systems outside the v0 core
14. Glossary
- Appendix A. Tunable parameters

---

## 1. Game overview and global rules

### 1.1 Overview

**1.1.1** [BG] A game has 8 players. Each round, every player builds a board of units during a Recruit Phase, then every board fights one opponent's board automatically in a Combat Phase. The loser of each fight takes damage to their hero. Players at 0 health are eliminated.

**1.1.2** [BG] The board is the fight's HP. Players have no health inside a fight, and heroes can't be attacked in combat. A fight is won by the side with units left. Hero health changes only after combat (chapter 10) or through specific effects. The owner confirmed this as a deliberate break from the earlier Autobattler project (N2 §2).

**1.1.3** [BG] The last player left places 1st. Other players place by elimination order, 8th to 2nd. Placing 1st to 4th counts as a win for rating (rules.md §17).

### 1.2 Global rules

**1.2.1** [BG] When card text contradicts this rulebook, the card text wins (not in rules.md; standard Hearthstone convention).

**1.2.2** [BG] Combat involves no player decisions. Where a rule says "random", the choice is uniform among the valid options unless the rule says otherwise (uncertain in HSBG — see rules.md §18).

**1.2.3** [PROPOSED] **Reading order.** The board's slots have one fixed order: F1, F2, F3, F4, B1, B2, B3 (chapter 8). Wherever HSBG resolves things "left to right" across a board (Start of Combat, deaths, End of Turn, triggers of the same kind), Bramble uses reading order. *Why:* it is the attack order the owner chose (9.4.2), so players learn one order for everything. *Galaxy:* numbers its slots 1–5 left to right, front to back, and uses that order for attacks.

**1.2.4** [PROPOSED] **Numbers.** Gold, Attack and Health are integers. Attack is never below 0. Stats are clamped at a hard maximum of 1,000,000,000 so arithmetic can't overflow, and numbers above 4 digits are shown condensed (HSBG does this since 36.2). *Why:* HSBG once deleted a unit whose Health grew too large (rules.md §18).

---

## 2. Lobby, heroes and matchmaking

### 2.1 Lobby

**2.1.1** [BG] A lobby has 8 players, playing 1-against-1 fights each round.

**2.1.2** [BG] When an odd number of players is alive, one player fights a **ghost**: a copy of the board and tier of the most recently eliminated player. The ghost is assigned at the start of the Recruit Phase. If a player concedes mid-phase, the ghost uses that player's board instead. Damage dealt to the ghost has no effect (rules.md §1).

**2.1.3** [PROPOSED] **Game length limit.** If a game reaches the end of round 50, it ends. Remaining players are placed by hero health plus armor, highest first; ties are broken at random. *Why:* HSBG has a turn limit but its value is unknown (rules.md §1), and an engine needs one.

**2.1.4** [BRAMBLE] **Asynchronous fights.** Bramble has no turn timer: each player takes their turns at their own pace and fights recorded snapshots of other players' boards, as Galaxy does (N7). Duos and bots stay outside v0.

**2.1.5** [OPEN] How async play reshapes 2.1.1–2.1.3: how many players a game has, how snapshots are chosen and matched, what replaces the ghost, and how a game ends. *Why:* these rules assume a live 8-player lobby (N7).

### 2.2 Heroes

**2.2.1** [BG] Each player chooses one hero from those offered. No hero is offered to two players in the same lobby (rules.md §2).

**2.2.2** [BG] Each player is offered 2 heroes. The hero choice timer is 70 seconds (rules.md §2).

**2.2.3** [OPEN] Whether Bramble offers more hero choices or hero rerolls, and whether any of it is paid. HSBG sells extra choices through its Season Pass, which players criticise as pay-to-win (patch-history.md lesson 8).

**2.2.4** [BG] Heroes whose power depends on a tribe are not offered in lobbies without that tribe (rules.md §2).

**2.2.5** [BG] Heroes start with 30 health. A hero may define a different starting value (rules.md §2).

**2.2.6** [BG] Each hero has a fixed armor value, set per hero for balance. Armor absorbs damage before health and is not restored (rules.md §2).

**2.2.7** [BG] Each hero has a hero power. Kinds include: active powers that cost gold and can be used once per turn; passives; Start of Combat powers; start- or end-of-turn triggers; counters and thresholds; once-per-game powers (rules.md §15.2).

### 2.3 Matchmaking

**2.3.1** [BG] Each round, living players are paired. While all 8 are alive, each player faces every opponent once before facing anyone again (rules.md §17).

**2.3.2** [BG] After the first elimination, a player doesn't face the same opponent within 3 rounds, when the number of players left allows it (rules.md §17).

**2.3.3** [BG] During the Recruit Phase, each player can see who their next opponent is (uncertain in HSBG — see rules.md §17).

---

## 3. Turn structure

### 3.1 Rounds

**3.1.1** [BRAMBLE] Each round (turn) is a Recruit Phase followed by a Combat Phase. Players do not share a clock: each takes their Recruit Phase independently (2.1.4).

**3.1.1a** [BRAMBLE ideation] On cards, **a turn** means one Recruit Phase plus the fight after it. Once-a-turn limits reset before that Recruit Phase begins. A limit that names a fight resets for each fight.

**3.1.2** [BRAMBLE] **No recruit timer.** The Recruit Phase lasts until the player ends it. HSBG gives 60 seconds in round 1, then 15 seconds more each round, up to 120 (rules.md §3). With no timer, the economy has to run out by itself: only the cost of refreshes rises within a turn (4.4), and free and triggered refreshes and gold-spent engines are bounded by content design (content-guardrails.md G1). How many shops a turn sees is tuned by playtesting, and the target will move. With the prices in 4.4, builds will differ, but most long turns should see around 20 shops (N8).

### 3.2 Start of the Recruit Phase

**3.2.1** [PROPOSED] At the start of each Recruit Phase, these steps happen in this order:
1. Gold is set: carried gold plus this turn's income (4.1).
2. From turn 2 on, the current upgrade cost drops by 1 (4.6.3).
3. The refresh counter resets to 0 (4.4.4).
4. The shop refills, or keeps its frozen cards and fills its empty slots; the freeze then ends (4.5).
5. Start-of-turn triggers resolve in reading order (1.2.3).

*Why:* HSBG's exact order isn't documented, and Bramble adds steps 1 and 3. This order lets start-of-turn effects see the new shop and the full gold total.

### 3.3 During the Recruit Phase

**3.3.1** [BG] During the Recruit Phase a player may take these actions in any order and as often as they can pay: buy, sell, refresh, freeze, upgrade, play a unit or spell from hand, move units (8.3), use the hero power, and use activated abilities (rules.md §5.3). Example: HSBG's Activate.

### 3.4 End of the Recruit Phase

**3.4.1** [PROPOSED] When the Recruit Phase ends (timer or player ends turn):
1. End of Turn triggers resolve in reading order (1.2.3).
2. Effects that last "this turn" end.
3. Unfrozen shop cards return to the pool (5.3.2).
4. Unspent gold is kept (4.1.2).
5. The board is copied for combat (9.1.1).

*Why:* HSBG's order is undocumented; the order of End of Turn triggers across units is believed to be left to right (keywords.md §B).

**3.4.2** [BG] Units in hand don't fight and don't count as being on the board (rules.md §5.3).

### 3.5 Combat Phase

**3.5.1** [BG] Each paired player's board fights its opponent's board (chapter 9). After all fights, damage is dealt (chapter 10), eliminations are checked, and the next round starts.

---

## 4. Economy

### 4.1 Gold

**4.1.1** [BG] **Income.** A player gains 3 gold on turn 1, and 1 more each turn, up to 10 a turn from turn 8 on.

| Turn | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8+ |
|---|---|---|---|---|---|---|---|---|
| Income | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |

**4.1.2** [BRAMBLE] **Carry-over.** Unspent gold carries over between turns. At the start of each Recruit Phase, a player's gold is the gold they had left at the end of the last one plus this turn's income. HSBG discards unspent gold (N1 §2.1).

**4.1.3** [BRAMBLE] **No cap, no interest.** There is no limit on how much gold a player can hold, and holding gold earns nothing. HSBG resets gold to at most 10 each turn (N2 §3).

**4.1.4** [PROPOSED] Effects that raise or lower "maximum gold" change the income ceiling in 4.1.1 (10), not a holding cap. *Why:* in HSBG maximum gold is both the refill and the cap; Bramble has no holding cap, so only the income meaning is left.

**4.1.5** [BG] Gold can't go below 0. An action that costs more gold than the player has can't be taken.

**4.1.6** [BG] Other gold comes only from selling (4.3), card effects and hero powers (rules.md §4).

### 4.2 Buying

**4.2.1** [BG] A player can buy any unit in their shop for 3 gold, whatever its tier. The bought unit goes to the player's hand (rules.md §5.3).

**4.2.2** [BG] A player with a full hand can't buy (uncertain in HSBG — see rules.md §5.3).

**4.2.3** [BG] Buying a unit leaves its shop slot empty until the shop next refills.

**4.2.4** [BG] Buying is allowed when the board is full, because the unit goes to hand. A unit can't be played from hand while the board has no empty slot (7.2.2).

**4.2.5** [BG] Tavern spells in the shop are bought for their own listed cost and go to hand (6.1.5).

### 4.3 Origin and selling

**4.3.1** [BRAMBLE] **Origin.** Every unit is either **Bought** or **Created**. A Bought unit was taken from the shop by paying for it. A Created unit came any other way: summoned, generated, copied, transformed into, or given by an effect ("get", "add to your hand"). Tokens are Created. HSBG makes no such distinction for selling (N1 §2.2).

**4.3.2** [BRAMBLE] A unit that an effect takes **from the shared pool** without payment, such as a Discover pick or the Triple Reward, counts as **Created** and sells for 0. It is still a real pool copy and returns to the pool when sold (5.3.4). The rule is that anything the player didn't pay for sells for 0 (N5 §8). *HSBG:* every unit sells for 1.

**4.3.3** [BRAMBLE] **Sell value.** Selling a Bought unit gives 1 gold. Selling a Created unit gives 0 gold. In HSBG every unit sells for 1 (N1 §2.2).

**4.3.4** [BRAMBLE] A golden unit made by a triple sells for 1 gold, even if some or all of its copies were Created (N3, "Selling created units after a triple").

**4.3.5** [BRAMBLE] Any other merge of units makes a Bought unit if at least one of the merged units was Bought. In the owner's words, a created unit that "merges with a real unit" sells for money (N3). Example: HSBG's Magnetic.

**4.3.6** [PROPOSED] Origin stays with the unit when it moves between hand and board, and when an effect transforms it or makes it golden without a triple. A Created unit made golden by an effect stays Created. *Why:* the owner's exception covers tripling and merging, not every upgrade, and tying sell value to the triple keeps the rule easy to read.

**4.3.7** [BG] Only units on the board can be sold, not units in hand. A sold unit leaves its slot, which becomes empty (not in rules.md).

**4.3.8** [BG] Card text can change a unit's sell value (rules.md §5.3).

### 4.4 Refresh

**4.4.1** [BG] **Refresh** replaces every card in the shop with new ones drawn from the pool. The replaced cards return to the pool. Refreshing a frozen shop also unfreezes it (rules.md §5.3; unfreezing not in rules.md).

**4.4.2** [BRAMBLE] **Escalating cost.** A refresh costs 1 gold for the first 15 paid refreshes of a turn. After that its cost rises by 1 gold every 5 paid refreshes, with no cap. HSBG refreshes always cost 1 (N1 §2.3; N8).

**4.4.3** [BRAMBLE] **Steps.** Paid refreshes 1–15 of a turn cost 1, 16–20 cost 2, 21–25 cost 3, 26–30 cost 4, and so on. The first step (after 15) and the step length (5) are tunable parameters (Appendix A). This replaces the 27 October thresholds of 1–10 at 1, 11–20 at 2 and 21+ at 3 (N5 §9; N8).

**4.4.4** [BRAMBLE] The refresh count resets to 0 at the start of each turn (N2 §3).

**4.4.5** [BRAMBLE] **Free refreshes** granted by effects cost no gold and **don't** count toward the thresholds. Only paid refreshes escalate (N5 §10).

**4.4.6** [PROPOSED] A card effect that replaces the shop's cards directly ("refresh the shop") costs nothing and doesn't count toward the thresholds. Only the player's paid Refresh action counts (4.4.5). *Why:* effect-driven rerolls are costed into the card that causes them; counting them would make cards punish the player's own refreshes.

**4.4.7** [BG] There is no limit on the number of refreshes beyond their cost (rules.md §5.3). The owner chose not to cap free refreshes either. Repeatable free-refresh loops are prevented by content design instead (content-guardrails.md G1; N6).

**4.4.8** [BRAMBLE ideation, optional] **Ask for Kin.** When enabled in Settings, pay 2 gold, once a turn, to refresh with at least two units sharing a tribe with your board. Nests count as Birds. The setting is **off by default** and applies to new games. It needs a tribe on your board or a Nest, draws eligible copies using usual tier odds, and fills the rest normally. If fewer than two eligible copies remain, it shows what it can. It counts as a paid refresh for escalating costs; its own price remains 2 and free refreshes are not spent.

### 4.5 Freeze

**4.5.1** [BG] Freezing is free and toggles the shop between frozen and unfrozen, up to 5 times per Recruit Phase (rules.md §5.3).

**4.5.2** [BG] At the start of the next Recruit Phase, a frozen shop keeps its cards and only its empty slots refill. If it already holds as many cards as its size, spells included, it gets no extra units (rules.md §5.2).

**4.5.3** [BG] The freeze ends once the shop has refilled at the start of the turn (not in rules.md).

**4.5.4** [BG] Cards in a frozen shop stay out of the pool (5.3.2).

### 4.6 Tiers and upgrading

**4.6.1** [BG] Shop tiers run from 1 to 6. Each player starts at tier 1. Tier 7 can be reached only through specific effects (rules.md §5.1).

**4.6.2** [BG] **Upgrade costs.** The base cost to upgrade to each tier is:

| Upgrade to | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|
| Base cost | 5 | 7 | 8 | 11 | 11 |

(rules.md §5.1, HSBG Solo since 34.2.) The owner chose to base tiers on HSBG and revisit as needed (N2 §4).

**4.6.3** [BG] At the start of each Recruit Phase from turn 2 on, the current upgrade cost drops by 1, to a minimum of 0. Example: upgrading to tier 2 costs 4 on turn 2 (the 0 minimum is inferred — see rules.md §5.1).

**4.6.4** [BG] After an upgrade, the cost resets to the base cost of the next tier. A player may upgrade more than once in a turn if they can pay.

**4.6.5** [BG] Upgrading doesn't refill the shop. Draws made after the upgrade use the new tier (not in rules.md).

Note: carry-over gold (4.1.2) makes early upgrades easier than in HSBG. The upgrade costs and the per-turn discount stand at HSBG values until playtests or the power budget show they need to change.

---

## 5. The shared pool, tribes and types

### 5.1 The pool

**5.1.1** [BG] Each lobby has one shared pool. All shops and every effect that draws "from the pool" take copies from it (rules.md §6).

**5.1.2** [BG] **Copies per unit.** The pool holds this many copies of each unit (rules.md §6; the owner chose HSBG's pool mechanics, N2 §4):

| Tier | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|
| Copies of each unit | 15 | 15 | 13 | 11 | 9 | 7 | 5 |
| Copies of each Tavern spell | 5 | 7 | 9 | 11 | 9 | 7 | — |

**5.1.3** [BG] The pool holds only units that have at least one of the lobby's tribes, plus neutral units. A unit with several tribes is in the pool if any one of them is in the lobby (rules.md §7).

### 5.2 Tribes and types

**5.2.1** [BRAMBLE] **Type line.** Every unit has a type line of one or more types, in the style of Magic: The Gathering creature types, e.g. "Owl Warrior" or "Squirrel Archer". HSBG units have zero, one or two tribes and nothing else (N1 §5).

**5.2.2** [OPEN] **Which types are tribes.** A tribe is a type that the lobby builder uses to include or exclude units. Undecided: whether tribes are the species words, a separate faction word, or some other subset of types. Fairies and oozes will exist as kinds of creature (N1 §6); how they map to tribes is undecided.

**5.2.3** [PROPOSED] **Type matching.** Card text that names a type ("your Owls") applies to every unit that has that type anywhere on its type line. A unit with the "All" type has every tribe. *Why:* this is the Magic rule the owner pointed to, and it matches HSBG's dual-type and "All"-type units (rules.md §7).

**5.2.4** [BG] **Tribes per lobby.** Each lobby uses a random subset of the tribes in rotation. HSBG uses 5 of 10 (rules.md §7). The owner confirmed the subset rule (N1 §4).

**5.2.5** [BRAMBLE ideation] The playable game draws **five tribes per lobby** from the six in rotation: Hedgerow folk, Fairies, Oozes, Birds, Bog folk and Hunters. Neutral units remain available.

**5.2.6** [BG] The lobby builder applies exclusion rules: pairs of tribes that can't share a lobby, units banned with a tribe, and heroes banned without one (rules.md §7; patch-history.md lesson 5).

**5.2.7** [BG] Units with no tribe (neutral) are always in the pool (rules.md §7).

**5.2.8** [OPEN] Whether to add a TFT-style trait system on top of types. The owner is leaning no (N1 §5). v0 has none.

**5.2.9** [BRAMBLE ideation] **Tribe bonus.** Harvest Supper (tier 3, 3 gold) gives a tribe +1/+1 permanently, once a turn, up to +3/+3 for that tribe. The bonus applies to every unit of that tribe you own: on the board, in hand, inside a Belly, away or waiting to land, and to units you get later. It does not apply to units summoned during a fight. A unit with two tribes gets both bonuses, and aiming Supper at it raises both; becoming golden does not double the tribe bonus. Each tribe's icon shows its current bonus. This is a separate stat layer, not a spell buff on each recipient, so it does not trigger Moss Ooze.

**5.2.10** [BRAMBLE ideation] **Sharing a tribe.** Two units share a tribe if at least one tribe appears on both type lines. Stand Behind Me and Bread from the Back give each eligible unit +2/+2 permanently if it shares a tribe with the target, otherwise +1/+1. The target's front/back position still determines which units receive the spell.

### 5.3 Units leaving and returning to the pool

**5.3.1** [BG] Buying a unit removes its copy from the pool (rules.md §6).

**5.3.2** [BG] Cards shown in a shop are out of the pool while they are shown. They return when the shop is refreshed or when the turn ends unfrozen (uncertain in HSBG — see rules.md §6).

**5.3.3** [BG] Discover options are out of the pool while being shown. The chosen one stays out; the others return (uncertain in HSBG — see rules.md §10).

**5.3.4** [BG] Selling a non-golden Bought unit returns its copy to the pool (rules.md §6).

**5.3.5** [PROPOSED] Selling a golden unit returns one copy to the pool for each of its three copies that came from the pool. Created copies return nothing. *Why:* HSBG's rule is unknown (rules.md §6 marks "returns 3 copies" UNVERIFIED), and Bramble's Created origin means a golden can contain copies the pool never held.

**5.3.6** [BG] Created units never come from the pool and never return to it (inferred in HSBG — see rules.md §6).

**5.3.7** [PROPOSED] A pool unit that leaves a player by any route other than selling (destroyed in the Recruit Phase, consumed, transformed away) also returns its pool copies. *Why:* keeps the pool's copy count conserved, so every unit's copies can always be accounted for.

**5.3.8** [BG] When a player is eliminated, the pool copies of their units, on board and in hand, return to the pool (uncertain in HSBG — see rules.md §6).

---

## 6. Shop offers and Discover

### 6.1 The shop

**6.1.1** [BG] **Shop size.** The shop offers this many cards, one of which is normally a Tavern spell (rules.md §5.2):

| Tier | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| Cards | 4 | 5 | 5 | 6 | 6 | 7 |
| of which units | 3 | 4 | 4 | 5 | 5 | 6 |

**6.1.1a** [BRAMBLE ideation] Tier 1 offers **4 units and 1 spell**, replacing its column above. Other tiers are unchanged.

**6.1.2** [BG] Shop units are drawn from units of the player's tier or lower, and units with fewer copies left appear less often (exact weighting uncertain in HSBG — see rules.md §5.2).

**6.1.3** [PROPOSED] **Draw algorithm.** Each unit offer is one copy drawn uniformly at random from all copies left in the pool whose tier is at or below the player's tier, so each unit's chance is proportional to its remaining copies. The drawn copy leaves the pool at once. *Why:* the simplest model that fits "copies left" in rules.md §5.2. The draw is one instance of the owner's flexible "pick N from a pool" building block, so it can be swapped later (N1 §7). *Galaxy:* weights draws towards higher rarity instead.

**6.1.3a** [BRAMBLE ideation] The playable ideation game chooses a tier first, then a remaining copy within that tier. Weights by shop tier (T1 through current): **100; 50/50; 20/30/50; 10/15/25/50; 5/10/15/25/45; 5/5/10/15/25/40**. Empty tiers are skipped and the remaining weights renormalize. Unit and spell slots use these odds on separate random streams. Frozen stock keeps its tier. Hiring Fair costs **6 gold** to Discover a tier-6 unit; it uses the same tier-6 pool and three distinct options as a tier-5+ Triple Reward. Rolls advance normally; repeats are possible, not fixed offers.

**6.1.4** [PROPOSED] If the pool has no eligible copies left for a shop slot, that slot stays empty. *Why:* an engine needs an answer; HSBG's isn't documented.

**6.1.5** [BG] **Tavern spells.** One shop slot per refill offers a spell of the player's tier or lower. Spells have their own costs, go to hand, are cast in the Recruit Phase, are single use and can't triple. A frozen spell stays frozen (rules.md §8).

### 6.2 Discover

**6.2.1** [BG] **Discover** offers a choice of 3 units, and the player takes 1 to hand. Options come from the lobby's pool, respect its tribes, and use the tier the effect names ("from tier X", "of your tier or lower", "next tier") (rules.md §10).

**6.2.2** [BG] The 3 options are different units (uncertain in HSBG — see rules.md §10).

**6.2.3** [PROPOSED] If fewer than 3 different eligible units have copies left, Discover offers as many as there are. With none, the effect does nothing. *Why:* engine edge case; not documented in HSBG.

**6.2.4** [BRAMBLE ideation] Hiring Fair Discovers a tier 6 unit. If at least five units on your board share a tribe, one of its three options is of that tribe when an eligible unit is available in the pool. Other options remain varied.

---

## 7. Hand, playing units, triples and golden units

### 7.1 Hand

**7.1.1** [BG] The hand holds up to 10 cards (uncertain in HSBG — see rules.md §5.3).

**7.1.2** [BG] A card gained while the hand is full is lost, unless the effect says it waits for space (uncertain in HSBG — see rules.md §5.3; keywords.md §C). Example: HSBG's Spellcraft.

### 7.2 Playing a unit

**7.2.1** [BRAMBLE] Playing a unit from hand puts it into **any empty slot the player chooses**, front or back. In HSBG the player picks a position in a single packed row (BLO; N3).

**7.2.2** [BG] A unit can't be played when the board has no empty slot, i.e. 7 units are on it. A unit that merges into another unit instead of taking a slot is the exception (rules.md §5.3). Example: HSBG's Magnetic (11.4.1).

**7.2.3** [BG] A played unit is placed first, then its "when played" effects resolve. Example: HSBG's Battlecry.

Note: the direction summary's open question 5 assumed bought units go straight to the board. This rulebook keeps HSBG's hand (4.2.1), because "when played" effects, merges, Discover and triples all depend on it.

### 7.3 Triples

**7.3.1** [BG] When a player holds 3 copies of the same non-golden unit across board and hand, they combine at once into one golden copy in hand. Copies that were on the board leave their slots, which become empty (rules.md §9).

**7.3.2** [BG] Triples form only in the Recruit Phase. When several units are summoned together, all of them finish arriving before any triple forms (rules.md §9, patch 19.6).

**7.3.3** [BG] Created copies count toward triples (rules.md §9).

**7.3.4** [BG] **Golden stats.** The golden unit has double the base stats and keeps every buff and debuff from the three copies. Attack and Health are each at least the golden base value (rules.md §9).

**7.3.5** [BRAMBLE] **Golden text.** A golden unit doubles every number in its effect (stat gains, damage, summons, gold), but thresholds and counters keep their normal value: a counter that fires after 3 deaths still fires after 3 (N6). Example: HSBG's Avenge (3) stays 3. *HSBG:* golden text is written per card. It usually doubles numbers or triggers twice (rules.md §9).

**7.3.6** [BG] **Triple Reward.** Playing a golden unit made by a triple adds a Triple Reward spell to hand: Discover a unit from the tier above the player's current tier, or tier 6 if the player is at 6 (tier used at cast is uncertain in HSBG — see rules.md §9).

**7.3.7** [PROPOSED] If a triple forms while the hand is full and all three copies were on the board, the golden goes into the vacated slot that comes first in reading order. *Why:* engine edge case; with Created copies counting, three board copies and a full hand is reachable.

---

## 8. The board

### 8.1 Layout

**8.1.1** [BRAMBLE] The board has **7 slots in two rows**: the front row F1–F4 and the back row B1–B3. At most 7 units are on the board. HSBG has 7 positions in one row (N1 §3; N2 §1).

**8.1.2** [BRAMBLE] The row caps of 4 front and 3 back are the **working cap**. The owner may change them after experiments (N2 §1; N3).

**8.1.3** [BRAMBLE] **Stagger.** The rows are offset by half a slot, like bricks. Each back slot sits between two front slots (N1 §3; N2 §1).

```
            FRONT ROW  (attacks first, is attacked first)
   ┌────┐     ┌────┐     ┌────┐     ┌────┐
   │ F1 │     │ F2 │     │ F3 │     │ F4 │
   └────┘     └────┘     └────┘     └────┘
         ╲   ╱      ╲   ╱      ╲   ╱
         ┌────┐     ┌────┐     ┌────┐
         │ B1 │     │ B2 │     │ B3 │
         └────┘     └────┘     └────┘
            BACK ROW  (protected while any front unit lives)

   x position:  F1=0  B1=0.5  F2=1  B2=1.5  F3=2  B3=2.5  F4=3
```

The diagonal lines are the "in front of / behind" links.

### 8.2 Relations between slots

**8.2.1** [BRAMBLE] **In front of and behind.** A back slot's diagonal neighbours in the front row are **in front of** it; a front slot's diagonal neighbours in the back row are **behind** it. Every back slot has exactly two slots in front; F1 and F4 have one slot behind, F2 and F3 have two (N2 §1).

**8.2.2** [PROPOSED] **Adjacent.** Two slots are adjacent when they are next to each other in the same row (F1–F2, F2–F3, F3–F4, B1–B2, B2–B3). Adjacency doesn't skip over an empty slot: if F2 is empty, F1 has no adjacent unit. *Why:* this keeps HSBG's meaning of "adjacent" (left and right in the row), and fixed slots make an empty slot a real gap (keywords.md §F). *Galaxy:* same-row neighbours (inferred).

**8.2.3** [PROPOSED] **Neighbour.** A slot's neighbours are its adjacent slots plus the slots in front of and behind it, so up to 4. *Why:* text sometimes needs "every unit touching this one"; one word for the union keeps card text short.

**8.2.4** [PROPOSED] **Relations belong to slots.** "The unit in front of this", "adjacent units" and the like mean the units currently in the related slots. An empty related slot contributes no unit. A unit that later enters that slot becomes the related unit. *Why:* this is what fixed slots buy (BLO pros), and "when the unit in front of this dies" then works as written.

**8.2.5** [BRAMBLE] **Leftmost and rightmost are per row.** There is no board-wide leftmost or rightmost. Card text that uses them must name a row ("your leftmost front-row unit"). Within a row, the leftmost unit is the occupied slot with the lowest number, and the rightmost the highest (N4 §5). *HSBG:* one row, so the term is board-wide.

**8.2.6** [PROPOSED] **Across from.** The enemy slot "across from" a slot is the enemy slot with the same label (F2 faces F2, B1 faces B1). If it is empty, there is no unit across. *Why:* both boards share the same grid. *Galaxy:* uses "the enemy across from me" for duel effects (Galaxy design-notes §5, idea 11).

**8.2.7** [BRAMBLE] **Rows.** "Front row" means slots F1–F4 and "back row" means B1–B3. Text that refers to a row applies to the units in its slots (N1 §3).

**Relations table**

| Slot | Row | Reading order | Adjacent | In front of it | Behind it | x |
|---|---|---|---|---|---|---|
| F1 | front | 1 | F2 | — | B1 | 0 |
| F2 | front | 2 | F1, F3 | — | B1, B2 | 1 |
| F3 | front | 3 | F2, F4 | — | B2, B3 | 2 |
| F4 | front | 4 | F3 | — | B3 | 3 |
| B1 | back | 5 | B2 | F1, F2 | — | 0.5 |
| B2 | back | 6 | B1, B3 | F2, F3 | — | 1.5 |
| B3 | back | 7 | B2 | F3, F4 | — | 2.5 |

### 8.3 Placement and moving

**8.3.1** [BRAMBLE] **Gaps are allowed.** Any set of occupied slots is a legal board, including an empty front row with units in the back. HSBG packs units together (BLO, Option A).

**8.3.2** [OPEN] **Minimum front row.** Whether a board must keep some number of front-row units, e.g. to limit a single tough front unit guarding a full back row (direction summary, question 4; BLO "Problems every option has to solve").

**8.3.3** [PROPOSED] **Moving.** During the Recruit Phase a player may move a board unit to any empty slot, or swap two board units, for free and any number of times. Moving doesn't trigger "when played" effects, and a unit can't be moved back to hand. *Why:* HSBG lets players reorder freely (rules.md §5.3); fixed slots turn reordering into moving and swapping.

**8.3.4** [BRAMBLE] **No packing.** Units never slide to fill a gap, in the Recruit Phase (after selling or a triple) or in combat (after a death) (BLO, Option A; N3).

**8.3.5** [PROPOSED] Units change slots only through the player's moves (8.3.3) or effects that say so. An effect that would move a unit into an occupied slot fails, unless it says "swap". *Why:* keeps position text reliable.

### 8.4 Summon placement

**8.4.1** [BRAMBLE] **Dead unit's slot first.** (N4 §4) When a unit's own death effect (text like "when this dies, summon…") or return effect (9.7.2) puts units on the board, the first one goes into the dying unit's slot if that slot is empty. *Why:* fixed slots give summons a natural home (BLO). *HSBG:* death-effect summons appear where the minion died (rules.md §11.7). *Galaxy:* a death effect's first summon takes the KO'd character's slot. Examples: HSBG's Deathrattle and Reborn; Galaxy's Farewell.

**8.4.2** [BRAMBLE] **Nearest empty slot.** (N4 §4) Every other summon goes into the empty slot nearest its source: first the same row, then the other row. Within a row, the nearest by x position wins, and a tie goes to the slot on the right. The source of a death effect is the dying unit's slot; a living source is its own slot. *Why:* keeps summons near their source, as HSBG summons appear next to it, usually on the right (rules.md §11.7).

| Source slot | Order in which empty slots are tried |
|---|---|
| F1 | F2, F3, F4, B1, B2, B3 |
| F2 | F3, F1, F4, B2, B1, B3 |
| F3 | F4, F2, F1, B3, B2, B1 |
| F4 | F3, F2, F1, B3, B2, B1 |
| B1 | B2, B3, F2, F1, F3, F4 |
| B2 | B3, B1, F3, F2, F4, F1 |
| B3 | B2, B1, F4, F3, F2, F1 |

**8.4.3** [PROPOSED] Summons from a source with no slot (a hero power, a spell with no target, a game modifier) go into the first empty slot in reading order. A spell or effect aimed at a unit uses that unit's slot as the source. *Why:* engine needs a default; front-first matches "fills from the front".

**8.4.4** [PROPOSED] Several summons from one effect are placed one at a time, each into the next slot by 8.4.1–8.4.3 as the board stands at that moment. *Why:* deterministic.

**8.4.5** [BG] If the board has no empty slot, the summon fails and is lost. Effects that explicitly "summon when there is space" wait instead (rules.md §11.7).

**8.4.6** [PROPOSED] Card text that names a slot ("summon into the slot behind this") overrides 8.4.1–8.4.3. If the named slot is full, the summon fails. *Why:* lets position-based cards be precise.

**8.4.7** [PROPOSED] These placement rules apply in the Recruit Phase and in combat alike. A unit summoned in the Recruit Phase stays on the recruit board and is Created (4.3.1). *Why:* one placement rule for both phases is easier to learn and to implement.

### 8.5 Slot effects

Note: the owner wants the rules to let Bramble experiment with slot effects, which fixed slots make possible (N9).

**8.5.1** [PROPOSED] **Slot effects.** A board slot can hold effects that apply to whatever unit is in it. They stay on the slot when units move, swap, are sold, die or are replaced. An empty slot's effects do nothing until a unit enters. Example: Galaxy's slot buffs.

**8.5.2** [PROPOSED] Slot effects are part of the board: they are copied into combat (9.1.1) and into the snapshot others fight (2.1.4). A change made in combat lasts that combat unless it says permanently.

**8.5.3** [PROPOSED] Slot effects last as their text says (chapter 12); with no duration they last the game.

**8.5.4** [BRAMBLE ideation] **Ring cap.** During recruiting, a slot’s Ring holds at most +4/+4. A full Ring cannot be aimed at by a Ring spell; overflow is lost. Sally Spore skips empty slots with full Rings. Fairy Monarch adds its bonus above the cap. Reel-Mistress moves whole Rings during combat and can stack them past the cap; recruiting Rings stay unchanged. Horseshoe halves the Ring and Monarch bonus together, rounded down.

---

## 9. Combat

### 9.1 Setup

**9.1.1** [BG] **Boards are copied into combat**, slot effects included (8.5.2). Confirmed by the owner (N4 §6). Changes in combat don't affect the recruit board, except effects that say "permanently" or that act on the recruit board directly. After combat, combat-only units disappear and the recruit board is as it was (rules.md §11).

**9.1.2** [BRAMBLE] Each unit starts combat in its recruit slot. Empty slots stay empty (BLO, Option A).

**9.1.3** [BG] Combat runs with no player decisions (rules.md §11).

### 9.2 Who attacks first

**9.2.1** [BG] The player with more units on the board attacks first. A tie is decided at random. Units are counted on the boards entering combat, before Start of Combat effects (counting moment uncertain in HSBG — see rules.md §11.1).

### 9.3 Start of Combat

**9.3.1** [BG] Start of Combat effects resolve in phases, in this order: game-wide modifiers; player-level modifiers (trinkets, quest rewards, secrets); hero powers; then units, first those that trigger from hand and then those on the board. Only phases for systems in the game apply (uncertain in HSBG — see rules.md §11.2, SIM).

**9.3.2** [BG] In the unit phase, one player chosen at random resolves all their Start of Combat units, then the other player does. Each player's units go in reading order (1.2.3), which replaces HSBG's left to right (uncertain in HSBG — see rules.md §11.2, SIM).

**9.3.3** [BG] Within a hero-power phase, player order is random (uncertain in HSBG — see rules.md §11.2, SIM).

**9.3.4** [BG] Start of Combat unit effects use the board as it was before the hero-power phases (uncertain in HSBG — see rules.md §11.2, SIM).

**9.3.5** [BG] Deaths caused by a Start of Combat effect resolve (9.7) before the next Start of Combat effect. If a board is empty after Start of Combat, combat ends (9.9).

### 9.4 Attack order

**9.4.1** [BG] After Start of Combat, the two sides take turns making one attack each, starting with the first attacker (rules.md §11.3).

**9.4.2** [BRAMBLE] **Order across rows.** On each side, units attack in reading order: front row left to right (F1–F4), then back row left to right (B1–B3), then the cycle repeats. HSBG uses one row, left to right (N1 §3; N2 §1). The owner confirmed this order over an interleaved one, accepting that the back row plays a reserve and support role (N4 §1).

**9.4.3** [BG] Each unit attacks once per cycle, unless an effect lets it attack more. The owner confirmed this (N2 §1). Example: HSBG's Windfury.

**9.4.4** [BRAMBLE] Rows set only the attack order and default targeting. If the front row is empty, the units left carry on in the same order (N3).

**9.4.5** [PROPOSED] **The attack pointer.** Each side keeps a pointer `P` (the reading-order number of the slot that made that side's most recent attack this cycle; 0 at the start of combat) and an "attacked this cycle" flag on each unit. When it is a side's turn:
1. A unit **can attack** if it is on the board, has Attack above 0, and no effect stops it.
2. The attacker is the unit with the lowest reading-order number that can attack and is not flagged.
3. If there is none, but some unit can attack, the cycle resets: clear every flag, set `P` to 0, and go back to step 2.
4. If no unit can attack at all, the side passes (9.4.10).
5. When a unit in slot number `i` attacks, set `P = i`, flag it, and flag **every unit in a slot numbered below `i`**.

*Why:* this is HSBG's rule that minions to the left of the attacker are marked as having attacked (uncertain in HSBG — see rules.md §11.3, SIM), stated for fixed slots and two rows. Flagging lower-numbered units is what makes the order "front row, then back row" even when units appear mid-cycle.

**9.4.5a** [BRAMBLE ideation] **Mire waits once.** At Start of Combat, Mire binds the enemy slot across to its maker: the enemy there must attack that maker while it lives, even in the back row. When first chosen to attack, the maker waits if a living enemy on its patch has not attacked. Waiting skips its attack for the current cycle (9.4.5), and the next eligible friendly unit attacks. It waits at most once a fight. An empty patch does not cause a wait. Two opposing mirers each wait once, then attack normally; a target with 0 Attack or a skipped turn cannot cause repeated waits. Borrowed Mire follows the same rule.

**9.4.6** [BG] Units with 0 Attack never attack and are skipped (rules.md §11.3).

**9.4.7** [PROPOSED] Empty slots are skipped; they take no turn. *Why:* direction summary, question 3.

**9.4.8** [BRAMBLE] **Units entering a slot mid-cycle.** (N4 §3) A unit summoned into slot number `j`, or returned there after dying:
- if `j` is below `P`, it is flagged and waits for the next cycle;
- if `j` equals `P` (the slot of the unit that just attacked, which died), it is not flagged, so it attacks next for its side;
- if `j` is above `P`, it is not flagged and attacks when the order reaches it.

*Why:* matches HSBG, where a token summoned in a dead minion's place takes the status of the minion to its right, so a dead attacker's tokens attack next, and one summoned to the left of the attacker waits (rules.md §11.3, SIM). *Galaxy:* a summon "inherits the same attack priority as its source", and one entering a slot that just attacked gets the next attack.

**9.4.9** [PROPOSED] A unit moved by an effect during combat keeps its flag. If it moves into a slot numbered below `P` and isn't flagged, it becomes flagged. *Why:* stops a unit from attacking twice in a cycle by moving.

**9.4.10** [BG] A side whose turn it is but which has no unit that can attack passes, and the other side keeps attacking (not in rules.md; follows from the stalemate rule in rules.md §11.3).

**9.4.11** [BG] **Repeat attacks.** A unit that an effect lets attack more than once in its turn makes those attacks back to back, choosing a new target for each. It stops if it dies or its Attack drops to 0. The pointer is set by its first attack (rules.md §11.3). Example: HSBG's Windfury.

**9.4.12** [BG] **"Attacks immediately."** A unit told to attack immediately makes an extra attack at once, out of turn. It doesn't change the pointer or flags, and the normal order resumes afterwards (uncertain in HSBG — see rules.md §11.3, SIM).

Note, worked example. Side A has units in F1, F3 and B2. Its order is F1, F3, B2, then repeat. F3 attacks (`P = 3`; F1 and F3 are flagged) and dies. Its death effect summons two tokens: the first goes into F3 (8.4.1) and is not flagged because `j = P`; the second goes into F4 (8.4.2), unflagged because `4 > P`. Side A's next attacks are: F3 token, F4 token, B2. Then the cycle resets and starts at F1. Had the second token gone into F2, it would have been flagged (`2 < P`) and waited for the next cycle.

### 9.5 Targeting

**9.5.1** [BRAMBLE] **Back-row protection.** An attacker's candidate targets are the enemy front-row units if there are any; otherwise the enemy back-row units. Back-row units can't be attacked while any enemy front-row unit lives, unless an effect says otherwise (11.5.3). In HSBG every enemy minion is a candidate (N2 §1).

**9.5.2** [BG] Untargetable units are removed from the candidates. Example: HSBG's Stealth.

**9.5.3** [PROPOSED] If every candidate is untargetable, those candidates lose that protection and stay the candidates. The back row does **not** become targetable because the front row is untargetable. *Why:* the owner's rule is "while any front-row unit is alive" (N2 §1). The HSBG simulator likewise clears Stealth when an attacker has no valid target (keywords.md §A). Example: HSBG's Stealth.

**9.5.4** [PROPOSED] Must-be-attacked works within the row that can be attacked. If any candidate must be attacked, the target is chosen among those only. While any enemy front-row unit lives, a back-row unit that must be attacked does nothing; once the back row is the candidate row, it must be attacked before the other back-row units. Source: the owner's 27 Oct ruling for Taunt (N4 §7). Example: HSBG's Taunt.

**9.5.5** [BG] The target is chosen at random among the remaining candidates (rules.md §11.4).

**9.5.6** [BRAMBLE] **Random effects ignore rows.** An effect that picks a random enemy ("deal 3 damage to a random enemy") chooses from every enemy unit in either row. Back-row protection (9.5.1) and must-be-attacked effects (9.5.4) apply only to attacks. Effects that hit a described group ("all enemies", "the units behind it") hit every unit in the group (N4 §2). *HSBG:* random effects choose from any enemy minion and ignore Taunt.

**9.5.7** [BG] Card text can override targeting (for example, "attacks the lowest-Attack enemy") (rules.md §11.4).

**9.5.8** [BG] Heroes can't be attacked (rules.md §11.4).

### 9.6 Resolving one attack

**9.6.0** [BRAMBLE ideation] **Bitter hits first.** At attack declaration, after the attack’s own bonuses (including a queued counter’s bonus), Bitter reduces the leading attacker’s Attack by its amount, down to 1. It applies before damage, Bristle, Shell and Hunker; the loss lasts this fight. Own and lent Bitter stack. Pack joiners keep their Attack. It also applies to counters and pounces, once per declared attack rather than once per Peck strike. A once-per-enemy use is spent at declaration even if the attack later deals no damage. Bitter cannot raise 0 Attack, deal damage or cause a wipe.

**9.6.1** [BG] An attack resolves in this order (uncertain in HSBG — see rules.md §11.5, SIM):
1. The defender's "when attacked" effects.
2. The attacker's "whenever this attacks" effects.
3. Damage exchange: attacker and defender deal damage equal to their Attack to each other at the same time. Splash effects damage their extra targets at the same time.
4. "After this attacks" effects.
5. Death resolution (9.7).
6. "After an attack" effects of player-level modifiers.

If the defender is gone after step 1 or 2, the attack ends without damage (not in rules.md). Examples: HSBG's Rally (step 2) and Cleave (step 3).

**9.6.2** [BG] In the damage exchange, the attacker's damage triggers resolve before the defender's (rules.md §11.5, standard Hearthstone).

**9.6.3** [BG] **Health and death.** A unit's Health is its maximum Health minus damage taken. A unit with Health 0 or less dies. Deaths are checked after each damage event, and all units at 0 or less die together (rules.md §11.6, SIM).

**9.6.4** [BG] Damage taken in combat stays for the rest of that combat (rules.md §11).

### 9.7 Death resolution

**9.7.1** [PROPOSED] **Dying units leave their slots first.** At the start of death resolution, every dying unit is removed from its slot, leaving it empty, before any trigger resolves. Triggers that refer to positions ("when the unit in front of this dies") use the positions the dying units held (12.2.3). *Why:* the dying unit's own summons can then take its slot (8.4.1). *Galaxy:* the same.

**9.7.2** [BG] Deaths resolve in this order (uncertain in HSBG — see rules.md §11.6, SIM quoting designer Mitchell Loewen):
1. "After a unit kills" triggers, then "whenever a unit dies" triggers.
2. Each dying unit in turn (order in 9.7.3): its own death effects, then death effects granted to it, then every friendly death counter advances by 1 and fires when it reaches its number.
3. "After a friendly unit dies" effects.
4. Return effects (units that come back after dying), after all death effects and counters.
5. Effects that trigger on a return.
6. New deaths start another pass.

Examples: HSBG's Deathrattle, Avenge and Reborn.

**9.7.3** [PROPOSED] **Order of dying units.** The active side's dying units resolve first, then the other side's. Within a side, they resolve in reading order. The active side is the side whose unit is attacking, or, outside an attack, the side whose effect caused the deaths. *Why:* HSBG resolves left to right within a side, but which side goes first is unknown and the simulator picks at random (rules.md §11.6). A fixed rule is easier to read and to test.

**9.7.4** [BG] **Death counters.** A death counter counts friendly deaths in this combat and fires each time the count reaches a multiple of its number (repeat behaviour uncertain in HSBG — see keywords.md §B). Example: HSBG's Avenge (X).

### 9.8 Summons in combat

**9.8.1** [BG] Units summoned in combat can attack in that combat; they join the attack order where they land (rules.md §11.3). Where they land is set by 8.4, and when they attack by 9.4.8.

**9.8.2** [BG] **Returns.** A unit that comes back after dying returns as a fresh copy of its card with no buffs. A golden unit stays golden. Its Health, and whether it can return again that combat, are set by the effect (rules.md §11.8). Example: HSBG's Reborn returns with 1 Health and can't return again that combat.

**9.8.3** [PROPOSED] A returning unit goes back to its own slot if it is empty. If a summon from its own death effect took that slot, it goes to the nearest empty slot (8.4.2). *Why:* returns resolve after death effects (9.7.2), so the slot may be taken; the nearest-slot rule keeps it close. Example: HSBG's Reborn.

**9.8.4** [BG] Units summoned in combat are combat-only and disappear after combat, unless an effect says otherwise (rules.md §11).

### 9.9 End of combat

**9.9.1** [BG] Combat ends when, after death resolution, one or both boards are empty, or when neither side has a unit that can attack (rules.md §11.9, §11.3).

**9.9.2** [BG] If exactly one board has units left, that side wins. If both boards are empty, or neither side can attack, the BG fight is a **tie** (rules.md §11.9). **BRAMBLE ideation — Last Blow:** a mutual wipe during attacks is won by the attacker in the final exchange, or by the owner of the effect that finishes it (including death effects; Bitter currently reduces Attack and cannot cause a wipe). With no survivors, deal only the round base (10.1.4a). A wipe during Start of Combat stays a tie. No-attack and safety-limit endings stay ties. Units fighting for a different side credit that side.

### 9.10 Runaway limits

**9.10.1** [PROPOSED] **Attack limit.** A combat ends after 200 attacks in total (both sides, extra attacks included). It ends as a tie. *Why:* HSBG's client limit is unknown; the simulator stops at 400 attacks (rules.md §11.3). A tie is the HSBG-style result. *Galaxy:* gives the win to the active player instead, which suits its async play.

**9.10.2** [PROPOSED] **Trigger limit.** A combat ends as a tie after 10,000 trigger resolutions. In the Recruit Phase, one player action stops resolving new triggers after 1,000. *Why:* catches loops that don't involve attacks; HSBG and Galaxy both patched loops one card at a time (patch-history.md lesson 2).

**9.10.3** [PROPOSED] **Return limit.** The same unit can come back after dying (any return or resummon effect) at most 5 times in one combat; further returns fail. *Galaxy:* caps resummons at 5 per character. *HSBG:* capped two looping cards at 30 loops in 30.0.2 (rules.md §11.3). Example: HSBG's Reborn.

---

## 10. Hero damage and elimination

### 10.1 Damage

**10.1.1** [BG] **Formula.** The winner of a fight deals damage to the loser's hero equal to the winner's tier plus the total tier of the winner's surviving units, in both rows (rules.md §12).

**10.1.2** [BG] A golden unit counts its normal tier (uncertain in HSBG — see rules.md §12, SIM).

**10.1.3** [BG] A Created unit counts its own tier, or tier 1 if it has none (uncertain in HSBG — see rules.md §12).

**10.1.4** [BG] **Damage cap.** Damage from one fight is at most 5 on turns 1–3, 10 on turns 4–7, and 15 from turn 8. The cap is removed once 4 or fewer players are left (continuation into 2026 uncertain in HSBG — see rules.md §12).

**10.1.4a** [BRAMBLE ideation] **40 Health.** A loss deals the round base plus 1 per enemy starting survivor. The base from round 1 is **0/0/0/1/1/2/2/3/4/5/7/9/11/13**, then stays at 13. No cap or toll. Ties deal no damage; Last Blow deals only the base. Armor absorbs damage first.

A starting survivor is one of the winner's own units recorded before Start of Combat, alive on its own side when the fight ends. Golden counts once. The same unit can return and still count. Starting Eggs count once too. Combat summons, replacement copies and stolen enemies do not count. This replaces 10.1.1–10.1.4 for ideation games; tools can select `legacy` for the previous tier, floor, cap and toll rules.

**10.1.4b** [BRAMBLE ideation] **Last Stand.** Only while four or fewer heroes are left, once per game, a loss to another hero that would knock your hero out from 2 Health or more leaves it on 1 instead, after Armor. A ghost never uses it. Ties and non-combat Health costs do not use it. A hero's panel records whether the save is used. It cannot fire while five or more heroes are left. The hero panel shows locked, ready or used; the lobby shows ready or used in the last four.

**10.1.4c** [BRAMBLE ideation] **Early Spoils.** Rounds 1–4: win a fight against a living hero and get **1 gold next turn**. Ties and wins against ghosts pay nothing. The fight result and next-income display name Spoils.

**10.1.5** [BG] Armor absorbs damage first; the rest comes off health (rules.md §12).

**10.1.6** [BG] A tie deals no damage (rules.md §11.9).

**10.1.7** [BG] A ghost board (2.1.2) deals damage normally when it wins, and damage dealt to it has no effect (rules.md §1).

### 10.2 Elimination

**10.2.1** [BG] A hero at 0 health or less is eliminated. Eliminations are checked after all fights of the round (uncertain in HSBG — see rules.md §12).

**10.2.2** [PROPOSED] Players eliminated in the same round are placed by their health after damage: lower health places lower. Ties are broken at random. *Why:* HSBG's rule is unknown (rules.md §12).

**10.2.3** [BG] The game ends when one player is left; that player places 1st (rules.md §12).

---

## 11. Example mechanics

None of these is a Bramble mechanic. They are mechanics from HSBG (at 36.6.3; rules.md §13, keywords.md) and Galaxy (Galaxy rules.md §10), kept as [EXAMPLE]s of how good mechanics break the system rules and of what Bramble's rules and code must be able to handle. Bramble designs its own, some of which exist in neither game (N9). Each entry says what the mechanic does in its source game and which rule it tests. Where a rule already decides how it would work on two rows, that worked version follows.

### 11.1 General

**11.1.1** [BG] Keywords are shorthand for rules text. Units can gain and lose keywords. A keyword gained in combat lasts only for that combat unless the effect says "permanently" (rules.md §13).

### 11.2 HSBG combat keywords

**11.2.1** [EXAMPLE] **Taunt.** HSBG: attackers must target a Taunt minion. Tests: must-be-attacked targeting (9.5.4). Two rows: a back-row Taunt does nothing while its front row has units, and protects the other back-row units once the back row can be attacked (9.5.4; N4 §7).

**11.2.2** [EXAMPLE] **Divine Shield.** HSBG: the first time this minion would take damage, it takes none and loses Divine Shield. It blocks Venomous and splash damage too (keywords.md §A). Tests: damage prevention inside the damage exchange (9.6.1). No rule decides damage prevention yet; it waits for the hook list.

**11.2.3** [EXAMPLE] **Windfury.** HSBG: attacks twice in a row each cycle. Golden Windfury is still two attacks; Mega-Windfury is retired (keywords.md §A). Tests: extra attacks and the attack pointer (9.4.3, 9.4.11).

**11.2.4** [EXAMPLE] **Reborn.** HSBG: the first time this minion dies in a combat, it returns with 1 Health. Tests: return effects (9.7.2 step 4, 9.8.2) and the return limit (9.10.3). Two rows: its slot is chosen by 9.8.3.

**11.2.5** [EXAMPLE] **Venomous.** HSBG: destroys the first minion it deals damage to each combat. Divine Shield blocks it and uses it up (shield interaction uncertain in HSBG — see keywords.md §A). Tests: destroy-on-damage and its order against damage prevention. No rule decides either yet; they wait for the hook list.

**11.2.6** [EXAMPLE] **Stealth.** HSBG: can't be targeted until it attacks or deals damage. Tests: untargetable candidates (9.5.2, 9.5.3). Two rows: a Stealthed front-row unit still protects the back row (9.5.3), and a Stealthed back-row unit stays untargetable after the front row falls, until it attacks.

**11.2.7** [EXAMPLE] **Cleave** (informal name in HSBG: "also damages the enemies next to whomever this attacks"). Tests: splash damage in the damage exchange (9.6.1) and adjacency (8.2.2). Two rows: it also damages the units adjacent to the target, in the target's row; an empty adjacent slot means no splash on that side. A version that splashes to the units behind would be a different effect (keywords.md §A).

**11.2.8** [EXAMPLE] **Attacks immediately.** HSBG: an extra attack made at once, out of turn. Tests: out-of-turn attacks and the attack pointer (9.4.12).

### 11.3 HSBG trigger keywords

**11.3.1** [EXAMPLE] **Battlecry.** HSBG: triggers when the minion is played from hand, after it is placed. Recruit Phase only. Tests: "when played" effects (7.2.3) and moving not counting as playing (8.3.3).

**11.3.2** [EXAMPLE] **Deathrattle.** HSBG: triggers when this minion dies. Tests: death effects (9.7.2 step 2), summons into the dying unit's slot (8.4.1) and last-known positions (12.2.3).

**11.3.3** [EXAMPLE] **Avenge (X).** HSBG: triggers after X friendly minions die in this combat. Tests: death counters (9.7.2 step 2, 9.7.4) and thresholds on golden units (7.3.5).

**11.3.4** [EXAMPLE] **Rally.** HSBG: triggers whenever this minion attacks, before damage. Tests: "whenever this attacks" effects (9.6.1 step 2).

**11.3.5** [EXAMPLE] **Start of Combat.** HSBG: triggers at the start of each combat. Tests: the Start of Combat step and its order (9.3).

**11.3.6** [EXAMPLE] **End of Turn** ("at the end of your turn"). HSBG: triggers at the end of the Recruit Phase. Tests: end-of-turn order (3.4.1, reading order 1.2.3).

### 11.4 HSBG Recruit Phase keywords

**11.4.1** [EXAMPLE] **Magnetic.** HSBG: played "to the left of a Mech", it fuses into that minion. Tests: merges and their origin (4.3.5) and playing on a full board (7.2.2). Two rows: it is played onto a friendly unit of the named type directly; the target gains its stats and text, and no slot is used, so it works on a full board.

**11.4.2** [EXAMPLE] **Spellcraft.** HSBG: gives a temporary spell when played and at the start of each Recruit Phase. The spell leaves the hand at the end of the turn. A golden minion gives a golden spell with double effect. If the hand is full, the spell waits for space (keywords.md §C). Tests: cards that wait for hand space (7.1.2), "this turn" durations (12.1.1) and golden text (7.3.5).

**11.4.3** [EXAMPLE] **Choose One.** HSBG: the player chooses one of two or more effects (keywords.md §C). Tests: player choices inside an effect in the Recruit Phase (3.3.1).

**11.4.4** [BG] **Discover** is a system, not an example: see 6.2.

**11.4.5** [EXAMPLE] **Activate (X).** HSBG: once per turn in the Recruit Phase, pay X gold to use the effect (keywords.md §C). Tests: Recruit Phase actions that cost gold (3.3.1, 4.1.5) and once-per-turn limits.

**11.4.6** [EXAMPLE] **Bonus Keyword.** HSBG: gives a random one of Divine Shield, Reborn, Stealth, Taunt, Venomous or Windfury, usually for one combat (keywords.md §C). Tests: gaining keywords (11.1.1), random choice (1.2.2) and combat durations (12.1.2).

### 11.5 Back-row access

Note: 11.5.1 (HSBG tribe mechanics) and 11.5.2 (retired HSBG keywords) were cut in v0.4. With every HSBG mechanic now an example, they had nothing left to rule on (N9).

**11.5.3** [OPEN] **Back-row access.** Which effects let attacks or effects reach the back row while the front row lives. The owner named overkill damage that splashes through and attacks that target the back row (N2 §1). Example: Galaxy's Sneak (11.6.2).

### 11.6 Galaxy examples

**11.6.1** [EXAMPLE] **Support.** Galaxy: gives a bonus to "the two characters in front of it", mostly an aura that ends when the supporter is KO'd. Tests: "in front of" relations (8.2.1, 8.2.4) and auras (12.2.1).

**11.6.2** [EXAMPLE] **Sneak.** Galaxy: attacks a random back-row enemy if there is one, otherwise any enemy. Tests: back-row protection (9.5.1), back-row access (11.5.3) and text that overrides targeting (9.5.7).

**11.6.3** [EXAMPLE] **Farewell.** Galaxy's name for a death trigger: fires when this character is KO'd, attacking or not, and its first summon takes the same slot. Tests: death effects (9.7.2) and summons into the dying unit's slot (8.4.1).

**11.6.4** [EXAMPLE] **Recruit.** Galaxy's name for a play trigger: fires when the card is taken from the shop, including banking it, and not on a transform. Tests: a take-from-shop trigger. With a hand that means buying (4.2.1), not "when played" (7.2.3).

**11.6.5** [EXAMPLE] **Hunt.** Galaxy: fires when this character attacks and KOs the defender, even if it also dies. Only the attacker hunts. Tests: "after a unit kills" triggers (9.7.2 step 1).

**11.6.6** [EXAMPLE] **Slot buffs.** Galaxy: buffs that live on a board slot and stay when the character in it changes (Galaxy rules.md §4). Tests: slot effects (8.5).

**11.6.7** [EXAMPLE] **Paint.** Galaxy: colours a slot permanently, and each colour gives the character in that slot a buff, such as +1/+1 for any coat (Galaxy rules.md §8). Tests: slot effects (8.5) and how long they last (8.5.3).

---

## 12. Durations and effect scopes

### 12.1 Durations

**12.1.1** [BG] **"This combat"** lasts until the combat ends. **"Permanently"** also applies the change to the unit on the recruit board. **"This game"** is a player-level change that lasts the whole game and can affect future cards. **"This turn"** or **"until next turn"** ends at the end of the Recruit Phase or the start of the next one (rules.md §13).

**12.1.1a** [BRAMBLE ideation] A printed permanent-buff ceiling caps Attack and Health bonuses in the permanent layer, including feeding, doubling, triples and permanent combat gains. The ceiling doubles on golden. Slot/aura and temporary combat buffs are separate. Feeding a fully capped unit is refused without consuming the item. Alderman Dozey's ceiling is +12/+12 (+24/+24 golden).

**12.1.2** [BG] Buffs gained in combat are lost after combat unless they say "permanently". *Galaxy:* makes all buffs permanent; its design notes advise Bramble not to copy that (Galaxy design-notes §6).

**12.1.2a** [BRAMBLE ideation] **Mrs Clover.** Her first two summons each turn gain the printed buff, counting the Recruit Phase and its following fight together. Recruiting buffs are permanent; combat buffs last that fight. The count resets at the start of the next Recruit Phase. Playing a unit from hand is not summoning it, and a summon that finds no room uses no buff.

**12.1.2b** [BRAMBLE ideation] **Elder Ooze.** While this lives, friendly units coming out of your Oozes gain its printed combat buff, including Wee Wobbly's Drips. Units released from Elder Ooze's own Belly when it dies also gain the buff. Returned enemy prisoners never gain it. Drips are summons, so they do not fire Belly-only effects such as Mr Syllabub's Start of Combat replay.

**12.1.3** [BG] Shop-wide buffs ("units in the shop have +1/+1 this game") apply to the units currently in the shop and to future shop units (rules.md §13).

**12.1.4** [BRAMBLE ideation] **Flying and Eggs.** Fly South pays no sale gold. The Bird keeps its stats and returns to hand after its printed trip; it cannot fly on the turn it lands. When sold text still fires on flight, When played can fire when replayed, and explicit homecoming text fires on landing. An empty Nest holds an Egg in combat with half its away Bird's current Attack and Health, each rounded up after permanent and tribe bonuses, but none of the Bird's text. Mother Goose's own Egg follows the same rule. An occupied Nest does not add an Egg. Eggs count as Eggs, not Birds. Tom Tit gives your Eggs their Bird's full Health; golden Tom Tit gives full Attack too. Redwing's full-stat coverage still applies; only the strongest coverage counts, and the Egg's slot Rings apply afterward. Empty own Nests display the resulting Egg stats and homecoming countdown; occupied Nests show the Nest below their standing unit. Old Tern's homecoming returns the other away Birds too, including lengthened trips, to hand or doorstep. Mrs Stork returns the Bird away longest per 6 gold spent (two if golden), only if it has missed a fight; ties choose the leftmost Nest. A starting Egg that survives adds 1 hero damage (10.1.4a).


**12.1.5** [BRAMBLE ideation] **Queen of Elfland.** The Queen pools the destroyed units' printed Attack and Health (doubled if those units are golden), plus their permanent buffs. Tribe bonuses, Rings, other auras and buffs for the next combat are excluded. Her golden version doubles that pool before dividing it among your other Fairies. This keeps a standing tribe bonus separate from permanent unit buffs.

**12.1.6** [BRAMBLE ideation] **Pass X:** your last unit, other than its source, gains X. Last means last occupied slot in **F1-B1-F2-B2-F3-B3-F4**; gaps do not stop it and it never lands on the source. With no other unit, nothing happens. Recruiting Passes wait until End of Turn and read the board then; a sold source is excluded. Combat Passes land immediately on the last living other unit. The permanent Pass mark names the end unit; selecting or moving a Pass source shows its actual recipient, or “no one to pass to”. Touching still requires an unbroken zigzag run.

**12.1.7** [BRAMBLE ideation] **Shy.** Only a spell aimed at the Shy unit or its slot can buff it while recruiting. The aimed spell sends it away and pays **2 gold next turn**, or **4 if golden**. Its other effects still resolve: aiming Harvest Supper at Shy still raises the tribe bonus. Rings, auras, tribe bonuses, unit text, and spells aimed elsewhere give it no stats and do not send it away. Combat buffs work normally. A Shy unit that leaves returns its copies to the pool; it is not sold. Destruction, including the Queen's Teind, pays no Shy gold, and Shy cannot receive a Teind share. Silky Rings a thanked unit's vacated slot, including her own, with the existing Ring cap. Mrs Mallow skips Shy when choosing your smallest unit (Attack plus Health, ties in zigzag order).

## 13. Systems outside the v0 core

**13.1.1** [PROPOSED] HSBG's seasonal systems are not in the v0 core rules: Trinkets and Dark Gifts (active at 36.6.3), and Quests, Anomalies, Buddies, Timewarped Tavern and Darkmoon Prizes (inactive). *Why:* HSBG turns them on and off by season, and each one forced changes to armor and timers (patch-history.md lesson 4). The owner wants game-warping modifiers to be addable later through a clean modifier layer (N1 §7; [architecture-notes.md](architecture-notes.md)).

**13.1.2** [PROPOSED] Tier 7 is reachable only by effects that say so (4.6.1), and no v0 system grants it. *Why:* in HSBG it comes only from seasonal systems and specific rewards (rules.md §15).

---

## 14. Glossary

Each term points to the rule that defines it.

| Term | Meaning | Rule |
|---|---|---|
| **Unit** | A card with Attack, Health and a type line that can be on the board. HSBG's *minion*. | 1.1.1, 5.2.1 |
| **Bought** | A unit taken from the shop by paying, or (proposed) drawn from the pool by an effect. Sells for 1 gold. | 4.3.1, 4.3.2 |
| **Created** | A unit that came any other way: summoned, generated, copied, given. Sells for 0 gold. | 4.3.1 |
| **Token** | A Created unit that is not a pool card. | 4.3.1 |
| **Origin** | Whether a unit is Bought or Created. | 4.3.1 |
| **Golden** | The combined unit made by a triple, with double base stats. | 7.3 |
| **Triple** | Three copies of the same non-golden unit combining into a golden. | 7.3.1 |
| **Pool** | The lobby's shared supply of unit and spell copies. | 5.1 |
| **Tier** | A unit's shop tier (1–7), and a player's current shop tier. | 4.6 |
| **Type, type line** | The words describing what a unit is, e.g. "Owl Warrior". | 5.2.1 |
| **Tribe** | A unit type used to build lobbies and match card effects. The playable game uses the six tribes listed in 5.2.5. | 5.2.2–5.2.5 |
| **Tribe bonus** | A standing Attack and Health bonus for owned units of that tribe and future arrivals; capped at +3/+3, excluding fight summons. | 5.2.9 |
| **Slot** | One of the 7 fixed board positions F1–F4, B1–B3. | 8.1 |
| **Slot effect** | An effect held by a board slot that applies to whatever unit is in it, and stays when the unit changes. | 8.5 |
| **Row** | The front row (F1–F4) or the back row (B1–B3). | 8.2.7 |
| **Reading order** | F1, F2, F3, F4, B1, B2, B3: the order of attacks and of board-wide resolution. | 1.2.3 |
| **Gap / empty slot** | A slot with no unit. Gaps are legal and never close up by themselves. | 8.3.1, 8.3.4 |
| **In front of** | For a back slot, the two front slots it sits between. | 8.2.1 |
| **Behind** | For a front slot, the back slot or slots that touch it (one for F1 and F4, two for F2 and F3). | 8.2.1 |
| **Adjacent** | The slot directly left or right in the same row. Doesn't skip gaps. | 8.2.2 |
| **Neighbour** | Any adjacent slot, or a slot in front of or behind. Up to 4. | 8.2.3 |
| **Across from** | The enemy slot with the same label. | 8.2.6 |
| **Leftmost / rightmost** | Per row: the lowest- or highest-numbered occupied slot in the named row. | 8.2.5 |
| **Summon** | Put a unit onto the board from outside the hand. Placement follows 8.4. | 8.4 |
| **Return** | A unit coming back onto the board after it dies, as a fresh copy. | 9.7.2, 9.8.2 |
| **Death counter** | An effect that counts friendly deaths in a combat and fires at its number. | 9.7.4 |
| **Candidates** | The enemy units an attack or single-target effect may pick from. | 9.5 |
| **Attack pointer, cycle** | The bookkeeping that decides who attacks next. | 9.4.5 |
| **Active side** | The side whose unit is attacking, or whose effect caused the event. | 9.7.3 |
| **Refresh** | Replace the shop's cards; the player's action costs gold on an escalating scale. | 4.4 |
| **Freeze** | Keep the shop's cards into the next turn. | 4.5 |
| **Discover** | Choose 1 of 3 units from the pool. | 6.2 |
| **Ghost** | The copied board an odd player out fights. | 2.1.2 |
| **Example mechanic** | An HSBG or Galaxy mechanic, tagged [EXAMPLE], kept to show which rule it tests. Not a Bramble mechanic. | 11 |

---

## Appendix A. Tunable parameters

The values an engine should read from configuration rather than hard-code.

| Parameter | Value | Rule | Status |
|---|---|---|---|
| Players per lobby | 8 | 2.1.1 | BG |
| Heroes offered | 2 | 2.2.2 | BG |
| Starting hero health | 30 | 2.2.5 | BG |
| Income by turn | 3, +1 per turn, max 10 | 4.1.1 | BG |
| Gold holding cap | none | 4.1.3 | BRAMBLE |
| Unit price | 3 | 4.2.1 | BG |
| Sell value, Bought / Created | 1 / 0 | 4.3.3 | BRAMBLE |
| Refresh costs | 1, then +1 per step, no cap | 4.4.2 | BRAMBLE |
| Refresh steps | first after 15, then every 5 | 4.4.3 | BRAMBLE |
| Freeze toggles per turn | 5 | 4.5.1 | BG |
| Upgrade base costs (to 2–6) | 5, 7, 8, 11, 11 | 4.6.2 | BG |
| Upgrade discount per turn | 1, minimum 0 | 4.6.3 | BG |
| Pool copies per unit by tier | 15, 15, 13, 11, 9, 7, 5 | 5.1.2 | BG |
| Shop cards by tier (units) | 4 (3), 5 (4), 5 (4), 6 (5), 6 (5), 7 (6) | 6.1.1 | BG |
| Tribes per lobby | open | 5.2.5 | OPEN |
| Hand limit | 10 | 7.1.1 | BG |
| Board slots, front / back | 4 / 3 | 8.1.2 | BRAMBLE |
| Damage cap by turn | 5 (1–3), 10 (4–7), 15 (8+), off at top 4 | 10.1.4 | BG |
| Attack limit per combat | 200 | 9.10.1 | PROPOSED |
| Trigger limit per combat / per action | 10,000 / 1,000 | 9.10.2 | PROPOSED |
| Returns per unit per combat | 5 | 9.10.3 | PROPOSED |
| Stat clamp | 1,000,000,000 | 1.2.4 | PROPOSED |
| Game length limit | 50 rounds | 2.1.3 | PROPOSED |
| Recruit timer | None | 3.1.2 | BRAMBLE |

### 12.2 Scopes

**12.2.1** [BG] Auras (continuous effects such as "adjacent units have +1 Attack") apply only while their source is on the board, and they are recalculated whenever the board changes (inferred; not in rules.md).

**12.2.2** [PROPOSED] **Board scopes.** "Your units" means the units on your board, not in hand. "Front-row units" and "back-row units" mean the units in those rows. Position words are defined in 8.2. *Why:* HSBG's "your minions" means the board; rows add new scopes that need fixed meanings.

**12.2.3** [PROPOSED] **Last-known positions.** A trigger about a dying unit's position ("when the unit in front of this dies", "when this dies, give the units behind it +2/+2") uses the slot the dying unit held, even though it has already left the slot (9.7.1). *Why:* without this rule, a dead unit would have no position for its own effects.

---

## Shared scale mechanisms [BRAMBLE ideation]

These are general mechanisms for scale experiments; none changes the default pool.

- **Biggest enemy:** the living enemy with highest current Attack + current Health,
  in any row, ignoring back-row protection. **Most Attack** and **most Health** use
  the named current stat in any row. Ties use F1–F4 then B1–B3, without RNG. Dying
  units are ineligible. Effect selectors do not change normal attack targeting.
- **Proportional stats:** set, reduce or gain Attack, Health or both by an integer
  ratio. Calculate each stat from its value immediately before that effect; round
  each fractional amount down. Reductions leave at least 0 Attack and 1 Health.
  These are stat changes, not damage; a later effect uses the resulting stats.
  Combat duration is the usual default in combat; permanent gains persist normally.
- **Damage Reduction N:** takes N less damage from each hit, to a minimum of zero.
  With `percent`, prevents that percentage instead, rounding prevention down.
  Reminder: *Takes this much less damage from each hit.* Fractional form is written
  as Damage Reduction 25%; its reminder uses the same meaning.
- **Shield:** prevents the first positive damage remaining after damage reduction.
  Reminder: *Prevents the first damage this would take each fight.* Zero damage
  does not consume it. Simultaneous hits use their event order; Shield prevents
  one hit, then Shell may cap the largest remaining hit. It does not prevent stat
  loss. Prevented hits cause no damage triggers, Nightshade or Take. A new fight
  restores a printed Shield. Multiple grants do not stack extra shields.
- **Cleave:** attacking strikes also hit occupied slots directly beside the target
  in its row, for that strike's damage. Reminder: *Attacks also hit the units beside
  the target.* Collateral hits use normal damage prevention and kill rules. Units
  beside the target do not retaliate; in-front/behind units are not hit. Quick
  applies to the entire attacking damage step, and each Peck strike can cleave.
  Joiners with Cleave also splash their contribution. Cleave does not chain.
- Optional `percent` on Bitter, Hex, Jenny and Jack Daw replaces flat Attack loss.
  Bitter retains its 1 Attack floor. Hex adds its base percentage per spell and
  persists on the slot. Jenny and Hex calculate their live loss from Attack before
  auras; recalculating the same board does not repeatedly shrink it. Jack Daw gains
  exactly the Attack actually removed. Fractions do not double on golden.
- **End of Turn doubler:** adds one firing of each of your End of Turn effects.
  Golden adds two. Multiple doublers add extra firings; they never recurse.
  Effects retain their own limits when caps are enabled. Each firing counts toward
  the ordinary action trigger guard.
- **Caps overlay:** `card_size_caps=false` removes card size, payment lifetime and
  per-turn/fight growth ceilings in a per-game content copy. It keeps trigger and
  attack guards, the numeric safety clamp, board/hand capacity, resource availability,
  timing conditions, and cycle/once-per-Nest recursion guards. The economy lever's
  explicit experimental config cap remains independently adjustable.
- **Hero/spell scaling:** opt-in positive flat gains become X% per printed point,
  of the recipient's respective current stat, with the printed amount as a floor.
  Delayed buffs lock in the scaled amount at cast time. Empty-slot effects use mean living board Attack/Health at cast time. Standing
  tribe bonuses use the lesser of those means. Negative gains and unit effects
  retain their original values. Scaling defaults off.
