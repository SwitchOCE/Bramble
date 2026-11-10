# Review queue

Decisions waiting on the owner, most important first. Each item points to where the full reasoning lives. Answer by number. Answers get recorded as owner notes, and the rulebook is updated to match.

Sources:
- [rulebook-deltas.md](rulebook-deltas.md): all 45 remaining proposed defaults and 6 open rules
- [power-budget.md](power-budget.md): the costing method and its open questions
- [board-layout-options.md](board-layout-options.md): the fixed-slots decision

## 1. Combat shape: answered 27 Oct

All seven are decided; see [the owner note](owner-notes/archive/2026-10-27d-combat-shape-decisions.md). The rulebook is updated to match.

- Attack order stays front then back.
- Random effects can hit either row.
- Summon timing and placement follow the proposed rules.
- Leftmost and rightmost are per row.
- Combat buffs end with the fight.
- Taunt works within the row that can be attacked.

## 2. Economy: answered 27 Oct

All four are decided; see [the owner note](owner-notes/archive/2026-10-27e-economy-decisions.md).

- Units drawn from the pool by effects sell for 0.
- Refresh thresholds are 1–10, 11–20 and 21+.
- Free refreshes don't count toward the thresholds.
- Economy and scaling text is priced in the budget, more strictly than in Battlegrounds.

The free-refresh safety cap was declined: loops are prevented by content design instead ([content-guardrails.md](content-guardrails.md) G1).

## 3. Power budget: answered 27 Oct

See [the owner note](owner-notes/archive/2026-10-27f-power-budget-decisions.md).

- Plain units sit on budget.
- Golden doubles effect numbers; thresholds stay the same.
- Tolerance is ±15%.

**In-depth review: ready.** [power-budget-review.md](power-budget-review.md) answers how many turns a scaling card takes to catch up, and at which economy level. Its decision points:

- **B1. Break-even turn.** By which turn should a fairly priced scaling card break even? Suggested: turn 12, with scaling charged for the fights left in the game, not for hold time.
- **B2. Design-target economy level:** no econ, standard, econ-heavy or high-roll?
- **B3. Target lobby pace.** A lobby as fast as Battlegrounds halves every scaling lead.
- **B4. Growth cap per tier?** Suggested about 0.8 / 1.3 / 1.7 / 2.5 / 3.8 stat points a turn at Tiers 1–5.
- **B5. Re-price recurring economy?** The current rule over-charges recurring gold by about 1.5–10×.
- **B6. What should late-game gold buy?** In the model, gold is worth almost nothing late.
- **B7. Build the whole-game bot next,** to measure real hold times?

## 4. The rest

16. The other ~45 proposed defaults in [rulebook-deltas.md](rulebook-deltas.md) are mostly edge cases with sensible defaults: start and end-of-turn order, pool returns, triples with a full hand, and so on. Skim them and flag any you disagree with. Unflagged ones count as accepted.
17. **The hand.** The rulebook keeps Battlegrounds' hand: bought units go to the hand, not straight onto the board. (rulebook 7.2)

## 5. Design philosophy

18. **Bridge pieces vs tribe-locked payoffs** (from `bramble-design-guidance.md`, 10 Nov). The game-design skill's Players check asks what a piece does outside its home tribe. The docs partly answer it: "Early units should be somewhat flexible as well as enabling" (09f), and "Tribe-only payoffs carry the tribe word, so others can't splash them" (`fundamentals.md`). Read together, early units are flexible bridges and payoffs stay tribe-locked. Is that right? *Ideation works to that reading until the owner answers (DECISIONS, 10 Nov).*
