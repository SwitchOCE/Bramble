# Which breaker method finds multi-piece engines? (11 Nov 2026)

Owner's idea: ask the breaker "what pieces would make this card break?" and have it look for them, instead of judging the card and listing obvious combos. Tested on 9 Battlegrounds cards with known answers, three methods × two models, one run each.

**Clean data (after the owner caught a leak).** A first round gave agents the full card library with first/last-seen dates, which let them infer a card was pulled fast; it was stopped. The clean round gave each card a snapshot of the pool at its date (minions, heroes and hero powers, buddies, tavern spells, trinkets and anomalies where they existed), with no dates, no patch notes, no repo and no web. Limits: other cards carry their latest wording; models may remember history from training.

Cards. Known broken (owner's memory and Blizzard's actions): Arcane Behemoth, Banana Slamma (2023 "double its stats"), Tidemistress Athissa (2022, with Stormscale Siren), Chronormu, Shadowy Construct (Teron's buddy, June 2024: "Deathrattle: give this minion's maximum stats to another friendly minion"; with Archlich Kel'Thuzad, Drakkari, Titus), Nathanos Blightcaller (Sylvanas's buddy, March 2023). Controls: Stone Age Slab, Flaming Enforcer, Brann.

Methods. A: judge on best play and list combos. B: work backwards (name the pieces that would break it, search the snapshot for them by mechanic, then judge). C: B plus a turn-by-turn best-case game.

B = called BROKEN; ~ = found the runaway engine but called it power fantasy; - = missed.

| | Behemoth | Slamma | Athissa | Chronormu | Construct | Nathanos | Controls wrongly BROKEN |
|---|---|---|---|---|---|---|---|
| Fable A | - | - | - | B | ~ (Kel'Thuzad, linear) | ~ | Slab only under one anomaly |
| **Fable B** | - | **B** | - | **B** | ~ (full loop, ×1.7/turn) | **B** | Slab "narrow" (Jandice re-buy) |
| Fable C | - | - | - | ~ | ~ (full loop) | ~ | Slab via Jandice or Bribe |
| Sonnet A | - | - | - | - | - (found Kel'Thuzad, called it fine) | - | Enforcer |
| Sonnet B | - | - | - | - | - | B | none |
| Sonnet C | - | B | - | - | - | B | Enforcer |

Findings:
1. **The model matters more than the method.** Fable found the Kel'Thuzad engine in every method; Sonnet in one, and judged it fine. Sonnet twice called a control broken.
2. **Working backwards (B) is the best method on Fable:** 3 of 6 called broken, Shadowy Construct's self-feeding loop found, no plain control wrongly broken.
3. **The verdict is the weak step.** Fable C found the Construct, Nathanos and Chronormu loops and still called them power fantasy: the turn-by-turn estimate made slow exponentials (×1.5 to ×1.7 a turn) look modest. A loop the breaker has found should be judged by the hard rule, not by the breaker's feel.
4. **Nobody found Behemoth's copy loop** (Discover copies, make one Golden, sell Behemoths into each other). Athissa was judged linear by all; its real problem was pace, not a loop.
5. **Stone Age Slab with a re-buy** (Jandice's swap, Anomalous Bribe) came up in three Fable runs. Unverified; may be a real exploit rather than a false alarm.

One run per cell, so treat single cells as noisy.
