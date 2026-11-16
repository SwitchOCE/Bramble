# Bramble power budget: methodology v1

> **Update, 27 Oct 2026.** The owner decided that random single-target effects can hit either row, and that Taunt only works within the row that can be attacked ([owner note](sources/2026-10-27d-combat-shape-decisions.md)). Back-row protection now applies to attacks only, so the back-row protection values below are upper bounds until the simulation is re-run.

**Status: v1 draft, revision 2, for the owner's review, 2 November 2026 (task S3).** This is a method, not a card list. The numbers are starting points to be replaced by simulation. Each one is marked:
- **[data]** from the Battlegrounds or Galaxy analysis, a committed model table, or a `budget_model.py checks` command (section 11);
- **[sim]** from a combat simulation (the toy sim or the rows study);
- **[scratch]** from a model run that is not in the repo (how to reproduce it is in section 11);
- **[judgement]** my call, to be tested; **[guess]** a rough number with no data behind it.

Evidence:
- [power-analysis.md](../research/battlegrounds/power-analysis.md), produced by `tools/research/power_budget.py`.
- [power-budget-review.md](power-budget-review.md) and its model `tools/research/budget_model.py` (tables in [docs/research/budget-model/](../research/budget-model/)).
- [effect-taxonomy.md](effect-taxonomy.md) and [effect_taxonomy.csv](../research/battlegrounds/analysis/effect_taxonomy.csv).
- [economy-text-by-era.md](../research/battlegrounds/economy-text-by-era.md), [economy-engines.md](../research/battlegrounds/economy-engines.md) and [economy-bounding.md](economy-bounding.md).
- [positioning-sim.md](positioning-sim.md) §5.2 and [rows_card_summary.csv](../research/battlegrounds/analysis/rows_card_summary.csv) (the rows study the owner kept the rows on).

Rules assumed: Battlegrounds baseline plus the decided Bramble differences in [rulebook.md](rulebook.md): carry-over gold with no cap, escalating refreshes (1/2/3 at 10/20), Created units sell for 0, fixed-slot staggered 4-3 board, front row first in the attack order, back row untargetable by attacks while any front unit lives, and no turn timer (3.1.2).

## Changelog

### v0 → v1

**Folded in**
- **Effect taxonomy.** Every class (all 102 rows of the taxonomy CSV) has a v1 price, with a default point where the band is a range, or a pointer (3.4). Each layer maps to one factor of the costing formula.
- **Economy text by era.** What Battlegrounds prints, how big, at which tiers, and where (4.2). It sets the size limits for economy text.
- **Economy engines and bounding.** The three loop shapes and what bounds each (4.4). The refresh schedule and the content guardrails are not repeated: [economy-bounding.md](economy-bounding.md) §4 and §7 is the one list (owner, 2 Nov: "One list in bounding").
- **The rows study.** Its measured prices replace v0's for Reborn, Divine Shield with Taunt on a weak body, combat buffs that land on back units, back-row auras and "across from" damage (3.1, 3.4).
- **Per-action triggers with no timer** are priced at full use on a normal turn (3.5).

**Set** (everything in v1 is a proposal for the owner's review; the tolerance bands are the owner's)
- **The tier curve** (2.2): V(t) is unchanged. One table holds every per-tier number the method uses.
- **Tolerance bands** (2.3): ±15% for plain cards, ±25% for economy, scaling and engine cards, both directions (owner, 2 Nov). The stale ±10% line is gone.
- **The spell budget** (4.5): what a Tavern spell's gold buys at each tier.
- **Recommended answers to B1–B7** from [power-budget-review.md](power-budget-review.md), plus B8 from economy-bounding (section 10).

**Changed rules** (proposed, awaiting the owner)
- **Per-turn scaling** is charged per tier from the model's break-even (2.2, 3.2, B1), not s × (H+1)/2 at 100%.
- **Gold on units** is priced from a per-tier table read from the model's break-even at a late sink of 2.0 SP per gold (2.2, 4.1, B5). v0's flat 50% charge, G(t) and the ×1.1 carry factor are no longer used in any price.
- **Recurring gold caps** (4.1): none unconditional at Tiers 1–2, +1 a turn at Tiers 3–4, +2 from Tier 5. **One-off gold** at most 2 per trigger at Tiers 1–2 and 1 from Tier 3.
- **Free refreshes** are priced at half a gold (4.3), as Battlegrounds' spells price them.
- **Spells** are priced in realised SP, and board spells on a full board (4.5).
- **Worked examples** are re-costed, and gold, refresh and spell examples are added (section 7).

### Revision 2 (after the critique of revision 1)

**Must-fix, done**
1. **Recurring gold at the measured sink.** Revision 1 set B5 at a late sink of 1.6–1.8 SP per gold. The normal-turn sink is 1.97–2.04 **[data: bound_packages.csv]**. All gold prices are now read at 2.0, with columns from 1.8 to 3.0 (4.1). +2 a turn moves from Tier 4 to Tier 5. Recurring gold leaves Tier 2 too: at 2.0 a 1/1 is +21% over, and at 2.5 it beats a plain unit.
2. **Board spells on a full board.** Rulebook 6.1.5 offers spells of the player's tier or lower, so a low-tier board spell is cast on late boards. Every board spell is now priced on 7 units (4.5, examples #12–13). Whether to take low-tier board spells out of later shops instead is question 6.
3. **H(t) is defined** in 2.2. No v1 price uses it any more: the gold table replaces the formula that needed it.
4. **Scaling charge per tier.** Revision 1's flat 0.8 × (F+1)/2 was +35% at Tier 1 and +27% at Tier 2 against the growth-cap data. The charge is now read per tier from the break-even (2.2, 3.2).
5. **Reproducibility.** Numbers from runs not in the repo are tagged **[scratch]**, not [data], and section 11 says how to reproduce each one. Where a committed table covers a decision (bound_packages.csv for the sink, bound_econ_recheck.csv at 1.8 and 3.0, scaling_rate_caps.csv), the decision rests on it.

**Should-fix, done**
- One-off gold above Tier 2 is no longer tagged as model data. It is smoothed by judgement, with a cap of 1 per trigger from Tier 3, and the second gold at Tiers 1–2 is priced at its measured value, not linearly (4.1).
- Free refresh (E52): one price, half a gold-equivalent, on a normal turn (4.3).
- Tolerance: cards with triggers R02–R10 or R14, or targets T12 or T14, are in the ±25% band. E62 is 25 (2.3, 3.4).
- Trigger counts for no timer: E14 uses units bought per turn (gold ÷ 3). R06 counts sells, which are bounded by units, not gold (3.4).
- Free inputs use a fixed reference per tier with neutral sources included, not each tribe's strongest source (3.5).
- Rows-study prices are adopted (3.1, 3.4).
- Spells: one measure (realised SP) for single and board spells, and the reason for no board premium is given (4.5).
- The recurring gold cap has one home: 4.1. Economy-bounding §6 is now a pointer to it.
- B7's claim that most prices are in band is replaced by a list of where they are and aren't (B7).
- B2 is tested: an income board at the new caps reaches Tier 6 on turn 8, not 7 (B2).
- B3 is tested: the scaling charge moves 13% or less between the printed-stats pace and a Battlegrounds-like pace (B3).
- 4.4 says the engine bounds rest on unapproved guardrails, and B8 says its 4× limit already fails a strong plausible board.
- Stat multiply and consume (E06, E08) are priced only once per turn and not retriggerable (3.2, 3.4).
- Classes that had no usable number now have one, and an Activate class is added (E88, 3.4).
- Fewer exchange rates: gold on a unit has one table, spells have S(t). One hold model (break-even by turn 12). Range-only bands have default points.

**Should-fix, declined in part**
- **S(t) rising with tier** (Battlegrounds goes from 4 to 6 per gold for one target, and 6 to 14–17.5 for team buffs). Kept flat at 5 from Tier 2. A spell's per-gold rate is the late sink, and the sink sets every gold price (4.1). The new caps hold up to a sink of about 2.5, so a modest rise at Tiers 5–6 is possible. That is the owner's call on how spells should feel (question 1).

---

## 1. The unit of value

**One stat point (SP)** is 1 Attack or 1 Health on a plain unit at an average position, measured by how much it raises the chance of winning a single fight against tier-matched boards.

- Everything else, including keywords, triggers, gold and position, is converted into SP-equivalents at a given tier.
- A card's budget is spent once. Body stats + the SP-equivalent of its text = the tier budget.
- SP-equivalents depend on tier. Divine Shield, for example, is worth about one enemy attack, and enemy attacks grow with tier **[sim]**. Every conversion is therefore a function of tier, not a constant.

Why SP and not gold: Battlegrounds minions all cost 3 gold, so gold can't separate tiers. A board slot, not gold, is the scarce resource **[data]**: buff spells buy stats 2–3× cheaper per gold than minion bodies do.

## 2. Baseline curve and tier curve

### 2.1 V(t), the stat total of a unit with no text

| Tier | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|
| V(t) | 5 | 7 | 8 | 10 | 12 | 14 | 18 (placeholder) |
| Battlegrounds median, current pool **[data]** | 4.5 | 6 | 7 | 9 | 10 | 12.5 | 19 |
| Galaxy median by rarity **[data]** | 4 (Common) | — | 7 (Uncommon) | — | — | 12 (Rare) | 16 (Epic) |

Where V(t) comes from:

- **Basis [data]:** a Battlegrounds card with none of the classified features carries 1.04–1.13 × its tier median. V(t) is about 1.1 × median, rounded. That is about 1.8 × t + 3.
- **Linear, not exponential [data]:** the two fit Tiers 1–6 equally well (R² 0.50 against 0.51). Linear is simpler to reason about. Revisit if whole-game sims show late tiers need a steeper step.
- **Attack share [data]:** the default split is 45–50% attack, as in Battlegrounds. Row-bound units adjust it (section 6).
- **On budget, not below [owner, 27 Oct].** Plain units sit on V(t).
- **Spread [data]:** Battlegrounds' interquartile range is about ±2 SP around the median at every tier, and its tuning steps are ±1–2 SP or ±1 tier. Bramble's tolerance (2.3) is tighter than that spread.

Tier 7 needs its own rules (how it is reached, what it is for) before it gets a budget. Rulebook 4.6.1 reaches it only through effects.

### 2.2 The tier curve

Every per-tier number the method uses, in one place. The sections in the last column give the reasons. "Break-even" means: bought when its tier opens, standard economy, the card ends level with a plain V(t) unit by turn 12 in the one-player model.

| Tier | 1 | 2 | 3 | 4 | 5 | 6 | Source |
|---|---|---|---|---|---|---|---|
| **Bodies and combat** | | | | | | | |
| V(t), plain body (SP) | 5 | 7 | 8 | 10 | 12 | 14 | 2.1 **[data, judgement]** |
| A(t), mean enemy Attack | 2.0 | 2.5 | 3.3 | 4.0 | 4.9 | 6.1 | 3.1 **[data]** |
| Divine Shield, 0.9 × A(t) | 1.8 | 2.25 | 3.0 | 3.6 | 4.4 | 5.5 | 3.1 **[sim, data]** |
| Reborn, 0.4 × V(t) | 2.0 | 2.8 | 3.2 | 4.0 | 4.8 | 5.6 | 3.1 **[sim: one card]** |
| Venomous, 0.25 × V(t) | 1.25 | 1.75 | 2.0 | 2.5 | 3.0 | 3.5 | 3.1 **[data]** |
| **Timing** | | | | | | | |
| Turn the tier opens, standard econ | 1 | 2 | 4 | 6 | 8 | 9 | [tier_reach.csv](../research/budget-model/tier_reach.csv) **[data: model]** |
| Mean unit on board at that turn (SP) | 5 | 5 | 6.3 | 7.2 | 9.4 | 10.4 | [economy_timeline.csv](../research/budget-model/economy_timeline.csv), board SP ÷ units **[data: model, printed-stats pace]** |
| H(t), the model's hold placeholder (fights) | 3 | 3 | 4 | 4 | 5 | 5 | `A["H"]` in budget_model.py. Used inside the model's v0 comparisons only. **No v1 price uses it.** |
| **Scaling** | | | | | | | |
| Charge per SP a turn (start or end of turn, "permanently") | 3.9 | 3.7 | 3.5 | 3.1 | 2.6 | 2.6 (T5 value) | 3.2, B1 **[data: model caps and `checks scaling`]** |
| Charge per SP per firing, combat trigger (× firings per fight) | 3.0 | 2.8 | 2.5 | 2.1 | 1.6 | 1.6 (T5 value) | same |
| Growth cap, per-turn (SP a turn) | 0.8 | 1.3 | 1.7 | 2.5 | 3.8 | T5 value until measured | [scaling_rate_caps.csv](../research/budget-model/scaling_rate_caps.csv) **[data: model]** |
| Growth cap, combat-triggered, 1 firing per fight | 1.0 | 1.7 | 2.2 | 3.6 | 6.2 | T5 value until measured | same **[data: model]** |
| **Gold on a unit** | | | | | | | |
| One-off gold: the first gold (SP) | 2.4 | 4.6 | 4.5 | 2.2 | 2.5 | 2.0 | 4.1 **[data: `checks econ` at 2.0 (bound_econ_recheck.csv at 1.8 and 3.0 for T1–T2); judgement T3–T6]** |
| One-off gold: each further gold in the same trigger (SP) | 0.6 | 1.0 | — | — | — | — | 4.1 **[data: `checks econ`; at Tier 1 it measures 0.7 at 2.0, and 0.6 is the difference of the rounded v1 prices 3.0 and 2.4]** |
| One-off gold, most per trigger | 2 | 2 | 1 | 1 | 1 | 1 | 4.1 **[data: `checks econ`; judgement]** |
| Recurring gold, SP per +1 gold a turn | none | none | 5.1 | 4.2 | 4.1 | 2.2 | 4.1 **[data: `checks econ` at 2.0 (bound_econ_recheck.csv at 1.8 and 3.0 for T3–T4)]** |
| Recurring gold, SP for +2 gold a turn | none | none | none | none | 7.3 | 4.5 | 4.1 **[data: `checks econ`]** |
| **Recurring gold cap on units (gold a turn, unconditional)** | **0** | **0** | **1** | **1** | **2** | **2** | 4.1 **[data, judgement]**. Proposed, awaiting the owner (B5, question 2). The one home of this cap |
| Free refresh, each (SP): half the first gold | 1.2 | 2.3 | 2.3 | 1.1 | 1.3 | 1.0 | 4.3 **[data: spell prices; judgement]** |
| **Spells** | | | | | | | |
| S(t), spell SP per gold of cost | 4 | 5 | 5 | 5 | 5 | 5 | 4.5 **[data T1, T3–T4; judgement]** |
| Typical spell cost (gold) | 1 | 1–2 | 2 | 2 | 2–3 | 2–3 | 4.5 **[data]** |
| **Recruit actions on a normal turn** | | | | | | | |
| Buys, plays or sells a turn (gold ÷ 3) | 1 | 1–2 | 2 | 2–3 | 3 | 3–4 | 3.5 **[data: model income; judgement]** |
| Reference free cards or casts a turn (3.5) | 0 | 0 | 1 | 1 | 2 | 2 | 3.5 **[guess]** |
| What the tier's economy text pays in, by default | one-off gold | one-off gold, Coins | gold, engines start | gold, engines | cards; gold through engines | cards; gold through engines | 4.2 **[data, judgement]** |

All gold prices assume a late sink of about 2.0 SP per gold. They hold, inside their bands, from about 1.8 to 2.5 (4.1).

### 2.3 Tolerance

**Owner, 2 Nov: "±15% default, ±25% engines". Both directions.**

- **Plain cards: ±15%** of V(t) for the card's measured or costed SP-equivalent.
- **Economy, scaling and engine cards: ±25%.** A card goes in this band if any part of its text:
  - is in an effect class with 25 in the Tol. column of 3.4 (stat growth, amplifiers, "this game" buffs, card generation, gold, refreshes, shop effects, multipliers, retriggers); or
  - uses a recruit trigger R02–R10 or R14 (start or end of turn, play, buy, sell, cast, Spellcraft, gold spent, refresh, card gained); or
  - targets T12 (future cards, "this game") or T14 (a slot).
- **Floor: ±1 SP, whichever is larger [judgement, kept from v0].** At Tiers 1–2 one stat is 14–20% of V(t), so a pure percentage would leave no legal body (question 5).
- **The golden check** (section 5) uses the card's own band: 2 × V(t) ± 15% or ± 25%.
- **What the band is for.** The owner: "We're going to get things wrong. That's okay. We're going to iterate and catch those things later." A card inside its band ships to playtest. A card outside it is re-costed or reworded first.

## 3. Costing an effect

Every effect is costed with one formula:

> **cost = magnitude × triggers × realisation × condition × persistence**

| Factor | Meaning | Where its value comes from | Taxonomy layer |
|---|---|---|---|
| **Magnitude** (SP) | Stats moved per trigger. +2/+2 = 4. +1 Attack to two units = 2. Divine Shield ≈ the mean enemy Attack at that tier. Gold: the table in 2.2. | Card text; [sim] for keywords | Effects E01–E88 |
| **Triggers** | Expected firings per fight (combat effects) or per turn (recruit effects) | [sim] per fight; 3.5 per turn | Triggers R01–R31 |
| **Realisation** | Share of the magnitude that turns into win rate. It depends on timing and geometry: a buff given after the target has attacked is wasted. | [sim], section 6 | Targets T01–T14 |
| **Condition** | Chance the condition holds: tribe on board, neighbour present, threshold reached | Lobby tribe odds; board-fill tables (section 6) | Conditions C01–C08 |
| **Persistence** | How long the value lasts: this fight only, permanent while held, or permanent after the card is sold | Section 3.2 | Effects and T12, T14 |

The card's body is then **V(t) − Σ cost**, split into attack and health with the row rules in section 6.

### 3.1 Keywords

Values are per tier, for a full board. A = mean enemy Attack at the tier: 2.0, 2.5, 3.3, 4.0, 4.9, 6.1 for Tiers 1–6 **[data]**.

| Keyword | Cost | Evidence and notes |
|---|---|---|
| Taunt | 0 SP plus the value of what it protects | Sim: 0.0–0.1 SP on vanilla boards. Battlegrounds charges about 0 **[data]**. Kept, and it works only within the row that can be attacked (owner, 27 Oct). |
| Divine Shield | 0.9 × A. **With Taunt on a front body of 1 Attack: about 1 SP in total** | Sim: 1.0–1.2 × A in either row. Battlegrounds charges about 0.25 × median, roughly 0.6 × A **[data]**. **[judgement]** Take the midpoint, because real boards carry DS counters (Venomous, cleave, AoE) that the sim lacks. **v1:** the rows study measured Taunt + Divine Shield on a 1/3 front unit at about 1 SP against 3.0 charged (Shellback Tortoise, positioning-sim §5.2) **[sim: one card]**. A shield on a body that can't trade only delays the fight. |
| Reborn | **0.4 × V(t)** on a body near V(t) (v0: 0.2) | The rows study measured 3.2–3.7 SP, 0.4–0.45 × V(3), on a 3/3 (Fern Hare) **[sim: one card]**. Battlegrounds charges 0.18–0.27 × median **[data]**; it under-charges Reborn the way it under-charges other text. The Reborn unit comes back in its own slot, so a front Reborn restores front protection (6.5). |
| Venomous | 0.25 × V(t) until simulated | Battlegrounds charges about 0.25 **[data]** |
| Windfury | Simulate case by case | It multiplies attack. Battlegrounds puts it on big bodies, not on cheap ones **[data]**. Cost it as about +0.8 × own Attack (one more attack if the unit survives its first trade) **[judgement]** and check in the sim. |
| Cleave / adjacent splash | Simulate | Depends on the number of enemy front neighbours: F1 and F4 have 1, F2 and F3 have 2, and the count falls as the front dies. |

### 3.2 Timing classes

**Combat-only effects** (Start of Combat, Deathrattle, Avenge, "when this attacks", auras). Value is measured per fight in the sim, so cost = SP-equivalent per fight. These are the easiest to calibrate. In Battlegrounds, death effects take 11–24% of the body **[data]**.

**One-shot recruit effects** (Battlecry: give +X/+Y). The buff stays on another body for every later fight while that body is kept. Cost = magnitude × realisation of the target's row, with no per-turn growth. **[judgement]** Treat the buff as body stats delivered elsewhere at 0.9 per SP: the player picks a good target, but the buff takes a slot's worth of setup.

**Per-turn scaling** (End of turn, Start of turn, "permanently", "this game"). This class is the main power-creep risk. Battlegrounds' share of scaling text went from about 6% of the pool in 2020 to 32% in 2026, while printed stats stayed flat **[data]**.

**v1 rule (B1): break even by turn 12, with the charge read per tier from the model.** If a unit adds s SP permanently each turn and is bought on the turn its tier opens:

> **cost = c(t) × s**, with c(t) = 3.9 / 3.7 / 3.5 / 3.1 / 2.6 / 2.6 at Tiers 1–6 (2.2)
>
> For a combat trigger that grows the unit permanently: **cost = c_combat(t) × s × firings per fight**, with c_combat(t) = 3.0 / 2.8 / 2.5 / 2.1 / 1.6 / 1.6.

- **Where c(t) comes from.** At each tier's growth cap, a 1/1 body breaks even, so c(t) at the cap is (V(t) − 2) ÷ cap: 3.85 / 3.8 / 3.6 / 3.15 / 2.6 **[data: scaling_rate_caps.csv, standard econ, by turn 12]**. Below the cap the charge per SP is a little lower, because small growth is sold sooner: at s = 0.25–1.0 it is 3.6–4.05 / 3.0–3.5 / 3.1–3.3 / 2.4–2.8 / 2.6 **[data: `checks scaling`]**. The table weights toward the cap. Its error at any s from 0.25 to the cap is under 0.4 SP, at most 5% of V(t).
- **Combat triggers cost less per SP** (1.2–3.2 against 2.4–4.05) **[data: `checks scaling`]**. The model doesn't say why; one reason may be that growth from a fight starts after that fight **[judgement]**. At the combat caps the charge is (V − 2) ÷ cap = 3.0 / 3.0 / 2.8 / 2.2 / 1.6 **[data: same file]**. The c_combat row's error is under 0.6 SP (7.5% of V(t)), largest near the Tier 3–4 caps.
- **It hardly depends on lobby pace.** With the rest of the lobby growing 1 SP per unit per turn (turn-12 boards about 180 SP), c(t) falls by 0–6%. At 2.5 (about 270 SP, Battlegrounds-like) it falls by 0–13%, most at Tier 1 **[scratch]**. Pace changes how many HP a scaling lead is worth, not where it breaks even (B3).
- **Why not H(t) or a flat rate.** v0 charged s × (H+1)/2 at 100%. That makes a card break even over exactly H fights, but early scaling units are kept 10–15 fights and late ones 2–3 **[data: hold_time.csv]**. Revision 1's 0.8 × (F+1)/2 over-charged Tiers 1–2 by 27–35% against the cap data. Reading the charge off the break-even fixes both, and drops a second hold model.
- **Growth caps (B4).** Above the per-tier cap in 2.2 even a 1/1 body is over budget. Such text moves up a tier, becomes conditional ("if you have a Fairy"), or gets a cap ("up to 5 times"). For example, unconditional "+1/+1 every turn" (s = 2) costs 7.4 at Tier 2, more than V(2) less a 1/1, and fits from Tier 4 (6.2 of 10).
- **Linear growth only.** The caps assume a fixed s per turn. Stat multiply (E06) and consume (E08) grow geometrically under retriggers (E80, E81) and over turns. v1 prices them only when the text is once per turn and can't be retriggered **[judgement]**. That is a proposed content rule for the owner (question 9).
- **Tail.** The charge runs to turn 12, so v1 adds no separate tail for buffs left on other units when the source is sold **[judgement]**. Text that also reaches units bought later ("this game", future cards, slots: T12, T14) counts those units in its magnitude (E12).
- **Bought late.** A scaling card bought after its tier opens is worth less (fewer fights). Price it at the tier-open turn, and say so on the card's design note. Slow scaling bought late is the trap; bought early it is the opposite (review §5).

**Economy** (gold, free refreshes, discounts). See section 4.

**Charge rate for recruit-phase value.** Battlegrounds barely charges stats for economy, card generation or recruit-phase buffs; those coefficients are −0.02 to −0.06 **[data]**. Recruit-phase cards are priced by tier and sold before late fights. Bramble's position (owner, 27 Oct: price recruit-phase value more strictly than Battlegrounds):

- Scaling: the break-even charge above, whose output is combat stats, the same currency as the body.
- Economy: the gold table in 2.2, plus per-tier caps on gold (4.1).
- Both stay stricter than Battlegrounds on purpose. The previous project's problems and Battlegrounds' own creep both point at under-priced scaling.

### 3.3 Conditions and tribe dependency

- **Tribe conditions:** cost × the chance the tribe text is live. v0 **[judgement]**: 0.6 for "a friendly <Tribe>" on a mid-game board, 0.3 for "for each <Tribe>", counting about half the board as the tribe in a committed build.
  - Battlegrounds charges almost nothing for tribe dependency (−0.02 **[data]**). Its lobbies remove tribes rather than discounting the cards.
  - Bramble also has a subset of tribes per game, and a tribe is a broad creature kind (owner, 2 Nov). Measure live rates in whole-game sims.
- **Thresholds and counters** ("Avenge (3)", "after 5 spells"): triggers = expected fights or turns in which the threshold is reached. Thresholds don't double on golden (section 5).
- **Limiters** ("once per turn", "3 times per turn"; C04) cap triggers. They are the main content tool for bounding recruit engines. Battlegrounds grew them from 0% to 5% of the pool as it added engines **[data: effect-taxonomy §6]**.
- **Drawbacks** give stats back. Battlegrounds adds 36–46% of the tier budget for a real drawback **[data]**, such as self-destruction, losing stats or damaging your hero. Cost drawbacks with the same formula and a negative magnitude.

### 3.4 Price bands by taxonomy class

Every class in [effect-taxonomy.md](effect-taxonomy.md), with its v1 price or a pointer. Where the band is a range, **the bold number is the default**: use it unless the design note says why not. "Grade" is the weakest evidence the price rests on. Tol. is the tolerance band (2.3). A card with a recruit trigger (R02–R10, R14) or a T12 or T14 target is in the 25 band whatever its effect's Tol. Counts, examples and history are in the taxonomy and its CSV.

**Effects: magnitude and persistence**

| ID | Class | v1 price (SP at the card's tier) | Grade | Tol. |
|---|---|---|---|---|
| E01 | Stat gain to another unit | One-off: 0.9 × SP given. Per trigger: × firings (3.5). In combat, to a back unit: × 1.4 (T04). On a spell: 4.5 | data, sim | 15 |
| E02 | Self stat gain | One-off: 1.0 × SP. Per turn: c(t) × s; combat-triggered: c_combat(t) × s × firings. Under the growth caps (2.2) | model | 25 |
| E03 | Temporary gain | SP × firings × realisation. "Until next turn" from a recruit card: **0.5** (0.4–0.6) of the permanent price | sim, guess | 15 |
| E04 | Single-stat gain | Attack 1.0 front, 0.75 back. Health 1.0. Health-only growth: **0.9** (0.8–1.0) | sim, judgement | 15 |
| E05 | Stat set | One-off gain of (N − the mean unit at the turn of use, 2.2) | guess | 15 |
| E06 | Stat multiply | The target's current stats: at least V(t) at Tiers 5–6. Proposed rule, not yet agreed (question 9): only once per turn and not retriggerable (3.2) | data, guess | 25 |
| E07 | Stat swap | **0.5** (0–1) alone; value from rows and Health-heavy scalers | guess | 15 |
| E08 | Stat transfer, consume | About V(shop tier) per use. Per turn it is scaling at about V(t) a turn: over every cap below Tier 4. Proposed rule, not yet agreed (question 9): only once per turn and not retriggerable (3.2) | data, model | 25 |
| E09 | Count-scaled body | Per-turn scaling: c(t) × X × the counter's rate | data, model | 25 |
| E10 | Buff amplifier | c(t) × bonus × source events per turn (3.5), under the growth caps | guess | 25 |
| E11 | Self-improving, future copies | c(t) × improvement per turn × what it improves, counting future copies | model, guess | 25 |
| E12 | Type-wide persistent buff | Magnitude × units of that type now and bought later | judgement | 25 |
| E13 | Static aura | Magnitude × targets × realisation × survival (6.2–6.3). Back unit on the units in front: about 1.0 × 0.9 nominal; the rows study measured **1.9 SP for +1 Attack to 2 units** (Lantern Moth). Front unit on the units behind: about 0.05 | sim | 15 |
| E14 | Shop buff | s = buff × units bought per turn (2.2: gold ÷ 3), counting only units bought, not units shown. "This game": all later buys. Under the growth caps | guess | 25 |
| E15 | Stat loss or debuff | **1.1** (1.0–1.2) × SP removed | guess | 15 |
| E16 | Slot buff | **1.1** (1.0–1.2) × SP, counting every unit that will stand in the slot (the slot keeps it) | guess | 25 (T14) |
| E17 | Hand buff | 0.9 × SP, realised on play | judgement | 15 |
| E20 | Keyword grant | 3.1 and 2.2: Divine Shield 0.9 × A(t), Reborn 0.4 × V, Venomous 0.25 × V, Taunt 0, Windfury 0.8 × Attack | sim, data | 15 |
| E21 | Keyword removal | Keyword value × chance the enemy has it, **0.4** (0.3–0.5) | guess | 15 |
| E22 | Ability grant | The granted text's price on the target × 1.1 | guess | 25 |
| E23 | Merge (Magnetic) | Full stats and text at 1.0, plus about 1 SP for the slot saved | data | 15 |
| E30 | Summon | Token SP × **0.8** (0.7–0.9) in combat; a Deathrattle summon refills its own slot | data, judgement | 15 |
| E31 | Summon or make a copy | The copied unit's expected stats at the turn of use: the mean unit in 2.2 (5, 6.3, 7.2, 9.4, 10.4 SP at turns 1/4/6/8/9; 13–17 at turns 10–12), or the copied card's own value if known | data: model, guess | 25 |
| E32 | Move or swap units | **0.5** (0–1) alone; an enabler for position text | sim, guess | 15 |
| E40 | Get a specific card | The card's value × 0.9. A spell: its cost × S(t) (4.5). A Coin: 1 one-off gold (2.2). Every turn: per-turn scaling | data | 25 |
| E41 | Get a random card | Random unit of tier k: **0.55** (0.4–0.7) × V(k) with space on the board, **0.3** (0.2–0.4) × V(k) on a full board. Spell price: 2 gold (4.5) | guess, data | 25 |
| E42 | Discover | Random × **1.25** (1.2–1.3). Spell price: 3 gold (4.5) | guess, data | 25 |
| E43 | Copy a card to hand | Unit: **0.8** (0.6–1.0) × V(k). Spell: the spell's value. Copies of gold or refresh spells need a per-turn cap (economy-bounding G12) | guess | 25 |
| E44 | Take a shop card free | A free buy saves 2 net gold (3 to buy, 1 back on sale; the unit is Created and sells for 0). Price it as 2 one-off gold at Tiers 1–2 (3.0 / 5.6), and about 4 SP from Tier 3 | data, guess | 25 |
| E45 | Discard | Negative: the discarded card's value | judgement | 15 |
| E50 | Gain gold | One-off and recurring: the gold table (2.2, 4.1). Caps per trigger and per turn (4.1) | data | 25 |
| E51 | Raise income ("maximum gold") | Under rulebook 4.1.4 it only lifts the 10-gold ceiling: about 1–2 SP. If it raises income at once: recurring +1 gold (2.2), under the caps. **Open: question 4** | guess | 25 |
| E52 | Free refresh | Half a gold-equivalent each: 2.2's row (1.2 / 2.3 / 2.3 / 1.1 / 1.3 / 1.0). Repeatable: × normal-turn firings (3.5), under a per-turn cap (G8) | data, judgement | 25 |
| E53 | Cost reduction | The gold saved, priced as one-off gold (2.2) | judgement | 25 |
| E54 | Sell value | Extra gold at sale, as one-off gold. Applies to Bought units only (economy-bounding G4) | rule | 25 |
| E55 | Pay Health for gold | 1 hero Health ≈ **0.4** (0.3–0.5) gold early, while the damage caps make losses cheap | guess | 25 |
| E60 | Shop contents control | About 2.5 free refreshes' worth (E52) for finding one type. Repeatable versions need a per-turn cap (economy-bounding G8) | guess | 25 |
| E61 | Act on a shop unit | Consume: E08. Buff a shop unit then buy it: a one-off E14 | guess | 25 |
| E62 | Tier jump | V(k+1) − V(k), about 1–2 SP plus better text. Discover from Tiers 6–7: about V(6–7) | data, guess | **25** |
| E63 | Freeze | 0 (a free action, rulebook 4.5) | rule | 15 |
| E70 | Transform | V(result) − V(source). On an enemy it is removal | guess | 15 |
| E71 | Destroy | Enemy: its SP × chance to hit (Venomous, 0.25 × V, is the reference). Own unit as a cost: a drawback, +36–46% of the budget | data | 15 |
| E72 | Deal damage | **0.85** (0.7–1.0) × damage in SP; overkill is wasted. "Across from" at Start of Combat: **1.15 × damage on a full board**, 0.9 on 3–4-unit boards (rows study: 3 damage measured 3.3–3.7 and 2.5–3.0) | guess, sim | 15 |
| E73 | Make Golden | About V(k) + the doubled text, with no Triple Reward. Tier 5+ or 4–5-gold spells | data | 25 |
| E80 | Multiplier | The sum of the doubled effects on the expected board. Tier 5+ only. One retrigger per board in the turn-length check (economy-bounding §7). Never doubles E06 or E08 | data, judgement | 25 |
| E81 | Trigger another unit's effect | The triggered effect's value × uses. Never triggers E06 or E08 | judgement | 25 |
| E82 | Cast a spell for free | The spell's value per cast (4.5) | data | 25 |
| E83 | Attack behaviour | Attacks immediately: about one extra attack, ≈ A(t) SP. Can't attack: a drawback | guess | 15 |
| E84 | Hero effect (Armor, heal) | 1 Armor ≈ **3** (2–5) SP-fights (0.2–0.67 HP per SP per fight, review §3) | model, guess | 15 |
| E85 | Game-rule change | No unit budget: review each one as a system | judgement | 25 |
| E86 | Duos only | Out of scope | — | — |
| E87 | Trigger rewiring | No unit budget: review as a system | judgement | 25 |
| **E88** | **Activate cost** ("pay N gold: effect", R11). *New in revision 2; now in the taxonomy and its CSV* | Per use: the effect's value − N × 2.0 SP (the late sink, 4.6). Once per turn. If the effect is permanent stats, it is per-turn scaling with s = that net value, under the growth caps | data, judgement | 25 |

**Targets: realisation.** All are multipliers on the effect, from effect-taxonomy §4.

| IDs | Rule | Grade |
|---|---|---|
| T01 self | × 1.0: it is body | judgement |
| T02 adjacent, T03 left-most / right-most | Same-row neighbours: 1.43 on a full board. Left-most and right-most are per row (rulebook 8.2.5). Adjacent auras realise 0.4–0.7 in Battlegrounds | data, sim |
| T04 in front of / behind | From a back unit: 2 in front, aura about 1.0, "when this attacks" about 0.15. From a front unit: 1.5 behind, aura about 0.05, one-off Start of Combat about 0.75 × 0.9 (6.3). **Combat buffs that land on back units (a front unit's Deathrattle, a back unit's "when a unit in front dies"): × 1.4 on the method's price.** The rows study measured 3.6 against 2.5 (Martyr Hedgehog) and 4.3 against 2.7 (Vigil Vole): back units survive and use the stats | sim (two cards for × 1.4) |
| T05 one chosen, T06 random friendly | × 0.9 chosen; × **0.85** (0.8–0.9) random (random can hit either row) | judgement, guess |
| T07 all friendly, T08 tribe subset | × expected units on board at the turn of use (the model: 1, 1, 3, 3, 6, 6, then 7 from turn 7); tribe × 0.6 or × 0.3 per unit (3.3). Spells: a full board (4.5) | data: model, judgement |
| T09 hand, T10 shop | Hand: × **0.85**, realised on play. Shop: count only the units the player buys (E14), not the units shown | guess |
| T11 enemy | Random enemy: either row (owner, 27 Oct) | rule |
| T12 future cards and "this game", T14 slot | Count the units bought later, and what stays after the source is sold (3.2). ±25% band | judgement, guess |
| T13 hero or player | See E84 | model, guess |

**Triggers: firings.** Combat triggers per fight; recruit triggers per turn, priced at full use on a normal turn (3.5).

| IDs | Firings | Grade |
|---|---|---|
| R01 Battlecry, R12 Choose One | 1; 2 with a doubler | rule |
| R02 start of turn, R03 end of turn | 1 per turn; priced with c(t) (3.2) | model |
| R04 after you play, R05 after you buy | Buys or plays a turn (2.2: gold ÷ 3), plus the reference free cards (2.2) | judgement, guess |
| R06 when sold | Sells are bounded by units, not gold: about one sell per buy once the board is full, plus every Created unit gained (they sell for 0). Use buys a turn + reference free cards, with no gold limit on the Created part | judgement |
| R07 on cast, R14 on card gained, R15 on discard | Spells bought: about **1** a turn at Tiers 1–3 and **2** at Tiers 4–6, plus the reference free cards (2.2) | guess |
| R08 Spellcraft, R11 Activate | 1 per turn (rulebook 11.4.2, 11.4.5) | rule |
| R09 on gold spent | Gold spent ÷ N per normal turn: about 12–17 gold at Tier 6 (3.5) | data: model |
| R10 on refresh | 6–11 per normal Tier-6 turn (3.5) | data: model |
| R13 on merge | Magnetic units played: **1** a turn in a committed build | guess |
| R16 on golden | Triples made: **0.25** a turn (about 3 a game) | guess |
| R20 Start of Combat | 1 per fight | rule |
| R21 Deathrattle | About 1 per fight if it dies: front units die 98–99% of fights, back units 67–83% | sim |
| R22 on attack, R23 on kill, R24 on damage taken | Front 1–1.5 attacks and 0.6–1.15 hits per fight; back 0.5–1 and 0.33–0.71; kills about 0.5 for a front unit | sim, guess |
| R25 Avenge | Friendly deaths: about 4–6 in a lost fight, **4.5** a fight on average; Avenge (N) fires deaths ÷ N | guess |
| R26 on summon | Summons a fight: **2** in a summon build, **0.5** otherwise | guess |
| R27 shield or Reborn lost | Friendly shields and Reborns on board × 0.9 (most are spent in a fight); **1** a fight in a shield build | guess |
| R28 combat result | Win rate × fights: **0.5** a fight | guess |
| R29 hero damage | Fights lost: **0.5** a fight | guess |
| R30 counter or quest | Fires when reached; thresholds don't double on golden | data |
| R31 static | Always on | rule |

**Conditions: chance it holds.** From effect-taxonomy §6.

| IDs | Factor | Grade |
|---|---|---|
| C01 tribe | × 0.6 or × 0.3 per unit (3.3) | judgement |
| C02 position | × chance the related slot is filled (6.3) | sim, judgement |
| C03 threshold, C04 limiter | Triggers = turns or fights in which it is reached; a limiter caps triggers (3.3) | rule |
| C05 state check | × **0.7** unless the design note gives a reason for another number | guess |
| C07 hand | Realised on play: × 0.85 (T09) | judgement |
| C06 random outcome | Random target × **0.85** (0.8–0.9) | guess |
| C08 golden | Chance a given unit is golden: **0.1** at Tiers 1–3, **0.25** at Tiers 4–6 | guess |

**Where the prices are weakest [judgement].** Only keywords, one-off stat gains, single stats, gold, spells, growth rates and the rows-study cards rest on data, the model or the sim. Card generation (E40–E43), free refreshes (E52), shop control (E60–E61), transform and damage (E70, E72), the Bramble-new classes (E07, E16, E32, T04, T14), and most combat-trigger counts (R13, R16, R25–R29) are guesses. These are also the classes Battlegrounds moved its text into from 2020 to 2026 (card generation 3% → 23% of minions, "this game" targets 1% → 16%) and barely charges stats for (body ratio 1.0–1.24) **[data: effect-taxonomy §1, §8]**. Expect playtests to move them most.

### 3.5 Recruit triggers with no turn timer

In Battlegrounds the timer limits how many actions a player takes. Bramble has none (rulebook 3.1.2). **[judgement]** Price every per-action trigger at its gold-bounded use: assume the player takes every action their gold allows on a normal turn.

- **A normal turn, not a banked one.** At Tier 6 the main model's player spends 10–14 gold a turn and banks 0–1 **[data: economy_timeline.csv]**. Banked turns of 30–60 gold are meant for the turn-length check (economy-bounding G10), which the owner has deferred, so nothing checks banked turns yet; they are not covered by the per-card price. That holds for every recruit trigger and for free refreshes (E52).
- **Firings to use** at Tier 6 on a normal turn **[data: bound_floor.csv, bound_summary.csv]**:
  - after you buy or play (R04–R05): about 3–4 (gold ÷ 3); sells (R06) as in 3.4;
  - after you spend N gold (R09): 12–17 gold spent ÷ N (13 with no engine, 17 for strong Rogers at a 12-gold bank, power policy). "After you spend 5 Gold" fires about 2.5–3.5 times;
  - after a refresh (R10): 6 paid refreshes for a player who also buys stats, 11 for one who only refreshes.
- **At lower tiers**, scale by the turn's income (rulebook 4.1.1). 2.2 has the counts.
- **Free inputs: a fixed reference, not the strongest source.** Cards that make free cards, spells or refreshes raise the firings of every buy, play or cast trigger on the board. Price those triggers with the reference in 2.2: 0 free cards or casts a turn at Tiers 1–2, 1 at Tiers 3–4, 2 at Tiers 5–6 **[guess]**. The reference counts neutral sources too: Tavern spells, neutral enablers, hero powers. It is fixed, so adding a new free source doesn't re-price old cards. A new source that would push a board past the reference is checked against the turn-length and engine-output tests (G10, B8), not by re-pricing.

## 4. Gold, carry-over, refreshes and spells

### 4.1 Gold

**Gold on a unit is priced from the table in 2.2.** Each number is the model's break-even: V(t) minus the body at which the card ends level with a plain unit by turn 12, bought when its tier opens, standard economy, with late gold buying **2.0 SP per gold**.

- **Why 2.0.** That is what a no-engine Tier-6 player's gold buys on a normal turn with Tavern spells at 5 SP per gold: 1.97–2.04 at banks 10–20 **[data: bound_packages.csv, package none, power policy, schedule s123_plus1_nocap]**. Recurring gold is spent on normal turns, so it is priced there.
- **What changed.** v0 and revision 1 used gold × factor × G(t) × 1.1, with factors measured at sinks of 1.6–1.8. G(t), the factors, H(t) and the ×1.1 carry factor are gone from pricing. The model already plays carry-over, so its break-even includes it.

**Gold prices against the late sink** (SP charged; "beats" = beats a plain unit even on a 0-SP body):

| Card | Tier | 1.8 | **2.0** | 2.2 | 2.5 | 3.0 | **v1 price** |
|---|---|---|---|---|---|---|---|
| Battlecry: gain 1 gold | 1 | 2.3 | 2.4 | 2.4 | 2.5 | 2.6 | **2.4** |
| Battlecry: gain 1 gold | 2 | 4.7 | 4.6 | 4.6 | 4.6 | 4.5 | **4.6** |
| Battlecry: gain 1 gold | 3 | 5.8 | 5.2 | 4.5 | 3.6 | 2.1 | **4.5** |
| Battlecry: gain 1 gold | 4 | worth less than nothing at every sink | | | | | **2.2** |
| Battlecry: gain 1 gold | 5 | 2.4 | 2.5 | 2.7 | 2.8 | 3.0 | **2.5** |
| Battlecry: gain 1 gold | 6 | 1.6 | 1.7 | — | 2.0 | — | **2.0** |
| Battlecry: gain 2 gold | 1 | 3.2 | 3.1 | 3.0 | 2.8 | 2.6 | **3.0** |
| Battlecry: gain 2 gold | 2 | 5.8 | 5.7 | 5.5 | 5.3 | 5.0 | **5.6** |
| Battlecry: gain 2 gold | 3 / 4 / 5 | beats / 4.7 / 8.7 | beats / 4.4 / 9.1 | beats / 4.1 / 9.5 | 7.9 / 3.7 / 10.0 | 7.1 / 3.0 / 10.9 | **not allowed** |
| Start of turn: gain 1 gold | 1 | 4.8 (body 0.2) | beats | beats | beats | beats | **not allowed** |
| Start of turn: gain 1 gold | 2 | 6.0 (body 1.0) | 6.5 (body 0.5) | 6.9 (body 0.1) | beats | beats | **not allowed unconditional** |
| Start of turn: gain 1 gold | 3 | 5.0 | 5.1 | 5.3 | 5.6 | 6.0 | **5.1** |
| Start of turn: gain 1 gold | 4 | 3.9 | 4.2 | 4.4 | 4.8 | 5.4 | **4.2** |
| Start of turn: gain 1 gold | 5 | 3.8 | 4.1 | 4.5 | 5.0 | 5.9 | **4.1** |
| Start of turn: gain 1 gold | 6 | 2.1 | 2.2 | — | 2.6 | — | **2.2** |
| Start of turn: gain 2 gold | 4 | 9.6 (body 0.4) | beats | beats | beats | beats | **not allowed** |
| Start of turn: gain 2 gold | 5 | 6.7 | 7.3 | 8.0 | 8.9 | 10.4 | **7.3** |
| Start of turn: gain 2 gold | 6 | 4.2 | 4.5 | — | 5.4 | — | **4.5** |

Sources: the 1.8 and 3.0 columns for Battlecry 1 gold at Tiers 1–2, start-of-turn 1 gold at Tiers 1–4 and 2 gold at Tiers 4–5 are [bound_econ_recheck.csv](../research/budget-model/bound_econ_recheck.csv) **[data]**. Every other cell is **[data]** from `python -I tools/research/budget_model.py checks econ 1.8 2.0 2.2 2.5 3.0`, the same break-even at the other sinks and tiers (section 11). "—" was not in the first run; the command now prints those cells too.

What the table says:
- **The window is about 1.8 to 2.5.** Inside it, every allowed card's price stays within its ±25% band: the largest shift is Tier-5 +2 gold, +1.6 SP (13% of V(5)) at 2.5. At 3.0 Tier-5 +2 gold is +26% and Tier-3 one-off gold −30%, both outside. So B5's prices stay valid while late gold buys 1.8–2.5 SP per gold, which ties them to the spell budget (4.5).
- **One-off gold is lumpy.** A gold is worth a lot when it moves an upgrade a turn earlier, and little otherwise. The model's player follows one policy, so the lumps are sharp: 2 gold at Tier 3 beats a plain unit at sinks up to 2.2, and 1 gold at Tier 4 is worth less than nothing. Real games blur these. **[judgement]** v1 smooths Tiers 3–6: 4.5 at Tier 3, 2.2 at Tier 4 (from 2 gold at 4.1–4.7), 2.5 at Tier 5, 2.0 at Tier 6 (the sink).
- **The second gold is worth less at Tiers 1–2:** 0.6 more at Tier 1 and 1.0 more at Tier 2. Revision 1 priced "Battlecry: gain 2 gold" at Tier 2 at 7.7 SP; the model says 5.6.

**Gold caps on units.** This table is the one home of the gold caps. They are proposals awaiting the owner (B5, question 2). Economy-bounding §6 points here.

| Tier | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| Recurring gold a turn, unconditional | **0** | **0** | 1 | 1 | 2 | 2 |
| One-off gold per trigger | 2 | 2 | 1 | 1 | 1 | 1 |

- **No unconditional recurring gold at Tiers 1–2.** At Tier 1 it beats a plain unit from a sink of about 1.9; at 1.8 its break-even body is 0.23, so a 1/1 is +35% **[data: bound_econ_recheck.csv]**. At Tier 2 a 1/1 is +15% at 1.8, +21% at 2.0 and beats a plain unit from about 2.3 **[data: bound_econ_recheck.csv at 1.8; `checks econ` above]**. Battlegrounds prints no recurring gold on Tier 1–2 minions now: its Tier 1–2 gold cards are one-shots (Southsea Busker, Shell Collector) **[data: economy-text-by-era §7]**.
- **Conditional or time-limited gold is allowed at Tiers 1–2:** "for the next 2 turns", or gold that needs a condition. Price it as one-off gold for each turn it pays, × the condition's chance **[judgement]**.
- **+2 a turn from Tier 5, not Tier 4.** At Tier 4 its break-even body is 0.43 at a sink of 1.8 **[data]**, and it beats a plain unit at 2.0 **[data: `checks econ`]**.
- **One-off gold at most 1 per trigger from Tier 3** (Battlegrounds' median is 1 in every era **[data: economy-text-by-era]**). 2 gold at Tier 3 beats a plain unit in the model, and at Tiers 4–5 its price swings by 2× with the sink.
- **Why caps at all.** Battlegrounds' minions that gave 2–4 gold a turn (Record Smuggler, Snarling Conductor, Industrious Deckhand, all Tier 4–5) each stayed in the pool only 4–18 months **[data: economy-text-by-era §9]**. With carry-over and no cap, recurring income sets the bank for the long turn, so the cap is the snowball guard. An income board at these caps reaches Tier 6 on turn 8; at the old caps it reached it on turn 7 (B2).

**What carry-over gold changes** (Battlegrounds: use it or lose it; Bramble: no cap, no interest):

- **No waste.** Gold made on a turn with nothing to buy is banked.
- **Burst turns.** Banking lets players save for a big turn. "Next turn" and "start of turn" gold are no worse than gold now. Cost them the same.
- **Snowball risk.** A recurring income unit pays out every turn it is held, and the bank grows. That is why recurring income gets the per-turn cap.
- **Banking costs shops.** The refresh price rises within a turn, so two 15-gold turns buy 24 shops and one 30-gold turn buys 20 **[data: arithmetic, economy-bounding §8]**.

### 4.2 How much economy text, and where [data: economy-text-by-era.md]

What Battlegrounds prints, as the size reference for Bramble's economy:

- **On minions, gold text is rare and small.** Gold, refresh and discount text ("strict" economy) is 3.7% of current minions (10 of 273). It peaked at about 7% in Dec 2024. The median effect is **1 gold** in every era; the largest single minion trigger ever printed is about 4.
- **Card generation is where minion economy grew.** Broad economy (strict plus get-a-card) rose from 6% of minions (2019–21) to 26% now.
- **Gold text sits at Tiers 1–4.** Strict economy is 0% at Tiers 5–7 now, and at most 4% at Tier 6 in any era. High tiers pay in cards. Broad economy peaks at Tiers 3–4 (36%).
- **The big economy is on systems every player gets.** 38% of current Tavern spells carry economy text (14% strict), about half of trinkets (6–9% strict, and the biggest gold: Bob's Tip Jar), and 53 of 123 hero powers (14 strict).
- **Gold-spent engines are about 1% of the pool, and none returns its cost.** Best single-card return per gold spent: Tethys 0.30–0.38 (golden 0.60–0.75), Rogers 0.20–0.22 (0.40–0.44), Hoggarr 0.33 (0.67). Blizzard tunes them one gold at a time (Tethys 8 → 9 → 10).
- **Every tribe now has some broad economy (14% or more); four have no strict economy at all** (Murlocs, Dragons, Undead, Aberrations).

What v1 takes from it **[judgement]**:
- The size limits: one-off gold of 1–2 per trigger on units, recurring caps in 4.1.
- "No gold text above Tier 4, cards instead" as the default for Tiers 5–6 (2.2, last row). Recurring gold at Tiers 5–6 and gold-spent engines are the exceptions, priced by the table and as engines (4.4).
- Tavern spells as the main home of shared economy (4.5), which matches the owner's "everybody has them". Where economy lives is the owner's call (question 3).

### 4.3 Refreshes

**Rules (decided 27 Oct):** refreshes 1–10 of a turn cost 1, 11–20 cost 2, 21+ cost 3 (rulebook 4.4.3). Free refreshes and effect refreshes don't count toward the steps (4.4.5, 4.4.6). **Deferred (owner, 2 Nov: "We can power budget it later"):** the proposed tail, from the 31st paid refresh, +1 gold every 5, no cap (economy-bounding §4.1). It changes no turn of 30 paid refreshes or fewer.

**Value of a free refresh (E52): half a gold-equivalent, on a normal turn [data: spell prices; judgement].**
- **The price.** 0.5 × the tier's first-gold value (2.2): 1.2 / 2.3 / 2.3 / 1.1 / 1.3 / 1.0 SP at Tiers 1–6.
- **Why half a gold.** Battlegrounds' Leaf Through the Pages sets free refreshes to 2 for 1 gold **[data]**. A free refresh saves a gold only when the player would have paid for that refresh, and early players mostly don't: a no-engine Tier-6 player sees 6–12 shops on a normal turn **[data: bound_floor.csv]**, so the price rarely passes 1.
- **Late floor.** At Tiers 5–6 it is not less than what a gold of refreshes buys there, 0.5–0.67 SP **[data: bound_packages.csv, economy-bounding §5]**. 1.0–1.3 clears that.
- **Normal turn only.** Repeatable sources are priced on normal-turn firings (3.5), like every other recruit trigger. What they do on a banked turn is the turn-length check's job (G10), not the price's. G10 is deferred, so nothing checks banked turns yet.
- Free refreshes stay under the guardrails: set, don't add (G5), a per-turn cap on every repeatable source (G8 widened), and the turn-length check (G10), all in economy-bounding §7.

**v0's escalation discount** (gold for rerolls worth × 1.0 / 0.5 / 0.33 by step) is replaced by the measured late sink (4.6).

### 4.4 Engines: what price can and can't bound [data: economy-engines.md, economy-bounding.md]

Three loop shapes:

| Shape | Example | What bounds it | Price lever |
|---|---|---|---|
| **A. Spend-return** (per gold spent, R09) | Tethys, Rogers | Gold only, if r < 1. The refresh price doesn't touch r. | r per card; the strongest-board check (G2) |
| **B. Refund per target** (per buy or sell) | Hoggarr | The refresh price, if hits per shop × net per buy < the price | Net per buy; shop concentrators one-off (G3, G8) |
| **C. Free-refresh branching** | Refreshing Anomaly + golden Brann | Nothing in the price: free shops aren't paid | Per-turn caps, set-don't-add (G5, G7, G8) |

What this means for pricing **[judgement on data]**:
- **Price shape-A cards on their normal-turn firings** (3.5), not their banked-turn firings. Their banked turns are checked by turn length.
- **An engine's reward is stats, not shops.** At a 30-gold bank strong Rogers sees 3 more shops than no engine but makes 5× the SP **[data: bound_summary.csv]**. B8 proposes a limit on engine SP per gold.
- **Gold-for-gold spells feed spend counters for free.** A "gain N gold" spell at cost N is net 0 but ticks every "after you spend" counter by N. Count them in r for the strongest-board check **[judgement]**.
- **Check combinations, not cards.** Loops come from stacking sources; no single Battlegrounds card returns its cost **[data: economy-text-by-era §5]**. The guardrails and the `bound check` command are in economy-bounding §7. Every economy, scaling or engine card's review records its turn length there (G10).

**These bounds aren't in force yet.** The engine limits rest on G2, G5, G8, G10, G12 and G14 in economy-bounding §7, and all are proposals the owner hasn't approved. Until they are, nothing in v1 stops a board with r ≥ 1 (shape A) or free-refresh branching (shape C). Shape-A cards are priced on normal-turn firings, so the stats they make on a banked turn are checked only by B8, which is also open. And B8's starting limit already fails a strong plausible board (B8).

### 4.5 Tavern spells: the spell budget

Spells reach the player as in Battlegrounds: one shop slot per refill offers a spell of the player's tier or lower, bought for its own cost (rulebook 6.1.5, 4.2.5), plus spells made by card text (owner, 2 Nov: "Like Battlegrounds").

**A spell has no body, so its whole cost buys effect:**

> **spell value (realised SP) = cost × S(t)**, within the spell's band (±15% for stat buffs, ±25% for economy, card and scaling spells)

**One measure: realised SP.**
- **One chosen target:** the player puts Attack on a front unit and Health anywhere, so realised = nominal. That is also how Battlegrounds' rate was measured, so S(t) applies as is.
- **Several units or the whole board: price on a full board, whatever the tier.** Rulebook 6.1.5 offers spells of the player's tier or lower, so a low-tier board spell keeps showing up and gets cast on 7 units late in the game. A full board is 4 front units at 1.0 per stat and 3 back units at 0.75 per Attack and 1.0 per Health (6.1). "+1/+1 to your units" is 13.25 realised SP. Early in the game such a spell is weak for its cost, and that is the price of staying in the pool. The other choice, taking low-tier board spells out of later shops, is a rule change (question 6).
- **No board premium.** Battlegrounds' board spells give 1.2–1.5× the single-target rate on 7 units **[data]**. v1 doesn't copy that **[judgement]**: those spells are cast late, when Battlegrounds' late gold is worth more, and Bramble has no data that spread stats are worth less than stats on one unit. A premium would also lift the late sink (below).

**S(t), stat-buff SP per gold of cost:**

| Tier | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| **S(t), v1** | **4** | **5** | **5** | **5** | **5** | **5** |
| Battlegrounds, one target, unconditional, median **[data]** | 4 | — | 6 | 5.5 | 12 (conditional) | — |
| Battlegrounds, whole board, total on 7 units **[data]** | — | 6 (4 units) | 7–8 | — | 14–17.5 | 14 |
| Battlegrounds median spell cost, current pool **[data]** | 1 | 2 | 2 | 2 | 3 | 3 |

Sources: [spell_gold_to_stats.csv](../research/battlegrounds/analysis/spell_gold_to_stats.csv), [spell_gold_to_stats_by_tier.csv](../research/battlegrounds/analysis/spell_gold_to_stats_by_tier.csv); costs from [spells.json](../research/battlegrounds/data/spells.json) (73 current solo Tavern spells).

**Why flat 5 from Tier 2, below Battlegrounds' late spells:**

- **The spell rate sets the late sink, and the sink sets every gold price.** A no-engine Tier-6 player's SP per gold, power policy, recommended refresh schedule:

| S(t) at Tier 6 | 5 | 7 | 8 | 10 |
|---|---|---|---|---|
| Sink: SP per gold at bank 12 / 30 / 60 | 1.99 / 1.92 / 1.66 **[data: bound_packages.csv]** | 2.65 / 2.55 / 2.20 **[scratch]** | 2.98 / 2.87 / 2.47 **[scratch]** | 3.64 / 3.49 / 3.01 **[scratch]** |

  The gold prices hold for a sink of about 1.8–2.5 (4.1). S(t) = 5 gives 2.0 on a normal turn. S(t) = 7 gives about 2.6, just past the window. Battlegrounds-level late spells (12–17 SP per gold on a full board) put the sink at 3.5 or more, which would push +2 gold a turn out of Tier 5 and most recurring gold out of the game.
- **Why flat, not rising with tier.** In Battlegrounds the per-gold rate rises with tier. In Bramble a spell's tier buys a bigger packet (a higher cost, so more stats per slot and per action) and new kinds of effect (Make Golden, high-tier Discover), not more stats per gold. A rising rate would raise late gold's value, and with it every gold price. The new caps leave room for 6 at Tiers 5–6 (sink about 2.3 by interpolation, not run). That is the owner's call (question 1).
- **Relative to the board it is close to Battlegrounds.** A 4-gold whole-board spell at 5 SP per gold is 20 SP, about 17% of the 118-SP board the model's standard player has on turn 12. Battlegrounds' Azerite Empowerment (56 SP for 4) is about 21% of a 270-SP Battlegrounds-pace board **[data: review §1.3, §7; judgement on the comparison]**.
- **Tier 1 is 4** because Battlegrounds' three unconditional Tier-1 buffs are all 4 per gold, and a 1-gold +2/+2 is already 80% of V(1) **[data]**.

**Pricing rules for each kind of spell:**

| Spell kind | Budget | Grade |
|---|---|---|
| One target, permanent stats | cost × S(t), nominal = realised | data |
| Whole board or several units | Realised SP on a full board (above), against cost × S(t) | judgement |
| "This game" or future cards (E12, E14) | Per-turn scaling (3.2), under the growth caps | model |
| Gain gold now | Gold parity: "gain N gold" costs N (Tavern Coin 1, Wealthy Bounty 2) | data |
| Gold later or on a condition | At most +1 net gold (Careful Investment: 1 for 2 next turn) | data |
| Get a random unit | 2 gold (Recruit a Trainee, Friendly Bounty). In Bramble its net cost equals a bought unit's (3 − 1 = 2) with no choice, so it is a fair or slightly weak buy | data, judgement |
| Discover a unit | 3 gold (A New Sprout, Hired Headhunter) | data |
| Free refreshes | "Set your free Refreshes to 2" for 1 gold, as Leaf Through the Pages. At its 1.1% spell-slot share, with Refreshing Anomaly and Sly Infiltrator and no retrigger, it gives 22 shops (p90 24) from 30 gold, inside the limits (economy-bounding §3.8, G5, G7) | data |
| Make Golden, tier jump, Discover high tier | 4–5 gold (Golden Touch 5, Hallowed Ritual 5) | data |

**Spell rules, proposed** (economy-bounding §5, §7; not decided):
- Spell prices never escalate within a turn (rulebook delta 4.2.5, G12). Only the paid Refresh escalates.
- Gold-giving spells carry a per-turn cap if anything can copy them (G12, G6).
- **Spell pool mix [judgement on data]:** about 40% stat buffs (Battlegrounds 42%; the late sink depends on it), about a third with economy text and about 15% strict (Battlegrounds 38% and 14%), the rest utility. A change to the mix moves the sink, so re-check 4.1 when it changes.

### 4.6 What late gold buys (B6)

Late gold buys Tavern spells at flat prices. A no-engine Tier-6 player gets 1.7–2.0 SP per gold this way, about 1.4 at the margin from 30 to 60 gold, against 0.5–0.67 for refreshes only **[data: bound_packages.csv]**. Spend-counter engines are the other late sink: golden Gunpowder Courier makes about 10 SP per gold **[data: bound_summary.csv, strong_scaler]**. Their rate is B8's question. Activate abilities are a third (E88): 23 of 273 current Battlegrounds minions pay 0–2 gold to use **[data]**.

## 5. Golden and triples

Battlegrounds' rule is exact in the data **[data]**:

- **Body:** golden = 2 × attack and 2 × health (977 of 981 minions ever in the pool).
- **Effects:** magnitudes double (208 of 283 numbers in the current pool), counters and thresholds stay the same (75), and some texts are reworded to trigger twice (121).
- **Reward:** a Triple Reward discovers a minion from the next tier up.

Bramble follows that rule (owner, 27 Oct). It gives one check per card: **the golden version, costed with the same formula, should come out at 2 × V(t) within the card's band (±15% or ±25%).** Effects that don't double cleanly fail the check and need a golden-specific line:

- effects capped by geometry (a back unit has at most two units in front of it);
- keywords that can't double (Divine Shield, Taunt);
- effects that multiply each other;
- gold over the per-trigger cap (4.1): a golden "gain 1 gold" at Tier 3 gives 2, so it needs a golden line or a lower tier;
- **engines**: a golden spend-return card doubles r. Battlegrounds' best single golden returns 0.75 gold per gold **[data]**. Check the golden in the strongest-board test (economy-bounding G2), not only the plain card.

The Triple Reward is outside the unit budget. It is part of the tier-up economy and is priced with tavern progression.

## 6. The fixed-slot staggered 4-3 board

```
 front   [F1]  [F2]  [F3]  [F4]
 back       [B1]  [B2]  [B3]
```

All [sim] values in 6.1–6.4 come from the toy simulation (vanilla units, Tier 2 and Tier 5 boards, front row then back row attack order) unless they cite the rows study. They are the starting coefficients for the full simulation. The attack order stays front then back (owner, 27 Oct).

### 6.1 Row value of Attack and Health

| | Front row | Back row |
|---|---|---|
| 1 Attack | 1.0 SP (F1 about 1.15, F4 about 0.9: earlier slots attack more often) | **0.75 SP** |
| 1 Health | 1.0 SP | 1.0 SP |
| Divine Shield | about 1.1 × A | about 1.1 × A |
| Times attacked per fight | 0.6–1.15 | 0.33–0.71 |
| Survives the fight | 1–2% | 17–33% |

- **Health is worth the same in both rows [sim].** Once the front falls, the back takes every hit. Health in the back isn't wasted, and it isn't extra valuable.
- **Back-row Attack is worth 0.72–0.75 of front-row Attack [sim].** Back units attack after the front has traded, so fewer of their attacks happen before the fight is decided. This is for printed and recruit-phase stats. Stats given to back units during a fight are worth more (× 1.4, T04 in 3.4) **[sim: rows study]**.
- **Placement of plain units is worth about 1.6 SP, and one rule finds all of it [sim: positioning-sim.md §1, §6].** Hitters in front, biggest first. With position cards in, getting placement right is worth 3–4 SP more on the rows than on one row.

**Costing rule.** A unit that can go anywhere has its body costed at 1 SP per stat, at the average position. A unit whose text ties it to a row is costed with that row's values:

- A back-bound unit's attack costs 0.75 SP per point, so it can print about a third more attack for the same budget.
- A front-bound unit's attack costs 1.0, or about 1.1 if its text favours the left slots.
- Price position cards on the turns they are bought, not only on full boards (positioning-sim §6).

### 6.2 The value of back-row protection

- Back units survive the fight 10–20× as often as front units, and are attacked half as often **[sim]**.
- This doesn't raise the value of their printed stats (6.1), but it does raise the value of **anything that works while the unit is alive**: auras, "whenever…" triggers, Rally-style "when this attacks", and stats it gains mid-fight.
- Survival factor for "while alive" effects **[judgement, from the exposure table]**: **0.9 in the back row, 0.5 in the front row.**

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
| Back unit: "units in front of this have +X Attack" | **about 100%** (95–119%); rows study: 1.9 SP for +1 to 2 units |
| Front unit: "units behind this have +X Attack" | **about 5%** (0–7%) |
| Battlegrounds adjacent aura, for comparison | 40–70% |
| Back unit: "when a unit in front of this dies, gain +2/+2" | about 7 SP per fight (about 1.9 triggers × 4 SP × 0.9) |

Battlegrounds dropped static auras (4% of minions in 2020, 0% now) **[data: effect-taxonomy §1]**. On Bramble's board the back-row aura on the units in front is the easiest support effect to price **[judgement]**.

**Costing rule:** realisation is part of the formula, and it depends on timing.

- A front unit's static aura on the back row is wasted, because the front is dead before the back acts.
- A one-off Start of Combat buff from the front to the back is not wasted: the buff outlives the giver.
- Wording decides value. The worked examples in section 7 show it.
- These coefficients assume front-then-back attack order.

**Empty and partial boards.** Multiply by the chance the neighbour slots are filled when the effect matters.

Board fill by turn **[data: model, economy_timeline.csv; to be measured in the bot]**: 1 unit on turns 1–2, 3 on turns 3–4, 6 on turns 5–6, 7 from turn 7.

A back-row support bought on turn 1 or 2 is placed behind whatever the player has. The rows study found the Tier-1 back aura worth slightly more on 3–4-unit boards than on full ones (2.2–2.4 SP against 1.9), because the player puts it behind the units that attack most **[sim: rows_card_summary.csv]**. So v1 drops v0's 0.6 early-board condition for back-row auras.

### 6.4 Empty-slot effects

- Removing any one unit from a full board costs 21–23 points of win rate, whichever slot is left empty **[sim]**. A gap has no defensive value of its own.
- An effect that needs an empty slot ("if there is no unit behind this…", "summon into an empty slot") therefore costs the player about one unit's worth of board once the board is full.
- **Costing rule [judgement]:**
  - Value the payoff against V(t) of the unit it displaces, taken at the tier where the player has a full board (about turn 7 on).
  - Before then the slot is free, so the same card is strong early and weak late.
  - Price at the turn band the card is meant for, and say so on the card's design note.

### 6.5 Known geometry risks to watch in simulation

- **Fortress (1 front, 3 back).** The rows study found no searched layout used one front unit, and a card built for it was weak (positioning-sim §6). A much stronger fortress card (big Taunt, Divine Shield giver) could still change this.
- **Summon placement.** Reborn and Deathrattle summons fill the dead unit's slot, as in Galaxy. A front unit's Reborn therefore restores front protection, so in Bramble it may be worth more in front than in back. The rows study's Reborn card measured best in F2 **[sim]**.
- **Galaxy precedent [data].** Galaxy charged early supports only 2 body SP for a 4 SP aura and later had to nerf them. Supports average 12% below their rarity's stat median. Pricing back-row auras at full realisation is stricter than Galaxy's launch pricing.

## 7. Worked examples

These are placeholder units with no woodland names. Each shows the arithmetic; none is a proposed card.

- **A** = mean enemy Attack (section 3.1).
- **"Back-bound"** means the text works only from the back row, so attack costs 0.75 SP (section 6.1).
- Results are rounded to whole stats. The last column is the total against the budget, and the band. "Measured" cites the rows study (positioning-sim §5.2) for the same text.

| # | Tier | Text | Costing | Body | Check |
|---|---|---|---|---|---|
| 1 | 1 | *(none)* | V(1) = 5 | **2/3** | 5.0 / 5 |
| 2 | 1 | Back row only: "The units in front of this have +1 Attack." | Magnitude 1 × 2 targets = 2 SP; realisation 1.0 [sim]; **v1:** no early-board discount (6.3) → **2.0**. Back-bound: body budget 3.0, so 1 Attack (0.75) + 2 Health. | **1/2** | 2.75 + 2 = 4.75 / 5 (±15%). Measured: 1/2 is +5% on full boards, +2–6% on 3–4 units; v0's 1/3 was +14–24%. |
| 3 | 2 | Divine Shield | 0.9 × A(2) = 0.9 × 2.5 → **2.25** | **2/3 DS** | 5 + 2.25 = 7.25 / 7 (±15%) |
| 4 | 3 | Back row: "When a unit in front of this dies, gain +1/+1." (ends with the fight) | Half the sim value of +2/+2 (7 SP) = 3.5; condition 0.9 → 3.2; **v1:** combat buff on a back unit × 1.4 → **4.4**. Back-bound: budget 3.6. | **2/2** | 1.5 + 2 + 4.4 = 7.9 / 8 (±15%). Measured: 2/2 is 0%; v0's 2/3 was +17%. |
| 5a | 3 | Front: "The units behind this have +2 Attack." | Nominal 2 × 1.5 neighbours = 3 SP, but realisation about 0.05 [sim] → **0.15**. Body 7.85. | 4/4 | **Flag: the text is nearly blank in combat. Reword or cut.** |
| 5b | 3 | Front: "Start of Combat: give the units behind this +2 Attack." | 2 × 0.75 (back attack) × 1.5 neighbours × 0.9 fill → **2.0**. Body 6. | **3/3** | 6 + 2 = 8 / 8 (±15%). Measured: +5% at F2. |
| 6 | 2 | "Battlecry: Gain 1 Gold." | **v1:** first gold at Tier 2 → **4.6** (2.2). Body 2.4. | **1/1** | 2 + 4.6 = 6.6 / 7 (−6%, ±25%). 1/2 is +9%, also in band. v0 charged 1.9 and gave 2/3. Battlegrounds' Shell Collector is 4/3 with a Coin. |
| 7a | 4 | Back row: "At the end of your turn, give the units in front of this +1/+1." | s = 2 SP × 1.9 occupied neighbours = 3.8 per turn; **v1:** 3.8 × c(4) 3.1 = **11.8** | — | **Fails: over the whole V(4) = 10, and over the Tier-4 growth cap of 2.5.** |
| 7b | 4 | Back row: "At the end of your turn, give the units in front of this +1 Health." | s = 1.9 per turn, under the cap; **v1:** 1.9 × 3.1 = **5.9**. Back-bound: budget 4.1. | **1/3** | 0.75 + 3 + 5.9 = 9.65 / 10 (−4%, ±25%: an R03 trigger). |
| 8 | 1 golden | Golden of #2: "+2 Attack to the units in front of this", body 2/4 | Aura 2 × 2 × 1.0 = 4; body 0.75 × 2 + 4 = 5.5 | **2/4** | 9.5 against 2 × V(1) = 10 (−5%). Passes. |
| 9 | 2 | Front: "If there is no unit behind this, it has +3/+3." | Payoff 6 SP. Early, the gap is free (condition about 0.8 through turn 4). Once the board is full, the gap costs a unit (about V(t)). Priced for turns 2–4: 6 × 0.8 → **4.8**. Body 2.2. | **1/1** (+3/+3 → 4/4) | 2 + 4.8 = 6.8 / 7 (±15%). Measured: the same text on a 2/1 is +21–31% on small boards and −36% on full ones, so the 1/1 is right for its turns. A trap late, and that's intended. |
| 10 | 3 | "Start of your turn: gain 1 Gold." | **v1:** recurring +1 at Tier 3 → **5.1** (2.2). Body 2.9. Gold cap: 1 a turn, at the cap. | **1/2** | 3 + 5.1 = 8.1 / 8 (+1%, ±25%). Battlegrounds' Accord-o-Tron is a 3/3 at Tier 3. |
| 11 | 3 | Spell, cost 2: "Give a unit +5/+5." | Budget 2 × S(3) 5 = 10; one chosen target, realised = nominal → **10** | — | 10 / 10 (±15%). Battlegrounds' Repair Job (+4/+8 for 2) is 12. |
| 12 | 5 | Spell, cost 2: "Give your units +1/+1." | Full board: front 4 × 2 = 8, back 3 × (0.75 + 1) = 5.25 → **13.25**, against 2 × 5 = 10 | — | **+33%: over.** At cost 3 the budget is 15 and it is −12%, in band. |
| 13 | 2 | Spell: "Give your units +1/+1." (the same text at Tier 2) | Priced on a full board, as #12: **13.25**. Cost 3: budget 15 | — | −12% (±15%). On turn 2–3 it buffs 1–3 units for 3 gold, about 5 SP: weak early, by design, because it stays in later shops (4.5). |
| 14 | 5 | "Start of your turn: gain 2 Gold." | **v1:** recurring +2 at Tier 5 → **7.3**. Body 4.7. Gold cap: 2 a turn, at the cap. | **2/3** | 5 + 7.3 = 12.3 / 12 (+2.5%, ±25%). At Tier 4 the same text beats a plain unit on any body (4.1). |
| 15 | 2 | "Battlecry: your next Refresh this turn is free." | **v1:** one free refresh at Tier 2 → **2.3** (4.3). Body 4.7. | **2/3** | 5 + 2.3 = 7.3 / 7 (+4%, ±25%). |

What the examples show:

- **#5a against #5b:** the same nominal effect is worth 0.15 or 2 SP depending on timing.
- **#2 and #4:** the rows study moved two v0 prices, in opposite directions from what v0 expected. Back-row auras were not weaker early, and combat buffs on back units were worth more.
- **#7a:** per-turn scaling breaks the budget fastest. This is the class that crept in Battlegrounds.
- **#6, #10 and #14:** gold is priced from one table per tier. The same "+2 a turn" is fine at Tier 5 and illegal at Tier 4.
- **#12 and #13:** board spells are priced on a full board at every tier.
- **#8:** the golden check catches effects that don't double cleanly. This one passes.

## 8. Validation plan: calibrating the budget by simulation

The toy simulation in `tools/research/power_budget.py` is the prototype. The real tool should live in the game's headless engine so that it uses the real rules.

1. **Parity.** Implement Bramble combat headless: fixed slots, attack order, targeting, summon placement. Reproduce the toy simulation's tables (slot exposure, row values, neighbour counts) as regression tests. If a rule changes, these numbers change. Record them.
2. **Baseline boards.** For each tier band (turns 1–3, 4–6, 7–9, 10+), build reference boards of plain units at V(t) with 45–50% attack. Use realistic unit counts per turn and realistic tier mixes.
3. **Per-SP slope.** At each tier band, measure the win-rate gain of +1 SP on a random slot. This converts win rate into SP (0.046 per SP at Tier 2 and 0.028 at Tier 5 in the toy simulation).
4. **Single-card fight test.**
   - Run at least 6,000 paired fights with common random numbers. At that count the standard error is about 0.5 points of win rate, or 0.1–0.2 SP.
   - Test the intended slot and every slot, on the board size of the turns the card is bought (positioning-sim §6). Report the SP-equivalent, the best and worst slot, and the gap between them, which measures how much position matters for that card.
   - **Pass band:** the card's tolerance (2.3): within ±15% of V(t) for plain cards or ±25% for economy, scaling and engine cards, or ±1 SP, whichever is larger.
5. **Whole-game bot test (B7).** This covers recruit-phase value: scaling, economy and card generation.
   - Run scripted bot lobbies with simple policies: buy by curve, level on a schedule, keep the best board, under Bramble's economy rules (carry-over, escalating refreshes, a spell slot in every shop).
   - Measure average placement, Battlegrounds' own balance metric ([Blizzard](https://us.forums.blizzard.com/en/hearthstone/t/87311/1)), and per-card placement impact when bought, in the style of HSReplay's Tier7.
   - Measure hold times, board fill by turn, the value of gold by turn, the late sink, lobby pace, and the scaling charges c(t). Replace the [judgement], [guess] and [scratch] placeholders with the results. The gold table (4.1) is the most policy-sensitive and goes first.
6. **Refit.** Once there are 50 or more test cards, regress their simulated SP-equivalents on their features (the same least-squares approach as Bursztein's Hearthstone model and this repo's analysis). Update the coefficients, and flag cards whose formula cost and simulated value disagree by more than 20%.
7. **Pace guardrails (B3).** Track total board SP by turn against a target curve. Galaxy polices "pace" (full heart losses early), not raw numbers **[data]**.
8. **Position check.** For the position-text test cards, report how often placement changes the fight result, as in [positioning-sim.md](positioning-sim.md).
9. **Turn-length check (G10).** *Deferred (owner, 2 Nov): skip until turn length is budgeted.* Every economy, scaling or engine card records median and 90th-percentile shops for its strongest package at banks of 30 and 60 gold, and its SP per gold (B8), with `python -I tools/research/budget_model.py bound check …` (economy-bounding §7).
10. **Later.** Automated parameter search over card numbers ([Ludus, AAAI 2022](https://ojs.aaai.org/index.php/AAAI/article/view/21550)), then human playtests, then telemetry. Simulation sets the starting numbers; play decides fun.

## 9. Open questions for the owner

Decided since v0 (for the record):
- **Attack order:** stays front then back (27 Oct, combat-shape note).
- **Plain units:** on budget (27 Oct).
- **Recruit-phase value priced more strictly than Battlegrounds:** yes (27 Oct).
- **Free refreshes count toward the steps:** no; content guardrails instead (27 Oct, G1).
- **Combat buffs:** end with the fight (27 Oct).
- **Taunt:** kept, within the row that can be attacked (27 Oct).
- **Golden rule:** 2× body, 2× effect sizes, 1× thresholds, plus a triple reward (27 Oct).
- **Tolerance:** ±15% for plain cards, ±25% for economy, scaling and engine cards, both directions (2 Nov).

Open, new in v1:

1. **How strong should late spells be?** v1 holds stat spells to 5 SP per gold from Tier 2. Late gold then buys about 2.0 SP per gold, and the gold prices hold up to about 2.5. Options: keep 5; raise Tiers 5–6 to 6 (sink about 2.3, still inside); or Battlegrounds-strength late spells (12–17 per gold on a full board, sink 3.5 or more), which would push most recurring gold out of the game. A whole-board +1/+1 at Tier 5 costs 3 gold under v1, about 3× weaker per gold than Battlegrounds' late board spells.
2. **No unconditional recurring gold at Tiers 1–2, and +2 a turn only from Tier 5?** At Tiers 1–2 it beats or nearly beats a plain unit on any legal body, and Battlegrounds prints none there today. Conditional and time-limited gold stays allowed.
3. **Where should strong shared economy live?** v1 assumes Tavern spells carry most of it: about a third of spells with economy text, as in Battlegrounds (4.2, 4.5). The alternative is more economy on tribe units, under the 4.1 caps.
4. **What does "increase maximum gold" do?** Under rulebook 4.1.4 it only lifts the 10-gold ceiling and is worth 1–2 SP. If it should raise income at once, as in Battlegrounds, it is recurring +1 gold and comes under the caps.
5. **Tolerance floor:** keep "±1 SP, whichever is larger" for low tiers, where one stat is 14–20% of V(t)?
6. **Low-tier board spells in late shops:** price them for a full board (weak when bought early; v1's choice), or take them out of the shop once the player's tier is above theirs (a change to rulebook 6.1.5)?
7. **Lobby pace (B3):** which feel do you want? Prices barely depend on it (13% or less), but it sets how many HP a scaling lead is worth and how big late boards look.
8. **One-off gold at most 1 per trigger from Tier 3?** Battlegrounds' median is 1. The model says 2 gold at Tier 3 beats a plain unit.
9. **Content rule for stat multiply and consume:** "once per turn, can't be retriggered"? Without it they grow geometrically and no price holds. This is a proposed rule, not saved anywhere.
10. **The answers to B1–B8 in section 10.** Each needs your yes or a different choice.

## 10. Recommended answers to B1–B8

From [power-budget-review.md](power-budget-review.md) §10 (B1–B7) and [economy-bounding.md](economy-bounding.md) §4.4 (B8). Each is a recommendation, not a decision.

### B1. Break-even turn for a fairly priced scaling card

**Recommendation: break even by turn 12 against a plain unit, bought when its tier opens. Read the charge per tier from the model: c(t) = 3.9 / 3.7 / 3.5 / 3.1 / 2.6 / 2.6 per SP a turn, and 3.0 / 2.8 / 2.5 / 2.1 / 1.6 / 1.6 per SP per combat firing (3.2).**
- **Why:** the H(t) rule is fair only if the card is sold after H fights. Real holds run the other way: 10–15 fights for early scaling, 2–3 for late **[data: hold_time.csv]**. Turn 12 is where most decisive fights fall in the model's horizon **[judgement]**.
- **Evidence:** at each tier's cap a 1/1 breaks even, which gives 3.85 / 3.8 / 3.6 / 3.15 / 2.6 **[data: scaling_rate_caps.csv]**. Below the cap the charge per SP is a little lower **[data: `checks scaling`]**. Revision 1's flat 0.8 × (F+1)/2, with F the fights from the tier's opening turn to turn 12, was +35% and +27% at Tiers 1–2 against these. The implied rate on (F+1)/2 rises from 0.6 at Tier 1 to 0.87 at Tier 5, so no flat rate fits.
- **Risk:** it rests on the HP proxy and a one-player model whose player sells by one policy. Check c(t) in the whole-game bot first (B7).

### B2. Design-target economy level

**Recommendation: price against "standard" (+0.5 gold a turn on average). Treat "econ-heavy" (Tier 6 on turn 8) as the ceiling a committed economy build should reach with legal cards. Treat "high-roll" (Tier 6 on turn 7) as out of reach for income units alone.**
- **Why:** economy moves the tier clock, not the crossover turns; each level reaches Tier 6 one turn sooner **[data: tier_reach.csv, review §1.3]**. Shared economy through spells (4.5) raises every player alike, so it shifts the clock for the lobby rather than the relative price of cards **[judgement]**.
- **Evidence:** at standard, Bramble reaches Tiers 2–6 on turns 2/4/6/8/9; econ-heavy 2/4/5/7/8; high-roll 2/3/5/6/7 **[data]**. **Tested in revision 2 [data: `checks reach`]:** boards that hold income units at the 4.1 caps from the turn each tier opens reach Tier 6 on turn 8 or 9. The richest tested, +2 gold a turn from turn 4 (two Tier-3 units), +3 from turn 6 and +6 from turn 8, on top of standard, reaches Tiers 2–6 on turns 2/4/5/7/8: econ-heavy. The old caps (+1 from turn 3 at Tier 2, +2 from turn 4, +4 from turn 6 with a Tier-4 +2) reach Tier 6 on turn 7: high-roll. The run counts the extra gold only, not the bodies the income units cost, so real boards are slower.
- **Risk:** the reference level moves economy results more than any price (review §7). If playtests show most players at econ-heavy, re-run the gold table there.

### B3. Target lobby pace

**Recommendation: price at the printed-stats pace (about 120 SP on the board at turn 12, the model's 118), and set the target pace for feel, not for prices. A pool with scaling text will run faster; the bot measures how much.**
- **Why:** the break-even charge hardly moves with pace. With the rest of the lobby growing 1 SP per unit per turn (turn-12 boards about 180 SP), c(t) falls by 0–6%; at a Battlegrounds-like 2.5 (about 270 SP), by 0–13%, most at Tier 1 **[scratch]**. Both are inside the ±25% band. What pace changes is how many HP a lead is worth: at 180 SP, scaling cards' turn-12 surplus is about a third smaller than at 118 **[data: pace_scenarios.csv]**. So pricing at 118 doesn't work against scaling comps.
- **The band:** revision 1's "110–160" had no source and is dropped. The pace_scenarios rows are 118, 180 and 273 at turn 12 **[data]**.
- **How it is held:** lobby pace is the sum of all scaling text, so it is a design target. Track it as a pace guardrail (section 8 step 7). The question for the owner is feel: how big late boards look, and how fast a scaling lead turns into hero damage (question 7).
- **Risk:** the model adds the lobby's growth as a pool on every board, so it can't see scaling comps racing each other.

### B4. Growth cap per tier

**Recommendation: yes. Unconditional per-turn self-scaling at most 0.8 / 1.3 / 1.7 / 2.5 / 3.8 SP a turn at Tiers 1–5; combat-triggered (one per fight) at most 1.0 / 1.7 / 2.2 / 3.6 / 6.2. Over the cap, the text must be conditional, capped ("up to N times") or move up a tier. Tier 6 uses the Tier-5 cap until measured.**
- **Why:** above these rates even a 1/1 body breaks even with a plain unit by turn 12, so no body price can fix the card **[data: scaling_rate_caps.csv, standard econ, by turn 12]**.
- **Applies to:** E02, E08–E11, E14 and every "this game" amplifier, with s counted at full use (3.5).
- **Linear growth only.** Stat multiply and consume (E06, E08) are priced only once per turn and not retriggerable (3.2, question 9).
- **Risk:** caps are by turn 12. Read by turn 10 they are higher at Tiers 4–5 (3.2 and 5.8). The tolerance (±25%) covers that gap at Tiers 1–4, not at Tier 5.

### B5. Re-price recurring economy

**Recommendation: yes. Price gold on units from the per-tier table (2.2, 4.1), read at a late sink of 2.0 SP per gold. No unconditional recurring gold at Tiers 1–2, +1 a turn at Tiers 3–4, +2 from Tier 5. One-off gold at most 2 per trigger at Tiers 1–2 and 1 from Tier 3.**
- **Why:** v0 charged recurring gold 1.5–10× too much and floored every such card from Tier 3 up; it charged one-off gold too little **[data: econ_break_even.csv, bound_econ_recheck.csv]**. Revision 1 fixed that with factors set at a sink of 1.6–1.8, but the normal-turn sink is 2.0 **[data: bound_packages.csv]**, and at 2.0 its Tier-1, Tier-2 and Tier-4 +2 cards were over budget on any legal body.
- **Evidence:** 4.1's table. Inside a sink of 1.8–2.5 every allowed card stays within ±25% of its price. Battlegrounds' per-turn gold on minions is usually 1 gold, and its 2–4-gold-a-turn minions didn't last **[data: economy-text-by-era §9]**.
- **Condition:** valid while late gold buys 1.8–2.5 SP per gold. That ties B5 to the spell budget and the spell mix (4.5, question 1). Re-run the table when either changes.
- **Replaces economy-bounding §6's earlier factors and caps**, which were measured at a sink of 1.6–1.8. That section now points here.

### B6. What late-game gold buys

**Recommendation: Tavern spells at flat prices that never escalate, a spell in every shop (rulebook 6.1.1 already has one), plus spend-counter engines and Activate abilities (E88) as optional sinks (4.6).**
- **Why:** with refreshes only, late gold buys 0.5–0.67 SP per gold; with spells, 1.7–2.0 **[data: bound_packages.csv]**. Spells are bought, not refreshed, so their value holds while escalation still limits shops.
- **Evidence:** Battlegrounds' Season 14 answer is also sinks: 23 of 273 minions have Activate **[data]**.
- **Needs:** rulebook delta 4.2.5 (spell prices fixed for the turn) and G12, both proposed in economy-bounding §7.

### B7. Build the whole-game bot next

**Recommendation: yes, as part of the headless engine's first milestone, before content is costed past the first test cards. First test cards may start from v1's numbers.**
- **Why:** the inputs that move results most are hold time, the player's policy, the late sink and lobby pace (review §7). All need a whole-game run. The scaling charge, the gold table and board fill by turn come from a one-player model until then.
- **Where v1 is known to be in band:** the rows-study cards after its re-prices (Moth 1/2, Vole 2/2, Badger, Keeper, Robin, Rot Toad, Puffball, Hare on full boards; positioning-sim §5.2) **[sim]**; scaling at the growth caps and gold at 1.8–2.5 against the one-player model (3.2, 4.1) **[data]**.
- **Where it is known to be out, or untested:** Lone Stag on full boards (by design, #9), Drummer Hare on small boards (−15–22%), Divine Shield on bodies that trade (one-card Taunt measurement), Reborn on bodies far from V(t), every [guess] class in 3.4, and anything on a banked turn (B8).
- **Why not first:** tribe and card prototypes can start now. The owner expects to iterate, and the bands catch the measured cases above.
- **Note:** the Python budget model stays the interim tool. The real one belongs in the engine (section 8; owner, 2 Nov).

### B8. Engine SP per gold (new, from economy-bounding §4.4)

**Recommendation: adopt as an open test, not yet a rule. Starting point: the strongest plausible engine makes at most about 4× the no-engine SP per gold on a 30-gold bank, about 7.7 SP per gold at Tier 6 with S(t) = 5. That limit already fails one strong plausible board, so the number is the owner's call.**
- **Why:** shop limits don't limit power. Two golden Rogers pass every shop limit and make about 920 SP from 30 gold; with Hoggarr, about 3,100 **[data: bound_summary.csv]**.
- **Evidence:** no engine 1.9 SP per gold; strong Rogers 7.3–7.6; **strong scaler (golden Gunpowder Courier) 9.9, about 5×, which fails a 4× limit**; ceiling Rogers 13 **[data: bound_summary.csv]**. Either the limit is about 5×, or spend-counter scalers like the Courier are weakened.
- **Risk:** the Rogers figures take Bounty text at face value, and SP per gold needs the combat link this model lacks. Confirm in the bot before it becomes a guardrail.

## 11. Limits and reproduction

- **Most inputs are judgement.** Hold times, board fill, the late sink and lobby pace all need the whole-game bot (B7).
- **The one-player model** behind sections 3.2 and 4 has no opponents, triples, tribes or shop randomness ([power-budget-review.md](power-budget-review.md) §11). Its economy results are knife-edge in places: one-off gold is lumpy (4.1), and the gold table is smoothed by judgement at Tiers 3–6.
- **The spell budget rests on few cards.** Only 2–4 unconditional single-target Battlegrounds spells per tier. The late sink uses the bounding model's average shop: a 42% buff share and one spell per shop.
- **The rows-study prices** (Reborn, Taunt with Divine Shield, back-unit combat buffs, "across from" damage) come from one or two cards each.
- **Taxonomy prices** for card generation, shop control, free refreshes, the Bramble-new classes and most combat-trigger counts are guesses (3.4).

**Reproduction.** The model numbers tagged [data] with a `checks` command come from `python -I tools/research/budget_model.py checks …`. It prints and writes nothing, and runs in one process (`reach` in seconds, `econ` and `scaling` in a few minutes).
1. **Gold table (2.2, 4.1):** `checks econ 1.8 2.0 2.2 2.5 3.0`. For level `standard`, kinds `gold_once` and `gold_per_turn` with 1 and 2 gold at Tiers 1–6, it bisects the body at which `compare(…)["surplus_hp_t12"]` is 0, at each late sink (`A["SINK_SP_PER_GOLD"]`). Price = V(t) − break-even body. At 1.8 and 3.0 it reproduces bound_econ_recheck.csv's `break_even_body_t12`.
2. **Scaling charge below the cap (3.2, B1):** `checks scaling 0`. The same bisection with kind `self_turn` (freq None) or `self_combat` (freq 1.0) at s = 0.25, 0.5, 1.0, 1.5, 2.0, 3.0. Charge = (V(t) − break-even body) ÷ s. At each cap it matches scaling_rate_caps.csv.
3. **Pace (3.2, B3):** `checks scaling 0 1 2.5` runs 2 at `A["GENERIC_GROWTH_PER_TURN"]` 0, 1.0 and 2.5 and prints the change in charge against pace 0. **Still [scratch]:** the claim that c(t) falls by 0–6% and 0–13% holds for `self_turn` at s = 1 only. At s = 0.25–0.5 the Tier-1 charge falls by up to 7.7% (pace 1.0) and 15.6% (pace 2.5), and the combat charge at Tier 1 by up to 10.7% and 21.7%. All are inside the ±25% band.
4. **Income board at the caps (B2):** `checks reach`. The boards are `CHECK_REACH_LEVELS` in budget_model.py, read with `reach_turns(simulate(name))`.
5. **Spell rate against the sink (4.5): still [scratch], not in the repo.** Set `B["SPELL_SP_PER_GOLD"]` to 7, 8 or 10 and call `bound_cell((package none, _sched("s123_plus1_nocap"), bank, "power", 6))` for banks 12, 30 and 60, with one worker. At 5 it matches bound_packages.csv. A re-run on 2 Nov reproduced every figure in 4.5's table.
