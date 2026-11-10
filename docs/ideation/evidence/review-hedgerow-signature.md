## Signature check: Hedgerow, pass 3 (A2 deciding criterion 1)

*[Saved verbatim from the fresh signature reviewer's hand-back, 10 Nov (workflow wf_ba56a210-573), checked against `docs/research/battlegrounds/`. Calls: DECISIONS (ideation/main) "Hedgerow light pass (A2): review calls".]*

Signature: yes. Re-skin: no.

**1. Verdict.** Yes: the Long Sleep, "every 3 turns in this slot". Dozey doubles permanently, and the Sleeping Partner pays Acorns, only while you leave them where they are. Moving resets the clock. Battlegrounds has timers (Starry-eyed Explorer, Lockboxes) and doubling (Corrupted Myrmidon, fight-only), but no permanent clock tied to a slot. The Standing Committee, which pays the Line by its weakest member, is a second new mechanic. It carries the Parish line, which skips Dozey.

**2. Re-skin test.** No Battlegrounds player would call this Quilboar. Quilboar makes free stat cards, raises their size for the game and spreads them wide. Hedgerow's held cards are gold, and its question is cash, hold or feed. The one real Quilboar echo is feeding Dozey, which is a Blood Gem on one unit.

| Mechanic | Closest Battlegrounds analogue | New or borrowed |
|---|---|---|
| Acorns, Stashes, Great Hoards | Tavern Coin | New: three combine into a bigger item (3 gold becomes 5, 15 becomes 16), so holding pays |
| The Larder (Treasurer, Mast) | Tavern Tipper, Time Saver (small rewards for unspent gold) | New to Battlegrounds. Mast's 20% is TFT's interest |
| Feeding Dozey | Blood Gems, Bristleback Brute | Borrowed |
| Dozey's sleeping clock | Corrupted Myrmidon, Starry-eyed Explorer ("every two turns") | New: permanent, tied to the slot, reset by moving |
| Gapless Line, Committee | Adjacency (Dire Wolf Alpha, Bannerboar) | New: a run through the board, paid by its smallest member |
| Mrs Mallow | Doubling (Myrmidon, Stone Age Slab) | The target is new, the verb familiar |
| Pass to last | Left- and right-most buffs (Majordomo Executus, Brazen Buccaneer, Gentle Stag) | Borrowed, and a game-wide rule (12.1.6) |
| Urchin's Hunker on last | Lightfeather Screecher | Borrowed pattern |
| Hayward | "This game" counters (Undead, Blood Gem size) | Borrowed. Paying per gold is the twist |

The design calls Mallow "a cousin of Battlegrounds' 'your lowest-stat minion' buffs". `minions.csv` has no such buff. Its "lowest" cards aim at enemies (Merciless Mammoth, Zapp Slywick).

Two cautions, both inside Bramble:
- **Timed doubling isn't Hedgerow's alone.** Fairy Monarch has "Every 2nd End of Turn: double your Ring size". Bog's Prince has "Every third kiss: double the Bog folk beside this", and Warty Nan reads "your smallest Bog folk". What stays Hedgerow's own is "in this slot".
- **Shipped text differs from the design doc** on rates: Dozey +2/+2 per gold (not +1/+1 per 2), the Partner two Acorns per unit, Mallow two smallest, the Committee a quarter, Beadle +2/+2. That's the B preset (rulebook 12.1.10). It doesn't change the signature.

**3. Economy.** Yes, tied to the tribe.
- **Sources:** the Partner counts only Hedgerow units touching it: 2 Acorns on another tribe's board, up to 14 on a full Line. Burdock and Sorrel Spill, so a summon with no room becomes an Acorn. Mast pays interest.
- **Hedgerow sinks:** Dozey eats it, the Treasurer grows on it, Hayward turns it into a tribe bonus, and the Sergeant throws it as an answer.
- **Weak spot:** an Acorn is plain gold. The Parish cashes everything and never faces the hoard decision.

**4. Example** (shipped text at 424b3c2a).
- **Alderman Dozey** (T4, 3/6): "Larder items played on this: +2/+2 per gold. Every 3 turns in this slot: double its stats." He wakes after your other End of Turn effects.
- **Dr Urchin** (T3, 2/5): "Bristle 2. Your last other Hedgerow unit has Hunker."
- **Acorn:** "Play for 1 gold. Three combine into a Stash." **Stash:** "Play for 5 gold. Three combine into a Great Hoard."
- **Sergeant-at-Conkers** (T3, 3/3): "Start of Combat: throw your smallest Larder item across. That enemy loses a tenth of its stats per gold."

**R9.** Dozey has sat in B3 since R7 and is 22/26. F4 is empty, so he's your last unit and has Urchin's Hunker. This is his third End of Turn there. You hold a Stash and two Acorns (7 gold) and have 9 income.
- **Cash it** (the Battlegrounds habit): 16 gold, two more buys. Dozey wakes to 44/52.
- **Feed it:** +14/+14 makes him 36/40, then the wake makes him 72/80. Seven gold became +28/+28. It doubles again at R12 and R15 if he stays put: +112/+112 by R15.
- **The fight:** the scout shows a 55/60 carry. If Dozey attacks, the fed one kills it and lives on 25 Health. If it attacks him, Hunker halves the 55, so he lives on 53 and kills it. The cashed Dozey dies attacking it and leaves it on 16, or at best trades with it.
- **R10:** the next scout shows their Sergeant across B3 with a Stash, which would halve him. R10 is the turn right after a wake, so moving him to F4 is free. Wait until R11 and the move pushes his wake to R13, so he fights R12 at half size.

Where to stand, and when you may move, has no Battlegrounds counterpart. It decides the fight, not just the stat total.

**5. Change.** None needed. To protect the signature, the cross-tribe check should keep "in this slot" for Hedgerow only, and give Fairy Monarch and Bog's Prince another clock or verb. The design doc already asks this of the Fairies.