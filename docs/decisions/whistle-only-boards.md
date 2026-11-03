---
id: whistle-only-boards
group: plays
size: small
headline: When only whistling marmots are left, does the fight end?
source: proto/main:docs/prototype/OWNER-QUESTIONS.md#7
option: End the fight at once
option: Keep fighting until the attack limit
suggested: End the fight at once
---
One of the new units, the Marmot Lookout, never attacks. When its turn comes, it whistles a warning instead, and the strongest enemy's next attack does only half damage. That raises an odd case: what happens when the only units left can't attack?

In the playable game, whistling doesn't count as attacking. So when neither side has anything left that can attack (only marmots, or marmots facing units with 0 Attack), the fight ends straight away. It also means the Hazel Dormouse, which waits as long as a friend could attack for it, wakes up and fights when its only friends left are marmots.

The original prototype plan had it the other way round: whistles kept the fight going until the 200-attack limit. We followed the unit's own write-up in the mechanics library instead.

**What we need from you:** is ending the fight at once the right call?

**Why it matters:** it's an edge case, but it decides whether a fight can stall for a long time with nothing happening. How such a fight is scored is the next card.

We'd suggest keeping it: a fight where nobody can hurt anybody has nothing left to show.

## Detail

- **Whistle (mechanics library entry 10):** "This never attacks, even with 0 Attack. When its turn in the attack order comes, it whistles instead, and that uses its side's turn. A whistle warns of the highest-Attack enemy unit that isn't already warned of (ties at random): that unit's next attack deals half damage, rounded up … Whistles don't count as attacks for ending combat: a side whose only units have Whistle can't attack (9.9.1)."
- **As built:** two Whistle-only boards, or one facing only 0-Attack units, end the fight at once with reason `no_attacks`. A waiting Bide unit whose only non-waiting friends have Whistle wakes. While the fight goes on, each whistle still counts toward the 200-attack limit.
- **The spec's earlier wording:** "a whistle uses its side's turn and counts toward the 200-attack limit (so two boards that only whistle or wait end)". It was superseded by entry 10 after the milestone B scope review.
- **Wording note:** the question says "a Marmot-only board ends the fight at once". The build ends it only when neither side can attack; a Marmot-only board facing attackers keeps being attacked.

**The original question (prototype question 7):**
> "Whistle-only boards. Followed library entry 10: a side whose only units have Whistle can't attack, so a Marmot-only board ends the fight at once, and a waiting Dormouse wakes when only Marmots are beside it. The spec had worded it the other way (whistles keep the fight going until the 200-attack limit)."

Sources: `proto/main:docs/prototype/OWNER-QUESTIONS.md`, `docs/prototype/SPEC.md` sections 4 and 9; `design/tribes-and-budget:docs/design/mechanics-library.md` entry 10.
