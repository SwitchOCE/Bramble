# Bramble power budget: methodology v0

**Status: draft for the owner's review, 27 October 2026.** This is a method, not a card list. The numbers are starting points to be replaced by simulation, and each one is marked as **[data]** (from the Battlegrounds or Galaxy analysis), **[sim]** (from the toy combat simulation) or **[judgement]** (my call, to be tested).

Evidence: [docs/research/battlegrounds/power-analysis.md](../research/battlegrounds/power-analysis.md), produced by `tools/research/power_budget.py`. Rules assumed: Battlegrounds baseline plus the decided Bramble differences in [direction-summary.md](direction-summary.md) (carry-over gold, escalating rerolls, fixed-slot staggered 4-3 board, front row first in the attack order, back row untargetable while any front unit lives).

## 1. The unit of value

**One stat point (SP)** is 1 Attack or 1 Health on a plain unit at an average position, measured by how much it raises the chance of winning a single fight against tier-matched boards.

- Everything else, including keywords, triggers, gold and position, is converted into SP-equivalents at a given tier.
- A card's budget is spent once. Body stats + the SP-equivalent of its text = the tier budget.
- SP-equivalents depend on tier. Divine Shield, for example, is worth about one enemy attack, and enemy attacks grow with tier **[sim]**. Every conversion is therefore a function of tier, not a constant.

Why SP and not gold: Battlegrounds minions all cost 3 gold, so gold can't separate tiers. A board slot, not gold, is the scarce resource **[data]**: buff spells buy stats 2–3× cheaper per gold than minion bodies do.

## 2. Baseline curve

**V(t), the stat total of a unit with no text**, at tier t:

| Tier | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|
| V(t) | 5 | 7 | 8 | 10 | 12 | 14 | 18 (placeholder) |
| Battlegrounds median, current pool **[data]** | 4.5 | 6 | 7 | 9 | 10 | 12.5 | 19 |
| Galaxy median by rarity **[data]** | 4 (Common) | — | 7 (Uncommon) | — | — | 12 (Rare) | 16 (Epic) |

Where V(t) comes from:

- **Basis [data]:** a Battlegrounds card with none of the classified features carries 1.04–1.13 × its tier median. V(t) is about 1.1 × median, rounded. That is about 1.8 × t + 3.
- **Linear, not exponential [data]:** the two fit Tiers 1–6 equally well (R² 0.50 against 0.51). Linear is simpler to reason about. Revisit if whole-game sims show late tiers need a steeper step.
- **Attack share [data]:** the default split is 45–50% attack, as in Battlegrounds. Row-bound units adjust it (section 6).
- **Spread [judgement]:** Battlegrounds' interquartile range is about ±2 SP around the median at every tier, and its tuning steps are ±1–2 SP or ±1 tier **[data]**. Bramble's tolerance should be tighter than its spread. **Target: each card's measured SP-equivalent within ±10% of V(t), or ±1 SP, whichever is larger.**

Tier 7 needs its own rules (how it is reached, what it is for) before it gets a budget.

## 3. Costing an effect

Every effect is costed with one formula:

> **cost = magnitude × triggers × realisation × condition × persistence**

| Factor | Meaning | Where its value comes from |
|---|---|---|
| **Magnitude** (SP) | Stats moved per trigger. +2/+2 = 4. +1 Attack to two units = 2. Divine Shield ≈ the mean enemy Attack at that tier. 1 gold = G(t) SP (section 4). | Card text; [sim] for keywords |
| **Triggers** | Expected firings per fight (combat effects) or per turn (recruit effects) | [sim] per fight; [judgement] per turn until whole-game sims exist |
| **Realisation** | Share of the magnitude that turns into win rate. It depends on timing and geometry: a buff given after the target has attacked is wasted. | [sim], section 6 table |
| **Condition** | Chance the condition holds: tribe on board, neighbour present, threshold reached | Lobby tribe odds; board-fill tables (section 6) |
| **Persistence** | How long the value lasts: this fight only, permanent while held, or permanent after the card is sold | Section 3.2 |

The card's body is then **V(t) − Σ cost**, split into attack and health with the row rules in section 6.

### 3.1 Keywords (v0 values)

Values are per tier, for a full board. A = mean enemy Attack at the tier: 2.0, 2.5, 3.3, 4.0, 4.9, 6.1 for Tiers 1–6 **[data]**.

| Keyword | v0 cost | Evidence and notes |
|---|---|---|
| Taunt | 0 SP plus the value of what it protects | Sim: 0.0–0.1 SP on vanilla boards. Battlegrounds charges about 0 **[data]**. On Bramble's board the front row already shields the back, and back-row Taunt does nothing while the front lives. **Open question: keep Taunt at all?** Galaxy has none. |
| Divine Shield | 0.9 × A | Sim: 1.0–1.2 × A in either row. Battlegrounds charges about 0.25 × median, roughly 0.6 × A **[data]**. **[judgement]** Take the midpoint, because real boards carry DS counters (Venomous, cleave, AoE) that the sim lacks. |
| Reborn | 0.2 × V(t) until simulated | Battlegrounds charges 0.18–0.27 × median **[data]**. Needs a sim with summon placement: the reborn unit takes the dead unit's slot. |
| Venomous | 0.25 × V(t) until simulated | Battlegrounds charges about 0.25 **[data]** |
| Windfury | Simulate case by case | It multiplies attack. Battlegrounds puts it on big bodies, not on cheap ones **[data]**. Cost it as about +0.8 × own Attack (one more attack if the unit survives its first trade) **[judgement]** and check in the sim. |
| Cleave / adjacent splash | Simulate | Depends on the number of enemy front neighbours: F1 and F4 have 1, F2 and F3 have 2, and the count falls as the front dies. |

### 3.2 Timing classes

**Combat-only effects** (Start of Combat, Deathrattle, Avenge, "when this attacks", auras). Value is measured per fight in the sim, so cost = SP-equivalent per fight. These are the easiest to calibrate. In Battlegrounds, death effects take 11–24% of the body **[data]**.

**One-shot recruit effects** (Battlecry: give +X/+Y). The buff stays on another body for every later fight while that body is kept. Cost = magnitude × realisation of the target's row, with no per-turn growth. **[judgement]** Treat the buff as body stats delivered elsewhere at 0.9 per SP: the player picks a good target, but the buff takes a slot's worth of setup.

**Per-turn scaling** (End of turn, Start of turn, "permanently", "this game"). This class is the main power-creep risk. Battlegrounds' share of scaling text went from about 6% of the pool in 2020 to 32% in 2026, while printed stats stayed flat **[data]**.

Cost scaling by its average contribution per fight. If a unit adds s SP permanently each turn and is held for H fights, the extra stats on the board over those fights are s, 2s, …, H × s. The average is:

> **per-fight equivalent = s × (H + 1) / 2**

Add a **tail** if the buffs stay after the source is sold: buffs on other units persist, buffs on the unit itself don't. The tail is s × H for each remaining fight in which the buffed units are kept. v0 counts half the tail **[judgement]**.

H(t) is the expected number of fights a unit of tier t is held. v0 placeholders **[judgement]**: H = 3 for Tiers 1–2, 4 for Tiers 3–4, 5 for Tiers 5–6. Whole-game simulations and playtests must measure H.

**Economy** (gold, free refreshes, discounts). See section 4.

**Charge rate for recruit-phase value.** Battlegrounds barely charges stats for economy, card generation or recruit-phase buffs; those coefficients are −0.02 to −0.06 **[data]**. Recruit-phase cards are priced by tier and sold before late fights. Bramble's position:

- **[judgement]** Charge per-turn scaling at 100% of its SP-equivalent, because its output is combat stats, the same currency as the body.
- **[judgement]** Charge economy at 50% of its gold value in body stats, and hold economy to a separate gold budget per tier (section 4).
- Both rates are stricter than Battlegrounds on purpose. The previous project's problems and Battlegrounds' own creep both point at under-priced scaling.

### 3.3 Conditions and tribe dependency

- **Tribe conditions:** cost × the chance the tribe text is live. v0 **[judgement]**: 0.6 for "a friendly <Tribe>" on a mid-game board, 0.3 for "for each <Tribe>", counting about half the board as the tribe in a committed build.
  - Battlegrounds charges almost nothing for tribe dependency (−0.02 **[data]**). Its lobbies remove tribes rather than discounting the cards.
  - Bramble also has a subset of tribes per game. Measure live rates in whole-game sims.
- **Thresholds and counters** ("Avenge (3)", "after 5 spells"): triggers = expected fights or turns in which the threshold is reached. Thresholds don't double on golden (section 5).
- **Drawbacks** give stats back. Battlegrounds adds 36–46% of the tier budget for a real drawback **[data]**, such as self-destruction, losing stats or damaging your hero. Cost drawbacks with the same formula and a negative magnitude.

## 4. Gold, carry-over and escalating rerolls

**Value of 1 gold, G(t) [judgement, anchored on data]:**

- **Body anchor:** a plain body costs 3 and sells for 1, so it buys V(t) SP for 2 net gold. That sets the floor: **G(t) = V(t) / 2**, which is 2.5, 3.5, 4, 5, 6 and 7 SP for Tiers 1–6.
- **Spell cross-check [data]:** Battlegrounds single-target buff spells give 4 SP per gold at Tier 1 and 5.5–6 at Tiers 3–4. That agrees at the low tiers.

**Two budgets.** An economy card has a body budget in SP, charged at 50% (section 3.2), and a gold budget: the net gold it returns over its expected hold must not exceed a cap per tier.

- v0 cap **[judgement]**: 1 gold per turn at Tiers 1–3, 2 per turn at Tiers 4–6.
- Effects that convert gold into gold ("for each gold you spend…") need a loop guard, not a price. Galaxy added a shop cap of 30 per turn after real loop problems **[data]**.

**What carry-over gold changes (Battlegrounds: use it or lose it; Bramble: no cap, no interest):**

- **No waste.** Gold generated on a turn with nothing to buy is banked instead of lost. Economy is therefore worth at least as much as in Battlegrounds. **v0 carry factor: ×1.1 [judgement].**
- **Burst turns.** Banking lets players save for a big turn: level up and buy several units at once. That makes "next turn" and "start of turn" gold no worse than gold now. Cost them the same.
- **Snowball risk.** Without a cap, a recurring income unit pays out every turn it is held, and the bank grows. That is why recurring income gets the per-turn gold cap above rather than a discount.

**What escalating rerolls change** (1 gold, then 2, then 3 after set counts in a turn; first threshold about 10):

- The marginal value of gold falls on big turns. Once the player is past the first threshold, gold spent on rerolls buys half as many shop views. For gold that is likely to go into rerolls, cost **G(t) × 1.0 below the threshold, × 0.5 between thresholds and × 0.33 above them [judgement]**.
- Buying units is unaffected (3 gold each).
- **Free refreshes** are worth the reroll price at the moment they are used. If they don't advance the escalation counter, they are worth 1 gold early and 2–3 gold on a big turn, which makes them stronger in Bramble than in Battlegrounds. **Open question below.**
- **Net effect [judgement]:** carry-over raises the value of steady income, and escalation lowers the value of very large single-turn income. The budget should favour small, steady economy and price spiky economy at the escalated rate.

## 5. Golden and triples

Battlegrounds' rule is exact in the data **[data]**:

- **Body:** golden = 2 × attack and 2 × health (977 of 981 minions ever in the pool).
- **Effects:** magnitudes double (208 of 283 numbers in the current pool), counters and thresholds stay the same (75), and some texts are reworded to trigger twice (121).
- **Reward:** a Triple Reward discovers a minion from the next tier up.

Bramble v0 follows that rule. It gives one check per card: **the golden version, costed with the same formula, should come out at 2 × V(t) ± 15%.** Effects that don't double cleanly fail the check and need a golden-specific line:

- effects capped by geometry (a back unit has at most two units in front of it);
- keywords that can't double (Divine Shield, Taunt);
- effects that multiply each other.

The Triple Reward is outside the unit budget. It is part of the tier-up economy and is priced with tavern progression.

## 6. The fixed-slot staggered 4-3 board

```
 front   [F1]  [F2]  [F3]  [F4]
 back       [B1]  [B2]  [B3]
```

All [sim] values come from the toy simulation: vanilla units, Tier 2 and Tier 5 boards, front row then back row attack order. They are the starting coefficients for the full simulation.

### 6.1 Row value of Attack and Health

| | Front row | Back row |
|---|---|---|
| 1 Attack | 1.0 SP (F1 about 1.15, F4 about 0.9: earlier slots attack more often) | **0.75 SP** |
| 1 Health | 1.0 SP | 1.0 SP |
| Divine Shield | about 1.1 × A | about 1.1 × A |
| Times attacked per fight | 0.6–1.15 | 0.33–0.71 |
| Survives the fight | 1–2% | 17–33% |

- **Health is worth the same in both rows [sim].** Once the front falls, the back takes every hit. Health in the back isn't wasted, and it isn't extra valuable.
- **Back-row Attack is worth 0.72–0.75 of front-row Attack [sim].** Back units attack after the front has traded, so fewer of their attacks happen before the fight is decided.
- **Placement of vanilla units barely matters [sim].** Putting the tanks in front instead of at random moves win rate by at most 1.5 points. Bramble's position decisions must come from text, which is the point of the two rows. With stats alone the board is nearly flat.

**Costing rule.** A unit that can go anywhere has its body costed at 1 SP per stat, at the average position. A unit whose text ties it to a row is costed with that row's values:

- A back-bound unit's attack costs 0.75 SP per point, so it can print about a third more attack for the same budget.
- A front-bound unit's attack costs 1.0, or about 1.1 if its text favours the left slots.

### 6.2 The value of back-row protection

- Back units survive the fight 10–20× as often as front units, and are attacked half as often **[sim]**.
- This doesn't raise the value of their stats (6.1), but it does raise the value of **anything that works while the unit is alive**: auras, "whenever…" triggers, Rally-style "when this attacks".
- v0 survival factor for "while alive" effects **[judgement, from the exposure table]**: **0.9 in the back row, 0.5 in the front row.**

### 6.3 "In front of" and "behind": expected neighbours

Static geometry, which applies in the recruit phase and at Start of Combat:

| Board | Units in front of a back unit | Units behind a front unit |
|---|---|---|
| Full (7) | 2 | F1, F4: 1; F2, F3: 2; mean 1.5 |
| 6, back gap at B1 | B2, B3: 2 | F1: 0, F2: 1, F3: 2, F4: 1 |
| 5 (F1–F4 + B2) | 2 | F1, F4: 0; F2, F3: 1 |
| 4 (F2, F3 + B1, B3) | B1: 1, B3: 1 | F2: 1, F3: 1 |
| 3 (F2, F3 + B2) | 2 | 1 each |

In combat it depends on attack order. This is the most important geometry result **[sim]**:

| Moment | Expected living neighbours (full board) | Consequence |
|---|---|---|
| A back unit attacks | **0.14–0.17 in front** (0 in 85–87% of attacks) | "When this attacks, buff the units in front of it" is nearly worthless. |
| A front unit attacks | 1.5 behind | "When this attacks, buff the units behind it" works. |
| A front unit dies | 1.47 behind (at least 1 in 98% of deaths) | "When the unit in front of this dies" fires about **1.9 times per back unit per fight**. |

Realisation of position auras on a full board **[sim]**:

| Effect | Realised share of nominal SP |
|---|---|
| Back unit: "units in front of this have +X Attack" | **about 100%** (95–119%) |
| Front unit: "units behind this have +X Attack" | **about 5%** (0–7%) |
| Battlegrounds adjacent aura, for comparison | 40–70% |
| Back unit: "when a unit in front of this dies, gain +2/+2" | about 7 SP per fight (about 1.9 triggers × 4 SP × 0.9) |

**Costing rule:** realisation is part of the formula, and it depends on timing.

- A front unit's static aura on the back row is wasted, because the front is dead before the back acts.
- A one-off Start of Combat buff from the front to the back is not wasted: the buff outlives the giver.
- Wording decides value. The worked examples in section 7 show it.
- These coefficients assume front-then-back attack order. If the order changes (open question 1), they must be re-measured.

**Empty and partial boards.** Multiply by the chance the neighbour slots are filled when the effect matters.

v0 board fill by turn **[judgement, to be measured]**: turn 1 has 1 unit, then about one more per turn up to 7 by turn 6–7.

A Tier 1 support bought on turn 1 or 2 has about one front neighbour for its first fights. Its condition factor is about 0.6, against 1.0 on a full board.

### 6.4 Empty-slot effects

- Removing any one unit from a full board costs 21–23 points of win rate, whichever slot is left empty **[sim]**. A gap has no defensive value of its own.
- An effect that needs an empty slot ("if there is no unit behind this…", "summon into an empty slot") therefore costs the player about one unit's worth of board once the board is full.
- **Costing rule [judgement]:**
  - Value the payoff against V(t) of the unit it displaces, taken at the tier where the player has a full board (about turn 6 on).
  - Before then the slot is free, so the same card is strong early and weak late.
  - Price at the turn band the card is meant for, and say so on the card's design note.

### 6.5 Known geometry risks to watch in simulation

- **Fortress (1 front, 3 back).** One tough front unit protects three back units. It isn't simulated yet. The direction summary lists it as an open question.
- **Summon placement.** Reborn and Deathrattle summons fill the dead unit's slot, as in Galaxy. A front unit's Reborn therefore restores front protection, so in Bramble it may be worth more in front than in back.
- **Galaxy precedent [data].** Galaxy charged early supports only 2 body SP for a 4 SP aura and later had to nerf them. Supports average 12% below their rarity's stat median. Pricing back-row auras at full realisation (above) is stricter than Galaxy's launch pricing.

## 7. Worked examples

These are placeholder units with no woodland names. Each shows the arithmetic; none is a proposed card.

- **A** = mean enemy Attack (section 3.1).
- **"Back-bound"** means the text works only from the back row, so attack costs 0.75 SP (section 6.1).
- Results are rounded to whole stats. The last column is the error against V(t).

| # | Tier | Text | Costing | Body | Check |
|---|---|---|---|---|---|
| 1 | 1 | *(none)* | V(1) = 5 | **2/3** | 5.0 / 5 |
| 2 | 1 | Back row only: "The units in front of this have +1 Attack." | Magnitude 1 × 2 targets = 2 SP; realisation 1.0 [sim]; condition 0.6 (early board) → **1.2**. Back-bound: body budget 3.8, so 1 Attack (0.75) + 3 Health. | **1/3** | 3.75 + 1.2 = 4.95 / 5 |
| 3 | 2 | Divine Shield | 0.9 × A(2) = 0.9 × 2.5 → **2.25** | **2/3 DS** | 5 + 2.25 = 7.25 / 7 |
| 4 | 3 | Back row: "When a unit in front of this dies, gain +1/+1 this combat." | Half the sim value of +2/+2 (7 SP) = 3.5; condition 0.9 (Tier 3 boards are nearly full) → **3.2**. Back-bound: budget 4.8. | **2/3** | 1.5 + 3 + 3.2 = 7.7 / 8 |
| 5a | 3 | Front: "The units behind this have +2 Attack." | Nominal 2 × 1.5 neighbours = 3 SP, but realisation about 0.05 [sim] → **0.15**. Body 7.85. | 4/4 | **Flag: the text is nearly blank in combat. Reword or cut.** |
| 5b | 3 | Front: "Start of Combat: give the units behind this +2 Attack." | 2 × 0.75 (back attack) × 1.5 neighbours × 0.9 fill → **2.0**. Body 6. | **3/3** | 6 + 2 = 8 / 8 |
| 6 | 2 | "Battlecry: Gain 1 Gold." | 1 gold × G(2) 3.5 × 1.1 carry × 50% recruit charge → **1.9**. Body 5.1. Gold budget: 1 one-off, within cap. | **2/3** | 5 + 1.9 = 6.9 / 7. Battlegrounds' Shell Collector is 4/3 with a Coin: Bramble is stricter by design. |
| 7a | 4 | Back row: "At the end of your turn, give the units in front of this +1/+1." | s = 2 SP × 1.9 occupied neighbours = 3.8 per turn; H = 4 → per-fight 3.8 × 2.5 = 9.5, plus half the tail → **≥ 9.5** | — | **Fails: the effect alone uses the whole V(4) = 10.** |
| 7b | 4 | Back row: "At the end of your turn, give the units in front of this +1 Health." | s = 1.9; per-fight 4.75 → **4.75**. Back-bound: budget 5.25. | **2/4** | 1.5 + 4 + 4.75 = 10.25 / 10 |
| 8 | 1 golden | Golden of #2: "+2 Attack to the units in front of this", body 2/6 | Aura 2 × 2 × 1.0 × 0.6 = 2.4; body 0.75 × 2 + 6 = 7.5 | **2/6** | 9.9 against 2 × V(1) = 10. Passes. |
| 9 | 2 | Front: "If there is no unit behind this, it has +3/+3." | Payoff 6 SP. Early, the gap is free (condition about 0.8 through turn 4). Once the board is full, the gap costs a unit (about V(t)). Priced for turns 2–4: 6 × 0.8 → **4.8**. Body 2.2. | **1/1** (+3/+3 → 4/4) | 2 + 4.8 = 6.8 / 7. Note: a trap late, and that's intended. |

What the examples show:

- **#5a against #5b:** the same nominal effect is worth 0.15 or 2 SP depending on timing.
- **#7a:** per-turn scaling breaks the budget fastest. This is the class that crept in Battlegrounds.
- **#8:** the golden check catches effects that don't double cleanly. This one passes.

## 8. Validation plan: calibrating the budget by simulation

The toy simulation in `tools/research/power_budget.py` is the prototype. The real tool should live in the game's headless engine so that it uses the real rules.

1. **Parity.** Implement Bramble combat headless: fixed slots, attack order, targeting, summon placement. Reproduce the toy simulation's tables (slot exposure, row values, neighbour counts) as regression tests. If a rule changes, these numbers change. Record them.
2. **Baseline boards.** For each tier band (turns 1–3, 4–6, 7–9, 10+), build reference boards of plain units at V(t) with 45–50% attack. Use realistic unit counts per turn and realistic tier mixes.
3. **Per-SP slope.** At each tier band, measure the win-rate gain of +1 SP on a random slot. This converts win rate into SP (0.046 per SP at Tier 2 and 0.028 at Tier 5 in the toy simulation).
4. **Single-card fight test.** Replace one baseline unit with the test card.
   - Run at least 6,000 paired fights with common random numbers. At that count the standard error is about 0.5 points of win rate, or 0.1–0.2 SP.
   - Test the intended slot and every slot. Report the SP-equivalent, the best and worst slot, and the gap between them, which measures how much position matters for that card.
   - **Pass band:** within ±10% of V(t), or ±1 SP.
5. **Whole-game bot test.** This covers recruit-phase value: scaling, economy and card generation.
   - Run scripted bot lobbies with simple policies: buy by curve, level on a schedule, keep the best board, under Bramble's economy rules (carry-over, escalating rerolls).
   - Measure average placement, Battlegrounds' own balance metric ([Blizzard](https://us.forums.blizzard.com/en/hearthstone/t/87311/1)), and per-card placement impact when bought, in the style of HSReplay's Tier7.
   - Measure H(t), board fill by turn, G(t) and the recruit charge rate, and replace the [judgement] placeholders with the results.
6. **Refit.** Once there are 50 or more test cards, regress their simulated SP-equivalents on their features (the same least-squares approach as Bursztein's Hearthstone model and this repo's analysis). Update the coefficients, and flag cards whose formula cost and simulated value disagree by more than 20%.
7. **Pace guardrails.** Track total board SP by turn against a target curve. Galaxy polices "pace" (full heart losses early), not raw numbers **[data]**. Add loop guards for any effect that can feed itself.
8. **Position check.** For the position-text test cards, report how often placement changes the fight result, as proposed in [board-layout-options.md](board-layout-options.md). The toy simulation says vanilla stats alone give almost no placement decisions.
9. **Later.** Automated parameter search over card numbers ([Ludus, AAAI 2022](https://ojs.aaai.org/index.php/AAAI/article/view/21550)), then human playtests, then telemetry. Simulation sets the starting numbers; play decides fun.

## 9. Open questions for the owner

1. **Attack order.** With the front row attacking first, back units mostly attack after the front has fallen. That makes "behind this" auras on front units almost worthless and back-row auras very efficient. Keep front-then-back, or test an interleaved order (F1, B1, F2, B2, …)? This changes every position coefficient.
2. **How strong is a unit with no text?** Proposed V(t) is 5/7/8/10/12/14, about 10% above Battlegrounds' medians. Battlegrounds makes vanilla units weak late in the game (Boulderfist Ogre). Should Bramble's plain units be on budget or below it?
3. **Price recruit-phase value more strictly than Battlegrounds?** Proposed: per-turn scaling charged at 100%, economy at 50% of its gold value, against Battlegrounds' near-zero. Battlegrounds' creep went through scaling text.
4. **Do free refreshes, and rerolls granted by cards, count toward the reroll escalation thresholds?** If they don't, they get stronger on big turns.
5. **Do combat buffs vanish after the fight (Battlegrounds) or persist (Galaxy)?** The method assumes Battlegrounds. Persistent buffs would turn every combat effect into a scaling effect.
6. **Keep Taunt?** It is worth about zero in the simulation, the front row already acts as a taunt, and Galaxy has none.
7. **Golden rule:** 2× body, 2× effect sizes, 1× thresholds, plus a triple reward. Accept as v0?
8. **Tolerance band:** ±10% of V(t) in single-fight tests. Is that tight enough, or too tight for engine cards that are meant to be weak in combat?
9. **Placeholders to measure before content design:** hold time H(t), board fill by turn, gold value G(t) = V(t)/2, and the per-turn gold cap. Is it acceptable to start the first test cards from these placeholders, or should the whole-game bot come first?
