# Direction summary

A summary of the owner's direction, written to plan from. It draws on these [owner notes](owner-notes/):

- [2026-10-27-battlegrounds-direction.md](sources/2026-10-27-battlegrounds-direction.md): the direction
- [2026-10-27b-board-answers-and-research.md](sources/2026-10-27b-board-answers-and-research.md): answers and research asks
- [2026-10-27c-packing-tokens-rows.md](sources/2026-10-27c-packing-tokens-rows.md): packing, token selling and row caps
- [2026-10-27d-combat-shape-decisions.md](sources/2026-10-27d-combat-shape-decisions.md): combat-shape decisions
- [2026-10-27e-economy-decisions.md](sources/2026-10-27e-economy-decisions.md): economy decisions
- [2026-10-27f-power-budget-decisions.md](sources/2026-10-27f-power-budget-decisions.md): power-budget decisions and the refresh cap

If this summary and the owner's words disagree, the owner's words win.

## The pitch in one line

A Hearthstone Battlegrounds-style auto-battler with some Once Upon a Galaxy influence, set in an idealized European woodland. The core change from Battlegrounds is a two-row staggered board that opens up position-based card design.

## Decided

**Base**
- Battlegrounds rules and systems are the baseline. Everything below is a stated difference from it.
- Unit tiers and pool mechanics follow Battlegrounds until there's a reason to change them.
- **The board is the fight's HP.** Fights are won by the units on the board; the player has no in-fight health. This is a deliberate break from the earlier Autobattler project. The owner wants the higher combat randomness and stakes of the Battlegrounds model.
- Units are cards with attack and health, plus a species/type line in the style of Magic: The Gathering creature types ("Owl Warrior", "Squirrel Archer").
- Tribes, with a subset of tribes in the pool each game.

**Economy**
- Unspent gold carries over between turns. No cap, no interest.
- Bought units sell for 1 gold. Created units (tokens, anything summoned or generated) sell for 0. A tripled unit sells for gold even if its copies were created. Units drawn from the pool by effects (Discover, Triple Reward) also sell for 0: anything not paid for sells for 0. Token rules may be expanded later.
- Rerolls cost 1, then 2, then 3 after set numbers of rerolls in a turn. The count resets each turn. Steps: refreshes 1–10 cost 1, 11–20 cost 2, 21+ cost 3, all tunable. Free refreshes from cards don't count toward the steps. The goal is to cap infinite-generation loops while still allowing big economy turns.

**Board and combat**
- 7 units in total, across two rows. Working cap: 4 front, 3 back, which gives a perfect brick (see [board-layout-options.md](board-layout-options.md)).
- The rows are staggered by half a slot, like bricks. Each back-row slot sits in the gap between two front-row slots.
- **"In front of" and "behind"** mean a unit's diagonal neighbours in the other row. A unit has at most two units in front of it and at most two behind it.
- **Fixed slots (Option A, chosen 27 Oct for now).** Units go in any of the 7 slots, gaps are allowed, and nobody moves when units die. See [board-layout-options.md](board-layout-options.md).
- **Targeting:** back-row units can't be attacked while any front-row unit is alive. Keywords may break this rule, e.g. overkill damage that splashes through, or attacks that target the back row.
- **Attack order:** front row left to right, then back row left to right, then repeat. Rows only set the order and default targeting. If the front row is empty, the units that remain simply carry on.
- Each unit attacks once per cycle, unless a Windfury-style keyword lets it attack more. The order was confirmed over an interleaved one, so the back row plays a reserve and support role.
- **Random effects ignore rows.** "A random enemy" can hit either row. Back-row protection and Taunt apply to attacks only.
- **Taunt works within the attackable row.** A back-row Taunt never pulls attacks off the front row, but protects the other back-row units once the back row can be attacked.
- **Summons:** a dying unit's first summon takes its slot; others go to the nearest empty slot. A unit summoned into the attacker's slot attacks next.
- **Leftmost and rightmost are per row.** Card text names the row.
- **Combat buffs end with the fight** unless the card says "permanently".

**Design space**
- Position-based text beyond Battlegrounds' leftmost/rightmost: "units behind this", "units in front of this gain X when…", "when the unit in front of this dies…".
- Survey keywords from Battlegrounds, Once Upon a Galaxy and other games for abilities to adopt.

**Roster and setting**
- Fewer woodland species than the folio explores.
- Add magical creatures that unlock mechanics animals can't: fairies, and oozes with ludicrous high-pitched voices (in the spirit of Viscous from Deadlock), possibly with an amalgamation mechanic.

**Pricing**
- Economy and scaling text is priced in the power budget, more strictly than in Battlegrounds, where under-priced scaling drove the power creep.
- Plain units sit on budget. Golden doubles effect numbers but keeps thresholds. A card within ±15% of its tier budget counts as on budget.
- The owner wants an in-depth review of the budget's assumptions before content: how many turns a scaling card takes to overtake an immediate-power card, at what level of economy.
- **Content safeguards over systems.** "Not every problem needs a system to prevent it." No refresh cap; repeatable free-refresh loops are prevented by content design ([content-guardrails.md](content-guardrails.md)).

**Process**
- **Fundamentals before content.** Detailed, bottom-up power budgeting comes before any content design. The owner sees the lack of it as a big issue in the earlier project.
- Close supervision from the start. The earlier project ran too unsupervised early on.
- A full rulebook will be written: Battlegrounds as the baseline, with Bramble's differences marked. The owner will mark further differences as problems come up.
- Deep research first: how Battlegrounds and Galaxy work and how they changed across patches, plus as complete a library of their card designs as possible, for power-budget reference.

**Engineering**
- Quality and adaptability over speed. Clear architecture and layer separation, solid documentation, fast content iteration.
- Flexible, performant building blocks. Example: one "pick N from a pool" function that takes the pool, its random-generation algorithm, inclusion and exclusion rules, and removals as parameters.
- Game-warping rule modifiers must be addable later without spaghetti. See [architecture-notes.md](architecture-notes.md).

## Undecided

- **Row caps.** The working assumption is 4–3, and experiments may change it.
- Which woodland species make the cut.
- Whether to add a TFT-style trait system (the owner is leaning no).
- Engine and language: no longer open. Decided 2 November 2026: Godot with GDScript, statically typed as strictly as possible ([research](../archive/engine-language.md)).

## Open questions

All open decisions are now in one place: [review-queue.md](review-queue.md). The rulebook's proposed defaults supersede the ones that used to be listed here.

## Foundations written

- [rulebook.md](rulebook.md): v0, 212 numbered rules, each tagged as Battlegrounds, Bramble, proposed or open. [rulebook-deltas.md](rulebook-deltas.md) lists every difference.
- [power-budget.md](power-budget.md): costing method v0, with worked examples and a validation plan.
- `docs/research/`: Battlegrounds and Once Upon a Galaxy rules, patch histories, card libraries and analysis.
