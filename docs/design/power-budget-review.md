# Power budget review: immediate power against scaling and economy

**Status: for the owner's review, 27 October 2026.** This answers the owner's question in [owner-notes/2026-10-27f-power-budget-decisions.md](owner-notes/2026-10-27f-power-budget-decisions.md):

> How many turns would it take for the scaling card to realistically catch up and be better than the immediate power card? At what level of econ?

- **Model:** `tools/research/budget_model.py` (standard library only). Every assumption is in one `ASSUMPTIONS` block at the top. Change a number and re-run with `python -I tools/research/budget_model.py` (about 30 seconds).
- **Tables:** [docs/research/budget-model/](../research/budget-model/). Each number below names its CSV.
- **Method under review:** [power-budget.md](power-budget.md) v0: V(t) = 5/7/8/10/12/14 SP, scaling charged at 100% of s × (H+1)/2, economy at 50% of its gold value with G(t) = V(t)/2, hold time H(t) = 3/3/4/4/5/5.

Words: **SP** is one stat point. **"Catches up"** means the scaling card's stats match the plain card's in that fight. **"Ahead in total"** means the running total of SP over all fights since purchase has turned positive and stays positive. **"HP"** means expected hero damage avoided, from a proxy (section 3). **Bought on turn 3** counts turn 3's fight as the first fight.

*Judgement calls are marked **[judgement]**. Most of the model's inputs are judgement; the point is to show which ones matter.*

---

## 1. The direct answers

### 1.1 The owner's example: a tier-2 "+1/+1 each turn" unit bought on turn 3

Against a plain tier-2 unit (7 SP). "End of turn: gain +1/+1" is 2 SP per turn. Source: [scaling_grid.csv](../research/budget-model/scaling_grid.csv) (tier 2, turn_planned 3, archetype `eot_+1/+1`).

| Econ level | Pricing (body) | Catches up | Ahead in total SP | Ahead in HP | Kept for (fights): scaling / plain | HP ahead by turn 8 / 10 / 12 / 15 |
|---|---|---|---|---|---|---|
| no econ | method 100% (3 SP) | turn 4 | turn 5 | turn 6 | 13 / 4.4 | 5.5 / 11.3 / 16.9 / 27.0 |
| **standard** | **method 100% (3 SP)** | **turn 4** | **turn 5** | **turn 6** | **12.9 / 4.4** | **5.1 / 10.7 / 16.1 / 25.9** |
| econ-heavy | method 100% (3 SP) | turn 4 | turn 5 | turn 6 | 12.7 / 4.7 | 5.2 / 9.0 / 13.6 / 22.5 |
| high-roll | method 100% (3 SP) | turn 4 | turn 5 | turn 6 | 13 / 4.7 | 4.0 / 8.0 / 13.2 / 22.7 |
| standard | HSBG-like (6.3 SP) | turn 3 | turn 3 | turn 3 | 12.9 / 4.4 | 13.6 / 21.5 / 28.7 / 40.6 |
| standard | method 100%, **sold after H = 3 fights** | — | — | — | 3 / 3 | −0.4 by turn 15 |

**Answer:** priced by the method, the tier-2 unit catches up on turn 4, is ahead in total on turn 5, and is ahead in expected hero damage on turn 6. Economy level barely moves those turns. It changes how far ahead the card gets: at econ-heavy or high-roll the lead by turn 10 is 15–25% smaller, because the player reaches higher tiers sooner and the plain alternative improves faster.

**The catch:** the method makes this card exactly fair *only if it is sold after 3 fights* (last row: −0.4 HP). In the model the player keeps it for the rest of the game (12.9 fights), because +2 SP a turn outgrows the tier curve. Kept that long, it is 10.7 HP ahead by turn 10. At the method's price it is under-priced.

### 1.2 Every tier, standard econ, bought on the turn the tier is reached

Source: [scaling_grid.csv](../research/budget-model/scaling_grid.csv), `pricing = budget100`, catch-up columns from `hold_mode = card`, kept and HP from `hold_mode = endo`. "Floor" means the method's body came out below a 1/1, so the card was given a 1/1 (2 SP).

| Tier | Bought | Text | Body (method raw) | Catches up | Ahead in total | Ahead in HP | Kept: scaling / plain (H) | HP ahead by turn 12 |
|---|---|---|---|---|---|---|---|---|
| 1 | 1 | +1 Health / turn | 3 | 2 | 3 | 3 | 15 / 6.4 (3) | +10.0 |
| 1 | 1 | +1/+1 / turn | 2 floor (1) | 2 | 2 | 2 | 15 / 6.4 (3) | +33.0 |
| 1 | 1 | combat +1/+1, 1/fight | 2 floor (1) | 3 | 4 | 4 | 15 / 6.4 (3) | +23.3 |
| 2 | 3 | +1 Health / turn | 5 | 4 | 5 | 6 | 11.9 / 4.4 (3) | +5.5 |
| 2 | 3 | +1/+1 / turn | 3 | 4 | 5 | 6 | 12.9 / 4.4 (3) | +16.1 |
| 2 | 3 | combat +1/+1, 1/fight | 3 | 5 | 7 | 8 | 12.9 / 4.4 (3) | +8.5 |
| 3 | 5 | +1 Health / turn | 5.5 | 7 | 8 | 9 | 10.1 / 3.0 (4) | +1.7 |
| 3 | 5 | +1/+1 / turn | 3 | 7 | 8 | 9 | 11 / 3.0 (4) | +6.5 |
| 3 | 5 | combat +1/+1, 1/fight | 3 | 8 | 10 | 11 | 11 / 3.0 (4) | +1.2 |
| 4 | 7 | +1 Health / turn | 7.5 | 9 | 10 | 10 | 8.1 / 2.7 (4) | +0.5 |
| 4 | 7 | +1/+1 / turn | 5 | 9 | 10 | 10 | 9 / 2.7 (4) | +2.2 |
| 4 | 7 | combat +1/+1, 1/fight | 5 | 10 | 12 | 13 | 9 / 2.7 (4) | −1.6 |
| 5 | 9 | +1 Health / turn | 9 | 11 | 13 | 14 | 5.7 / 2.7 (5) | −0.5 |
| 5 | 9 | +1/+1 / turn | 6 | 11 | 13 | 14 | 6.4 / 2.7 (5) | −1.0 |
| 5 | 9 | combat +1/+1, 1/fight | 6 | 12 | 15 | never | 6.4 / 2.7 (5) | −3.2 |
| 6 | 9 | +1/+1 / turn | 8 | 11 | 13 | 14 | 6.4 / 6.4 (5) | −1.7 |

"+2/+2 a turn" floors at Tiers 1–5 (raw body −3 to 0). Its HP lead by turn 12 is +57, +47, +27, +9 and +0.5 at Tiers 1–5. It is over budget at any body below tier 5.

**Answer:** under the method's pricing, a scaling unit catches up 1–3 fights after purchase and is ahead in total after 2–6 fights. The method's formula fixes this by construction (section 4.1). What changes by tier is whether there are enough fights left to profit:

- **Tiers 1–3, bought early: the method under-prices scaling.** The cards are kept 10–15 fights, not 3–4, and end well ahead.
- **Tier 4: about fair.**
- **Tiers 5–6, bought on turn 9: the method over-prices scaling.** The cards cross over on turn 13–15 and are still behind by turn 12.

### 1.3 What economy level changes

Turn each tier is reached ([tier_reach.csv](../research/budget-model/tier_reach.csv)). The HSBG no-econ row reproduces Battlegrounds' standard curve: tier 2 on turn 2, then 4, 6, 8 and 10.

| Rules | Econ level | Tier 2 | 3 | 4 | 5 | 6 | Board SP turn 8 / 12 |
|---|---|---|---|---|---|---|---|
| Bramble | no econ | 2 | 4 | 6 | 8 | 10 | 68 / 106 |
| Bramble | standard (+1 every other turn) | 2 | 4 | 6 | 8 | 9 | 66 / 118 |
| Bramble | econ-heavy (+1 from turn 3, +2 from turn 5) | 2 | 4 | 5 | 7 | 8 | 75 / 134 |
| Bramble | high-roll (+2, +3, +4) | 2 | 3 | 5 | 6 | 7 | 101 / 149 |
| HSBG | no econ | 2 | 4 | 6 | 8 | 10 | 65 / 114 |
| HSBG | high-roll | 2 | 4 | 5 | 7 | 8 | 86 / 152 |

- **Economy moves the tier clock, not the crossover.** Each econ level reaches tier 6 one turn sooner than the one below it. Crossover turns for a given card don't change (table 1.1).
- **More econ makes scaling a little worse.** The plain alternative gets better faster, so the scaling card's lead shrinks by 15–25% (table 1.1). Cards bought late are replaced sooner at high-roll ([hold_time.csv](../research/budget-model/hold_time.csv)): a tier-4 +1 Health unit bought on turn 7 is kept 1.1 fights at high-roll against 8.1 at standard.
- **Carry-over accelerates high econ.** With the same extra gold, Bramble reaches tier 6 on turn 7 at high-roll, against turn 8 in HSBG.

### 1.4 Economy cards

Body at which an economy card breaks even with a plain unit in expected HP by turn 12, standard econ ([econ_break_even.csv](../research/budget-model/econ_break_even.csv)):

| Card | Tier | Plain body | Method body | Break-even body | Implied economy charge (method: 0.5) |
|---|---|---|---|---|---|
| Battlecry: gain 1 gold | 1 | 5 | 3.6 | 2.8 | 0.79 |
| Battlecry: gain 1 gold | 2 | 7 | 5.1 | 2.2 | 1.25 |
| Start of turn: gain 1 gold | 1 | 5 | 0.9 (→ 1/1) | 2.6 | 0.29 |
| Start of turn: gain 1 gold | 2 | 7 | 1.2 (→ 1/1) | 3.0 | 0.35 |
| Start of turn: gain 1 gold | 3 | 8 | −0.8 (→ 1/1) | 4.1 | 0.22 |
| Start of turn: gain 1 gold | 4 | 10 | −1.0 (→ 1/1) | 7.5 | 0.11 |
| Start of turn: gain 2 gold | 4 | 10 | −12 (→ 1/1) | 4.4 | 0.13 |
| Start of turn: gain 2 gold | 5 | 12 | −21 (→ 1/1) | 8.7 | 0.05 |

**Answer:**

- **One-off gold early is priced about right, or slightly cheap.** It pays back by turn 6–9 ([econ_cards.csv](../research/budget-model/econ_cards.csv)). It is worth 2–5 SP of body.
- **Recurring gold is over-charged by the method, increasingly so with tier.** "+1 gold each turn" is worth about 2.5–4 SP of body at Tiers 1–3 and about 2.5 at Tier 4. The method charges 4–11 SP, which floors every card from Tier 3 up.
- **Why:** in the model, gold is worth most early (it buys tiers) and little late. Once the board is full of on-tier units and the player is at tier 6, extra gold only buys refreshes, and Bramble's escalating refresh price makes those cheap in value (section 6).

### 1.5 What this means

1. **Hold time decides the answer, and H(t) is wrong in both directions.** Plain units bought early are kept longer than H (4–6 fights at Tiers 1–2). Late units are kept shorter (2–3 at Tiers 3–5). Scaling units that grow at least as fast as the tier curve (about 1 SP a turn) are kept for the rest of the game. The method's 100% charge is correct only for the hold it assumes.
2. **Tempo is cheap.** Over the whole game, the hero-damage cost of a weaker board while a scaling unit catches up is a median of 2.0 HP, and at worst 8.9 HP for slow cards bought late (`tempo_cost_hp` in [scaling_grid.csv](../research/budget-model/scaling_grid.csv), method price, realistic hold). Battlegrounds' damage caps (5 on turns 1–3, 10 on turns 4–7) keep it small. The early rounds are where scaling is cheapest to buy.
3. **Rates need a per-tier cap, not just a price.** Above a certain growth per turn, even a 1/1 body is too strong (section 4.3).
4. **Economy is the reverse: under-valued by the formula when recurring, and worth most on turns 1–5.**

---

## 2. How the model works

A deterministic one-player game, turn by turn, under Bramble's rules ([rulebook.md](rulebook.md) chapter 4):

- **Gold:** income 3 to 10 per turn, carry-over with no cap and no interest, plus the econ level's extra gold.
- **Upgrading:** costs 5/7/8/11/11 with the 1-per-turn discount. The player upgrades when it can pay and either keeps 3 gold for a buy or has let the discount run 2 turns.
- **Buying:** units cost 3 and are worth V(tier). On a full board the player buys only if the new unit beats the weakest by 2 SP, and sells the weakest for 1.
- **Leftover gold:** banked until tier 6, then spent on refreshes at 1/2/3 gold (thresholds 10 and 20). Each refresh adds 1 permanent SP.
- **HSBG mode:** no carry-over (leftover gold is spent on 1-gold refreshes), for comparison.

**Two worlds.** The same game twice, once buying the plain card and once the test card on turn a. The per-fight difference in total board SP is the card's value, including the knock-on effects: earlier or later replacement, gold spent elsewhere.

**Three hold modes:**
- `card`: the card is never sold, to show its own curve.
- `fixed`: the card is sold after H(t) fights, as the method assumes.
- `endo`: the player's sell rule decides. The player values a scaling or economy unit at its value 2 turns ahead.

**Policy ensemble.** One greedy policy makes knife-edge decisions: one extra gold can move a whole upgrade. Every comparison is therefore averaged over 7 variants of the policy. The spread is in the `policy_spread_sp_t15` column. Crossover turns use the base policy only.

---

## 3. The hero-damage proxy (a proxy, not a measurement)

Expected HP from 1 SP in one fight = win-rate gain per SP × damage of a loss ([hp_weights.csv](../research/budget-model/hp_weights.csv)).

- **Win-rate gain per SP = 2.0 / board SP**, capped at 0.15. The toy combat sim measured 0.046 per SP on 42-SP boards and 0.028 on 74-SP boards ([power-analysis.md](../research/battlegrounds/power-analysis.md) section 7), which gives K = 1.9–2.1. **[data, extrapolated]**
- **Damage of a loss** = winner's tier + 2 surviving units × the average unit tier, capped at 5 (turns 1–3), 10 (4–7) and 15 (8+), as in rulebook 10.1. The 2 survivors are **[judgement]**.
- One card can move a fight's win rate by at most 0.5 **[judgement]**.

| Turn | 1 | 3 | 4 | 6 | 8 | 10 | 12 | 15 |
|---|---|---|---|---|---|---|---|---|
| HP per SP per fight | 0.45 | 0.53 | 0.67 | 0.40 | 0.38 | 0.32 | 0.25 | 0.20 |

**One SP on turns 3–4 is worth about 2–3× one SP on turns 12–15.** Small early boards make each stat matter more, and that outweighs the higher late damage caps. This is the one place the model favours immediate power.

Limits: there is no opponent model, losing by more isn't punished more, being low on health isn't worth more, and the damage cap is never removed at the top 4. HP totals above about 10 mean "this card decides games". Read them as rankings, not exact values.

---

## 4. Implications for the pricing rates

### 4.1 What the 100% rule does by construction

With body = V − r × s × (H+1)/2, the card's stat curve gives exactly ([closed_form.csv](../research/budget-model/closed_form.csv)):

- **catches up at fight r × (H+1)/2**
- **ahead in total at fight r × (H+1) − 1**

At r = 1 and H = 3, those are fights 2 and 3. The rule sets the crossover from H. **Charging scaling at 100% makes it exactly break even over H fights, so it is neither better nor worse than the plain unit if H is right.** It becomes strictly better for every fight the card is kept past H, and strictly worse if it is sold sooner.

To make a card cross over in total at fight k: **r = (k+1) / (H+1)**. With H = 3, crossover at fight 5 needs r = 1.5; at fight 7, r = 2.

### 4.2 Rate that breaks even by turn 12, with realistic holding

Standard econ ([break_even_rates.csv](../research/budget-model/break_even_rates.csv), `by_turn = 12`). ">4" means even a 1/1 body comes out ahead.

| Tier (turn bought) | +1 Health / turn | +1/+1 / turn | combat +1/+1 at 0.5 per fight | combat +1/+1 at 1 per fight |
|---|---|---|---|---|
| 1 (1) | >4 | >4 | >4 | >4 |
| 2 (2) | 1.76 | >4 | 1.26 | >4 |
| 3 (4) | 1.26 | >4 | 0.87 | 1.09 |
| 4 (6) | 1.12 | 1.24 | 0.70 | 0.83 |
| 5 (8) | 0.87 | 0.87 | 0.53 | 0.53 |

By turn 10 the rates are lower, and by turn 15 higher (same file). **No single rate works across tiers.** The fair rate falls with tier, because the card arrives later and has fewer fights to profit.

### 4.3 The largest growth a tier can carry

Largest SP per turn a 1/1 can gain and still only break even with a plain unit ([scaling_rate_caps.csv](../research/budget-model/scaling_rate_caps.csv), standard econ):

| Tier | Self-scaling, by turn 10 / 12 / 15 | Combat-triggered (1 per fight), by turn 10 / 12 / 15 |
|---|---|---|
| 1 | 0.79 / 0.78 / 0.76 | 1.0 / 1.0 / 0.9 |
| 2 | 1.4 / 1.3 / 1.2 | 1.9 / 1.7 / 1.4 |
| 3 | 1.9 / 1.7 / 1.5 | 2.6 / 2.2 / 1.7 |
| 4 | 3.2 / 2.5 / 2.0 | 5.1 / 3.6 / 2.5 |
| 5 | 5.8 / 3.8 / 2.7 | >8 / 6.2 / 3.5 |

**[judgement on the reading]** Unconditional "+1/+1 every turn" (2 SP) is over budget at Tiers 1–2 with any body. At Tier 3 it needs a 1/1. Such text either moves to Tier 3–4, or becomes conditional ("if you have a Fairy"), or capped ("up to 5 times").

### 4.4 A candidate fix: charge for the fights left, not H(t)

Replace H with **F = fights from purchase to a target turn** (for example turn 12) in s × (F+1)/2, at 100%. Test: [horizon_pricing_check.csv](../research/budget-model/horizon_pricing_check.csv).

- Where the body doesn't floor, the HP lead at the target turn is −0.3 to −4. That is slightly strict but closer to 0 than the H(t) rule, which ranges from −3 to +16 across the same cards.
- Where it floors, the text is over budget, which is the same answer as 4.3.
- The early-fight weighting (section 3) is why it comes out strict. A rate of about 0.8 on F would centre it **[judgement; not yet tested]**.

### 4.5 Economy rates

- **One-off gold:** the method's 50% charge is slightly light. Break-even implies 0.8 at Tier 1 and 1.25 at Tier 2. This is noisy (section 6).
- **Recurring gold:** the method charges H turns of gold at G(t) = V(t)/2 per gold. The model implies 0.05–0.35 of that, falling with tier. Two reasons:
  - **G(t) rises with tier, but measured gold value falls with turn.** See table 6.1.
  - **Recurring income is kept far longer than H.** Its value is spread over late turns, when gold is worth little.
- The v0 per-tier gold cap (1 gold per turn at Tiers 1–3) is not challenged by this model.

---

## 5. Hold time: placeholders against the model

Mean fights kept, standard econ ([hold_time.csv](../research/budget-model/hold_time.csv)). A value of 15 means "the rest of the game" (the horizon).

| Tier | Bought | H(t) | Plain unit | +1 Health / turn | +1/+1 / turn | combat +1/+1 at 1 per fight |
|---|---|---|---|---|---|---|
| 1 | 1 | 3 | 6.4 | 15 | 15 | 15 |
| 1 | 3 | 3 | 4.3 | 10.3 | 12.9 | 12.9 |
| 2 | 3 | 3 | 4.4 | 11.9 | 12.9 | 12.9 |
| 2 | 5 | 3 | 2.9 | 8.6 | 11.1 | 11.1 |
| 3 | 5 | 4 | 3.0 | 10.1 | 11 | 11 |
| 3 | 7 | 4 | 2.7 | 5.0 | 8.3 | 8.3 |
| 4 | 7 | 4 | 2.7 | 8.1 | 9 | 9 |
| 4 | 9 | 4 | 2.0 | 3.6 | 5.9 | 5.9 |
| 5 | 9 | 5 | 2.7 | 5.7 | 6.4 | 6.4 |
| 5 | 10 | 5 | 1.9 | 2.4 | 2.4 | 2.4 |

Reading:

- **H(t) rises with tier, but real holds fall with the turn bought.** Early units wait for the board to fill (turn 7 at standard). Late units are bought into a full board and replaced quickly.
- **Scaling units make their own hold time.** A unit that gains at least about 1 SP a turn keeps up with V(your tier), which rises about 1 SP a turn (5 → 14 over turns 1–9), so it is never the weakest unit and is never sold.
- **When a scaling card is worthless:** the `replaced_before_cross_*` columns flag cards that are sold before they cross over.
  - At standard econ: slow scaling bought late (+1 Health at tier 4 on turn 9; everything at tier 5 on turn 10), and combat-triggered growth at Tiers 5–6.
  - At high-roll: also tier-3 +1 Health on turn 5, and every tested text at tier 4 on turn 7 and tier 5 on turn 8.
  - **Buying slow scaling late is the trap. Buying it early is the opposite.**
- **Caveat:** the model has no triples, tribes or Discover. In real play those pull units off the board for reasons other than stats, so real holds are shorter. Measure H in the whole-game bot (power-budget.md section 8 step 5).

---

## 6. Gold, carry-over and HSBG's use-it-or-lose-it

### 6.1 What one gold is worth, by when it arrives

Cumulative board SP-fights to turn 15 from one extra gold ([gold_value.csv](../research/budget-model/gold_value.csv)). The method's G(t) × H(t) is shown for comparison: 7.5 at tier 1, rising to 35 at tier 6.

| Econ level | Bramble: turns 1–5 / 6–8 / 9+ | HSBG: turns 1–5 / 6–8 / 9+ |
|---|---|---|
| no econ | 9.5 / 11.7 / 5.0 | 13.4 / 9.0 / 3.5 |
| standard | 25.4 / 4.8 / 6.1 | 12.2 / 4.0 / 5.3 |
| econ-heavy | 6.4 / 7.2 / 0.6 | 16.0 / 9.9 / 7.8 |
| high-roll | 20.9 / 10.3 / 0.2 | 13.1 / 18.4 / 4.5 |

- **Gold is worth most on turns 1–5 and least from turn 9.** The method's G(t) assumes the opposite.
- **Value per gold is lumpy.** It depends on whether the gold completes a 3-gold buy or an upgrade, so single turns swing from about 0 to about 30.
- **At econ-heavy and high-roll, late Bramble gold is worth almost nothing (0.2–0.6).** The player is at tier 6 with a full board, and refreshes past the 10th cost 2.

### 6.2 Carry-over against no carry-over

Same economy card, Bramble rules against HSBG rules ([carry_over.csv](../research/budget-model/carry_over.csv)): the ratio of value has a **median of 0.94** (interquartile range 0.60–1.53, 64 cases).

- **Carry-over doesn't reliably make economy worth more in this model.** The v0 ×1.1 carry factor is inside the noise.
- **Gains:** no gold is wasted, and early gold banks into earlier tiers. That is the 25.4 against 12.2 at standard econ on turns 1–5.
- **Losses:** the escalating refresh price cuts the value of large late incomes, which HSBG spends on 1-gold refreshes.
- **[judgement]** The design question isn't the carry factor. It is **what late gold should buy in Bramble.** Without a late sink (spells, triples, upgrades), economy cards are early-game cards whatever they cost.

---

## 7. Sensitivity: which assumptions move the answers

Each assumption pushed low and high; the swing is the range of the result ([sensitivity.csv](../research/budget-model/sensitivity.csv)). Top entries per headline metric:

**Tier-2 +1/+1 per turn, bought turn 3, method price, standard econ: HP ahead by turn 10 (base 10.7)**

| Assumption (low / high) | Low | High | Swing |
|---|---|---|---|
| Scaling charge rate 0.5 / 1.5 | 17.3 | 7.5 | 9.8 |
| H(t) −1 / +1 (changes the price) | 14.0 | 7.5 | 6.5 |
| Lobby pace 0 / 2.5 SP per unit per turn | 10.7 | 4.7 | 6.1 |
| Win-rate slope K 1.5 / 2.5 | 8.1 | 13.4 | 5.4 |
| V(t) × 0.85 / × 1.15 | 13.3 | 9.0 | 4.3 |
| Survivors on a loss 1 / 3 | 7.8 | 11.8 | 4.0 |

Its crossover turn (base 5) moves only with the charge rate (3–6), H (4–6) and the leveling policy (5–6). The hold (12.9 fights) moves by at most 1 fight under any assumption.

**Tier-4 +2/+2 per turn at the tier-4 turn: HP ahead by turn 12 (base 9.4)**: leveling policy (2.5–11.5), V(t) scale (5.5–14.3), reference econ (9.4–16.7), keep look-ahead (3.7–9.4), charge rate (9.4–15.1), lobby pace (4.0–9.4).

**Tier-3 +1 gold per turn at the method price: HP ahead by turn 12 (base −5.6)**: reference econ (−16.7 at no econ, −12.5 at econ-heavy; base −5.6), keep look-ahead (−5.6 to +5.0), leveling policy (−11.0 to −2.1), lobby pace (−5.6 to +3.0), refresh value (−8.6 to −1.6).

**What matters most:**

1. **The charge rate and H.** These are the knobs being reviewed, so that is expected.
2. **Lobby pace: how fast everyone else's boards grow.** At 2.5 SP per unit per turn (turn-12 boards of about 270 SP, nearer modern HSBG), every scaling lead roughly halves ([pace_scenarios.csv](../research/budget-model/pace_scenarios.csv)). The lobby's growth is set by the content as a whole, so **this is a design target, not a fact to measure.**
3. **Player policy (when to level, when to sell).** It moves economy results more than any price does. Economy value depends on play skill, which the whole-game bot has to model.
4. **The HP proxy (K, survivors).** It moves the size of results by ±30%, not their sign.

The refresh value moves economy results only. The minimum gain for a replacement barely matters.

---

## 8. Real-card sanity check

Ten current HSBG pairs ([minions.json](../research/battlegrounds/data/minions.json), patch 37.0.0), at printed stats, standard econ, bought on the turn the tier opens, realistic holding ([real_cards.csv](../research/budget-model/real_cards.csv)). "Method body" is what the v0 rules would allow for that text.

| Tier | Scaling or economy card | vs immediate card | Method body / printed | Kept: card / partner | HP ahead by turn 10, printed-stats lobby / HSBG-like lobby | Community view |
|---|---|---|---|---|---|---|
| 1 | Lullabot 2/2, +1 Health end of turn | Scarlet Survivor 3/3 | 3 / 4 | 15 / 6.4 | +9.6 / +4.3 | Older +1/+1 version: "not as strong as it seems" ([Fantasywarden](https://fantasywarden.com/games/hearthstone-battlegrounds-mech-minions)) |
| 1 | Wrath Weaver 1/3, +2/+2 per Demon played | Scarlet Survivor 3/3 | −2.5 / 4 | 15 / 6.4 | +21.0 / +4.5 (after 7.5 self-damage) | Buffed in 36.0.3 (Jul 2026) to +2/+2 ([patch notes](https://hearthstone-decks.net/36-0-3-patch-notes/)) |
| 1 | Southsea Busker 3/1, 1 gold | Scarlet Survivor 3/3 | 3.6 / 4 | 6.9 / 6.4 | −0.0 / −3.8 | "Very niche" ([Fantasywarden](https://fantasywarden.com/games/hearthstone-battlegrounds-pirate-minions)) |
| 2 | Shell Collector 4/3 + Coin | Tarecgosa 4/4 | 5.1 / 7 | 4.7 / 4.7 | +7.8 / +4.4 | Earlier 1-drop version was a standard turn-1 economy buy (source not pinned) |
| 2 | Surfing Sylvar 1/2, +1 Attack to adjacent each turn | Tarecgosa 4/4 | 1.4 / 3 | 4.4 / 4.7 | +3.5 / +1.3 | "Not a very good minion" ([Fantasywarden](https://fantasywarden.com/games/hearthstone-battlegrounds-pirate-minions)) |
| 3 | Devout Hellcaller 4/4, +2/+2 per Demon hit (1.5 per fight assumed) | Greedy Conniver 7/7 | −7 / 8 | 11 / 11 | +19.4 / +8.3 | Buffed Sep 2026; Blizzard said self-damage Demons were underperforming ([wiki](https://hearthstone.wiki.gg/wiki/Battlegrounds/Devout_Hellcaller), [patch notes](https://hearthstone.blizzard.com/en-us/news/24296231/3642-patch-notes)) |
| 3 | Accord-o-Tron 3/3, +1 gold each turn | Greedy Conniver 7/7 | −0.8 / 6 | 11 / 11 | −4.9 / +1.9 (vs a plain 8-SP unit: +6.4 / +7.1) | Cut from Tier 4 5/5 to Tier 3 3/3 in Apr 2026 ([wiki](https://hearthstone.wiki.gg/wiki/Battlegrounds/Accord-o-Tron)) |
| 4 | Parasitic Fleshling 4/6, +2/+2 to left-most each turn | Zesty Shaker 6/7 | −8 / 10 | 9 / 8.3 | +9.6 / +4.2 | New Sep 2026, no data |
| 4 | Flaming Enforcer 4/5, eats the highest-Health shop unit | Zesty Shaker 6/7 | −7.5 / 9 | 9 / 8.3 | +20.2 / +10.3 | "Ramps up a lot", take it early ([Fantasywarden](https://fantasywarden.com/games/hearthstone-battlegrounds-strategy-guide)) |
| 4 | Gearfin 6/5, two 1-cost spells each turn (as 2 gold) | Zesty Shaker 6/7 | −12 / 11 | 9 / 8.3 | +4.2 / +2.2 | New Aug 2026, no data |

Where the community evidence is: a research pass found almost no tier-list, HSReplay or Reddit strength data for these cards. HSReplay returned 403, Reddit was blocked, and bgknowhow now redirects. Fantasywarden's dates and card versions look unreliable. The firmest signals are Blizzard's own changes.

**What the comparison says:**

- **Where it agrees:**
  - Flaming Enforcer is strong.
  - Southsea Busker is marginal.
  - Accord-o-Tron is clearly good against an on-curve body. That is consistent with Blizzard cutting it from a Tier 4 5/5.
  - Early economy pays: the 2020 HSReplay guide says extra early gold means more buys and faster levels ([HSReplay](https://articles.hsreplay.net/2020/04/15/battlegrounds-guide-april-2020/)).
  - Early losses are cheap because of the damage caps ([Blizzard](https://news.blizzard.com/en-us/article/24159389/9)).
- **Where it disagrees:** the model rates every self-scaler higher than players or Blizzard do (Lullabot, Wrath Weaver, Devout Hellcaller, Surfing Sylvar). Likely reasons:
  1. **HSBG's lobby is far faster than printed stats.** In an HSBG-like lobby the leads drop by half or more.
  2. **HSBG units leave the board for triples, tribes and Discover, which the model doesn't have.** The 2020 guide says to "keep scaling minions and triple them" but swap early non-scalers. The model reproduces the swap-out, not the triple pressure.
  3. **Tribe conditions.** Wrath Weaver and Devout Hellcaller need Demons. The model assumes half your buys qualify and 1.5 Demon hits per fight, both **[judgement]** and probably high.
  4. **Health-only growth is counted as full SP.** Lullabot's +1 Health is worth less than +1/+1, even though the toy sim values Health at 1 SP.
- **Lesson [judgement]:** in Battlegrounds scaling is kept in check by the speed of everything else. Bramble's strict pricing aims at a slower lobby, so scaling cards will matter *more* per card than in HSBG, and the per-tier caps (section 4.3) matter more too.

---

## 9. Every assumption, why, and what happens if it's wrong

| Assumption | Value | Tag | Why | If it's wrong |
|---|---|---|---|---|
| V(t) | 5/7/8/10/12/14 | method | power-budget.md section 2 | ±15% moves scaling leads by 15–50% (section 7). Crossovers don't move. |
| H(t) | 3/3/4/4/5/5 | method, judgement | power-budget.md 3.2 | Only enters through the price. The model measures hold separately (section 5). |
| Income, upgrade costs, discount, refresh 1/2/3 after 10/20, unit 3, sell 1 | rulebook | rule | rulebook chapter 4 | These are rules, not guesses. |
| Upgrade rule: keep 3 for a buy, or let the discount run 2 turns | 3, 2 | judgement | Reproduces the HSBG curve 2/4/6/8/10 under HSBG rules | Greedy or patient leveling moves economy results by up to ±9 HP (section 7). |
| Replace only if the new unit is 2 SP better | 2 | judgement | A swap costs 2 net gold | Barely matters (section 7). |
| Player values scaling and economy units 2 turns ahead | 2 | judgement | Players keep growing units | 0 turns sells economy cards quickly and makes them look better. It is the second-largest economy driver. |
| Refresh value | 1 SP per refresh | judgement | Better picks, triples and spells; HSBG spells give 4–6 SP per gold when offered | Matters for late gold only. 0 to 3 moves the tier-3 economy card by 7 HP. |
| Economy levels | +0.5, +1→+2, +2→+4 per turn | judgement | Spread from "nothing" to "economy hero" | The engines' own body cost isn't in the economy timeline, so high-roll is an upper bound. |
| Win-rate slope K | 2.0 / board SP | data, extrapolated | Toy sim at Tiers 2 and 5 | ±25% scales HP results by about ±25%. Signs don't change. |
| Survivors on a loss | 2 | judgement | HSBG damage formula | 1 to 3 moves results by about −25% / +10%. |
| Damage caps | 5 / 10 / 15 | rule | rulebook 10.1.4 | Cap removal at the top 4 isn't modelled, which under-values late SP. |
| Lobby pace | 0 SP per unit per turn | judgement | The printed-stats world the budget assumes | 2.5 (HSBG-like) halves scaling leads. **A design target.** |
| Horizon | turn 15 | judgement | Most decisive fights are by turns 12–16; no game-length data was found | Results "by turn 12" are the main ones quoted. |
| Recruit-trigger share | half your buys qualify | judgement | A committed tribe build | Halving it halves "after you play X" values. |
| Board, triples, tribes, opponents | not modelled | — | Out of scope for a budget model | The main reason holds are too long here (section 8). |

---

## 10. Decision points for the owner

1. **What turn should a fairly priced scaling card cross over?** The method's rule says fight H (3–5 fights after purchase) and assumes it is sold then. The alternative is a target turn: for example "a scaling card bought when its tier opens breaks even against a plain unit by turn 12" (sections 4.2 and 4.4). *My recommendation [judgement]: break even by turn 12, using the fights-left rule (4.4) at about 0.8 rather than H(t).*
2. **What economy level is the design target?** "Standard" (+0.5 gold a turn) is the reference here. High-roll reaches tier 6 on turn 7. Should content allow that, or should the per-tier gold cap stop it? (Tier reach, section 1.3.)
3. **What lobby pace is the target?** Is Bramble's turn-12 board about 120 SP (printed world) or 270 SP (HSBG-like)? This changes how strong every scaling card is, and it is set by how much scaling text the game prints overall. It needs a pace guardrail (power-budget.md section 8 step 7).
4. **Per-tier caps on growth rates?** For example: at most about 0.8 SP per turn at Tier 1, 1.3 at Tier 2, 1.7 at Tier 3, 2.5 at Tier 4 and 3.8 at Tier 5, unless the text is conditional or capped (section 4.3).
5. **Re-price recurring economy?** The model says the 50% charge over H turns is 1.5–10× too strict for "+1 gold each turn" and puts every such card at Tier 3+ on a 1/1. It also says one-off gold is about right. Change the economy rule to charge by turn of arrival (gold is worth most on turns 1–5), or keep it strict on purpose to suppress economy decks?
6. **What should late gold buy?** With escalating refreshes and no cap, gold after tier 6 is nearly worthless in the model. Either accept that economy is an early-game role, or design a late sink.
7. **Replace H(t) with measured holds.** Holds here run opposite to the placeholders (section 5). Should the whole-game bot (power-budget.md section 8 step 5) come next, so H, refresh value and lobby pace are measured rather than assumed?

---

## 11. Limits

- **One player, stat lumps.** No opponents' cards, triples, tribes, shop randomness, hand limit or spells as cards. The policy is scripted and averaged over 7 variants, not optimised.
- **The hero-damage weighting is a proxy** built from a toy sim's slope and the HSBG damage formula.
- **Results are knife-edge in places.** Economy cards especially swing with whether one gold completes a purchase. Check `policy_spread_sp_t15` before relying on a single economy cell.
- **Community evidence is thin.** See section 8.
