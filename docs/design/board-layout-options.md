# Board layout options: packing versus fixed slots

The owner asked for pros and cons of packing versus fixed slots on a 4–3 board ([owner note](owner-notes/2026-10-27c-packing-tokens-rows.md)).

> **Decision, 27 October 2026:** the owner chose **Option A, fixed slots**, for now. Units go in any slot, gaps are allowed, and nobody moves in combat. This can be revisited after prototyping.

## The 4–3 grid

A 4–3 cap gives a perfect brick:

```
 front   [F1]  [F2]  [F3]  [F4]
 back       [B1]  [B2]  [B3]
```

| Slot | In front of it | Behind it |
|---|---|---|
| F1, F4 | — | 1 back unit |
| F2, F3 | — | 2 back units |
| B1, B2, B3 | exactly 2 front units | — |

This works because the back row has one fewer slot than the front, so every back slot has two front neighbours. With 3–4 the brick inverts: B1 and B4 would each have only one unit in front of them.

**4–3 is the cleaner shape.**

## The decision is really two decisions

"Packing" bundles two separate questions:

1. **Placement during the recruit phase.** Can the player put a unit in any slot and leave gaps, or are units forced into the leftmost free slots of their row?
2. **What happens in combat when a unit dies.** Do the survivors slide left to close the gap (Battlegrounds), or does everyone stay in their slot?

That gives four combinations:

| | **Survivors stay put in combat** | **Survivors slide left in combat** |
|---|---|---|
| **Free placement, gaps allowed** | **A. Fixed slots.** Fully positional. | B. Odd: deliberate gaps vanish after the first death. |
| **Forced left-pack** | **C. Pack at setup, freeze in combat.** | **D. Battlegrounds-style packing everywhere.** |

B is not worth pursuing. A, C and D are the real candidates.

## Option A: fixed slots, no packing

The player places units in any of the 7 slots and gaps are allowed. Nothing moves in combat.

**Pros**
- Neighbours never change, so "in front of" and "behind" always mean the same units. This is the strongest support for the position-based design the two rows exist for.
- "When the unit in front of this dies" works as written: the slot is now empty and nothing slides in.
- Summoned units have a natural home: the slot of the unit that died.
- Leaving a gap is a real decision. For example, a front unit with no one behind it can't trigger "behind" effects but also exposes nothing.
- Slots can carry modifiers later, such as zone terrain or anomalies that change one slot. This fits the "rule modifiers" architecture.

**Cons**
- More decisions each turn: slower, and fiddlier on mobile.
- It's a bigger departure from Battlegrounds for players arriving from it.
- Summon placement needs rules: which slot, and what if it's full.
- Bad placements are easy for new players, for example a strong unit with nothing in front of it.

## Option C: pack at setup, freeze in combat

Units always fill each row from the left during the recruit phase, so placement is simply "which row and what order". In combat nobody moves.

**Pros**
- Setup is as simple as Battlegrounds: pick a row, drag to reorder.
- Neighbours are stable for the whole fight, so position text stays readable.
- Partly filled boards always look the same. Three front units always sit in F1–F3.

**Cons**
- Board shape is fixed by unit count, so the player can't create deliberate gaps.
- Left-packing makes the left side matter more than the right. With 2 front and 3 back units, B3 has no units in front of it.
- Summons still need a rule. Deaths leave gaps, so either summons fill the dead unit's slot or the board becomes uneven.

## Option D: Battlegrounds-style packing everywhere

Units pack left at setup, and survivors slide left whenever a unit dies.

**Pros**
- Most familiar to Battlegrounds players. The board always looks full.

**Cons**
- Neighbours change every time anything dies or is summoned. "The unit behind this" can mean three different units in one fight, which undercuts the main reason for the two rows.
- Mid-combat re-packing across two staggered rows is hard to show clearly in animation. The shuffling would also make replays harder to follow.
- Death triggers get ambiguous: after the unit in front dies and its neighbours slide, who counts as "in front" now?

## Problems every option has to solve

- **One front unit guarding a full back row.** Back units can't be targeted while any front unit lives. With 1–3, a single tough front unit protects three back units. That could be a fun "fortress" build, or a degenerate one. It can be tuned with a minimum front count, splash or overkill keywords, or back-row-targeting effects.
- **Summon placement on a full row.** Does an overflow go to the other row, or fail as in Battlegrounds?
- **"Leftmost" and "rightmost".** On a gapped board these need a definition: the first and last occupied slots.
- **Attack order with gaps.** Skip empty slots. This is easy, but it should be stated.

## Recommendation

**Prototype A and C side by side and drop D.** D works against the reason the board has two rows.

C is the safe default and close to the owner's first instinct ("units pack"). A is the bolder option and probably the better home for position-based cards.

In a headless simulation, run the same 20–30 position-based test cards under both rules and compare:

- how often each card's text actually triggers;
- how often a player's placement choice changes the result;
- how many decisions a turn takes.

The owner believes Galaxy lets units sit unpacked. The Galaxy research in progress will confirm its exact rules, and they should be weighed here when it lands.
