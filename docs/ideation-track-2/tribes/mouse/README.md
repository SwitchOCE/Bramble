# Mice — the Kin

The family passes Attack to the nearest surviving Mouse. The needle line grows through counted pile-ons. Gnaw is reserved for later.

| Tier | Card | Attack/Health | Text |
|---|---|---|---|
| Token | Cousin | 2/2 | Hand-me-down. |
| 1 | Needle Page | 4/3 | Pile on 1. |
| 1 | Hedgerow Scout | 3/4 | Hand-me-down. |
| 2 | Harvest Piper | 3/3 | Recruit: Give your other Mice +2 Attack. |
| 2 | Hayloft Aunt | 2/4 | Hand-me-down.<br>Recruit: Add a Cousin to your hand. |
| 2 | Shrew Cutpurse | 2/4 | Pile on 1.<br>After this piles on, gain 1 gold. |
| 3 | Thimble Captain | 3/6 | Charge 2: Whenever a neighbour attacks, summon a Cousin. |
| 3 | Fencing Master | 4/5 | Pile on 2.<br>After this piles on, it gains +2 Attack permanently. |
| 3 | Bell-ringer | 3/5 | Hand-me-down.<br>Your Hand-me-downs give +3 more Attack. |
| 3 | Needle Sister | 4/4 | Charge 2: After this gains a Hand-me-down, it attacks immediately. |
| 4 | Dormouse Cook | 2/9 | At the end of your turn, give your other Mice +3 Attack. |
| 4 | Grandmother Hob | 3/8 | Charge 4: After one of your Mice gains a Hand-me-down, give it +4 Attack permanently. |
| 4 | Thimble Sentinel | 3/10 | Guard.<br>Hand-me-down. |
| 4 | Drill-sergeant | 4/8 | Your Mice neighbouring this have Pile on 1. |
| 5 | Parish Standard-bearer | 6/8 | Start of fight: Give your Mice +2 Attack this fight for each Mouse you have. |
| 5 | Widow Thimble | 5/10 | Your Hand-me-downs go to the 2 nearest Mice. |
| 5 | Dame Bodkin | 6/9 | Pile on 2.<br>Your Mice's pile-on hits deal double damage. |
| 6 | Needle Pikeman | 6/14 | Pile on 5.<br>Can't attack.<br>After this piles on, your Mice with Pile on gain +2 Attack permanently. |
| 6 | King Speck | 6/14 | Whenever this attacks, fill your empty slots with Cousins. |
| 6 | Old Mother Needle | 7/14 | Charge 3: Your Hand-me-downs are permanent. |

## The Kin’s Health exception

“I agree with all the designers' picks.” The owner’s answer to open question 4 of the Mouse pitch allows the Thimble Sentinel’s 3/10 Guard body. The Kin’s buffs and Hand-me-downs still give Attack only. The rule it bends is the owner’s, 16 Nov 2026: “I don't want them to scale HP, so they are weak, but it'd be good for the Mice as a tribe to have a lot of attack scaling” (`docs/ideation-track-2/HANDOVER.md`).

## Reading the pitch against the rulebook

The pitch’s turn-10 board prints Pile on 2 on a golden Needle Page. Rule 7.3.5a keeps its printed Pile on 1. The Drill-sergeant’s costing counts four neighbours, while the pitch’s text says “next to” (two in its row under 8.2.2). The balance orchestrator chose the costing: the card says “neighbouring” and reaches up to four (8.2.3). Proposal. Pile on itself still listens to all four neighbours under 8.2.3.

## Implementation proposals

- A golden Drill-sergeant grants Pile on 2. It reaches its neighbours (8.2.3), not only the units next to it in its row.
- A golden Widow chooses the three nearest Mice. Multiple Widows use the largest recipient count.
- A golden Dame Bodkin triples pile-on damage and keeps Pile on 2.
- One Old Mother charge covers all recipients of one Hand-me-down. Multiple Mothers spend one available charge between them, in reading order.
- All heirs receive the gift before reactions. Each heir resolves Grandmother Hob’s gains before Needle Sister attacks. Heirs resolve in nearest order.
