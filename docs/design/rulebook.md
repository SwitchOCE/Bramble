# Bramble rulebook

**v0.11 draft, 19 Nov 2026 (Created units that are real cards sell for money, like Bought ones, and tokens for 0, set by the owner on 19 Nov, C17; v0.10 of 19 Nov: no shared pool, so the shop draws by fixed chances, and async play against recorded runs, set by the owner on 19 Nov, C16; v0.9 of 17 Nov let units move freely between hand and board and sell from either, and play triggers resolve on recruit, set by the owner on 17 Nov, C15; v0.8 of 16 Nov set the hand limit to 7, C14; v0.7 of 12 Nov set the economy and tier-up prices, C13; v0.6 set damage and starting health on 12 Nov, C12; v0.5 of 8 Nov updated damage, starting health, shop size, pool, stat scale and combining from N11–N13), baseline HSBG patch 36.6.3**

This is the full rule set for Bramble, written so the owner can find every place Bramble differs from Hearthstone Battlegrounds (HSBG) and so an engine can be built from it. HSBG is the default for systems (economy, shop, pool, turn flow, combat order) wherever the owner hasn't decided otherwise. Mechanics and keywords from HSBG and Galaxy appear only as [EXAMPLE]s of what the rules must handle. Bramble designs its own (N9). Every difference is tagged. A one-page list of all differences and open items is in [rulebook-deltas.md](rulebook-deltas.md).

No content is defined here: no units, tribes or cards. The mechanics include the owner's own keywords in 11.7, Venomous (11.2.5) and Cleave's change (11.2.7a). Examples use placeholder names, or name an HSBG or Galaxy mechanic to show which rule it tests (chapter 11).

## Legend

Every numbered rule carries exactly one tag:

| Tag | Meaning |
|---|---|
| **[BG]** | Taken from Battlegrounds unchanged. |
| **[BRAMBLE]** | An owner decision that differs from Battlegrounds. The owner's words or the owner note are cited. |
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
| N1 | [sources/2026-10-27-battlegrounds-direction.md](sources/2026-10-27-battlegrounds-direction.md) |
| N2 | [sources/2026-10-27b-board-answers-and-research.md](sources/2026-10-27b-board-answers-and-research.md) |
| N3 | [sources/2026-10-27c-packing-tokens-rows.md](sources/2026-10-27c-packing-tokens-rows.md) |
| N4 | [sources/2026-10-27d-combat-shape-decisions.md](sources/2026-10-27d-combat-shape-decisions.md) |
| N5 | [sources/2026-10-27e-economy-decisions.md](sources/2026-10-27e-economy-decisions.md) |
| N6 | [sources/2026-10-27f-power-budget-decisions.md](sources/2026-10-27f-power-budget-decisions.md) |
| N7 | [sources/2026-11-02-pre-development-design-pass.md](sources/2026-11-02-pre-development-design-pass.md) |
| N8 | [sources/2026-11-02d-refresh-schedule-and-free-refreshes.md](sources/2026-11-02d-refresh-schedule-and-free-refreshes.md) |
| N9 | [sources/2026-11-02e-mechanics-are-examples.md](sources/2026-11-02e-mechanics-are-examples.md) |
| N10 | [sources/2026-11-02f-new-effects-and-goldfish-designers.md](sources/2026-11-02f-new-effects-and-goldfish-designers.md) (the owner's answers on the v0.4 rewrite) |
| N11 | [sources/2026-11-08-autobattler-systems-thoughts.md](sources/2026-11-08-autobattler-systems-thoughts.md) (damage, shop, pool, combining) |
| N12 | [sources/2026-11-08b-taste-answers.md](sources/2026-11-08b-taste-answers.md) (stat scale, taste) |
| N13 | [sources/2026-11-08c-rulebook-go-ahead-and-scaling.md](sources/2026-11-08c-rulebook-go-ahead-and-scaling.md) (go-ahead for the v0.5 changes) |
| C12 | The owner's decision in chat, 12 Nov 2026: damage (10.1.1, 10.1.3), draws (10.1.6) and starting health (2.2.5). No owner note was written; the intent is recorded in 10.1.3. |
| C13 | The owner's decisions in chat, 12 Nov 2026: income (4.1.1), unit prices (4.2.1), sell values (4.3.3, 4.3.4), refreshes (4.4.2, 4.4.3), tier-up prices and discount (4.6.2, 4.6.3) and shop size (6.1.1). No owner note was written. The owner's words, the models and the evidence are in [../research/economy/2026-11-12-economy-and-tier-prices.md](../research/economy/2026-11-12-economy-and-tier-prices.md). |
| C14 | The owner's decision in chat, 16 Nov 2026: hand limit (7.1.1). No owner note was written; the owner's words are quoted in 7.1.1. |
| C15 | The owner's decision in chat, 17 Nov 2026: units move freely between hand and board (7.2.4) and sell from either (4.3.7), and play triggers resolve on recruit (7.2.3). Later that day, answering questions on the project board: recruit effects also resolve for units gained without buying (7.2.6), the Triple Reward comes when the triple forms (7.3.6), and 7.2.5 is accepted. No owner note was written; the owner's words are quoted in those rules. Their words of 15 Nov on what follows from free moving are in [owner-ideas-log.md](owner-ideas-log.md), entries 3 and 4. |
| N14 | [sources/2026-11-19b-tribe-rework-directions.md](sources/2026-11-19b-tribe-rework-directions.md), last section: the owner's answers on the Pigeon and Mouse rework page, 19 Nov 2026 ("I agree with all the designers' picks", and Active as a gold cost and a colon). Its editor note lists the picks (P1–P5, M1–M5); the pitches are [../workstreams/reworks/pitch-pigeon.txt](../workstreams/reworks/pitch-pigeon.txt) and [pitch-mouse.txt](../workstreams/reworks/pitch-mouse.txt). |
| C16 | The owner's decisions in chat, 19 Nov 2026, approving the plan in [../workstreams/third-run/ghost-plan.md](../workstreams/third-run/ghost-plan.md): the shared pool is removed and every card keeps a fixed chance (5.1, 6.1), async play against recorded runs (2.1), and ghosts refilled from bots during development (2.1.8). The owner: "I like the rest of the plan. I approve all of it." No owner note was written; the owner's words are quoted in those rules. |
| C17 | The owner's instruction in chat, 19 Nov 2026: Created units that are real cards sell for money, like Bought units; tokens still sell for 0 (4.3.2–4.3.5). The owner: "You have my permission to just update the rulebook to remove that and notify other sessions that are currently working that that change will come through." No owner note was written; the owner's words are quoted in 4.3.2. |
| Taste | [owner-taste.md](owner-taste.md) (the owner's taste, with worked evidence) |
| BLO | [board-layout-options.md](board-layout-options.md), decision box (Option A, fixed slots, 27 Oct 2026) |
| rules.md | [../research/battlegrounds/rules.md](../research/battlegrounds/rules.md) (HSBG at 36.6.3) |
| keywords.md | [../research/battlegrounds/keywords.md](../research/battlegrounds/keywords.md) |
| patch-history.md | [../research/battlegrounds/patch-history.md](../research/battlegrounds/patch-history.md) |
| Galaxy | [../research/galaxy/rules.md](../research/galaxy/rules.md) and [design-notes.md](../research/galaxy/design-notes.md) |

The owner's words win over this rulebook if they disagree, whether quoted here or in an owner note.

**Words.** This rulebook says *unit* for HSBG's *minion*, *shop* for the *Tavern*, and *tier* for *Tavern Tier*.

## Contents

1. Game overview and global rules
2. Lobby, heroes and matchmaking
3. Turn structure
4. Economy
5. Shop chances, tribes and types
6. Shop offers and Discover
7. Hand, playing units, triples and golden units
8. The board
9. Combat
10. Hero damage and elimination
11. Example mechanics and Bramble keywords
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

**1.2.5** [BRAMBLE] **Stat scale.** As a working value, base stats and effect numbers are about double HSBG's. This is the owner's estimate, and it may change. Not every number has to double. The aim is room to tune effects that scale or get upgraded, so that one improvement isn't a literal doubling of power (N12 §3, §7.2). *Why:* at HSBG's +1/+1, the smallest possible change is about 50% of a stat. So upgrades double power, and cards like Felfire Conjurer had no setting between too strong and useless. If Blood Gems started at 2/2, the first +1/+1 upgrade would add 50% instead of 100% ([owner-taste.md](owner-taste.md) §2.3). *HSBG:* base scale. *Galaxy:* smaller still. *TFT:* hundreds, stepping about 50–60% per level (N11 §2).

Note: content is costed against the [tier guide](tier-guide.md), which is in ratios so it holds at any stat scale (12 Nov 2026). The earlier power budget, built on HSBG-scale numbers, is [archived](../archive/power-budget/ARCHIVED.md) (16 Nov 2026).

---

## 2. Lobby, heroes and matchmaking

### 2.1 Lobby

**2.1.1** [BRAMBLE] **A game of recorded runs.** A game has 8 players: the player and 7 **recorded runs** of other players. A recorded run is one player's whole game, turn by turn: for each turn, the board (with its slots), hand and tier that player took into that turn's fight. Each round, players are paired 1-against-1 (2.3). The owner approved decision 3 of the ghost plan on 19 Nov 2026: "Yeah, we'll go with the async rules you suggested. I like those rules." (C16) *Galaxy:* 6 players, the other 5 recorded runs (Galaxy rules.md §1). *HSBG:* 8 live players.

**2.1.2** [BG] When an odd number of players is alive, one player fights a **ghost**: a copy of the board and tier of the most recently eliminated player. The ghost is assigned at the start of the Recruit Phase. If a player concedes mid-phase, the ghost uses that player's board instead. Damage dealt to the ghost has no effect (rules.md §1).

Note: a recorded run is not a ghost in this sense. Recorded runs take damage and can be eliminated (2.1.4); the ghost of 2.1.2 is only the stand-in for an odd player out.

**2.1.3** [PROPOSED] **Game length limit.** If a game reaches the end of round 50, it ends. Remaining players are placed by hero health plus armor, highest first; ties are broken at random. *Why:* HSBG has a turn limit but its value is unknown (rules.md §1), and an engine needs one.

**2.1.4** [BRAMBLE] **Asynchronous fights.** Bramble has no turn timer. Each player takes their turns at their own pace and fights recorded runs (N7). Each run seat brings the board recorded for that turn of its own run (2.1.5). Run seats also fight each other. All 8 seats begin with the game's normal starting health and armor (2.2.5–2.2.6). The same damage, elimination and placement rules apply to every seat (chapter 10, C16). Duos stay outside v0. Bots appear only as the makers of recorded runs during development (2.1.8). *Galaxy:* opponents are always on your turn, and fights between recorded runs decide their heart damage (Galaxy rules.md §1).

**2.1.5** [BRAMBLE] **A run that ended early.** On every turn after a run's last recorded turn, its seat fights with the last board it recorded (C16). *Galaxy:* the same (Galaxy rules.md §1).

**2.1.6** [BRAMBLE] **Choosing the recorded runs.** The 7 recorded runs are chosen when the game starts, from runs made on the same rules version and of similar strength. A player never meets a run they have already met in the same session (C16). *Galaxy:* "never face the same 'async run' twice in a gameplay session" (Galaxy patch-history.md).

**2.1.7** [BRAMBLE] **What the player sees of the next opponent.** During the Recruit Phase, the player sees who the next opponent is and their health (2.3.3), but not the board they will bring. A player sees the boards only of opponents already fought. *Why:* a recorded run can't adapt to the player; the owner, 9 Nov 2026: "does the active player get to adapt to a ghost that can't adapt to them?" ([sources/2026-11-09a-stat-scale-and-fundamentals.md](sources/2026-11-09a-stat-scale-and-fundamentals.md)). Chosen with the rest of 2.1 (C16).

**2.1.8** [BRAMBLE] **Recorded runs after a change, during development.** While Bramble is in development, the recorded runs are made by bots, and after any change to the rules or cards the whole field of runs is made again from bot games on the new version. The owner, 19 Nov 2026: "I like the idea of repopulating with bots for all of development" (C16).

**2.1.9** [OPEN] **Recorded runs across patches, in the live game.** 2.1.8 holds only in development. In the live game ranked games must not be filled with bots, so a patch can't simply replace the field. The owner, 19 Nov 2026: "we won't have any ghosts if we make an update in the future. Like that rule can only hold in dev, and I don't want to populate ranked games in the future with bots. So we may have to allow the architecture for a player to play against a different patch. And I'm not sure how that would work with utility effects and stuff. And we'd hope to age the old ghosts out very quickly. It's a thorny subject, essentially. ... we need to document that we need a solution long term and look at how other games have done it" (C16). The ghost system is planned to record each run's rules version and a fingerprint of each card it holds, so that this work isn't ruled out later. How other games handle it, and a proposal: `docs/workstreams/third-run/ghost-patches-long-term.md`. *Galaxy:* boards from old patches were filtered out of the async pool after big changes (Galaxy patch-history.md).

**2.1.10** [BRAMBLE] **After the live player is eliminated.** The remaining seats keep fighting until the game ends under the usual rules (10.2.3, 2.1.3). All 8 seats receive a placement (C16).

**2.1.11** [BRAMBLE] **Combat changes to a run seat.** Changes a fight makes to a run seat's units, hand, slots or other recruit state expire after that fight, including effects that say "permanently" (9.1.1). Hero damage and elimination still apply (2.1.4). *Why:* the seat's board comes from its run for each fight (2.1.4–2.1.5).

**2.1.12** [BRAMBLE] **The ghost of an eliminated run seat.** When the most recently eliminated player (2.1.2) is a run seat, the ghost copies the board that seat last fought with. *Why:* that is the board it was eliminated with, as for a live player; its run's board for a later turn was never in this game. 2.1.11 and 2.1.12: The owner, 21 Nov 2026, agreeing with the recommendations put to them: "I agree with the calls."

### 2.2 Heroes

**2.2.1** [BG] Each player chooses one hero from those offered. No hero is offered to two players in the same lobby (rules.md §2).

**2.2.2** [BG] Each player is offered 2 heroes. The hero choice timer is 70 seconds (rules.md §2).

**2.2.3** [OPEN] Whether Bramble offers more hero choices or hero rerolls, and whether any of it is paid. HSBG sells extra choices through its Season Pass, which players criticise as pay-to-win (patch-history.md lesson 8).

**2.2.4** [BG] Heroes whose power depends on a tribe are not offered in lobbies without that tribe (rules.md §2).

**2.2.5** [BRAMBLE] **Starting health.** Heroes start with **40 health** by default (C12). A hero may define a different starting value, as a balance lever (rules.md §2). It goes with the damage values in 10.1.3. HSBG uses 30.

Note: the direction of per-hero adjustments is open. The owner's lean: the strongest heroes get 40 and weaker heroes get more, so adjustments might only ever go up from 40. Lowering the strongest heroes below 40 is still possible (C12).

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

**3.1.2** [BRAMBLE] **No recruit timer.** The Recruit Phase lasts until the player ends it. HSBG gives 60 seconds in round 1, then 15 seconds more each round, up to 120 (rules.md §3). With no timer, the economy has to run out by itself: only the cost of refreshes rises within a turn (4.4), and free and triggered refreshes and gold-spent engines are bounded by content design (content-guardrails.md G1). How many shops a turn sees is tuned by playtesting, and the target will move. With the prices in 4.4, builds will differ, but most long turns should see around 20 shops (N8).

### 3.2 Start of the Recruit Phase

**3.2.1** [PROPOSED] At the start of each Recruit Phase, these steps happen in this order:
1. Gold is set: carried gold, this turn's income (4.1), and any gold earned during the last fight.
2. From turn 2 on, the current upgrade cost drops by the discount for waiting: 1 more than it dropped the turn before (4.6.3).
3. The refresh counter resets to 0 (4.4.4).
4. The shop refills, or keeps its frozen cards and fills its empty slots; the freeze then ends (4.5).
5. Start-of-turn triggers resolve in reading order (1.2.3), followed by player-wide effects.

*Why:* HSBG's exact order isn't documented, and Bramble adds steps 1 and 3. This order lets start-of-turn effects see the new shop and the full gold total.

**3.2.2** [BRAMBLE] **Effects that use the last fight.** Grudge, Relic Seeker and Old Campaigner pay when their owner next starts a Recruit Phase. They use the board that fought and the last fight's result. They pay after a win, loss or tie, even if the unit died. A player needs a previous fight and another Recruit Phase to receive these rewards. Recorded-run opponents skip this phase (2.1). On 20 Nov 2026, the owner said, "I don't really think we should have any end-of-fight effects. Start-of-turn effects would be better." The owner delegated the details, including paying units that died, on 20 Nov 2026.
**3.2.2a** [BRAMBLE] Relic Seeker pays 2 gold plus 1 per unit that outnumbered you last fight (9.2.1, shared rulings 1–5). A golden pays 4 plus 2 per unit (owner's pick, 20 Nov 2026). [PROPOSED] With several Relic Seekers only the highest payout applies, with ties resolved in reading order (agent's default).


### 3.3 During the Recruit Phase

**3.3.1** [BG] During the Recruit Phase a player may take these actions in any order and as often as they can pay: buy, sell, refresh, freeze, upgrade, play a unit or spell from hand, move units on the board (8.3) and between the board and the hand (7.2.4), use the hero power, and use activated abilities (rules.md §5.3). Example: HSBG's Activate.

Note: Bramble's activated abilities are Actives (11.7.1).

### 3.4 End of the Recruit Phase

**3.4.1** [PROPOSED] When the Recruit Phase ends (timer or player ends turn):
1. End of Turn triggers resolve in reading order (1.2.3).
2. Effects that last "this turn" end.
3. Unfrozen shop cards are cleared; with no pool they go nowhere (5.1.1).
4. Unspent gold is kept (4.1.2).
5. The board is copied for combat (9.1.1).

*Why:* HSBG's order is undocumented; the order of End of Turn triggers across units is believed to be left to right (keywords.md §B).

**3.4.2** [BG] Units in hand don't fight and don't count as being on the board (rules.md §5.3).

### 3.5 Combat Phase

**3.5.1** [BG] Each paired player's board fights its opponent's board (chapter 9). After all fights, damage is dealt (chapter 10), eliminations are checked, and the next round starts.

---

## 4. Economy

### 4.1 Gold

**4.1.1** [BRAMBLE] **Income.** A player gains 5 gold on turn 1. Income rises by 2 a turn until it reaches 15, then by 1 a turn, with no ceiling. In the owner's words: "Let's go with the Plus 2 income per turn. Let's say that once you get to 15 total income, it increases by 1 per turn after that" (C13). *HSBG:* 3 on turn 1, +1 a turn, up to 10 from turn 8.

| Turn | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11+ |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Income | 5 | 7 | 9 | 11 | 13 | 15 | 16 | 17 | 18 | 19 | +1 a turn |
| Total so far | 5 | 12 | 21 | 32 | 45 | 60 | 76 | 93 | 111 | 130 | |

**4.1.2** [BRAMBLE] **Carry-over.** Unspent gold carries over between turns. At the start of each Recruit Phase, a player's gold is the gold they had left at the end of the last one plus this turn's income. HSBG discards unspent gold (N1 §2.1).

**4.1.3** [BRAMBLE] **No cap, no interest.** There is no limit on how much gold a player can hold, and holding gold earns nothing. HSBG resets gold to at most 10 each turn (N2 §3).

**4.1.4** [PROPOSED] Effects that raise or lower "maximum gold" change the player's income from 4.1.1 by that amount, not a holding cap. *Why:* in HSBG maximum gold is both the refill and the cap. Bramble has no holding cap and no income ceiling, so only the income meaning is left.

**4.1.5** [BG] Gold can't go below 0. An action that costs more gold than the player has can't be taken.

**4.1.6** [BG] Other gold comes only from selling (4.3), card effects and hero powers (rules.md §4).

### 4.2 Buying

**4.2.1** [BRAMBLE] **Unit price.** A unit costs its tier + 1 in gold: 2 at tier 1, up to 7 at tier 6. The owner: "Units are going to cost 1 plus their tavern tier" (C13). The bought unit goes to the player's hand (rules.md §5.3). *HSBG:* every unit costs 3.

**4.2.2** [BG] A player with a full hand can't buy (uncertain in HSBG — see rules.md §5.3).

**4.2.3** [BG] Buying a unit leaves its shop slot empty until the shop next refills.

**4.2.4** [BG] Buying is allowed when the board is full, because the unit goes to hand. A unit can't be played from hand while the board has no empty slot (7.2.2).

**4.2.5** [BG] Tavern spells in the shop are bought for their own listed cost and go to hand (6.1.5).

### 4.3 Origin and selling

**4.3.1** [BRAMBLE] **Origin.** Every unit is either **Bought** or **Created**. A Bought unit was taken from the shop by paying for it. A Created unit came any other way: summoned, generated, copied, transformed into, or given by an effect ("get", "add to your hand"). Tokens are Created. HSBG makes no such distinction for selling (N1 §2.2).

**4.3.2** [BRAMBLE] A unit that an effect gives without payment, such as a Discover pick or the Triple Reward, counts as **Created**. A Created unit that is a real card, one the shop can offer (a Discover pick, the Triple Reward, a copy of a card), sells for the same as a Bought unit (4.3.3); a **token** sells for 0. The owner, 19 Nov 2026: "all of our spells currently, due to the rule that units sell with zero gold, which I'm probably going to change ... update the rulebook to remove that ... I think created units seem *[probably "should"]* to sell for money because elsewhere, those spells, you know, that anything that discovers a unit just feels very, very, very underpowered" (C17). The owner, 19 Nov 2026, later the same day: "it's just for discovered units. Like, tokens, I think, are a separate type of card. They're like things that are summoned during shop. They're not like a copy of an existing card. ... When you discover a card from a triple reward or from a spell, it's a real card. A token is not a real card, it's a token" (C17). This replaces the 27 Oct rule that anything the player didn't pay for sells for 0 (N5 §8). *HSBG:* every unit sells for 1.

**4.3.3** [BRAMBLE] **Sell value.** Selling a unit that is a real card, Bought or Created, gives half its tier in gold, rounded up: 1 at tiers 1–2, 2 at tiers 3–4, 3 at tiers 5–6. Selling a token gives 0 gold. Until 19 Nov 2026 every Created unit sold for 0 (4.3.2, C17). The owner: "Let's change it so units sell for half its tier rounded up" (C13). *HSBG:* every unit sells for 1.

| Tier | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| Costs | 2 | 3 | 4 | 5 | 6 | 7 |
| Sells for | 1 | 1 | 2 | 2 | 3 | 3 |
| Gold lost on a sale | 1 | 2 | 2 | 3 | 3 | 4 |

**4.3.4** [BRAMBLE] A golden unit made by a triple sells for the sell value of 4.3.3 for each of its copies that is a real card, Bought or Created. The owner: "a triple of a 5 would actually sell for 9, not 8", and tokens "don't increase the sell price, even if they're combined into a triple" (C13). A golden made only from tokens sells for 0. This replaces the 27 Oct rule that a tripled golden always sells for 1 (N3).

**4.3.5** [BRAMBLE] Any other merge of units makes a Bought unit if at least one of the merged units was Bought (N3: a created unit that "merges with a real unit"). Since 19 Nov this changes the sell value only for a token, which then sells as a real card (4.3.3, C17). Example: HSBG's Magnetic.

**4.3.6** [PROPOSED] Origin stays with the unit when it moves between hand and board, and when an effect transforms it or makes it golden without a triple. A Created unit made golden by an effect stays Created. *Why:* the owner's exception covers tripling and merging, not every upgrade, and tying sell value to the triple keeps the rule easy to read.

**4.3.7** [BRAMBLE] A unit can be sold from the board or from the hand, for the same value. In the owner's words (17 Nov 2026): "you could sell from either the hand or the board" (C15). A unit sold from the board leaves its slot, which becomes empty. *HSBG:* only minions on the board can be sold (not in rules.md).

**4.3.8** [BG] Card text can change a unit's sell value (rules.md §5.3).

### 4.4 Refresh

**4.4.1** [BG] **Refresh** replaces every card in the shop with new ones, drawn by the shop's chances (5.1.2). Refreshing a frozen shop also unfreezes it (rules.md §5.3; unfreezing not in rules.md).

**4.4.2** [BRAMBLE] **Escalating cost.** A refresh costs 1 gold for the first 10 paid refreshes of a turn. After that its cost rises by 1 gold every 5 paid refreshes, with no cap. The owner: "change the refreshes to the first 10… And then after that, they go up… one every 5, like before" (C13). HSBG refreshes always cost 1 (N1 §2.3).

**4.4.3** [BRAMBLE] **Steps.** Paid refreshes 1–10 of a turn cost 1, 11–15 cost 2, 16–20 cost 3, 21–25 cost 4, and so on. The first step (after 10) and the step length (5) are tunable parameters (Appendix A). This replaces the 2 Nov schedule of 15 at 1 gold, then +1 every 5 (N8, C13).

**4.4.4** [BRAMBLE] The refresh count resets to 0 at the start of each turn (N2 §3).

**4.4.5** [BRAMBLE] **Free refreshes** granted by effects cost no gold and **don't** count toward the thresholds. Only paid refreshes escalate (N5 §10).

**4.4.6** [PROPOSED] A card effect that replaces the shop's cards directly ("refresh the shop") costs nothing and doesn't count toward the thresholds. Only the player's paid Refresh action counts (4.4.5). *Why:* effect-driven rerolls are costed into the card that causes them; counting them would make cards punish the player's own refreshes.

**4.4.7** [BG] There is no limit on the number of refreshes beyond their cost (rules.md §5.3). The owner chose not to cap free refreshes either. Repeatable free-refresh loops are prevented by content design instead (content-guardrails.md G1; N6).

### 4.5 Freeze

**4.5.1** [BG] Freezing is free and toggles the shop between frozen and unfrozen, up to 5 times per Recruit Phase (rules.md §5.3).

**4.5.2** [BG] At the start of the next Recruit Phase, a frozen shop keeps its cards and only its empty slots refill. If it already holds as many cards as its size, spells included, it gets no extra units (rules.md §5.2).

**4.5.3** [BG] The freeze ends once the shop has refilled at the start of the turn (not in rules.md).

Rule 4.5.4 (frozen cards stay out of the pool) was removed in v0.10: with no pool (5.1.1), a frozen shop holds nothing back from anyone. The number is not reused.

### 4.6 Tiers and upgrading

**4.6.1** [BG] Shop tiers run from 1 to 6. Each player starts at tier 1. Tier 7 can be reached only through specific effects (rules.md §5.1).

**4.6.2** [BRAMBLE] **Upgrade costs.** The base cost to upgrade to each tier is:

| Upgrade to | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|
| Base cost | 8 | 12 | 16 | 19 | 26 |

The owner chose these from simulated lobbies: "8, 12, 16, 19, 26" (C13). *HSBG:* 5, 7, 8, 11, 11 (rules.md §5.1, Solo since 34.2).

**4.6.3** [BRAMBLE] **Discount for waiting.** At the start of each Recruit Phase from turn 2 on, the current upgrade cost drops by 1 more than it dropped the turn before: 1 after one turn waited, then 2, 3, 4 and 5, to a minimum of 0. Over 1 to 5 turns waited, the total discount is 1, 3, 6, 10 and 15. The owner: "1, then 2, then 3, then 4, then 5" (C13). *HSBG:* 1 a turn.

| Upgrade to | Now | 1 turn waited | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| 2 | 8 | 7 | 5 | 2 | 0 | 0 |
| 3 | 12 | 11 | 9 | 6 | 2 | 0 |
| 4 | 16 | 15 | 13 | 10 | 6 | 1 |
| 5 | 19 | 18 | 16 | 13 | 9 | 4 |
| 6 | 26 | 25 | 23 | 20 | 16 | 11 |

**4.6.4** [BRAMBLE] After an upgrade, the cost resets to the base cost of the next tier, and the discount starts again from 0. The owner: "The discount should reset back to 0" (C13). A player may upgrade more than once in a turn if they can pay, as in HSBG.

**4.6.5** [BG] Upgrading doesn't refill the shop. Draws made after the upgrade use the new tier (not in rules.md).

**4.6.6** [PROPOSED] After 5 turns waited, the discount stays at 5 a turn: 20 off after 6 turns, 25 after 7. *Why:* the owner's list ends at 5, and stopping the growth there keeps a long wait from paying ever more.

Note: **design intent.** A player who waits on a tier gets gold back for the turns spent without higher-tier units. The owner: "staying multiple turns on one tavern tier needs to be given some money back in return. That's what it's for" (C13). Upgrading 2 turns in a row costs nearly full price, so it means saving or giving up buys. In simulated lobbies these prices gave:
- most players reaching tier 5, around turn 7–8;
- about 2 players a lobby reaching tier 6, around turn 14, almost all of them in the top four;
- rushing to tier 6 losing.

The results rest on guessed unit power, scaling and economy units. Recheck them once real units exist: [../research/economy/README.md](../research/economy/README.md).

---

## 5. Shop chances, tribes and types

### 5.1 Shop chances

**5.1.1** [BRAMBLE] **No shared pool.** Bramble has no shared, copy-limited pool. Nothing is taken out when a card is offered, bought or Discovered, and nothing is returned when it is sold, refreshed away, used up or its player is eliminated. Any number of players can hold any number of copies of a card. The owner, 19 Nov 2026: "I want that removed because ... having a minion pool doesn't make sense for async play when you can't adjust." (C16) This settles the old 5.1.4 (a pool, or set chances; N11 §5.5) and replaces the 27 Oct choice of HSBG's pool mechanics (N2 §4). *HSBG:* one shared pool per lobby with copy counts (rules.md §6).

**5.1.2** [BRAMBLE] **Fixed chances.** Each card has a fixed weight, set by its tier, and the weights never change during a game. They are the copy counts HSBG's pool starts with, so every card keeps the chance it had on turn one under the old pool (C16):

| Tier | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|
| Weight of each unit | 15 | 15 | 13 | 11 | 9 | 7 | 5 |
| Weight of each Tavern spell | 5 | 7 | 9 | 11 | 9 | 7 | — |

Note: this keeps the draws the bots and the balance work learned. Whether chances should lean toward the player's tier is still open (6.1.7).

**5.1.3** [BG] Only units that have at least one of the lobby's tribes, plus neutral units, can be offered. A unit with several tribes can be offered if any one of them is in the lobby (rules.md §7).

Rule 5.1.4 (a pool, or set chances) was removed in v0.10: 5.1.1–5.1.2 settle it. The number is not reused.

### 5.2 Tribes and types

**5.2.1** [BRAMBLE] **Type line.** Every unit has a type line of one or more types, in the style of Magic: The Gathering creature types, e.g. "Owl Warrior" or "Squirrel Archer". HSBG units have zero, one or two tribes and nothing else (N1 §5).

**5.2.2** [OPEN] **Which types are tribes.** A tribe is a type that the lobby builder uses to include or exclude units. Undecided: whether tribes are the species words, a separate faction word, or some other subset of types. Fairies and oozes will exist as kinds of creature (N1 §6); how they map to tribes is undecided.

**5.2.3** [PROPOSED] **Type matching.** Card text that names a type ("your Owls") applies to every unit that has that type anywhere on its type line. A unit with the "All" type has every tribe. *Why:* this is the Magic rule the owner pointed to, and it matches HSBG's dual-type and "All"-type units (rules.md §7).

**5.2.4** [BG] **Tribes per lobby.** Each lobby uses a random subset of the tribes in rotation. HSBG uses 5 of 10 (rules.md §7). The owner confirmed the subset rule (N1 §4).

**5.2.5** [OPEN] How many tribes are in rotation and how many are in each lobby.

**5.2.6** [BG] The lobby builder applies exclusion rules: pairs of tribes that can't share a lobby, units banned with a tribe, and heroes banned without one (rules.md §7; patch-history.md lesson 5).

**5.2.7** [BG] Units with no tribe (neutral) can always be offered (rules.md §7).

**5.2.7a** [BRAMBLE] The shared units enter every lobby’s shop with the same per-card weight as a tribe unit of their tier (owner's pick, 20 Nov 2026).

**5.2.8** [OPEN] Whether to add a TFT-style trait system on top of types. The owner is leaning no (N1 §5). v0 has none.

### 5.3 Units leaving and returning to the pool

Removed in v0.10. Rules 5.3.1–5.3.8 described copies leaving and returning to the shared pool. With no pool (5.1.1), nothing leaves or returns. The numbers are not reused.

---

## 6. Shop offers and Discover

### 6.1 The shop

**6.1.1** [BRAMBLE] **Shop size.** The shop shows **5 units and 2 spells at every tier**. Tiers change only the odds of what appears (6.1.7), not the number of offers. The owner: "I want the shop to always have 5 units and 2 spells… It will not change with tier. What will change is the shop odds and the chances of finding effects of specific rarities" (C13). This settles the shop-size experiments of N11 §5.2 (3 to 7 cards, fixed or growing). The owner, 13 Nov: "Yes, it's settled" (C13).

Note: 7 offers at once is up from the earlier working value of 5 cards, 1 of them a spell, so the shop layout needs checking. N11 §5.2 noted that seven at once can feel overwhelming. Fewer offers push design toward generally useful units, which costs asymmetry and strategic variety. *HSBG:* grows with tier (rules.md §5.2):

| Tier | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| Cards | 4 | 5 | 5 | 6 | 6 | 7 |
| of which units | 3 | 4 | 4 | 5 | 5 | 6 |

Note: with a fixed shop, upgrading a tier gives access to higher-tier units but no extra slots. In HSBG it also adds slots.

**6.1.2** [BRAMBLE] Shop units are drawn from units of the player's tier or lower, by the fixed chances of 5.1.2 (C16). *HSBG:* units with fewer copies left appear less often (rules.md §5.2).

**6.1.3** [BRAMBLE] **Draw algorithm.** Each unit offer is one draw among the eligible units (5.1.3, 6.1.2), each with a chance proportional to its weight (5.1.2). Draws are independent, so a shop can show the same unit twice. This is the same as drawing one copy from a full HSBG pool that never runs down (C16). The draw is one instance of the owner's flexible "pick N from a pool" building block, so it can be swapped later (N1 §7). *Galaxy:* weights draws towards higher rarity instead.

**6.1.4** [PROPOSED] If no unit is eligible for a shop slot, that slot stays empty. With fixed chances this happens only if a lobby has no units at all at the player's tier or lower. *Why:* an engine needs an answer; HSBG's isn't documented.

**6.1.5** [BG] **Tavern spells.** The shop's spell slots (6.1.1) each offer a spell of the player's tier or lower. Spells have their own costs, go to hand, are cast in the Recruit Phase, are single use and can't triple. A frozen spell stays frozen (rules.md §8).

**6.1.6** [OPEN] **Shop slots as their own upgrade.** The owner's idea: extra shop slots as something a player can invest in separately, not tied to tier or anything else (N11 §5.3). It's undecided whether to add it.

Note: the owner's general rule for upgrades (N11 §5.7) is not to bundle two things a strategy may want separately. TFT's levelling gives board space and better shop odds together, and reroll comps want the first without the second. Bramble's board is fixed at 7 (8.1.1), and a limit that grows with level is not planned, though the owner hasn't ruled it out (N11 §5.8).

**6.1.7** [OPEN] **Tier weighting.** Two options:
- **Flat, as now:** draws stay proportional to the fixed weights (5.1.2, 6.1.3), as in HSBG at the start of a game. At tier 6, about a third of HSBG's shop slots are tier 1–2 units, which the owner sees as late-game noise ([owner-taste.md](owner-taste.md) §2.2).
- **Weighted toward the player's tier, as in TFT:** Galaxy similarly weights toward higher rarity. The cost is that a specific low-tier unit becomes hard to find late, so levelling has a real cost for some strategies (N11 §5.4).

Linked: 5.1.2. The owner's 19 Nov choice kept today's flat chances and left this open (C16).

Note: on 12 Nov the owner leaned toward TFT-style rarities, and asked to come back to the shop odds after the economy (C13). The economy sims used a TFT-like table, given in [../research/economy/2026-11-12-economy-and-tier-prices.md](../research/economy/2026-11-12-economy-and-tier-prices.md) §2. Its tier-6 row is 7/13/22/27/21/10 % per slot. It is a working assumption, not a decision.

### 6.2 Discover

**6.2.1** [BG] **Discover** offers a choice of 3 units, and the player takes 1 to hand. Options are drawn by the fixed chances (5.1.2), respect the lobby's tribes, and use the tier the effect names ("from tier X", "of your tier or lower", "next tier") (rules.md §10).

**6.2.2** [BG] The 3 options are different units (uncertain in HSBG — see rules.md §10).

**6.2.3** [PROPOSED] If fewer than 3 different units are eligible, Discover offers as many as there are. With none, the effect does nothing. *Why:* engine edge case; not documented in HSBG.

---

## 7. Hand, playing units, triples and golden units

### 7.1 Hand

**7.1.1** [BRAMBLE] The hand holds up to 7 cards. In the owner's words (16 Nov 2026): "I don't see any reason now that we've changed the UI it can't go to 7. I think 7's a good fit." (C14) *HSBG:* 10 (uncertain in HSBG — see rules.md §5.3).

**7.1.2** [BG] A card gained while the hand is full is lost, unless the effect says it waits for space (uncertain in HSBG — see rules.md §5.3; keywords.md §C). Example: HSBG's Spellcraft.

### 7.2 Playing a unit

**7.2.1** [BRAMBLE] Playing a unit from hand puts it into **any empty slot the player chooses**, front or back. In HSBG the player picks a position in a single packed row (BLO; N3).

**7.2.2** [BG] A unit can't be played when the board has no empty slot, i.e. 7 units are on it. A unit that merges into another unit instead of taking a slot is the exception (rules.md §5.3). Example: HSBG's Magnetic (11.4.1).

**7.2.3** [BRAMBLE] **Recruit effects, not play effects.** Bramble's equivalent of a "when played" effect resolves when the unit is recruited, that is bought (4.2.1), not when it is played. Playing a unit from hand triggers nothing by itself, so a unit that returns to hand and is played again (7.2.4) repeats nothing. In the owner's words (15 Nov 2026, [owner-ideas-log.md](owner-ideas-log.md), entry 4): "So I think our battlecry effect should be on recruit rather than on play, our equivalent." The owner confirmed it as decided on 17 Nov 2026 (C15). Example: Galaxy's Recruit (11.6.4). *HSBG:* a played minion is placed first, then its Battlecry resolves (11.3.1).

**7.2.4** [BRAMBLE] **Back to hand.** During the Recruit Phase a player may move a unit from the board back to hand and play it again, for free and any number of times. In the owner's words (17 Nov 2026): "Units could move freely between the hand and the board, unlike in Battlegrounds." (C15) *HSBG:* a played minion can't return to hand, except by a card effect.

**7.2.5** [BRAMBLE] A unit can't be moved back to a full hand (7.1.1). A unit keeps its stats, buffs and origin (4.3.6) when it moves between hand and board. Proposed as a default on 17 Nov 2026; the owner accepted it that day ("Yes.", C15).

**7.2.6** [BRAMBLE] A recruit effect (7.2.3) also resolves for a unit gained without buying it: a Discover pick, a Triple Reward, a unit an effect adds to hand. The owner, asked on 17 Nov 2026 "Does a recruit effect fire for a unit you didn't buy?": "Yes." (C15)

Note: free moving lets a player take a unit off the board once it has paid out, or put it on only when it pays. The owner's direction for units that give an advantage during the Recruit Phase is a keyword that locks them onto the board for the turn ([owner-ideas-log.md](owner-ideas-log.md), entries 3 and 4). It has no name and is not a rule yet.

Note: the direction summary's open question 5 assumed bought units go straight to the board. This rulebook keeps HSBG's hand (4.2.1), because merges, Discover and triples all depend on it.

### 7.3 Triples

**7.3.1** [BG] When a player holds 3 copies of the same non-golden unit across board and hand, they combine at once into one golden copy in hand. Copies that were on the board leave their slots, which become empty (rules.md §9).

**7.3.2** [BG] Triples form only in the Recruit Phase. When several units are summoned together, all of them finish arriving before any triple forms (rules.md §9, patch 19.6).

**7.3.3** [BG] Created copies count toward triples (rules.md §9).

**7.3.4** [BG] **Golden stats.** The golden unit has double the base stats and keeps every buff and debuff from the three copies. Attack and Health are each at least the golden base value (rules.md §9).

**7.3.5** [BRAMBLE] **Golden signature.** A golden unit doubles its base stats (7.3.4) and its signature, the effect a player buys it for. A signature number doubles. An action with no number happens twice or applies to twice as many units. Charge can provide the extra uses when it is how the signature action repeats. A small side number may also double when its cost in power is low. An effect can double its magnitude or its frequency, with the other staying as printed. Multipliers and repeat counts rise by one step, so “twice” becomes “three times.” Thresholds, costs and per-fight caps written into an effect stay as printed. A keyword's number doubles like any other number (Thorns 8 becomes 16, Fury 1 becomes 2). That includes Charge N and Pile on N, even where the effect's own number doubles too: shown that a golden Flying Ace would gain four times the Renown, the owner said "Double them too" (20 Nov). Supply N is the open case in 7.3.5a. A golden never changes how a keyword works: no extra returns, no "twice each fight". A keyword without a number, such as Guard, stays as it is, so some goldens gain less than others; the owner: "Not all goldens need to be balanced, but all base cards should be" ([owner note, 20 Nov](owner-notes/2026-11-20b-goldens-keep-keywords-working.md)). A card may break the rule for the rule of cool, and its golden text states the effect. Per-card golden values live in card data. Decided by the owner's delegation on 20 Nov 2026. In the owner's words, “They double the coolest effect on the card.”

**7.3.5a** [PROPOSED] A golden keeps Supply N as printed: a triple adds the three copies' remaining Supply (11.7.5) and doesn't double it. An Active's cost and a cost such as Root N never double. *Why:* a triple already brings three copies' Supply. The owner's "Double them too" (7.3.5) named Charge and Pile on, not Supply.

**7.3.6** [BRAMBLE] **Triple Reward.** When a triple forms, a Triple Reward spell is added to hand: Discover a unit from the tier above the player's current tier, or tier 6 if the player is at 6. Playing the golden unit gives nothing more. In the owner's words (17 Nov 2026): "Triples occur on recruit, not on play." (C15) *HSBG:* the reward comes when the golden minion is played (tier used at cast is uncertain in HSBG — see rules.md §9).

**7.3.7** [PROPOSED] If a triple forms while the hand is full and all three copies were on the board, the golden goes into the vacated slot that comes first in reading order. *Why:* engine edge case; with Created copies counting, three board copies and a full hand is reachable.

**7.3.8** [OPEN] **Multiple-copy strategies.** It's undecided whether Bramble supports strategies built on finding many copies of one unit, like TFT's 1-, 2- and 3-star levels, or keeps HSBG's single triple (N11 §5.6). The owner notes that a combining system is tied to the shop, the pool and the power jump per step. HSBG's doubling leaves no room for a level above golden, while TFT's ~60% steps allow three levels (N11 §6).

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

**8.3.3** [PROPOSED] **Moving.** During the Recruit Phase a player may move a board unit to any empty slot, or swap two board units, for free and any number of times. Moving a unit on the board triggers nothing. Moving between the board and the hand is 7.2.4. *Why:* HSBG lets players reorder freely (rules.md §5.3); fixed slots turn reordering into moving and swapping.

**8.3.4** [BRAMBLE] **No packing.** Units never slide to fill a gap, in the Recruit Phase (after selling or a triple) or in combat (after a death) (BLO, Option A; N3).

**8.3.5** [PROPOSED] Units change slots only through the player's moves (8.3.3) or effects that say so. An effect that would move a unit into an occupied slot fails, unless it says "swap". *Why:* keeps position text reliable.

### 8.4 Summon placement

**8.4.1** [BRAMBLE] **Dead unit's slot first.** (N4 §4) When a unit's own death effect (text like "when this dies, summon…") or return effect (9.7.2) puts units on the board, the first one goes into the dying unit's slot if that slot is empty. *Why:* fixed slots give summons a natural home (BLO). *HSBG:* death-effect summons appear where the minion died (rules.md §11.7). *Galaxy:* a death effect's first summon takes the KO'd character's slot. Examples: HSBG's Deathrattle and Reborn; Galaxy's Farewell.

**8.4.1a** [PROPOSED] King Speck summons a Cousin in the exact slot an allied Mouse died in, at 9.7.2 step 3. If the slot is occupied, the effect does not spend a charge or summon. The Cousin starts with the dead Mouse's own Attack this fight (11.7.13) and its normal token Health, 4 if golden. Agent's default for the owner's 20 Nov 2026 picks.

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

**8.4.5** [BRAMBLE] (owner's pick, 20 Nov 2026) If the board has no empty slot, the summon fails. Each Hopper that fails this way gives its player Tide +1 immediately, in the Recruit Phase or in combat. Other summons, including Elder Mother's Compost copies, are lost. [PROPOSED] A failed summon does not trigger effects that listen for a summon (agent's default).

**8.4.6** [PROPOSED] Card text that names a slot ("summon into the slot behind this") overrides 8.4.1–8.4.3. If the named slot is full, the summon fails. *Why:* lets position-based cards be precise.

**8.4.7** [PROPOSED] These placement rules apply in the Recruit Phase and in combat alike. A unit summoned in the Recruit Phase stays on the recruit board and is Created (4.3.1). *Why:* one placement rule for both phases is easier to learn and to implement.

### 8.5 Slot effects

Note: the owner wants the rules to let Bramble experiment with slot effects, which fixed slots make possible (N9).

**8.5.1** [PROPOSED] **Slot effects.** A board slot can hold effects that apply to whatever unit is in it. They stay on the slot when units move, swap, are sold, die or are replaced. An empty slot's effects do nothing until a unit enters. Example: Galaxy's slot buffs.

**8.5.2** [PROPOSED] Slot effects are part of the board: they are copied into combat (9.1.1) and into the recorded runs others fight (2.1.1). A change made in combat lasts that combat unless it says permanently.

**8.5.3** [PROPOSED] Slot effects last as their text says (chapter 12); with no duration they last the game.

Note: Renown (11.7.6) is a slot effect with its own rules: it reaches only some units, and Renown gained in a fight counts from the next fight instead of lasting that fight (8.5.2). It replaces the Pigeons' slot buffs. Bramble's slot effects are now the Guard post and Renown: stored Attack and Health on a slot (slot buffs) were retired from the game on 19 Nov 2026, once no card gave them (the Pigeon and Mouse reworks; build plan S9).

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

**9.6.1** [BRAMBLE] An attack resolves in this order. Skipping hits on dead units and ending a dead unit's actions is the owner's (20 Nov 2026), and so is the strike back: a defender killed by the attacker's hit still hits back, Venomous included (owner, 20 Nov 2026, choosing "Yes, both hits land"). The order within steps 2–3 and a skipped Hit or splash being lost are [PROPOSED] agent defaults.
1. The defender's "when attacked" effects.
2. The attacker's "whenever this attacks" effects, then its allies hear the attack. Queued pile-on Hits resolve in the order queued. Each Hit checks that both its source and its chosen target are alive.
3. Damage exchange. If both units are alive when this step begins, they commit damage equal to their Attack to each other. Resolve the attacker's direct damage and its effects (including Overrun), then the chosen Cleave splash, then the defender's committed strike back, which keeps its own damage effects (Venomous) even if the defender died to the attacker's hit, since the two hits are one exchange (owner, 20 Nov 2026). Skip damage aimed at a unit already dead and skip splash from a dead attacker. A skipped splash or Hit keeps its original target and is lost.
4. The living attacker's "after this attacks" effects.
5. Death resolution (9.7).
6. "After an attack" effects of player-level modifiers.

If either combatant dies in step 1, go straight to the death step. If either dies in step 2, skip the exchange. A surviving attacker still resolves its "after this attacks" effects when a pile-on kills the defender.

**9.6.1a** [PROPOSED] An attack that takes no damage protects its attacker from before step 1 through step 5. Hedge Lancer's first attack each fight is protected (first two when golden), whether in turn or out of turn. Tourney Champion's start-of-fight attacks are protected. Agent's default for the owner's 20 Nov 2026 picks.

**9.6.2** [BG] In the damage exchange, the attacker's damage triggers resolve before the defender's (rules.md §11.5, standard Hearthstone).

**9.6.2a** [PROPOSED] For “only attacks can damage this,” both participants in the direct damage exchange can deal damage. Hits, Thorns, Cleave splash, Overrun carry and other effects deal zero. A destroy still works (agent's default for the owner's 20 Nov 2026 picks).

**9.6.3** [BRAMBLE] **Health and death.** A unit's Health is its maximum Health minus damage taken. It dies as soon as its Health reaches 0 or less or it is destroyed. Its auras end immediately. Skip Hits, damage and destruction aimed at a dead unit, and skip its attacks, pile-ons, Hits and other triggers. Its own death effects and any return resolve in the death step. At each death check, all dead units still on the board enter the same batch (9.7).

“A unit shouldn't be hit again if it's already been killed” and “dying units should not be able to perform any actions they're dead” (owner, 20 Nov 2026).

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

**9.7.2a** [PROPOSED] After the killer's own kill effects in step 1, its allies hear the kill. The killer is credited even if it also died. Wing Commander counts each kill by a friendly Pigeon with Sortie, including granted Sortie and its own kills, and awards Renown to the killer's slot for the next fight (11.7.6). Wing Commander's text is the owner's pick (20 Nov 2026); this timing is the agent's default.

**9.7.2b** [BRAMBLE] “The unit that killed it” is the source of the first damage that reduced its Health to 0 or less, or the first effect that destroyed it, from either row (owner, 20 Nov 2026). A dead killer still gets credit and living allies can hear the kill. Only a living killer runs its own kill effects. A death effect that targets the killer needs a living killer from that death.

**9.7.3** [PROPOSED] **Order of dying units.** The active side's dying units resolve first, then the other side's. Within a side, they resolve in reading order. The active side is the side whose unit is attacking, or, outside an attack, the side whose effect caused the deaths. *Why:* HSBG resolves left to right within a side, but which side goes first is unknown and the simulator picks at random (rules.md §11.6). A fixed rule is easier to read and to test.

**9.7.4** [BG] **Death counters.** A death counter counts friendly deaths in this combat and fires each time the count reaches a multiple of its number (repeat behaviour uncertain in HSBG — see keywords.md §B). Example: HSBG's Avenge (X).

### 9.8 Summons in combat

**9.8.1** [BG] Units summoned in combat can attack in that combat; they join the attack order where they land (rules.md §11.3). Where they land is set by 8.4, and when they attack by 9.4.8.

**9.8.2** [BG] **Returns.** A unit that comes back after dying returns as a fresh copy of its card with no buffs. A golden unit stays golden. Its Health, and whether it can return again that combat, are set by the effect (rules.md §11.8). Example: HSBG's Reborn returns with 1 Health and can't return again that combat.

**9.8.3** [PROPOSED] A returning unit goes back to its own slot if it is empty. If a summon from its own death effect took that slot, it goes to the nearest empty slot (8.4.2). *Why:* returns resolve after death effects (9.7.2), so the slot may be taken; the nearest-slot rule keeps it close. Example: HSBG's Reborn.

**9.8.4** [BG] Units summoned in combat are combat-only and disappear after combat, unless an effect says otherwise (rules.md §11).

### 9.9 End of combat

**9.9.1** [BG] Combat ends when, after death resolution, one or both boards are empty, or when neither side has a unit that can attack (rules.md §11.9, §11.3).

**9.9.2** [BG] If exactly one board has units left, that side wins. If both boards are empty, or neither side can attack, the fight is a **tie** and nobody takes damage (rules.md §11.9).

### 9.10 Runaway limits

**9.10.1** [PROPOSED] **Attack limit.** A combat ends after 200 attacks in total (both sides, extra attacks included). It ends as a tie. *Why:* HSBG's client limit is unknown; the simulator stops at 400 attacks (rules.md §11.3). A tie is the HSBG-style result. *Galaxy:* gives the win to the active player instead, which suits its async play.

**9.10.2** [PROPOSED] **Trigger limit.** A combat ends as a tie after 10,000 trigger resolutions. In the Recruit Phase, one player action stops resolving new triggers after 1,000. *Why:* catches loops that don't involve attacks; HSBG and Galaxy both patched loops one card at a time (patch-history.md lesson 2).

**9.10.3** [PROPOSED] **Return limit.** The same unit can come back after dying (any return or resummon effect) at most 5 times in one combat; further returns fail. *Galaxy:* caps resummons at 5 per character. *HSBG:* capped two looping cards at 30 loops in 30.0.2 (rules.md §11.3). Example: HSBG's Reborn.

---

## 10. Hero damage and elimination

### 10.1 Damage

**10.1.1** [BRAMBLE] **Small and big losses.** The loser of a fight takes the round's loss damage (10.1.3). The loss is:
- a **small loss** if the loser killed at least half of the winner's starting units (10.1.2), that is, if kills × 2 ≥ starting units;
- a **big loss** otherwise. A big loss deals **3 more** than a small loss.

Examples: against 7 starting units, a small loss needs 4 kills. Against 3, it needs 2. Against 2, it needs 1. The tiers of units and the winner's tier don't count (C12).

*Why:*
- **The owner's reasons for measuring the fight, not tiers** (N11 §4.1–4.5):
  - HSBG's formula punishes the loser for the *tier* of the units left alive, which says nothing about how close the fight was.
  - Every HSBG damage cap treated the symptom.
  - Damage should reflect having a chance to win and killing enemy units.
- **Why two levels instead of 1 per surviving unit (C12).** Late in an HSBG game, a loss is almost always 15 or 0. The owner wants damage that is less binary and more predictable. A count of surviving units is a poor measure of how the fight went, and tokens warp it. "Did you kill half their starting board or not" is easy to read and can't be stacked by a wide board.
- *HSBG:* winner's tier + total tier of surviving units, capped (rules.md §12).

**10.1.2** [PROPOSED] **Starting units.** A starting unit is one on the winner's board when combat begins, before any Start of Combat effect. Golden units count as 1, like any other.
- A starting unit counts as **killed** unless it is alive on the winner's side at the end of the fight.
- A starting unit that dies and returns (9.8) and is alive at the end is not killed.
- A starting unit that ends the fight on the loser's side counts as killed.
- Units summoned or created during combat never count, on either side. A unit the winner takes from the loser during combat isn't one of the winner's starting units.

*Why:* starting units stop combat summons from changing the result (N11 §4.5). Tokens played before combat are starting units like any other; the half-board test keeps them from adding damage beyond the +3. A return is the same unit coming back, not a new body, and returns are capped (9.10.3).

**10.1.3** [BRAMBLE] **Loss damage by round.** A small loss deals **the round number + 1, up to 10**. A big loss deals 3 more (C12).

| Round | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9+ |
|---|---|---|---|---|---|---|---|---|---|
| Small loss | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
| Big loss | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 |

With 40 starting health (2.2.5), a late small loss is a quarter of a hero's starting health and a late big loss about a third.

Note: **design intent.** The system exists to make players spend their gold early instead of saving it. The owner's picture of round 1:
- A player can buy up to 2 units on round 1.
- A player who buys no unit on round 1 should take the 5 at once.
- A player with 2 units who can't kill even 1 enemy unit has greeded, and is punished for it.
- Players always have the choice not to greed, so the values are set assuming players **can** avoid big losses. Big losses are the penalty for greed and for falling far behind; small losses set the game's length.

The game-length aims behind the values (owner, 12 Nov):
- The winner plays about 13–14 fights, with a range of roughly 12–16, and some games run long.
- A player at a reasonable level who isn't outplayed should survive 8–9 fights.
- Nobody should go out after only 2 losses.
- Damage grows so that long games close out.

Note: **what the values gave in a toy lobby** (8 live players, simulated; Damage Lab, archived in `docs/archive/damage-lab/` on `main`):

| Big losses | Typical game (10th–90th percentile) | First player out | Out after 3 losses or fewer |
|---|---|---|---|
| All avoided | 16 fights (15–19) | round 8 | 0% |
| None avoided (about 60% of losses big) | 14 (13–17) | round 7 | 0% |

Note: **tunable, with fallbacks.** Every value here is tunable (Appendix A): starting health, the round-1 value, the growth per round, the cap of 10, the +3 and the half-board test. If the system produces bad results, other versions were explored on 12 Nov:
- a big loss as a percentage of the small loss (×1.5) instead of a flat +3;
- a closing ramp: extra growth per round from a set round;
- 1 damage per surviving starting unit on top of round damage (the v0.5 rule, as in TFT);
- 100 health with a percentage curve (4%, +2% a round, up to 20%).

The v0.5 fallbacks also still stand: damage modified by tier, or by the Attack or Health left on the board, which is less readable (N11 §4.5).

Note: **dependency on the economy.** The round-1 picture assumes a player can buy 2 units on round 1. Under the v0.7 economy (4.1.1, 4.2.1: 5 gold on round 1, tier-1 units cost 2) they can.

Note: **game length in the economy sims.** In simulated lobbies with the v0.7 economy, games ran about 16 fights in every set-up, against the 13–14 aimed for above. Lowering health to 34 shortened games by only about 1 fight, and it shut many players out of tier 5. So damage and tier prices need tuning together, and the length should be checked again once real units exist ([../research/economy/README.md](../research/economy/README.md)).

**10.1.4** [PROPOSED] **No other cap.** HSBG's per-turn caps are removed. The most a single loss can deal is 13 (10.1.3). *Why:* the caps patched a formula that could deal 30–49 in one fight (N11 §4.2). Here the cap of 10 in 10.1.3 is the ceiling. *HSBG:* at most 5 damage on turns 1–3, 10 on turns 4–7 and 15 from turn 8, with the cap removed once 4 or fewer players are left (rules.md §12).

**10.1.5** [BG] Armor absorbs damage first; the rest comes off health (rules.md §12).

**10.1.6** [BG] A tie (a draw) deals no damage to either player (rules.md §11.9; the owner confirmed it for Bramble, C12).

**10.1.7** [BG] A ghost board (2.1.2) deals damage normally when it wins, and damage dealt to it has no effect (rules.md §1).

Note: recorded runs (2.1.1) are players, not ghosts in this sense: they deal and take damage normally (2.1.4).

### 10.2 Elimination

**10.2.1** [BG] A hero at 0 health or less is eliminated. Eliminations are checked after all fights of the round (uncertain in HSBG — see rules.md §12).

**10.2.2** [PROPOSED] Players eliminated in the same round are placed by their health after damage: lower health places lower. Ties are broken at random. *Why:* HSBG's rule is unknown (rules.md §12).

**10.2.3** [BG] The game ends when one player is left; that player places 1st (rules.md §12).

---

## 11. Example mechanics and Bramble keywords

Except 11.2.5, 11.2.7a–b and 11.7, none of these is a Bramble mechanic. They are mechanics from HSBG (at 36.6.3; rules.md §13, keywords.md) and Galaxy (Galaxy rules.md §10), kept as [EXAMPLE]s of how good mechanics break the system rules and of what Bramble's rules and code must be able to handle. Bramble designs its own, some of which exist in neither game (N9). Each entry says what the mechanic does in its source game and which rule it tests. Where a rule already decides how it would work on two rows, that worked version follows.

### 11.1 General

**11.1.1** [BG] Keywords are shorthand for rules text. Units can gain and lose keywords. A keyword gained in combat lasts only for that combat unless the effect says "permanently" (rules.md §13).

### 11.2 HSBG combat keywords

**11.2.1** [EXAMPLE] **Taunt.** HSBG: attackers must target a Taunt minion. Tests: must-be-attacked targeting (9.5.4). Two rows: a back-row Taunt does nothing while its front row has units, and protects the other back-row units once the back row can be attacked (9.5.4; N4 §7).

**11.2.2** [EXAMPLE] **Divine Shield.** HSBG: the first time this minion would take damage, it takes none and loses Divine Shield. It blocks Venomous and splash damage too (keywords.md §A). Tests: damage prevention inside the damage exchange (9.6.1). No rule decides damage prevention yet; it waits for the hook list.

**11.2.3** [EXAMPLE] **Windfury.** HSBG: attacks twice in a row each cycle. Golden Windfury is still two attacks; Mega-Windfury is retired (keywords.md §A). Tests: extra attacks and the attack pointer (9.4.3, 9.4.11).

**11.2.4** [EXAMPLE] **Reborn.** HSBG: the first time this minion dies in a combat, it returns with 1 Health. Tests: return effects (9.7.2 step 4, 9.8.2) and the return limit (9.10.3). Two rows: its slot is chosen by 9.8.3.

**11.2.5** [BRAMBLE] **Venomous.** Destroys the first unit this damages each fight. Used by neutral cards (owner's pick, 20 Nov 2026). [PROPOSED] Fully prevented damage leaves Venomous available (agent's default).

**11.2.6** [EXAMPLE] **Stealth.** HSBG: can't be targeted until it attacks or deals damage. Tests: untargetable candidates (9.5.2, 9.5.3). Two rows: a Stealthed front-row unit still protects the back row (9.5.3), and a Stealthed back-row unit stays untargetable after the front row falls, until it attacks.

**11.2.7** [EXAMPLE] **Cleave** (informal name in HSBG: "also damages the enemies next to whomever this attacks"). Tests: splash damage in the damage exchange (9.6.1) and adjacency (8.2.2). Two rows: it also damages the units adjacent to the target, in the target's row; an empty adjacent slot means no splash on that side. A version that splashes to the units behind would be a different effect (keywords.md §A).

**11.2.7a** [BRAMBLE] **Cleave hits one unit, not two.** Bramble's Cleave also damages one unit next to the target, in the target's row. The owner, 19 Nov 2026, on the Flying Ace: "the cleave should only hit one thing, not two".

**11.2.7b** [PROPOSED] Which unit Cleave hits is picked at random from the units next to the target, using the fight's seeded random numbers (balance pass 1's choice, 19 Nov 2026, not the owner's).

**11.2.8** [EXAMPLE] **Attacks immediately.** HSBG: an extra attack made at once, out of turn. Tests: out-of-turn attacks and the attack pointer (9.4.12).

### 11.3 HSBG trigger keywords

**11.3.1** [EXAMPLE] **Battlecry.** HSBG: triggers when the minion is played from hand, after it is placed. Recruit Phase only. Tests: play triggers, which Bramble moves to recruiting (7.2.3), and a unit replayed from hand repeating nothing (7.2.4).

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

**11.6.4** [EXAMPLE] **Recruit.** Galaxy's name for a play trigger: fires when the card is taken from the shop, including banking it, and not on a transform. Tests: a take-from-shop trigger. With a hand that means buying (4.2.1). Bramble's own play triggers work this way (7.2.3).

**11.6.5** [EXAMPLE] **Hunt.** Galaxy: fires when this character attacks and KOs the defender, even if it also dies. Only the attacker hunts. Tests: "after a unit kills" triggers (9.7.2 step 1).

**11.6.6** [EXAMPLE] **Slot buffs.** Galaxy: buffs that live on a board slot and stay when the character in it changes (Galaxy rules.md §4). Tests: slot effects (8.5). Bramble has no stat slot buffs since 19 Nov 2026 (8.5, note); the example still tests the general rule.

**11.6.7** [EXAMPLE] **Paint.** Galaxy: colours a slot permanently, and each colour gives the character in that slot a buff, such as +1/+1 for any coat (Galaxy rules.md §8). Tests: slot effects (8.5) and how long they last (8.5.3).

### 11.7 Bramble keywords

Note: Bramble's own keywords, from the owner's answers on the Pigeon and Mouse rework page (N14). Active, Charge and Supply are global: any tribe's card may use them. Card text and costs are in the pitches and the tribe files, not here.

**11.7.1** [BRAMBLE] **Active.** An activated ability is written as a gold cost and a colon, "{1}: effect", and shown as a gold coin holding the number, 0 when it is free. The card prints no keyword word. Any tribe's unit can have one. It replaces the Pigeons' Orders. The owner: "I think Active should just have a little gold cost. We don't need to say it's an Active, then people will figure it out. Put a little zero there or a one inside the gold icon, depending on its cost", and earlier the same day, "that's just a global keyword any tribe can have access to" (N14).

**11.7.2** [PROPOSED] An Active is used in the Recruit Phase (3.3.1), from the board, never from the hand, once a turn for each unit unless its card says otherwise. Using it pays the cost (4.1). A golden unit pays the same cost and follows the signature rule (7.3.5). *Why:* the Pigeon pitch's rule; Orders worked the same way. Example: HSBG's Activate (11.4.5).

**11.7.3** [BRAMBLE] **Charge N.** The effect works N times, then stops. All N uses come back at the start of every fight. It replaces limits written "(N a fight)" and "the first time each fight". The owner: "Charge is just a set number of uses, so we don't have to consistently go '(up to N times)'", then the pick of two words, Charge that refills and Supply that never refills (P2, N14).

Note: the Charge the owner picked also refills at the start of each turn, for effects used in the Recruit Phase. No approved card needs that yet; it waits for one.

**11.7.4** [BRAMBLE] **Supply N.** The effect works N times in the whole game, then never again (P2, N14).

**11.7.5** [PROPOSED] Charge and Supply are written in front of the effect they limit, like a trigger word: "Charge 4: After a friendly unit dies, …". Each time the effect resolves it uses one. Supply left is a count on the unit and moves with it (7.2.5). A triple adds the three copies' remaining Supply. A golden that isn't made by a triple (a Discover pick) starts with full Supply N. *Why:* the pitch's rules for the triple; full Supply for a given golden is the simplest default.

**11.7.6** [BRAMBLE] **Renown.** A number on a slot. Each point gives +1/+1 to the unit that starts the fight in that slot, while it lives, and to each reservist that steps into the slot (11.7.8). Nothing else gets it: not summons, returns or a unit moved there in the fight. Renown is permanent: it stays on the slot when the unit is moved, sold or dies, and never moves with a unit. Renown gained in a fight goes on the real slot at once and counts from the next fight. Old Campaigner adds Renown in the next Recruit Phase (3.2.2). The owner: "Maybe instead of buffing slots, we give a slot a renown, and we can change the size of the renown maybe through the game ... And renown gives stats only to starting units or reservists"; then the picks of even Renown (P1) and of Renown earned in a fight counting from the next fight (P5) (N14).

**11.7.7** [PROPOSED] Renown is borrowed: an effect that only reads a unit's Attack or Health reads it, and an effect that copies, keeps or takes a unit's stats leaves it out (shared ruling 43). On the recruit board a unit shows its stats with its slot's Renown, since that is what it starts the next fight with. *Why:* the Pigeon pitch's rules, matching the retired slot buffs.

**11.7.8** [BRAMBLE] **Reserve and its limit.** In a fight, after a friendly unit dies, a unit with Reserve in your hand steps into the slot it died in. That unit is a reservist. You call at most 2 reservists from your hand each fight; cards can raise the limit (the Quartermaster: "You can call 1 more reservist each fight"). Reserve itself is the playable build's, accepted with its mechanics on 17 Nov 2026 ([STATUS](../STATUS.md)). The owner on Pigeons: "I like the idea of Pigeons as caring about Reserve, or air support or something, which is these reinforcements that come in"; the limit is their pick (P5, N14).

**11.7.9** [PROPOSED] **Which slot a reservist fills.** After a round of deaths, reservists fill the empty slots friendly units died in this fight, in this order: your Guard post, then the slot with the most Renown, then reading order (1.2.3). The leftmost reservist in hand goes first. Reserve is not a summon or a return, reservists aren't counted for Outnumbered, and the hand is the same after the fight. *Why:* the Pigeon pitch's order: the most famous company is refilled first. It replaces "Guard post first, then reading order" in the build's shared ruling 6.

**11.7.10** [PROPOSED] (owner's pick, 20 Nov 2026) **Privates step in.** A Pigeon card's "a Private steps in" puts a Private into that slot as a reservist: it has the slot's Renown but doesn't count against the limit, and its card's Charge limits it. In a round of deaths it comes after reservists from the hand (shared ruling 6, step 4), and only if the slot is still empty. *Why:* the Pigeon pitch's rules: Pigeon summons get Renown, other tribes' summons don't.

**11.7.11** [BRAMBLE] **Pile on N.** The first N times a neighbour attacks each fight, this hits the target first: it deals its Attack to the target before the attack and takes none back. Every Pile on card prints its N. The owner's pick of Pile on counted for every card, "Pile on N" (M3, N14).

**11.7.12** [BRAMBLE] **Hand-me-down.** When this dies, the nearest friendly Mouse gains its Attack this fight. The Mice's Kin mechanic, the owner's pick (M1, N14); the rule is the Mouse pitch's.

**11.7.13** [PROPOSED] Hand-me-down passes the unit's own Attack only (shared ruling 43): this fight's buffs on the unit pass; Renown and auras don't. With no friendly Mouse on the board, nothing happens. It is a death effect (9.7.2 step 2). **Nearest** is the friendly Mouse on the board fewest neighbour steps (8.2.3) from the dying unit's slot; ties go in reading order. *Why:* the pitch's rule notes. The pitch doesn't define nearest; neighbour steps use an existing term and suit two staggered rows.

**11.7.14** [BRAMBLE] **Grudge N.** At the start of your turn, the unit gains +N Health and +N/+N more for each unit you were outnumbered by last fight (3.2.2). Count the boards at the start of that fight, before start-of-fight effects, leaving out back-row Squires on both sides. Grudge-keeper gives Grudge to your Knights. Use the highest Grudge number once for each unit. Delegated by the owner on 20 Nov 2026.

---

## 12. Durations and effect scopes

### 12.1 Durations

**12.1.1** [BG] **"This combat"** lasts until the combat ends. **"Permanently"** also applies the change to the unit on the recruit board. **"This game"** is a player-level change that lasts the whole game and can affect future cards. **"This turn"** or **"until next turn"** ends at the end of the Recruit Phase or the start of the next one (rules.md §13).

**12.1.2** [BG] Buffs gained in combat are lost after combat unless they say "permanently". *Galaxy:* makes all buffs permanent; its design notes advise Bramble not to copy that (Galaxy design-notes §6).

**12.1.3** [BG] Shop-wide buffs ("units in the shop have +1/+1 this game") apply to the units currently in the shop and to future shop units (rules.md §13).

### 12.2 Scopes

**12.2.1** [BG] Auras (continuous effects such as "adjacent units have +1 Attack") apply only while their source is on the board, and they are recalculated whenever the board changes (inferred; not in rules.md).

**12.2.2** [PROPOSED] **Board scopes.** "Your units" means the units on your board, not in hand. "Front-row units" and "back-row units" mean the units in those rows. Position words are defined in 8.2. *Why:* HSBG's "your minions" means the board; rows add new scopes that need fixed meanings.

**12.2.3** [PROPOSED] **Last-known positions.** A trigger about a dying unit's position ("when the unit in front of this dies", "when this dies, give the units behind it +2/+2") uses the slot the dying unit held, even though it has already left the slot (9.7.1). *Why:* without this rule, a dead unit would have no position for its own effects.

---

## 13. Systems outside the v0 core

**13.1.1** [PROPOSED] HSBG's seasonal systems are not in the v0 core rules: Trinkets and Dark Gifts (active at 36.6.3), and Quests, Anomalies, Buddies, Timewarped Tavern and Darkmoon Prizes (inactive). *Why:* HSBG turns them on and off by season, and each one forced changes to armor and timers (patch-history.md lesson 4). The owner wants game-warping modifiers to be addable later through a clean modifier layer (N1 §7; [architecture-notes.md](architecture-notes.md)).

**13.1.2** [PROPOSED] Tier 7 is reachable only by effects that say so (4.6.1), and no v0 system grants it. *Why:* in HSBG it comes only from seasonal systems and specific rewards (rules.md §15).

---

## 14. Glossary

Each term points to the rule that defines it.

| Term | Meaning | Rule |
|---|---|---|
| **Unit** | A card with Attack, Health and a type line that can be on the board. HSBG's *minion*. | 1.1.1, 5.2.1 |
| **Bought** | A unit taken from the shop by paying. | 4.3.1 |
| **Created** | A unit that came any other way: summoned, generated, copied, given. A real card sells for the same as a Bought unit (since 19 Nov); a token sells for 0. | 4.3.1, 4.3.2 |
| **Token** | A Created unit that is not a card the shop can offer, such as a summon. Sells for 0. | 4.3.1, 4.3.3 |
| **Origin** | Whether a unit is Bought or Created. | 4.3.1 |
| **Golden** | The combined unit made by a triple, with double base stats. | 7.3 |
| **Triple** | Three copies of the same non-golden unit combining into a golden. | 7.3.1 |
| **Shop chances** | The fixed weight each card has of being offered. Bramble has no shared pool. | 5.1 |
| **Recorded run** | One player's game, turn by turn, that others fight in async play. | 2.1.1 |
| **Run seat** | A seat in a game played by a recorded run. | 2.1.4 |
| **Live player** | The seat a person (or, in development, a bot) plays in real time; the other 7 are run seats. | 2.1.10 |
| **Tier** | A unit's shop tier (1–7), and a player's current shop tier. | 4.6 |
| **Type, type line** | The words describing what a unit is, e.g. "Owl Warrior". | 5.2.1 |
| **Tribe** | A type used to build lobbies. Which types are tribes is open. | 5.2.2 |
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
| **Discover** | Choose 1 of 3 units, drawn by the shop chances. | 6.2 |
| **Ghost** | The copied board an odd player out fights. Recorded runs are often called ghosts too. | 2.1.2 |
| **Example mechanic** | An HSBG or Galaxy mechanic, tagged [EXAMPLE], kept to show which rule it tests. Not a Bramble mechanic. | 11 |
| **Active** | An effect the player pays a gold cost for in the Recruit Phase, written "{1}: effect". | 11.7.1 |
| **Charge N, Supply N** | N uses of an effect: Charge's come back every fight, Supply's never do. | 11.7.3, 11.7.4 |
| **Renown** | A permanent number on a slot: +1/+1 a point for the unit that starts the fight there and for reservists. | 11.7.6 |
| **Reservist** | A unit that steps in from the hand (Reserve) or a Private that steps in. | 11.7.8, 11.7.10 |

---

## Appendix A. Tunable parameters

The values an engine should read from configuration rather than hard-code.

| Parameter | Value | Rule | Status |
|---|---|---|---|
| Players per lobby | 8 | 2.1.1 | BG |
| Heroes offered | 2 | 2.2.2 | BG |
| Stat scale | about 2× HSBG | 1.2.5 | BRAMBLE |
| Starting hero health | 40 by default; heroes may differ | 2.2.5 | BRAMBLE |
| Income by turn | 5, +2 a turn until 15, then +1 a turn, no ceiling | 4.1.1 | BRAMBLE |
| Gold holding cap | none | 4.1.3 | BRAMBLE |
| Unit price | tier + 1 | 4.2.1 | BRAMBLE |
| Sell value | half the tier, rounded up, for any real card, Bought or Created; 0 for a token; a golden sums its real-card copies | 4.3.3, 4.3.4 | BRAMBLE |
| Refresh costs | 1, then +1 per step, no cap | 4.4.2 | BRAMBLE |
| Refresh steps | first after 10, then every 5 | 4.4.3 | BRAMBLE |
| Freeze toggles per turn | 5 | 4.5.1 | BG |
| Upgrade base costs (to 2–6) | 8, 12, 16, 19, 26 | 4.6.2 | BRAMBLE |
| Upgrade discount per turn waited | 1, 2, 3, 4, 5, minimum 0; resets at each upgrade | 4.6.3, 4.6.4 | BRAMBLE |
| Upgrade discount after 5 turns waited | 5 a turn | 4.6.6 | PROPOSED |
| Shop chance weight per unit by tier | 15, 15, 13, 11, 9, 7, 5 | 5.1.2 | BRAMBLE |
| Players per game | 8: the player and 7 recorded runs | 2.1.1 | BRAMBLE |
| Shop offers | 5 units and 2 spells at every tier | 6.1.1 | BRAMBLE |
| Tribes per lobby | open | 5.2.5 | OPEN |
| Hand limit | 7 | 7.1.1 | BRAMBLE |
| Board slots, front / back | 4 / 3 | 8.1.2 | BRAMBLE |
| Small loss by round | round + 1, up to 10 | 10.1.3 | BRAMBLE |
| Big loss extra damage | +3 | 10.1.1 | BRAMBLE |
| Kills needed for a small loss | half of the winner's starting units | 10.1.1 | BRAMBLE |
| Damage cap | none beyond the cap of 10 in 10.1.3 | 10.1.4 | PROPOSED |
| Attack limit per combat | 200 | 9.10.1 | PROPOSED |
| Trigger limit per combat / per action | 10,000 / 1,000 | 9.10.2 | PROPOSED |
| Returns per unit per combat | 5 | 9.10.3 | PROPOSED |
| Stat clamp | 1,000,000,000 | 1.2.4 | PROPOSED |
| Game length limit | 50 rounds | 2.1.3 | PROPOSED |
| Recruit timer | None | 3.1.2 | BRAMBLE |
| Reservists from hand per fight | 2, raised by cards | 11.7.8 | BRAMBLE |
