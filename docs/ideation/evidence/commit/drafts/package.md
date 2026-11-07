# Candidate package, for costing

The orchestrator's pick from three drafts and two critics, before costing. Numbers are first guesses. "Was" is the text built today (`../cards-now.md`).

## Core: what makes committing pay

**1. Stand Behind Me.** Tier 3 spell, cost 2.
- Was: Aim at a front-row unit: the units behind it gain +1/+2.
- Now: Aim at a front-row unit: the units behind it gain +1/+1 permanently, or +2/+3 if they share its tribe.

**2. Bread from the Back.** Tier 2 spell, cost 2.
- Was: Aim at a back-row unit: the units in front of it gain +1/+1.
- Now: Aim at a back-row unit: the units in front of it gain +1/+1 permanently, or +2/+2 if they share its tribe.

**3. Harvest Supper.** Tier 5 spell, cost 4 → 3.
- Was: Give your units +1/+1. Give your smaller row another +1/+1.
- Now: Aim at a unit with a tribe: your units of that tribe gain +1/+1 permanently, including ones you get later.
- New rule (the only new mechanic): each player has a tribe bonus per tribe, shown on that tribe's icon. It applies to every unit of that tribe you have, wherever it is (board, hand, Belly, away), and to units you get later. Selling a unit doesn't take it away. A unit with two tribes gets both.

**4. Hiring Fair.** Tier 5 spell, cost 6.
- Was: Discover a tier 6 unit.
- Now: Discover a tier 6 unit. If 4 or more of your units share a tribe, one of the three is of that tribe.

**5. Tribes per lobby: 5** (was 6). About 20% more of your tribe per shop (measure section 8).

## Bounds on the neutral scalers

**6. Queen of Elfland.** Tier 6, 8/8.
- Was: ...Your other units split their stats evenly.
- Now: Every 3rd End of Turn: destroy the units behind this (or this, if none). Your other Fairies split their stats evenly.

**7. Charcoal Burner.** Tier 5, 5/7.
- Was: End of Turn: burn your gold above 5. Units behind this gain +1/+1 per 2 burned.
- Now: End of Turn: burn your gold above 5, up to 6. Units behind this gain +1/+1 per 2 burned. (Golden: +2/+2 per 2 burned.)

## One tier-6 reason per tribe (cards that were vanilla or weak)

**8. Fairy Monarch.** Tier 6, 6/8 vanilla → 5/7. Text: Rings under your Fairies give double their stats. Golden: triple.

**9. Elder Ooze.** Tier 6, 7/7 vanilla → 5/7, Belly 2. Text: Belly 2. Whenever a unit comes out of one of your Oozes, it gains +1/+1 this combat for each unit that has come out of your Oozes this fight. Golden: +2/+2 for each.

**10. Moss Ooze.** Tier 2, 3/4 vanilla → 2/4. Text: When a spell gives one of your Oozes stats, the units inside it gain them too. Golden: twice that.

**11. The Laird of the Sett.** Tier 6, 4/6.
- Was: ...Your Hunters with a quarry gain +1/+1 this fight.
- Now: At the bell, all your units with no quarry take the enemy across from them as quarry. After each Take this fight, your Hunters gain +1/+1 this combat. Golden: +2/+2.

**Hedgerow and Bog folk get no tier-6 change.** They are the two most-picked tribes and already have engines; the kin clause and the tribe bonus reach them.

## Birds

**12. The Egg (rule change).**
- Was: a Nest holds a 0/2 Egg in fights.
- Now: While a Bird is away, the Egg on its Nest fights with that Bird's Attack and Health, and no text.
- Fly South then costs the Bird's text and its slot's choices for two fights, not its body. Buffs on a Bird keep paying while it flies. With the tribe bonus, an away Bird keeps growing.

**13. The Seven Whistlers.** Tier 6, 3/3 → 4/6.
- Was: count different Birds on your board or away, not hand. At 7, all enemies lose 1/4 Attack and Health. Otherwise, only the enemy across does.
- Now: Start of Combat: each enemy across from one of your Birds or Eggs loses 1 Attack and 1 Health this combat for each Bird you have, on the board or away, up to 6. Golden: 2 and 2, up to 12.

**Optional 14. Homecoming.** A Bird coming home may be played onto its own Nest when a unit stands there; that unit goes to your hand.

## Not design: the bots

**15.** `strategy_fit` gives Oozes and Birds `power` and per-unit weights in line with Hedgerow and Fairies. Hard should value the kin clause, the tribe bonus and Hiring Fair's tribe option. Without this the bench re-measures the priors.

## Cut, with reasons

Every capstone from designer C (they punish tall boards instead of paying for commitment; heavy engine). The Hedgerow "run" and Bound-Beater (hidden zigzag geometry). "A unit on a Nest is a Bird" (breaks the type line). Ring doubling as a keyword rule (the Monarch does it as card text). Figgy Duff and Old Crane growth (hidden growth, giants). Reynard and Peg Powler as written (unreadable).
