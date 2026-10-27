# Direction summary

A summary of the owner's direction, written to plan from. The full records are in [owner-notes/](owner-notes/):

- [2026-10-27-battlegrounds-direction.md](owner-notes/2026-10-27-battlegrounds-direction.md): the direction
- [2026-10-27b-board-answers-and-research.md](owner-notes/2026-10-27b-board-answers-and-research.md): answers and research asks
- [2026-10-27c-packing-tokens-rows.md](owner-notes/2026-10-27c-packing-tokens-rows.md): packing, token selling and row caps

If this summary and a record disagree, the record wins.

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
- Bought units sell for 1 gold. Created units (tokens, anything summoned or generated) sell for 0. A tripled unit sells for gold even if its copies were created. Token rules may be expanded later.
- Rerolls cost 1, then 2, then 3 after set numbers of rerolls in a turn. The count resets each turn. The first threshold is roughly 10; all thresholds must be easy to tune. The goal is to cap infinite-generation loops while still allowing big economy turns.

**Board and combat**
- 7 units in total, across two rows. Working cap: 4 front, 3 back, which gives a perfect brick (see [board-layout-options.md](board-layout-options.md)).
- The rows are staggered by half a slot, like bricks. Each back-row slot sits in the gap between two front-row slots.
- **"In front of" and "behind"** mean a unit's diagonal neighbours in the other row. A unit has at most two units in front of it and at most two behind it.
- **Fixed slots (Option A, chosen 27 Oct for now).** Units go in any of the 7 slots, gaps are allowed, and nobody moves when units die. See [board-layout-options.md](board-layout-options.md).
- **Targeting:** back-row units can't be attacked while any front-row unit is alive. Keywords may break this rule, e.g. overkill damage that splashes through, or attacks that target the back row.
- **Attack order:** front row left to right, then back row left to right, then repeat. Rows only set the order and default targeting. If the front row is empty, the units that remain simply carry on.
- Each unit attacks once per cycle, unless a Windfury-style keyword lets it attack more.

**Design space**
- Position-based text beyond Battlegrounds' leftmost/rightmost: "units behind this", "units in front of this gain X when…", "when the unit in front of this dies…".
- Survey keywords from Battlegrounds, Once Upon a Galaxy and other games for abilities to adopt.

**Roster and setting**
- Fewer woodland species than the folio explores.
- Add magical creatures that unlock mechanics animals can't: fairies, and oozes with ludicrous high-pitched voices (in the spirit of Viscous from Deadlock), possibly with an amalgamation mechanic.

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
- Reroll thresholds and escalation steps.
- Engine and language.

## Open questions

Fixed slots need a few rules. Each question has a proposed default for the owner to accept or change.

1. **Summon placement.** Proposed: a unit summoned by a dying unit takes its slot. Otherwise it goes to the empty slot nearest the source, in the same row first, then the other row. If there's no room, it fails, as in Battlegrounds.
2. **Leftmost and rightmost.** Proposed: the first and last occupied slots, read across the front row and then the back row.
3. **Attack order with gaps.** Proposed: empty slots are skipped.
4. **One front unit guarding a full back row (1–3).** Allow it and watch it in testing, or set a minimum front count?
5. **Buying with no free slot.** Proposed: blocked once 7 units are on the board, as in Battlegrounds. Bought units go into the first empty slot, and the player moves them afterwards.

## In progress

Research agents are writing into `docs/research/`:

- a Battlegrounds rules reference, patch history and keyword glossary with two-row notes;
- a Battlegrounds card data library;
- a Once Upon a Galaxy rules reference, patch history, card library and design notes.

Power budgeting and the first Bramble rulebook draft come next.
