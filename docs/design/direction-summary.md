# Direction summary

A summary of the owner's notes from 27 October 2026, written to plan from. The full record is in [owner-notes/2026-10-27-battlegrounds-direction.md](owner-notes/2026-10-27-battlegrounds-direction.md). If this summary and the record disagree, the record wins.

## The pitch in one line

A Hearthstone Battlegrounds-style auto-battler with some Once Upon a Galaxy influence, set in an idealized European woodland. The core change from Battlegrounds is a two-row board that opens up position-based card design.

## Decided

**Base**
- Battlegrounds rules and systems are the baseline. Everything below is a stated difference from it.
- Units are cards with attack and health, plus a species/type line in the style of Magic: The Gathering creature types ("Owl Warrior", "Squirrel Archer").
- Tribes, with a subset of tribes in the pool each game to keep games varied.

**Economy**
- Unspent gold carries over between turns.
- Bought units sell for 1 gold. Created units (tokens, anything summoned or generated) sell for 0.
- Rerolls cost 1, then escalate to 2, then 3 after set numbers of rerolls. First guess for the first threshold is 10; all thresholds must be easy to tune. The goal is to cap infinite-generation loops while leaving room for big economy turns, through limits or diminishing returns.

**Board**
- Two rows instead of seven slots. The player chooses the split, e.g. 6+1, 3+4, 1+2.
- Row 1 attacks first and is attacked first. Once every row 1 unit has had its turn, row 2 attacks, left to right. Otherwise it is Battlegrounds' left-to-right order.
- The rows are offset: a back-row slot sits between two front-row slots, not directly behind one. The exact geometry still needs confirming (questions below).

**Design space**
- Position-based text beyond Battlegrounds' leftmost/rightmost: "units behind this", "units in front of this gain X when…", "when the unit in front of this dies…".
- Survey keywords from Battlegrounds, Once Upon a Galaxy and other games for abilities to adopt.

**Roster and setting**
- Fewer woodland species than the folio explores.
- Add magical creatures that unlock mechanics animals can't: fairies, and oozes with ludicrous high-pitched voices (in the spirit of Viscous from Deadlock), possibly with an amalgamation mechanic.

**Engineering**
- Quality and adaptability over speed. Clear architecture and layer separation, solid documentation, fast content iteration.
- Flexible, performant building blocks. Example: one "pick N from a pool" function that takes the pool, its random-generation algorithm, inclusion and exclusion rules, and removals as parameters.
- Game-warping rule modifiers (in the vein of anomalies, trinkets and quests) must be addable later without spaghetti. The owner asked for a recommendation on how; see [architecture-notes.md](architecture-notes.md).

## Undecided

- Which woodland species make the cut.
- Whether to add a TFT-style trait system. The owner is "not sold on that at all".
- Reroll thresholds and escalation steps.
- The board geometry details below.

## Questions for the owner

**Board geometry.** The owner invited questions on this one.

1. **Staggering.** Is the board staggered like bricks, so each back-row slot sits in the gap between two front-row slots? With 3 in front, would the back row then have 4 positions: the two outer edges and the two gaps?
2. **Board size.** Is the cap still 7 units in total, split however the player likes? Does either row have its own maximum?
3. **"Behind" and "in front of".** Does a back-row unit count as behind both front-row units it sits between? Does a front-row unit have up to two units behind it?
4. **Targeting.** Can row 2 units be attacked while any row 1 unit is alive, or only once row 1 is empty?
5. **Attack order.** Is the cycle row 1 left to right, then row 2 left to right, then back to row 1? What happens when a unit dies mid-cycle?

**Economy**

6. Does the reroll counter reset every turn, or count across the whole game?
7. Is carried-over gold capped, or does it earn interest?
8. Does a created unit sell for 0 even after it is tripled or otherwise upgraded?

## Suggested next steps

These are inputs for the owner's action plan, not the plan itself.

1. Answer the board questions, then draw the board as a one-page diagram.
2. Shortlist tribes: a few woodland species, plus fairies and oozes.
3. Run a keyword survey across Battlegrounds, Once Upon a Galaxy and others, tagged by which ones the two rows improve.
4. Write a short rules spec: turn structure, economy, combat, with the Battlegrounds deltas called out.
5. Choose the architecture approach and engine, using architecture-notes.md as the starting point.
