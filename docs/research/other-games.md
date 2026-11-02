# Other games: positioning, bounded economies and recurring archetypes

**Status: research for the design pass, 2 November 2026.** Task R4 of the pass the owner set out in [owner-notes/2026-11-02-pre-development-design-pass.md](../design/owner-notes/2026-11-02-pre-development-design-pass.md). It answers three questions only:

1. What positioning and adjacency add to decisions and strategy variety, and what they cost.
2. How games without a turn timer, or with async fights, keep economy and turn length bounded.
3. Which archetype shapes recur across games.

No player-sentiment research, per the owner. Claims are marked **[data]** (from a cited source, the card libraries or a model run) or **[judgement]**. Galaxy facts come from [galaxy/rules.md](galaxy/rules.md) and [galaxy/design-notes.md](galaxy/design-notes.md) unless a link says otherwise. Web sources were read on 2 Nov 2026.

**Games covered**

| Game | Why it's here | Fights | Timer |
|---|---|---|---|
| Once Upon a Galaxy | Same staggered brick as Bramble, fixed slots, async | Async ghosts in ranked | None in async |
| Storybook Brawl (SBB) | 4 front, 3 back: Bramble's exact row caps | Live lobby | Yes [judgement: live 8-player lobby] |
| Super Auto Pets (SAP) | A 1-D line where order is the whole game; untimed async mode | Arena: async; Versus: live | Arena: none; Versus: yes |
| Teamfight Tactics (TFT) | Free placement on a hex grid with movement | Live lobby | Yes |
| Backpack Battles | Async, adjacency puzzle, escalating reroll cost | Async ghosts | None found |
| The Bazaar | Async, adjacency and left/right positions, action-count turns | Async ghosts | None found |
| Mechabellum | Positioning and counter-deployment as the core | Live 1v1 | Yes |
| Hearthstone Battlegrounds | Baseline: adjacency and leftmost/rightmost in one row | Live lobby | Yes |
| Marvel Snap | Lanes as a card-battler | Live 1v1 | Yes |

Storybook Brawl closed on 1 May 2023 after its owner, FTX, went bankrupt ([Bloomberg](https://www.bloomberg.com/news/articles/2023-04-25/sam-bankman-fried-s-favorite-game-storybook-brawl-to-close-post-ftx-bankruptcy), [Wikipedia](https://en.wikipedia.org/wiki/Storybook_Brawl)). Its closure says nothing about its rows. [data]

---

## 1. Positioning and adjacency

### 1.1 How each game does position

| Game | Board | Targeting | What position decides | How much text uses it |
|---|---|---|---|---|
| **Battlegrounds** | 7 in one row, packs left | Random, Taunt first | Attack order, Cleave and adjacency neighbours, summon space, Magnetic | 54 of 986 minions ever in the pool (5.5%) and 17 of 273 current (6.2%) name "adjacent", left or right [data: `minions.json`, regex on text] |
| **Galaxy** | 3 front, 2 back, brick, fixed slots | Random front-row enemy; Sneak hits the back | Supports, slot buffs, Paint, facing slots, "first slot" | 65 of 603 active cards (11%) use row or neighbour words; 139 (23%) if slot buffs and Ranged count [data: `galaxy/data/cards.json`, regex] |
| **SBB** | 4 front, 3 back | Front row first; Ranged and Flying reach the back | Support buffs "the two units in front"; back row holds units that grow | Not counted; the card list is offline |
| **SAP** | 5 in one line, packs forward | Front pet fights front pet. No randomness in who fights | Order of the queue: who tanks, who triggers on whom | Whole archetypes: Guard pets "jump in front of friends"; Kangaroo "Friend ahead attacks: gain +1/+1"; Flamingo "Faint: give the two nearest friends behind +1/+1" ([archetypes](https://superautopets.wiki.gg/wiki/Pet_Archetypes), [Kangaroo](https://superautopets.wiki.gg/wiki/Kangaroo), [Flamingo](https://superautopets.wiki.gg/wiki/Flamingo)) [data] |
| **TFT** | 4 × 7 hex grid per player (not re-checked); units move | Nearest enemy, plus abilities that jump, hook or hit lines | Who the frontline shields, where the carry hides, baiting assassins | Positioning is a core skill: corners against snipes, spacing against lines and hooks ([Mobalytics positioning guide](https://mobalytics.gg/blog/tft/tft-positioning-guide-how-to-get-the-most-from-your-units/)) [data] |
| **Mechabellum** | Open field; units persist and are repositioned each round | Pathing and range | Counter-deployment against the army the opponent showed | Placement is the main decision each round ([FinalBoss guide](https://finalboss.io/mechabellum-beginner-guide-to-unit-roles-deployment-and)) [data] |
| **Backpack Battles** | Grid backpack, item shapes | No targeting; items trigger on timers | Which items touch: buffs and recipes need neighbours | "Two items combine … only if they are adjacent"; the Pan deals more damage next to food ([Wikipedia](https://en.wikipedia.org/wiki/Backpack_Battles)) [data] |
| **The Bazaar** | One row of items with sizes | No targeting; items trigger on cooldowns | Neighbours and leftmost/rightmost | Many items act on "adjacent" items or the item to the left ([Mobalytics item pages](https://mobalytics.gg/the-bazaar/dooley-items), [BazaarDB: Hourglass](https://www.bazaardb.gg/card/1sk99jmuf77zkyxy9rt7trq8u/Hourglass)) [data] |
| **Marvel Snap** | 3 lanes, 4 cards each | None; win 2 of 3 lanes on power | Which lane each card goes to; lanes have their own rules | Every card play is a lane choice ([Shacknews](https://shacknews.com/article/132689/how-to-play-marvel-snap)) [data] |

### 1.2 What position adds: three separate kinds of decision

The games above get depth from position in three different ways. They are worth keeping apart, because Bramble's async fights remove one of them. [judgement]

**A. Guard and carry.** One slot is safer, so the player decides who is protected and who protects. SAP's Guard pets, TFT's frontline and backline, SBB's and Galaxy's back rows all do this. Bramble's back-row protection is this kind. [data for the rules, judgement for the grouping]

**B. Neighbour synergy.** Text that reads the units next to, ahead of or behind this one. SAP, Galaxy, The Bazaar, Backpack Battles and Battlegrounds' adjacency cards all do this. It is a build puzzle the player solves against their own board, not against an opponent. [judgement]

**C. Counter-positioning.** Placing against a known enemy board. TFT players scout and rearrange: a carry in the corner beats one assassin and loses to another ([Mobalytics](https://mobalytics.gg/blog/tft/tft-how-to-adapt-positioning/)). Mechabellum is built around answering the army the opponent fielded. This needs the player to know the board they will face. [data for the examples]

**Bramble can only have C if the player sees the snapshot they will fight before ending the turn.** In Galaxy's async play the opponent is a recorded run, and whether you see it before placing is not stated in the guide (UNVERIFIED). Battlegrounds shows who the next opponent is (rulebook 2.3.3; uncertain) but not the board they will end the turn with. If Bramble shows nothing, position is A and B only. [judgement] *Question for the owner, below.*

### 1.3 What Bramble's own evidence says

From the toy sim in [power-analysis.md §7](battlegrounds/power-analysis.md) (6,000 paired fights per cell, vanilla boards) [data]:

- **Vanilla placement is almost not a decision.** Putting the four highest-Health units in front, or the four lowest, moves win rate by at most 1.5 points against random placement ([sim_placement.csv](battlegrounds/analysis/sim_placement.csv)).
- **Direction matters.** A back unit's "units in front of this have +2 Attack" realises 95–119% of its nominal value. A front unit's "units behind this have +2 Attack" realises 0–7%, because the front row has mostly traded off before the back row attacks. Battlegrounds adjacency realises 39–72% ([sim_positional_effects.csv](battlegrounds/analysis/sim_positional_effects.csv)).
- **"When the unit in front of this dies"** fires about 1.9 times per back unit per fight.

Other games agree that position depth comes from text and targeting rules, not from the grid:

- SAP gets heavy use from 5 slots because targeting is deterministic: the front pet always fights the front pet. Every "friend ahead" or "friend behind" effect lands on a unit the player chose. [judgement from the rules on [The Basics](https://superautopets.wiki.gg/wiki/The_Basics)]
- Battlegrounds' random targeting dilutes position. Only about 6% of its minions read position at all. [data, above]
- Galaxy, with front-row-first targeting like Bramble's, puts position on about 11–23% of cards, and most of it is back-to-front (Support, 25 cards) or slot-based (62 slot mentions) ([galaxy/content-library.md](galaxy/content-library.md)). [data]

### 1.4 What position costs

| Cost | Evidence |
|---|---|
| **Pricing errors on back-row auras.** A protected aura is worth more than its nominal stats. | Galaxy charged early Supports 2–6 body SP for 4–28 SP of aura, then cut Pix and Puck to +2 in March 2026 for causing "more full heart losses than we prefer early in games" ([power-analysis.md §6](battlegrounds/power-analysis.md), [patch](https://galaxy.fun/articles/patch-mid-march-2026/)) [data] |
| **Support bodies get too small to matter.** | Galaxy said Supports are "so lowly statted" that their payoff cards needed help ([patch](https://galaxy.fun/articles/patch-mid-november-2025/)) [data] |
| **Every protected row needs a way in.** | SBB: Ranged and Flying hit the back row ([HSReplay](https://articles.hsreplay.net/2022/09/23/storybook-brawl-the-perfect-game-for-battlegrounds-players-2/)). Galaxy: Sneak. TFT: assassins that jump and hooks that pull the furthest unit ([Mobalytics](https://mobalytics.gg/blog/tft/tft-how-to-counter-assassin-shade-comps/)). No game with a protected row runs without one. [data] |
| **More decisions per turn.** | SAP keeps it small: one queue of 5. TFT and Mechabellum make placement a large share of each turn. Bramble's 7 fixed slots with gaps sit between them. [judgement] |
| **Text that never fires.** | Front-to-back effects realise 0–7% in Bramble's attack order (sim, above). Galaxy has only 3 "behind me" cards, against about 15 "in front of me" ([content-library.md](galaxy/content-library.md)). [data] |
| **Shuffling breaks neighbour text.** | SAP and Battlegrounds pack, so "friend behind" can mean a different unit after a death. SAP's text works around it with "nearest". Galaxy and Bramble fix slots instead. [data for the rules] |

### 1.5 What this means for Bramble

- **Position will add depth only through text and keywords**, mostly back-to-front, plus slot effects. The geometry alone adds almost nothing (sim). [data + judgement]
- **Price back-row auras above nominal**, not at it. Galaxy's correction is the warning. [judgement]
- **Write the back-row reach keyword into the first content set.** Every comparable game has one. [judgement]
- **Neighbour synergy (kind B) is the safest win.** It works without seeing the opponent, it suits async, and SAP shows it can carry whole archetypes on a tiny board. [judgement]
- **Counter-positioning (kind C) depends on a rules choice** about showing the snapshot. [judgement]
- The owner's test stands: if the position cards in the quick sim don't make smart placement beat random placement, cut the rows ([owner note](../design/owner-notes/2026-11-02-pre-development-design-pass.md), "Positioning").

---

## 2. Bounding economy and turn length without a timer

### 2.1 What each game uses

| Game | Timer | Gold between turns | Per-turn bound | Hard cap | Per-card limits |
|---|---|---|---|---|---|
| **Galaxy** (async) | None | No gold at all | 2 picks a turn; only bonus shops add more | **30 shops a turn**, then the Limit Breaker treasure (+10/+10) and no more bonus shops. Set at 20 on 30 Apr 2026, raised to 30 on 11 May 2026, to bring "long silver and spell chained shops to a conclusion" ([patch](https://galaxy.fun/articles/patch-mid-may-2026/)) | Boons check once at the start of the fight, so they can't complete twice a turn [data] |
| **SAP Arena** (async) | None ([The Basics](https://superautopets.wiki.gg/wiki/The_Basics)) | 10 gold each turn; gold does **not** carry over "save for a few exceptions" ([Gold](https://superautopets.wiki.gg/wiki/Gold)) | Fixed income | Free rolls cap at 10; stats cap at 50 ([Hamster](https://superautopets.wiki.gg/wiki/Hamster), [The Basics](https://superautopets.wiki.gg/wiki/The_Basics)) | **"Works N times per turn"** on economy pets: Hamster "Roll: gain one free roll. Works 2/4/6 times per turn"; Goat "Friend bought: gain +1/2/3 Gold. Works 2 times per turn" ([Goat](https://superautopets.wiki.gg/wiki/Goat)) [data] |
| **Backpack Battles** (async) | None found | Fixed table per round: 13, 13, 15, 10, 11 … 16 ([Gold](https://backpackbattles.wiki.gg/wiki/Gold)). Carry-over not stated (UNVERIFIED) | Fixed income; items sell for half their price | None found | **Reroll costs 1 gold "up to four times per round", then 2** for the rest of the round ([Gold](https://backpackbattles.wiki.gg/wiki/Gold)) [data] |
| **The Bazaar** (async) | None found | Gold plus an Income stat paid each day ([Mobalytics, via search](https://mobalytics.gg/the-bazaar/guides/start-of-run-guide)) | **A day is split into hours; each hour offers three events and you take one** ([Game8](https://game8.co/articles/games/the-bazaar)) | 10 PvP wins ends the run | Merchant rerolls cost 3 gold (Silver) or 4 (Gold) ([Mobalytics patch notes, via search](https://mobalytics.gg/the-bazaar/guides/patch-notes)) [data] |
| **Battlegrounds** (live) | Yes | Resets to income, max 10 | The recruit timer | Combat limits only | Tethys "After you spend 10 Gold, get a random Pirate"; Rogers "After you spend 9 Gold" [data: `minions.json`]. Can run without limit inside the timer (owner note) |
| **TFT** (live) | Yes | Carries over, with interest: +1 per 10 held, up to +5 at 50 ([west-games](https://west-games.com/tft-gold-interest-calculator/)) | The round timer | Interest cap | Reroll 2 gold, XP 4 gold ([wecoach](https://wecoach.gg/blog/article/how-to-play-teamfight-tactics-tft)) [data] |
| **SBB** (live) | Yes [judgement] | 2 gold at start, +1 a turn, limit 12 ([HSReplay part 1](https://articles.hsreplay.net/2022/09/16/storybook-brawl-the-perfect-game-for-battlegrounds-players/)) | Timer; one spell bought per turn ([part 2](https://articles.hsreplay.net/2022/09/23/storybook-brawl-the-perfect-game-for-battlegrounds-players-2/)) | Gold limit | Not researched |

### 2.2 The patterns

Every async game here bounds a turn with at least one of these tools beyond price, and Galaxy and SAP use three each. [data for the table, judgement for the grouping]

1. **Income resets or is fixed each turn** (SAP resets; Backpack Battles pays a fixed table, carry-over unverified). In SAP, saving can't build a giant turn.
2. **A fixed count of actions** (Galaxy's picks; The Bazaar's hours). Turn length is bounded by actions, not gold.
3. **Rising cost within a turn** (Backpack Battles' 1 → 2 after 4 rerolls). The same tool Bramble uses.
4. **Per-card "N times per turn" limits** (SAP on every economy pet; Galaxy's Boons). A content rule, not a system rule.
5. **A hard cap with a consolation prize** (Galaxy's 30 shops; SAP's 10 free rolls).

Two histories show the order things went wrong in:

- **Galaxy's loops came from chained free shops, not paid ones.** It capped them at 20, then raised the cap to 30 within two weeks. [data]
- **SAP turned gold-per-roll into capped free rolls.** Hamster was "Roll: gain +1 gold, works 2/4/6 times per turn" before v0.40. It became free rolls at the start of turn, then roll-triggered free rolls, still with the per-turn limit ([Hamster history](https://superautopets.wiki.gg/wiki/Hamster)). [data]

### 2.3 Where Bramble sits

Bramble uses tool 3 only, plus content design ([rulebook 4.1.2–4.1.3, 4.4](../design/rulebook.md); [content-guardrails.md](../design/content-guardrails.md) G1). Among the games here, only Bramble and possibly Backpack Battles combine **no timer, carry-over gold and no per-turn action count** (Backpack Battles' carry-over is unverified). Backpack Battles steps its reroll cost up after 4 rerolls; Bramble does so after 10. [data for the rules; judgement for the comparison]

**Saving alone reaches the target range.** With the 1–10 / 11–20 / 21+ thresholds, paid refreshes cost 1 × 10 + 2 × 10 = 30 gold for 20 refreshes. So [data: arithmetic on rulebook 4.4.3]:

| Gold spent on refreshes | Paid refreshes | Shops seen (incl. the first) |
|---|---|---|
| 10 | 10 | 11 |
| 30 | 20 | 21 |
| 45 | 25 | 26 |
| 60 | 30 | 31 |

A player who banks 30 gold over a few turns sees 21 shops with no engine at all. The owner's target is that *the strongest engines* see about 20–30 ([rulebook 3.1.2](../design/rulebook.md)). An engine that also gets gold back pushes well past it. For comparison, Backpack Battles charges 4 + 2 × 13 = 30 gold for 17 rerolls. [data: arithmetic]

This doesn't break the "rising cost only" choice. Seeing shops without gold to buy is mostly worthless. But it means the thresholds, not the engines, set the ceiling for a saver. [judgement]

### 2.4 What this means for Bramble

- **SAP's "Works N times per turn" is the cleanest content-level tool** that fits the owner's choices: only refreshes escalate, and engines are bounded by content design. It could be a standard clause for any card that makes gold or free refreshes. [judgement]
- **Count free shops in the 20–30 target**, as Galaxy does. Galaxy's loops came from free shops. [data for Galaxy, judgement for Bramble]
- **"After you spend N gold" engines (Tethys, Rogers) are self-bounding** only while gold is bounded. With uncapped carry-over, the bound is the total gold banked plus the gold the engine returns. Any engine card that returns gold needs its return rate checked against the refresh thresholds. [judgement]
- Galaxy's cap is a precedent for the owner's range: a live game settled on 30 shops a turn after trying 20. [data]

---

## 3. Archetype shapes that recur

The owner's four flavours (economy actions, go-wide, scam, scaling with tall or wide shapes) all appear in every game with enough content. Three more recur and are worth naming. [judgement for the grouping; examples are data]

| Shape | Battlegrounds | Galaxy | SAP | Others |
|---|---|---|---|---|
| **1. Economy through many small actions** | Tethys, Rogers (spend gold, get cards); refresh-based tribes | Bonus-shop chains from Silvers and spells; captains that bend shop count | Gold pets (Goat, Swan, Pig) and Roll pets (Hamster) ([archetypes](https://superautopets.wiki.gg/wiki/Pet_Archetypes)) | TFT: interest and loss-streak economy is system-level, not card-level. The Bazaar: Income items. Backpack Battles: Lucky Piggy "Shop entered: gain 1" |
| **2. Go wide: many small bodies, good trades** | Deathrattle and token tribes | Toys: summon chains | Summon pets (Turkey), Faint pets | SBB: Last Breath summons |
| **3. Scam: kill something much bigger** | Venomous; Leeroy the Reckless, "Destroy the minion that killed this" [data: `minions.json`] | Poison Apple; Wicked Witch "reduce that enemy and the ones next to it to 1 Health"; Shrink Tea | Ailment and Disruption pets (Goblin Shark) | TFT: %-health damage and execute effects |
| **4a. Scale tall: one or two huge units** | Single-target buff engines | Supports feeding the front (Oberon: "+20 Attack" each fight) | Buffs into one pet up to the 50 cap | SBB: back-row units that grow while protected |
| **4b. Scale wide: many medium units** | Tribe-wide buffs (Murloc Warleader "Your other Murlocs have +2 Attack") | Animals buffing each other; Candy's shared counter | Buff pets (Giraffe) | |
| **5. Retrigger and doubling** | Brann "Your Battlecries trigger twice"; Titus "Your Deathrattles trigger an extra time" [data: `minions.json`] | "Double" means +1 trigger, by house rule | | The Bazaar: Haste and Charge on adjacent items |
| **6. Protected engine behind a wall** | Rare: one row | Fae: Support | Guard pets | SBB Support; TFT backline carry |
| **7. Before-the-fight burst** | Start of Combat | "Each fight" effects | Start of battle pets | |

Notes on the shapes:

- **Shapes 1–4 are the owner's list.** Each game reaches them through its own trigger words (Battlecry, Recruit, Hunt, Faint, Roll). The shape recurs; the trigger is the tribe's flavour. [judgement]
- **Shape 5 is the main source of loops.** Battlegrounds' Brann with a refresh effect is G1's origin ([content-guardrails.md](../design/content-guardrails.md)). Galaxy capped "double" at +1 trigger. Retrigger cards need checking against every economy card. [data + judgement]
- **Shape 6 only exists on boards with a protected slot.** It is what Bramble's rows add over Battlegrounds. It is also where Galaxy's pricing errors were. [data + judgement]
- **Scaling has two axes, not one.** *What* triggers growth (buy, spell, death, roll) and *where* growth lands (one unit, the tribe, a slot). Galaxy adds a third answer to "where": the slot itself, through slot buffs and Paint, which survive unit swaps. [data for Galaxy, judgement for the framing]
- **Economy is card-level in Battlegrounds, Galaxy and SAP, and system-level in TFT.** Bramble follows the card-level model, so its economy archetypes must be bounded on the cards (section 2). [judgement]

---

## 4. Findings in short

1. **Rows add depth only through text.** Vanilla placement moves win rate by at most 1.5 points. Back-to-front effects realise 95–119% of nominal; front-to-back 0–7%. SAP shows a tiny board can carry whole archetypes when text reads neighbours. [data + judgement]
2. **Every game with a protected row has a way in** (SBB Ranged and Flying, Galaxy Sneak, TFT assassins and hooks). Bramble needs one from the first content set. [data + judgement]
3. **Async fights remove counter-positioning** unless the player sees the snapshot before ending the turn. That decides whether Bramble's position game is two kinds of decision or three. [judgement]
4. **The async games here bound a turn with fixed income, action counts, per-card limits or hard caps. Bramble uses rising refresh cost only**, with uncapped carry-over. Saving 30 gold already buys 20 refreshes, the bottom of the target range. [data + judgement]
5. **SAP's "Works N times per turn" is a ready-made content guardrail** for economy and free-refresh cards, in line with G1 and "rising cost only". Galaxy's loops came from free shops; its cap settled at 30. [data + judgement]
6. **Seven archetype shapes recur.** The owner's four, plus retrigger (the main loop risk), protected engine (what rows add) and before-the-fight burst. [judgement]

## 5. Questions for the owner

1. **Should the player see the snapshot they will fight before ending the recruit phase?** Yes makes counter-positioning possible, as in TFT and Mechabellum. No keeps position to guard-and-carry and neighbour synergy.
2. **Should every card that makes gold or free refreshes carry a "works N times per turn" limit, as in SAP?** It is a content rule, not a system cap.
3. **Does the 20–30 shop target count every shop seen**, including free refreshes and shop-replacing effects, as Galaxy's cap does?
4. **Is it fine that saving alone reaches 21 shops?** With uncapped carry-over, 30 banked gold buys 20 paid refreshes with no engine. If not, the thresholds would need to be lower or steeper.
5. **Which way into the back row do you want for the first set:** a Sneak-style attacker, Ranged or Flying as in SBB, splash through the line, or more than one?

## Sources not reached

- Storybook Brawl's wiki (paywalled) and card list. SBB's reroll and level costs are not confirmed.
- Backpack Battles: whether gold carries over between rounds.
- The Bazaar: the number of hours per day, the board's slot count and any limit on merchant rerolls. Mobalytics pages returned 403; their figures above come from search-result text.
- Mechabellum: whether the opponent's last placement is shown during deployment.
