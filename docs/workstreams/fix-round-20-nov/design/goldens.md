# Goldens for every card (proposal, not decided)

**For dev at 5d697e07** (origin/dev, PR #201): 100 units, tokens included (Badger 19, Locust 20, Mouse 20, Pigeon 21, Thorn 20). Text and golden text are as the game shows them, dumped from the game code in headless Godot (`ViewAdapter.printed_unit`). The rule is in `golden-rule.md`, and every card is in `goldens.json`.

**12 of 100 change.** The other 88 already double their cool part. Four Badger cards get a wording change only: "Grudge 2" (see start-of-turn.md).
- **Badgers, Locusts and Thorns** are the same on dev as on main, so their 11 changes stand.
- **Mice and Pigeons** were reworked on dev. Their goldens already follow this rule almost everywhere: Charge doubles when the effect has no number, and multipliers go up one step. One changes: Quartermaster.

## The changes

| Card | Golden now | Proposed | Cool part |
|---|---|---|---|
| Hedge Lancer (T3) | Fury 2; attacks immediately once | Fury 1; "attacks immediately, twice, and takes no damage" | The owner's example: the free attack |
| Tourney Champion (T5) | Fury 2; strikes the top attacker | Fury 1; strikes "the 2 enemies with the most Attack" | The free strike on the best enemy |
| The Oakfeller (T6) | Fury 6; one follow-up | Fury 3; "attacks twice more" after a kill | The kill chain |
| Herald of the Charge (T4) | stats only | "Your front-row units attack immediately" (4 units, not 2) | The charge |
| Greatsword Bearer (T4) | stats only | "Your front-row units have Overrun" | Giving Overrun |
| Husk Sentry (T1) | stats only | "Molt twice" | Coming back |
| Hawthorn Warden (T4) | stats only | "Root 2, twice each fight" | Coming back |
| The Old Hedge (T6) | stats only | "Root 1, twice each fight" for other Briars | Everything comes back |
| Old Mother Midden (T6) | +4/+4, three times | +2/+2, three times | The multiplier, not both |
| Elder Mother (T5) | 4 copies, +2/+2 each | 4 copies, +1/+1 each | The army, not both |
| Brood Mother (T3) | 2 Hoppers, +2/+2 | 1 Hopper, +2/+2 | The Hopper upgrade; fewer low-tier Hoppers, as the owner wants |
| Quartermaster (T4) | Reserve to 2 units; call 2 more | Reserve to 1 unit; call 2 more | Calling more reservists |

## Risky for balance (flagged in `why`)

- **High:** Wing Commander (kept; the owner said the card "has to go"), Air Marshal (kept; up to 6 immediate attacks), Tourney Champion, The Old Hedge.
- **Medium:** Hedge Lancer (about x3-4 the plain card, above the T3 golden ceiling of x2), Herald of the Charge, The Oakfeller, Needle Sister, Lieutenant, Orchard Stripper (kept; 10 to every enemy at T4), Sky-darkener with Mother of Thousands (Hopper counts), Old Brock (see old-brock.md).
- To check them, run each one on the fight engine at golden stats against a full mid board. Then compare it with its tier's golden ceiling: x2 at Tiers 1-3, x2-4 at Tiers 4-6.

## What the dev redo changed from the main-based draft

- **Main-only changes dropped:** Shrew Harrier, Kettle-drummer and Brigadier are gone on dev. Regimental Sergeant Major has no multiplier now, so its golden (4 to 8 Renown) is fine.
- **Flags dropped:** Ballista, Catapult and Master of Engines are gone on dev, so dev has no Hit cards left.
- **New on dev:** Quartermaster changes, and Air Marshal, Needle Sister and Lieutenant are flagged.
- **Drill Sergeant:** the game already shows its golden as "Pile on 2", which this rule agrees with. My earlier worry was wrong.
