# Birds player check

A fresh player's check of `ideation/birds-pass1`, played with `tools/play` against the full-strength bot lobby. Learned from `PLAYTEST.md` and `play.sh help` only.

## Placings

| Game | Seed | Hero | Plan | Place |
|---|---|---|---|---|
| 1 | 101 | Pipkin | Birds | 3rd |
| 2 | 202 | Old Mother Mousewife | Birds | **1st** |
| 3 | 303 | Hob Mumblecrust | Birds | 8th |
| 4 | 404 | Old Mother Mousewife | Best cards (drifted into Birds) | 3rd |
| 5 | 505 | Little King Wren | Best cards (mixed) | 8th* |

\*Game 5's rounds 7–12 were played by a simple script (buy the biggest stats, tier up when affordable), so that placing says little. Game 1 lost one fight to my own input error (a wasted Beltane Bonfire), and in game 3 I made a real mistake: I borrowed gold in rounds 1–2.

## Rounds 1–6, buy by buy

**G1 (Birds).** R1: no Bird; bought Wick. R2: **One Swallow** + A Leg Up + Rainy Day. The Swallow's 1 gold back paid for both spells, so yes, worth it. R3: **Chiffchaff** (2/3 on play) over Nip and Pill Bug, then tiered; flew the Swallow. R4: **Mrs Jay** 3/3 + Crumb; flew Chiffchaff to fire its +1/+1 again. R5: **Mr Redbreast** + a second **Jay**; flying Jay gave an Acorn and a second Nest, making Redbreast 4/6. This was the first click. R6: replayed Chiffchaff (3/4), tiered, bought the third **Jay** for the triple. Birds best in 5 of 6 shops.

**G2 (Birds).** R1: **Chiffchaff**, the best R1 body. R2: **Mrs Dunnock** (2/3) + Leg Up; flew Chiffchaff beside Dunnock. R3: no Bird; replayed Chiffchaff (3/4), tiered. R4: **Redwing** + Sorrel. Redwing beside the Nest gives a full-stat Egg, and with Dunnock the Bird comes back next turn, so Chiffchaff gains +1/+1 every other turn for free. R5: no Bird; Chiffchaff 5/6. R6: no Bird; Harvest Supper on Birds + Lodger. Birds were worth it every time they appeared.

**G3 (Birds).** No Bird in the first **8 shops** (R1–R5, including refreshes). I filled with Burdock, Young Brock, Moss Ooze and Nip. R5: **Mrs Jay + Redwing** together, clearly better than Toll-Bard and Sable for this plan. R6: flew Jay; refreshes still showed no Bird.

**G4 (best cards).** R1: **Dunnock** (all three units were Birds). R2: **Chiffchaff** over Young Pretender: same stats, plus growth beside Dunnock. R3: no Bird; Warty Nan. R4: **Redbreast** (2/4, the best raw body) + Burdock. R5: no Bird; tiered. R6: **Old Tern + Tom Tit** over Cluricaun and Dishwater Nell. Birds on merit in 4 of 6 rounds.

**G5 (best cards).** R1–2: no Bird; Warty Nan, Pill Bug. R3: **Dunnock**, as the best body only; its text did nothing. R4: Turnip Scarecrow (it fits Wren) + **Redbreast** as a plain 2/4. R5: Hopkin + **Chiffchaff** (a fair pick, not a clear one). R6: Dr Urchin over **Tom Tit**: with one Egg, Tom Tit was just a 2/4.

## The owner's question

**"I can't see why you would play the early-game Birds over other cards."** Now I would, often. There are two reasons. First, the tier 1–2 Birds are simply the best bodies in their shops: Chiffchaff is 2/3 on play, Dunnock 2/3, Jay 3/3, Redbreast and Redwing 2/4, against 1/2s and 2/1s. Second, by round 4 or 5 they form small engines you can feel: Swallow's refund pays for a spell, Jay's flight feeds Redbreast a Nest and you an Acorn, and Chiffchaff beside Dunnock or Redwing grows for free. Without other Birds, Dunnock and Tom Tit are just stats.

**Does the journey hold?** Early holds, and late holds strongly: golden Jay, Stork, Goose and Whistlers, or Cuckoo + Redwing + Gabble Ratchet, won 4 of 6, 7 of 7 and 5 of 6 of my late fights. **The middle breaks.** In all three games where Birds got going (G1, G2, G4) I lost 4–6 fights in a row in rounds 7–12, from 40 to 4 health in G2. The payoffs (Cuckoo, Stork, Goose) need Birds to be away, and while they're away your board is made of Eggs at half stats. **Tier 3 is the one I'd skip:** Tom Tit was a weak buy every time, Old Tern is slow, and Jack Daw did nothing for me. Cuckoo (tier 4) was the card that turned the early growth into a win.

**Clarity.**
- **Fly South:** clear. The board marks a Bird "sell: flies south".
- **Eggs:** clear in the fight log.
- **Nests:** the board shows only `{Nest}`, not the Egg's stats, so I couldn't tell what would fight there without doing the sum. That a unit played onto a Nest keeps it, I found by accident.
- **The Cuckoo:** clear, and the strongest Bird I played.
- **Mrs Stork:** confusing once. A Bird must have missed a fight before Stork can bring it home. That's only in DETAILS, so in G1 a whole turn's spending did nothing and I couldn't see why.

## Three biggest problems

1. **The mid-game slump for Birds.** Every Bird plan that got going took a 4–6 loss streak in rounds 7–12 while the payoffs set up. Away Birds turn the board into half-stat Eggs exactly when damage starts to matter.
2. **Whether Birds show up at all.** In G3 the first Bird came in shop 9, and that game ended 8th. At the top, Old Tern's Discover twice offered only 2 cards because "the pool has no more eligible cards": with bots also drafting Birds, the tier 5–6 Bird pool runs dry.
3. **Rules you can't see on the card.** Stork's "must have missed a fight" is only in DETAILS. Empty Nests don't show their Egg's stats. Mr Crumb's Pass landed on itself whenever the zigzag broke. Nests also take board slots, which made placing new buys awkward in G1. (Tool, not game: shifting hand numbers caused two of my misplays.)
