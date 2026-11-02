# Bramble effect taxonomy

**Status: draft for the owner's review, 2 November 2026.** This answers the owner's ask in [owner-notes/2026-11-02-pre-development-design-pass.md](owner-notes/2026-11-02-pre-development-design-pass.md):

> We need to understand our total effects taxonomy, and if we can, have some idea of the power associated with those effects.

- **What it is:** every kind of effect a card can have, built bottom-up from all Battlegrounds and Galaxy card text, with how common each one is and a rough price.
- **Data:** [effect_taxonomy.csv](../research/battlegrounds/analysis/effect_taxonomy.csv), one row per class. Counts, examples, price bands and no-timer risk are all in it.
- **Method it feeds:** [power-budget.md](power-budget.md) v0 and [power-budget-review.md](power-budget-review.md). Prices reuse their V(t), A(t), realisation and scaling rules.
- **Tags:** **[data]** comes from the card library, a model run or a cited source. **[sim]** comes from the toy combat sim. **[judgement]** is my call. **[guess]** is a rough number with no data behind it, to be replaced.

Words: **SP** is one stat point. **V(t)** is the stat total of a plain unit at tier t: 5, 7, 8, 10, 12, 14. **A(t)** is the mean enemy Attack: 2.0, 2.5, 3.3, 4.0, 4.9, 6.1. **"Now"** means the Battlegrounds pool at patch 37.0.0 (26 Oct 2026). **Body ratio** is a card's stats over its tier median: below 1 means Battlegrounds charged stats for the text.

---

## 1. Headline findings

1. **Battlegrounds moved its text from the board to the player.** From 2020 to 2026, as a share of the minion pool **[data]**:
   - Down: summons 27% → 11%, self stat gain 15% → 9%, tribe-named text 45% → 31%, static auras 4% → 0%, text with no trigger 20% → 9%.
   - Up: "this game" and future-card targets 1% → 16%, getting cards of any kind 3% → 23% (specific 0% → 10%, random 1% → 8%), effects on shop units 0% → 6%, stat transfer and consume 1% → 6%, buff amplifiers 0% → 6%, self-improving cards 0% → 6%, on-attack triggers 4% → 11%.
   - These are the classes the budget review flagged as hardest to price. They are also the ones Battlegrounds barely charges stats for (section 8).
2. **Battlegrounds' economy lives outside the tribe minions.** Gold, free refreshes, discounts and income appear on 3% of current minions (9 of 273; [economy-text-by-era.md](../research/battlegrounds/economy-text-by-era.md) counts 10 because it also counts Snarky Shark's "Refresh the Tavern with a Fishbait", which this taxonomy puts under shop control, E60), but on 11% of current tavern spells, 10% of 2026 trinkets and 14% of current hero powers **[data]**. "Everybody has them" in Battlegrounds means shared systems sell economy to every player. **[judgement]** Tavern spells are the natural home for Bramble's strong shared economy, with tribe units holding the engines that turn it into stats.
3. **Rising refresh cost bounds per-refresh engines but not per-gold engines.** A trigger that pays per refresh ("after you refresh, gain 1 gold") is cut off by the 2- and 3-gold steps. A trigger that pays per gold spent (Tethys, Rogers: "after you spend N gold") returns the same share of every gold, whatever the price. Free refreshes skip the steps entirely. Section 7 gives the arithmetic: **reaching 20–30 shops needs an engine return of about 0.67–0.8 gold per gold from a 10-gold turn, and needs no engine at all from 30–60 banked gold.**
4. **No timer means every player uses action-count effects to the full.** In Battlegrounds, effects that pay per refresh, buy, cast or sell are partly limited by how many actions a player can make before the timer. In Bramble a player can always take every action their gold allows. **[judgement]** Price per-action triggers at their gold-bounded maximum, not at Battlegrounds' observed use.
5. **Bramble's board opens classes neither game uses.** No Battlegrounds or Galaxy card moves units between slots, and one Battlegrounds card ever swaps Attack and Health **[data]**. Galaxy has two-row "in front of / behind" text on 20 characters and slot buffs on 44 **[data]**. Battlegrounds has neither. These classes are priced from the toy sim only.
6. **Battlegrounds dropped static auras; Bramble's geometry favours them again.** A back-row aura on the units in front realises about 100% of its nominal value; a front-row aura on the units behind realises about 5% (power-budget 6.3) **[sim]**. **[judgement]** Back-row auras are Bramble's cheapest-to-price support effect. Battlegrounds replaced auras with "this game" buffs, which are much harder to price.

---

## 2. How the taxonomy fits the budget

Every card text is four parts. Each part maps to one factor of the costing formula (power-budget 3):

> **cost = magnitude × triggers × realisation × condition × persistence**

| Part | Question | Formula factor | Section |
|---|---|---|---|
| **Effect** | What happens? | Magnitude (SP per firing), and persistence for "this game" effects | 3 |
| **Target** | To whom? | Realisation (geometry, fill) and persistence (tail) | 4 |
| **Trigger** | When, how often? | Triggers per fight or per turn | 5 |
| **Condition** | Only if? | Condition (chance it holds) | 6 |

Example: Battlegrounds' Wolf Pup (T3, "Rally: give your other minions +4/+1") is effect E01 (stat gain, 5 SP), target T07 (all friendly, about 6 others on a full board), trigger R22 (on attack, about 1–1.5 per fight for a front unit, temporary for the fight) and no condition.

**Tolerance** (owner, 2 Nov): plain cards ±15%, economy, scaling and engine cards ±25%. The last column of each effect table says which band a class falls in.

**The owner's examples, mapped:**

| Owner's words | Class |
|---|---|
| give a unit an additional ability | E20 keyword grant, E22 ability grant |
| change its stats | E05 stat set, E06 stat multiply, E07 stat swap, E15 stat loss |
| increase its stats | E01, E02, E03 |
| increase the power of future stat increases | E10 buff amplifier |
| give a specific type of stat increase | E04 single-stat, E12 type-wide buff, E16 slot buff |
| give a card that does this effect | E40 get a specific card |
| get a random card | E41 random card, E42 Discover |

---

## 3. Effects: what happens

Columns:
- **Now:** count of current solo Battlegrounds minions (of 273) / current tavern spells (of 76) / current Galaxy characters (of 314) **[data]**.
- **2020 → 2026:** share of the Battlegrounds minion pool, averaged over each year's monthly builds **[data]**.
- **Price:** SP of body the text costs at the tier it is printed. One-off means a single firing.
- **Risk:** no-timer risk, H/M/L (section 7).
- **Tol.:** tolerance band, ±15 or ±25.

### 3.1 Stats

| ID | Class | Examples | Now | 2020 → 2026 | Price | Risk | Tol. |
|---|---|---|---|---|---|---|---|
| E01 | Stat gain to another unit | Joyous, Wolf Pup, Banana spell | 62 / 29 / 103 | 23% → 25% | One-off: 0.9 × SP given (method 3.2). Typical text: +1/+1 at T1 = 1.8, +2/+2 at T3 = 3.6, +4/+4 at T5 = 7.2. Per trigger: × firings. Spells give 4 SP per gold at T1 and 5.5–6 at T3–4 **[data]** | L | 15 |
| E02 | Self stat gain | Glim Guardian, Lullabot, Wrath Weaver | 22 / 1 / 38 | 15% → 9% | One-off: 1.0 × SP. Per turn: s × (F+1)/2 × 0.8, with growth caps of about 0.8 / 1.3 / 1.7 / 2.5 / 3.8 SP per turn at T1–T5 (review 4.3–4.4) **[model]** | L | 25 |
| E03 | Temporary gain (this combat, until next turn) | Mini-Myrmidon, Humming Bird | 8 / 0 / 0 | 1% → 3% | SP × firings × realisation. A recruit card's "until next turn" buys one fight: about 0.4–0.6 of the permanent price **[guess]** | L | 15 |
| E04 | Single-stat gain (Attack or Health only) | Glim Guardian, Fortify, Pointy Arrow | 26 / 4 / 30 | 14% → 13% | Attack: 1.0 front, 0.75 back **[sim]**. Health: 1.0 in the sim; take 0.8–1.0 for Health-only growth, which the review found over-valued **[judgement]**. Battlegrounds prices +4 Attack and +2/+2 the same per gold **[data]** | L | 15 |
| E05 | Stat set ("set to 20/20") | Tyrael, Perfect Vision, Upper Hand | 1 / 3 / 0 | 0% → 1% | A one-off gain of (N − typical stats of the target at that tier). Late only **[guess]** | L | 15 |
| E06 | Stat multiply ("double its Attack") | Stone Age Slab, Brood of Nozdormu | 2 / 1 / 4 | 1% → 1% | Gives the target's current stats, so it grows with the game: at least V(t) at T5–6 **[guess]**. Battlegrounds prints it at T4–T7 only **[data]** | M | 25 |
| E07 | Stat swap | none current; 1 Battlegrounds card ever | 0 / 0 / 0 | 0% | 0–1 SP alone; value comes from rows (back Attack is 0.75) and Health-heavy scalers **[guess]** | L | 15 |
| E08 | Stat transfer and consume | Flaming Enforcer, Mind Muck, Heroic Underdog | 16 / 4 / 3 | 1% → 6% | Gives about V(shop tier) per use. Per turn, that is about V(t) of growth per turn, over every cap below T4 (review 4.3) **[model]**. Flaming Enforcer was 20 HP ahead by turn 10 in the review's sanity check **[data, model]** | H | 25 |
| E09 | Count-scaled body ("has +X for each") | Eternal Knight, Abyssal Bruiser; Galaxy Treasure Hoard | 5 / 0 / 51 | 1% → 2% | Per-turn scaling with s = X × the counter's rate. Body ratio 0.81: Battlegrounds charges this class more stats than any other **[data]** | M | 25 |
| E10 | Buff amplifier ("your spells give an extra +1/+1") | Azsharan Cutlassier, Fearless Foodie, Enchanted Sentinel | 14 / 0 / 29 | 0% → 6% | s = bonus × source events per turn, kept after sale. +1/+1 on 2 spells a turn = 4 SP a turn, over the T1–T3 caps **[guess]**. Body ratio 1.13: not charged in Battlegrounds **[data]** | M | 25 |
| E11 | Self-improving or future-copy improvement | Fire Baller, Tasty Lobster, Darkcrest Strategist | 20 / 0 / 4 | 0% → 6% | Per-turn scaling: improvement per turn × what it improves, with the tail for future copies **[model, guess]** | M | 25 |
| E12 | Type-wide persistent buff ("your Undead have +1 Attack this game") | Nerubian Deathswarmer, Volumizers, Forest Rover | 13 / 1 / 17 | 0% → 4% | Magnitude × units of that type now and later, with the full tail (method 3.2). Body ratio 0.87 **[data]** | L | 25 |
| E13 | Static aura | none current (Dire Wolf Alpha-style, retired) | 0 / 0 / 13 | 4% → 0% | Magnitude × targets × realisation × survival. Back unit on the units in front: realisation about 1.0, survival 0.9. Front unit on the units behind: about 0.05 **[sim]** | L | 15 |
| E14 | Shop buff ("units in the shop have +1/+1 this game") | Dune Dweller, Living Azerite, Them Apples | 7 / 3 / 9 | 0% → 3% | s = buff × units bought per turn (about 1–2), kept for the game **[guess]**. Not charged in Battlegrounds (body 1.11) **[data]** | H | 25 |
| E15 | Stat loss or debuff on enemies | Upper Hand; Galaxy Poison Apple | 0 / 1 / 1 | 0% | 1.0–1.2 × SP removed **[guess]** | L | 15 |
| E16 | Slot buff (stats on a board position) | Galaxy only: Presence of Gaia, Candy Claws | 0 / 0 / 44 | — | 1.0–1.2 × SP with the full tail, since the slot keeps it **[guess]** | L | 15 |
| E17 | Hand buff | Bream Counter, Twilight Tidehunter | 5 / 0 / 0 | 1% → 2% | 0.9 × SP, realised when played **[judgement]** | L | 15 |

### 3.2 Keywords, abilities and merging

| ID | Class | Examples | Now | 2020 → 2026 | Price | Risk | Tol. |
|---|---|---|---|---|---|---|---|
| E20 | Keyword grant | Bubble Gunner, Amber Guardian, Nadina; Fortify spell | 19 / 6 / 3 | 8% → 7% | Permanent, per power-budget 3.1: **Divine Shield 0.9 × A(t) = 1.8 / 3.0 / 4.4 at T1 / T3 / T5**; Reborn 0.4 × V(t) = 2.0 / 3.2 / 4.8 (power-budget v1 2.2 and 3.1, from the rows study); Venomous 0.25 × V = 1.25 / 2.0 / 3.0; Taunt 0; Windfury 0.8 × Attack. Re-granted each fight: the per-fight value each fight **[sim, data]** | L | 15 |
| E21 | Keyword removal | Sin'dorei Straight Shot | 1 / 0 / 0 | 0% | Keyword value × chance the enemy has it (0.3–0.5) **[guess]** | L | 15 |
| E22 | Ability grant (give new text) | Magicfin Mycologist; Galaxy Tsarmina, Bounty Contract | 1 / 0 / 4 | 0% → 1% | The granted text's price on the target × 1.1, since no slot is used **[guess]** | M | 25 |
| E23 | Merge (Magnetic) | Volumizers, Accord-o-Tron, Annoy-o-Module | 19 / 0 / 0 | 2% → 6% | Full stats and text at 1.0, plus about 1 SP for the slot saved. Battlegrounds charges Magnetic about 1 SP at T3 **[data]** | L | 15 |

### 3.3 Board

| ID | Class | Examples | Now | 2020 → 2026 | Price | Risk | Tol. |
|---|---|---|---|---|---|---|---|
| E30 | Summon | Harmless Bonehead, Flittering Bat, Cadaver Caretaker | 24 / 1 / 22 | 27% → 11% | Token SP × 0.7–0.9 in combat **[judgement]**. Battlegrounds charges a Deathrattle summon about 1.2 SP at T3 (all-time; 1.7 in the current pool) **[data]**. A Deathrattle summon refills its own slot (rulebook 8.4.1), so in front it restores protection | L | 15 |
| E31 | Summon or make a copy | Flighty Scout, Stitched Salvager | 5 / 0 / 2 | 1% → 3% | Gives the copied unit's current stats: price on expected late stats **[guess]** | M | 25 |
| E32 | Move or swap units (position change) | none in either game | 0 / 0 / 0 | 0% | 0–1 SP alone. With plain units placement is worth about 1.6 SP on the rows and one rule finds it; with two position cards it is worth 4.9 SP ([positioning-sim.md](positioning-sim.md) §1, §4.2) **[sim]**, so a move's value comes from position text on the board **[guess]** | L | 15 |

### 3.4 Cards

| ID | Class | Examples | Now | 2020 → 2026 | Price | Risk | Tol. |
|---|---|---|---|---|---|---|---|
| E40 | Get a specific card (named spell, Blood Gem, Coin) | Shell Collector, Gem Rat, Firescale Hoarder; Galaxy Treasure Find | 30 / 3 / 47 | 0% → 10% | The card's value × 0.9. A spell gives 4–6 SP per gold of its cost **[data]**. A Coin is 1 gold. Every turn = per-turn scaling | M | 25 |
| E41 | Get a random card | Tad, Headhunter Gryphon, Rogers; Recruit a Trainee | 23 / 4 / 13 | 1% → 8% | A random unit of tier k: **0.4–0.7 × V(k) while the board has space, 0.2–0.4 × V(k) on a full board** (a Created unit sells for 0) **[guess]**. T1 unit = 2–3.5 SP early | M | 25 |
| E42 | Discover | Patient Scout, Primalfin Lookout; A New Sprout | 8 / 11 / 18 | 1% → 2% | Random × 1.2–1.3 **[guess]**. Battlegrounds sells "Discover a Tier 1 minion" for 3 gold, the price of a buy **[data]** | M | 25 |
| E43 | Copy a card to hand | Cataclysmic Harbinger, Disguised Graverobber | 9 / 1 / 3 | 1% → 2% | A unit copy: 0.6–1.0 × V(k), stats plus triple progress **[guess]**. A spell copy: the spell's value | M | 25 |
| E44 | Take a shop card free (steal) | Decoy Conjurer; Enchanted Lasso | 2 / 2 / 2 | 0% | A free buy, 1–2 gold-equivalent in Bramble because the unit is Created and sells for 0 (rulebook 4.3.2). Enchanted Lasso costs 2 gold **[data]** | H | 25 |
| E45 | Discard | Brain Rotter, Mangled Bandit | 12 / 3 / 0 | 0% → 1% | Negative: the discarded card's value. It pays for discard payoffs **[judgement]** | L | 15 |

### 3.5 Economy

Gold prices come from the budget model (power-budget-review 1.4 and 4.5). They fall with the turn the gold arrives.

| ID | Class | Examples | Now | 2020 → 2026 | Price | Risk | Tol. |
|---|---|---|---|---|---|---|---|
| E50 | Gain gold | Southsea Busker, Shell Collector, Accord-o-Tron; Tavern Coin, Wealthy Bounty | 4 / 6 / 0 | 1% → 3% | **One-off: about 2 SP per gold at T1, about 5 at T2** (break-even bodies 2.8 and 2.2) **[model]**. **Recurring +1 per turn: about 2.4 / 4.0 / 3.9 / 2.5 SP at T1–T4** **[model]**. Caps: see power-budget.md 4.1 | H | 25 |
| E51 | Raise income ("maximum gold") | Snare Trapper; Strike Oil | 1 / 2 / 0 | 0% | Depends on rulebook 4.1.4. If it only lifts the 10-gold ceiling, it pays from turn 8: about 1–2 SP **[guess]**. If income rises at once, price as recurring +1 gold. **Question 2** | L | 25 |
| E52 | Free refresh (or another way to pay) | Refreshing Anomaly, Sly Infiltrator; Leaf Through the Pages | 3 / 1 / 5 | 0% → 1% | 1 gold early, 2–3 gold on a big turn, because it doesn't advance the count (method 4): about 1–2 SP each at T1–T3 **[judgement]** | H | 25 |
| E53 | Cost reduction | Ominous Seer; Frigid Blossom trinket | 1 / 0 / 0 | 0% → 1% | The gold saved. "Next spell costs 1 less" = 1 gold; an upgrade discount = 1 gold **[judgement]** | M | 25 |
| E54 | Sell value | Tortollan Blue Shell | 1 / 0 / 0 | 0% → 1% | Extra gold at sale, delayed **[judgement]** | M | 25 |
| E55 | Pay hero Health instead of gold | Malchezaar; Hasty Excavation | 1 / 1 / 0 | 0% → 1% | 1 hero Health is about 0.3–0.5 gold early, while the damage caps (5 / 10 / 15) make losses cheap **[guess]** | M | 25 |
| E88 | Activate cost ("pay N gold: effect", once per turn; R11) | the R11 cards: Suspicious Prisonguard, Brain Rotter, Clever Castaway | see R11 | see R11 | Added with power-budget v1 revision 2, not by the text patterns. Per use: the effect's value − N × 2.0 SP (the late sink, power-budget 4.6). If the effect is permanent stats, it is per-turn scaling with s = that net value, under the growth caps (power-budget 3.4) **[data, judgement]** | L | 25 |

### 3.6 Shop

| ID | Class | Examples | Now | 2020 → 2026 | Price | Risk | Tol. |
|---|---|---|---|---|---|---|---|
| E60 | Shop contents control ("refresh with type X") | Snarky Shark; Lost Staff of Hamuul, Saloon's Finest | 4 / 2 / 14 | 0% → 1% | About 1 free refresh plus better odds: a targeted refresh is worth 2–3 normal ones for finding one type **[guess]** | H | 25 |
| E61 | Act on a shop unit (buff, consume, steal, make Golden) | Waveling, En-Djinn Blazer, Insatiable Ur'zul | 16 / 8 / 0 | 0% → 6% | Consume: see E08. Buff a shop unit then buy it: a one-off E14 **[guess]** | H | 25 |
| E62 | Tier jump (higher-tier cards) | Greedy Conniver; Robust Evolution | 2 / 2 / 4 | 0% | Up a tier: V(k+1) − V(k), about 1–2 SP plus better text. Discover from T6–T7: about V(6–7) **[guess]**. Body ratio 1.32 **[data]** | L | 15 |
| E63 | Freeze | none current | 0 / 0 / 0 | 0% | 0: freezing is a free action (rulebook 4.5) | L | 15 |

### 3.7 Removal and transformation

| ID | Class | Examples | Now | 2020 → 2026 | Price | Risk | Tol. |
|---|---|---|---|---|---|---|---|
| E70 | Transform | Robust Evolution; Galaxy True Love's Kiss, Stroke of Midnight | 0 / 1 / 7 | 1% → 0% | V(result) − V(source). On an enemy it is removal **[guess]** | L | 15 |
| E71 | Destroy | Leeroy the Reckless; Butchering | 5 / 1 / 3 | 0% → 1% | Enemy: its SP × chance to hit; Venomous is the reference at 0.25 × V. Destroying your own unit as a cost is a drawback worth +36–46% of the budget **[data]** | L | 15 |
| E72 | Deal damage | Boom-in-a-Box, Wildfire Elemental, Obsidian Ravager | 5 / 0 / 7 | 5% → 3% | 0.7–1.0 × damage in SP; overkill is wasted; area damage hits your own too **[guess]** | L | 15 |
| E73 | Make Golden | Elite Navigator, Captain Sanders; Golden Touch | 4 / 2 / 2 | 0% → 1% | About V(k) + the doubled text, with no Triple Reward. Battlegrounds keeps it to T5+ or 4–5-gold spells **[data]** | L | 25 |

### 3.8 Rules and retriggers

| ID | Class | Examples | Now | 2020 → 2026 | Price | Risk | Tol. |
|---|---|---|---|---|---|---|---|
| E80 | Multiplier ("trigger twice") | Brann, Titus, Drakkari Enchanter, Balinda | 7 / 0 / 3 | 1% → 2% | The sum of the doubled effects on the expected board. T5+ only **[judgement]**. Battlegrounds prints it at T4–T6 with body 0.87 **[data]** | H | 25 |
| E81 | Trigger another unit's effect | Kelp Keeper, Young Murk-Eye, Deathstrider | 5 / 0 / 0 | 2% → 1% | The triggered effect's value × uses **[judgement]** | H | 25 |
| E82 | Cast a spell for free | Cagey Conjurer, Runic Arcanist, Air Revenant | 8 / 0 / 9 | 0% → 2% | The spell's value per cast **[data]** | M | 25 |
| E83 | Attack behaviour (attacks immediately, can't attack, Ranged, Sneak) | Heroic Broodmother, Eternal Tycoon | 3 / 0 / 15 | 2% → 1% | Attacks immediately: about one extra attack, about A(t) SP. Can't attack: a drawback **[guess]** | L | 15 |
| E84 | Hero effect (Armor, heal) | Armor Stash; Soul Rewinder | 4 / 1 / 7 | 2% → 2% | 1 Armor is worth about 2–5 SP-fights (0.2–0.67 HP per SP per fight, review 3) **[model, guess]** | L | 15 |
| E85 | Game-rule change (triples, hand, hero power) | Elemental of Surprise, Thorned Trailblazer | 4 / 3 / 9 | 0% → 1% | No unit budget: review each one as a system **[judgement]** | M | 25 |
| E86 | Duos only: Pass and teammate | Portal spells | 0 / 3 / 0 | — | Out of scope | — | — |
| E87 | Trigger rewiring ("Recruit abilities are also Farewell") | Galaxy treasures only | 0 / 0 / 0 | — | No unit budget: system-level **[judgement]** | M | 25 |

**Printed keywords** (a card that simply has Divine Shield) are priced in power-budget 3.1 and aren't repeated here.

---

## 4. Targets: to whom

| ID | Target | Now (BG minions / Galaxy chars) | 2020 → 2026 | Price modifier |
|---|---|---|---|---|
| T01 | Self | 44 / 98 | 24% → 16% | × 1.0: it is body |
| T02 | Adjacent (same row) | 10 / 4 | 5% → 5% | Mean 1.43 neighbours on a full Bramble board (F1, F4, B1, B3 have 1; F2, F3, B2 have 2; rulebook 8.2) **[data]**. Battlegrounds adjacent auras realise 0.4–0.7 **[sim]** |
| T03 | Left-most, right-most, first | 9 / 3 | 2% → 2% | One target. Per row in Bramble (rulebook 8.2.5) |
| T04 | **In front of, behind, row** | 0 / 20 | — | From a back unit: 2 in front, static aura realises about 1.0, "when this attacks" about 0.15 alive. From a front unit: 1.5 behind, static aura about 0.05, one-off Start of Combat about 0.75 × 0.9 (power-budget 6.3) **[sim]** |
| T05 | One chosen friendly | 19 / 1 | 9% → 8% | × 0.9 one-off: the player picks well (method 3.2) |
| T06 | Random friendly | 1 / 1 | 5% → 0% | × 0.8–0.9; random single targets can hit either row (owner, 27 Oct) **[guess]** |
| T07 | All friendly | 19 / 30 | 2% → 7% | × units on board: about 1 early, 7 by turn 6–7 (method 6.3) |
| T08 | Tribe subset | 48 / 41 | 36% → 22% | × 0.6 for "a friendly X", × 0.3 per unit for "for each X" (method 3.3) |
| T09 | Hand | 13 / 0 | 2% → 5% | × 0.8–0.9, realised on play **[guess]** |
| T10 | Shop | 19 / 20 | 1% → 7% | Realised only on buy: × share of shop units bought **[guess]** |
| T11 | Enemy | 3 / 13 | 7% → 1% | Random enemy: either row |
| T12 | Future cards and "this game" | 45 / 30 | 1% → 16% | Full tail: it stays after the source is sold (method 3.2) |
| T13 | Hero or player | 15 / 8 | 4% → 3% | See E84 |
| T14 | **Slot** | 0 / 49 | — | Full tail: the slot keeps it **[guess]** |

T04 and T14 are Bramble's new targeting space. Battlegrounds has none of either.

---

## 5. Triggers: when and how often

Expected firings feed the formula's "triggers" factor. Counts are current Battlegrounds minions / current Galaxy characters **[data]**.

| ID | Trigger | Now | 2020 → 2026 | Expected firings | Risk |
|---|---|---|---|---|---|
| R01 | Battlecry (Galaxy: Recruit) | 46 / 45 | 26% → 18% | 1; 2 with a doubler | L |
| R02 | Start of turn | 1 / 3 | 2% → 1% | 1 per turn × fights left | L |
| R03 | End of turn | 17 / 0 | 4% → 7% | 1 per turn × fights left | L |
| R04 | After you play a unit | 12 / 9 | 4% → 4% | 1.5–3 per turn **[guess]** | M |
| R05 | After you buy | 4 / 0 | 0% → 1% | 1.5–3 per turn; up to gold ÷ 3 with no timer **[guess]** | H |
| R06 | When sold | 13 / 1 | 1% → 4% | 1–2 per turn **[guess]** | H |
| R07 | On spell cast | 19 / 14 | 0% → 5% | 1–3 spells per turn, more with spell generators **[guess]** | H |
| R08 | Spellcraft | 11 / 0 | 0% → 5% | 1 per turn plus on play (rulebook 11.4.2) | L |
| R09 | **On gold spent** ("after you spend N gold") | 5 / 0 | 0% → 2% | Gold spent ÷ N: 10 ÷ N on income alone, more with bank and engines | **H** |
| R10 | **On refresh** | 4 / 0 | 0% → 2% | 2–5 refreshes on a normal turn, 20–30 on an engine turn | **H** |
| R11 | Activate (pay gold, once per turn) | 23 / 0 | 0% → 2% (8% now) | 1 per turn (rulebook 11.4.5) | L |
| R12 | Choose One | 10 / 0 | 0% → 2% | 1 | L |
| R13 | On merge | 3 / 0 | 0% → 1% | Per merge | M |
| R14 | On card gained | 2 / 21 | 0% | Per card gained | H |
| R15 | On discard | 3 / 0 | 0% | Per discard | M |
| R16 | On Golden or triple | 3 / 7 | 0% | Per golden | L |
| R20 | Start of Combat (Galaxy: each fight) | 13 / 27 | 1% → 4% | 1 per fight | L |
| R21 | Deathrattle (Galaxy: Farewell) | 49 / 47 | 25% → 22% | About 1 per fight if it dies: front units die 98–99% of fights, back units 67–83% **[sim]** | L |
| R22 | On attack (Rally) | 33 / 13 | 4% → 11% | Front about 1–1.5 attacks per fight, back about 0.5–1 **[guess, from the exposure table]** | L |
| R23 | On kill (Galaxy: Hunt) | 1 / 40 | 1% → 0% | About 0.5 per fight for a front unit **[guess]** | L |
| R24 | On damage taken | 2 / 4 | 2% → 2% | Times attacked: front 0.6–1.15, back 0.33–0.71 per fight **[sim]** | L |
| R25 | On friendly death, Avenge (N) | 7 / 2 | 4% → 4% | Friendly deaths ÷ N; about 4–6 deaths in a lost fight **[guess]** | L |
| R26 | On summon | 5 / 3 | 4% → 2% | Per summon | L |
| R27 | Loses Divine Shield, is Reborn | 3 / 0 | 2% → 1% | Per event | L |
| R28 | Win, lose or tie a fight | 1 / 6 | 0% | Win rate × fights | L |
| R29 | On hero damage | 4 / 0 | 1% → 1% | Per hit | M |
| R30 | Counter or quest ("(N left!)") | 17 / 51 | 0% → 6% | Fires once reached; thresholds don't double on golden (power-analysis 3) **[data]** | L |
| R31 | No trigger (static, or a spell's immediate effect) | 25 / 40 | 20% → 9% | Always on | L |

Notes:
- **Galaxy's dominant triggers differ.** Hunt (on kill) is on 40 Galaxy characters and 1 Battlegrounds minion; quests and counters on 51. Galaxy has no gold, so it has no gold-spent or refresh triggers.
- **Combat triggers are low risk for the timer question.** They are bounded by the fight and by the runaway limits (rulebook 9.10).

---

## 6. Conditions

| ID | Condition | Now (BG minions / Galaxy chars) | 2020 → 2026 | Price factor |
|---|---|---|---|---|
| C01 | Names a tribe | 71 / 84 | 45% → 31% | × 0.6 or × 0.3 (method 3.3). Battlegrounds charges almost nothing (−0.02) **[data]** |
| C02 | Position (adjacent, left-most, slot, row) | 16 / 67 | 6% → 6% | × chance the related slot is filled (power-budget 6.3) |
| C03 | Threshold or counter | 17 / 1 | 0% → 6% | Triggers = turns or fights in which it is reached |
| C04 | **Limiter** (once per turn, N times per combat) | 16 / 5 | 0% → 5% | Caps the triggers. The main content tool for bounding recruit engines (G1) |
| C05 | State check (if you have, while) | 12 / 11 | 2% → 3% | × chance the state holds |
| C06 | Random outcome | 34 / 30 | 15% → 11% | Random target × 0.8–0.9 **[guess]** |
| C07 | Hand | 12 / 0 | 2% → 5% | Realised on play |
| C08 | Golden | 10 / 13 | 0% → 3% | × chance of a golden, low early |

**Limiters grew from 0% to 5% of the pool** as Battlegrounds added more recruit engines **[data]**. They are how a strong engine is printed without a loop.

---

## 7. No turn timer: which classes are risky

### 7.1 Why

The owner chose no turn timer: fights are async against snapshots, so the economy has to run out by itself. Only the paid refresh escalates (1 gold for refreshes 1–10, 2 for 11–20, 3 from 21; rulebook 4.4.3). Free refreshes don't count (4.4.5). Gold carries over with no cap (4.1.2–4.1.3). The owner's target: the strongest engines see **about 20–30 shops in a turn**.

### 7.2 Two kinds of engine

- **Per-action engines** pay per refresh, buy, cast or sell. The refresh steps bound them: a reward worth 1 gold per refresh breaks even at refresh 1–10, then loses 1 gold per refresh at 2 gold and 2 at 3 gold. It loops forever only if it returns 3 gold-equivalent per refresh or more.
- **Per-gold engines** pay per gold spent (R09: Tethys, Rogers, Gunpowder Courier). They return the same share r of every gold, whatever the refresh price. **Rising refresh cost doesn't bound them.** If r reaches 1, the loop is infinite at any price.
- **Free refreshes** skip the steps. A source of free refreshes that a per-action engine can feed is a loop (content guardrail G1).

### 7.3 Shops per turn

Total gold available = starting gold ÷ (1 − r), where r is the gold-equivalent returned per gold spent. Shops seen at Bramble's refresh steps **[data: rulebook 4.4.3 arithmetic]**:

| Starting gold | r = 0 | 0.5 | 0.67 | 0.75 | 0.8 | 0.9 |
|---|---|---|---|---|---|---|
| 10 (one turn's income) | 10 | 15 | 20 | 23 | 26 | 43 |
| 30 (banked) | 20 | 30 | 40 | 50 | 60 | 110 |
| 60 (banked) | 30 | 50 | 70 | 90 | 110 | 210 |

Reading:
- **From one turn's income, 20–30 shops needs r of about 0.67–0.85.** The limit on r is in the one guardrail list, [economy-bounding.md](economy-bounding.md) §7 (G2, G11).
- **Banked gold alone reaches the target.** 30 banked gold buys 20 shops and 60 buys 30, with no engine. With an engine on top, a banked turn goes far past 30. Whether the 20–30 target includes banked gold is **question 1**.
- Buying units also spends gold and feeds per-gold engines; the table counts only refreshes, so it is an upper bound on shops for a given r.

### 7.4 The classes, by risk

**High.** These can feed themselves in the Recruit Phase, so without a timer only gold and content bound them:

| Class | Why | Battlegrounds case |
|---|---|---|
| E52 free refresh, E60 shop control | Skip the only escalating cost | Refresh anomaly × golden Brann loop (G1) |
| R09 on gold spent | Escalation doesn't touch r | Tethys, Rogers, Captain Flat Tusk, Darkgaze Elder |
| R10 on refresh, E14/E61 shop effects per refresh | Pay per refresh; full use with no timer | Waveling, En-Djinn Blazer (+10/+10 per refresh) |
| R05, R06, R07, R14 on buy, sell, cast, card gained | Fed by card generators and free cards | The Shadow of Doubt, spell engines |
| E50 gold from recruit triggers | Gold that returns gold | Accord-o-Tron is per turn (safe); per-action gold isn't |
| E44 free shop cards, E41/E40 cards that make gold or spells | Free inputs for buy and cast triggers | Enchanted Lasso, Rogers' Bounties |
| E80 multiplier, E81 retrigger on recruit triggers | Double every other risk | Brann, Kelp Keeper |
| E08 consume per action | Stats per refresh or per cast | Felboar, Insatiable Ur'zul |

**Medium.** Bounded per turn, but realised in full with no timer: per-turn scaling (E09–E12), Discover chains (E42), merges (R13), self-damage for gold (E55; bounded by the hero's Health).

**Low.** Combat effects and keywords. Fights have their own runaway limits (rulebook 9.10), and async doesn't change them.

### 7.5 Content rules (proposals)

The content rules this section proposed are merged into the one guardrail list in [economy-bounding.md](economy-bounding.md) §7 (owner, 2 Nov: "One list in bounding"); all are proposals awaiting the owner. The limit on r per gold is G2 there (0.5 on the strongest board, not 0.6 per card); per-action engines are G3 and G8; free cards checked against every engine are in G10. Pricing per-action triggers at full use is a pricing rule, in [power-budget.md](power-budget.md) 3.5.

---

## 8. What Battlegrounds charges stats for

Mean body ratio of all-time cards with each class, from the CSV **[data]**. Below 1 means the text was paid for in stats. Selection bias applies (power-analysis 2): engines are often under-statted on purpose.

- **Charged:** count-scaled bodies 0.81, multipliers 0.87, type-wide persistent buffs 0.87, Discover 0.92, Deathrattle 0.92, stat transfer 0.93.
- **Not charged:** buff amplifiers 1.13, shop buffs 1.11, gold 1.11, free refreshes 1.24, card generation 1.01–1.04, Activate 1.23.
- **[judgement]** Battlegrounds prices recruit-phase value by tier, not by stats (power-analysis 2). Bramble's method charges it in stats on purpose (power-budget 3.2). The classes in the "not charged" list are where Bramble's prices will differ most from Battlegrounds and where playtests will move them most.

---

## 9. Limits

- **The classifier is crude.** Each class is a simple text pattern, run once on 2 Nov over 991 solo minions, 112 pool spells, 420 trinkets, 607 other texts (hero powers, anomalies, quests, buddies, Timewarped) and 603 Galaxy cards. Spot checks on the current-pool lists show a few wrong or missed cards per class. Use the counts as sizes, not exact numbers. The patterns live in a scratch script that is not yet in the repo; committing it as `tools/research/effect_taxonomy.py` is a follow-up.
- **History uses today's text.** The yearly shares apply each card's latest text to the pools it was in. Cards reworded over time are counted with their new text.
- **Duos-only cards are left out** (30 of the current 303 minions).
- **Most prices are rough.** Only keywords, stat gains, single stats, gold and scaling rates rest on data or the model. The rest are marked [guess] and are for iteration, as the owner said: "we're going to get things wrong… iterate".
- **Bramble-new classes** (E07, E16, E32, T04, T14) have no card data in Battlegrounds. They rest on the toy sim and Galaxy.

---

## 10. Questions for the owner

1. *Deferred (owner, 2 Nov): turn length and shop targets wait for later power budgeting; see economy-bounding.md.* **Does the 20–30 shop target include banked gold?** With no cap on carry-over, 60 saved gold buys 30 shops with no engine (section 7.3). If the target is per turn's income, engines need r under about 0.67–0.85. If it includes the bank, either banked turns go far past 30, or late refreshes need more steps.
2. **What does "increase maximum gold" do in Bramble?** Rulebook 4.1.4 says it lifts the 10-gold ceiling. Read that way, it does nothing before turn 8 and is weak. If it should raise income at once, as in Battlegrounds, it is a recurring +1 gold and much stronger.
3. **Where should strong shared economy live?** Battlegrounds puts most of it in spells, trinkets and hero powers (11–14%), not tribe minions (3%). Should Bramble do the same with tavern spells, or put more economy on tribe units?
4. **Which Bramble-new classes do you want in v0?** Moving or swapping units, Attack-Health swap, slot buffs (Galaxy's core, persistent), and in-front/behind targeting. Each adds depth to the rows but has no Battlegrounds data to price it.
5. **Are combat-earned free refreshes allowed under G1?** Battlegrounds has "whenever this takes damage, gain a free refresh (3 times per turn)" and "whenever a Rally minion attacks, gain a free refresh". They are bounded by the fight, not by a once-per-turn rule.
