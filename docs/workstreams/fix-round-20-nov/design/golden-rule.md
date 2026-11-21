# The golden rule (proposal, not decided)

**For dev at 5d697e07** (origin/dev, PR #201).

Replaces rulebook 7.3.5 ("doubles every number, keeps thresholds", from the archived 27 Oct power budget). Dev also has a proposed 7.3.5a (golden and counts); this rule takes it in. The owner (20 Nov): "The cool part of the card needs to be the part that doubles ... They double the coolest effect on the card."

## The rule

1. A golden unit has double stats, and doubles its **signature**: the part a player buys it for.
2. If the signature is a number (damage, Renown, a buff, gold, Hoppers summoned), that number doubles.
3. If it is an action with no number (an attack, a Private stepping in, a return, a keyword it gives), the golden does it twice, or to twice as many units. On dev that often means doubling the Charge.
4. Only the signature doubles. A small side number may double too when it is cheap (a Fury 1), but never the number and how often it happens together. Doing both makes a golden worth about four copies (dev's 7.3.5a says the same).
5. A "twice" becomes "three times": multipliers and repeat counts go up by one step, not double.
6. Thresholds, costs, Supply and per-fight caps stay as printed. A card may break any of this for the rule of cool. Its golden text then says what it does.

## How it compares with Battlegrounds

Battlegrounds writes each golden by hand, and the cards don't agree with each other. That is the owner's point. From the card data in `docs/research/battlegrounds/data/minions.csv`:
- **Red Whelp:** its Start of Combat damage happens "twice" on the golden. The action is the cool part, so the action doubles.
- **Scallywag:** its Pirate "attacks immediately", and the golden does not attack twice; it summons a 2/2 instead. Battlegrounds shrank the free attack here. The owner wants the opposite for Hedge Lancer, so this rule follows the owner, not Scallywag.
- **Multipliers go up by one:** Brann, Baron Rivendare, Khadgar and Drakkari Enchanter go from twice to three times. That is line 5.
- **Breaking the pattern for the rule of cool:** Seabreaker Goliath goes from Windfury to Mega-Windfury (four attacks), but Crackling Cyclone and Zapp keep plain Windfury. Cave Hydra and Foe Reaper keep Cleave with only stats doubled. Wildfire Elemental and Rylak Metalhead go from one neighbour to both: twice as many units.

## Guardrails: where doubling the cool part breaks the game

These effects get a doubled count only with a flag, and never a doubled count and a doubled number together:

| Effect | Owner's rating | Golden here | Rough price |
|---|---|---|---|
| **Free attack** (Hedge Lancer, Tourney Champion) | free hit "capstone-level" | Twice; Fury not doubled; flagged | One free attack that kills is about 1 enemy body. Golden stats already make it twice as lethal, so twice the attacks lands about x3-4 for Lancer: above the T3 ceiling (x2). Tourney Champion, about x2-3, at the T5 top. |
| **Attacks immediately** (Wing Commander, Air Marshal, Needle Sister, Herald) | the start-of-combat attack the owner said "has to go" | Twice the Charge or twice the units; flagged | Normal attacks take damage back: about +0.5 body each for a lone unit. Air Marshal's golden makes up to 6, with Sortie and +8 Attack from Group Captain: far more. |
| **Cleave** | "incredibly good" | Never doubled (Flying Ace) | Not priced. No golden changes it. |
| **Hit-like damage** (Lieutenant: a row deals its Renown) | Hit is "unbelievably good" | Half becomes full; flagged | About one enemy hurt or killed for each unit in the row, before the fight. |
| **Returns** (Molt, Root) | — | Twice a fight; flagged on Old Hedge | One return is about one more body for that fight. The Old Hedge golden gives a whole board a second return, so its only brake is Compost. |
| **Number and count on one card** (Midden, Elder Mother, Brood Mother, Quartermaster) | — | One of the two kept | Doubling both made these about x3-4 the plain card. Each now lands at about x1.5-2. |

**How I priced it.** I priced it by hand, per the skill's Costing section: count enemy bodies removed, or friendly bodies added, against the tier's in-fight target. I also used the fight-engine calibration the Old Brock work already ran (`scratchpad/brock/calibration_results.json`). On an 8/20 test unit, Cleave measured about x1.1 of the unit's stats, and the Lancer's free attack about x1.15. That **fails the skill's own "check the check"**: the owner rates both far higher. The test unit's 8 Attack rarely kills a 10-12 Health target, and both effects scale with Attack, which goldens double. So I trust the by-hand numbers here and mark the risky goldens rather than price them precisely. To check them, run each flagged golden on the fight engine at golden stats, against a full mid board.

## Open points for the owner

- **Fury stays 1 on the free-attack goldens.** Hedge Lancer and Tourney Champion now go from Fury 2 to Fury 1. This is the "one thing doubles" line, and each extra attack triggers Fury anyway. A player may still read it as a loss. Keeping Fury 2 as well is the generous choice, at about x4-5 for Lancer.
- **Grudge as a numbered keyword** ("Grudge 1", "Grudge 2") makes the golden text short and fixes the golden reminder. It changes four cards' wording, including the plain cards.
