---
id: whistle-stalemates
group: plays
size: small
headline: Score a marmots-only standoff as a draw, or a loss?
source: proto/main:docs/prototype/OWNER-QUESTIONS.md#8
option: Keep it a draw
option: Count it as a loss
suggested: Keep it a draw
---
The Marmot Lookout never attacks; it whistles to soften enemy hits instead. So when both sides are down to nothing but marmots, nobody can win the fight. We had the bots play 200 whole games, and that happened in 21 fights out of 8,667, about one fight in 400.

Right now, those fights count as a draw: nobody takes damage, just as when both boards are wiped out at once.

**What we need from you:** should that stay a draw, or count as a loss?

**Why it matters:** it's rare, but it decides whether two marmot-heavy boards can trade nothing and walk away even.

We'd suggest keeping it a draw. It matches how ties already work, and it's too rare to steer anyone's strategy.

## Detail

- **Soak result:** 200 bot-only games, 8,667 fights. 21 ended `no_attacks` as a draw, every one with only Marmot Lookouts (Whistle) left on both sides. No fight reached the attack or trigger limit.
- **The rule today:** library entry 10 and rulebook 9.9.1. A side whose only units have Whistle can't attack, and a fight where neither side can attack ends as a tie.
- **The question is vague** on "a loss": a loss for whom isn't said. Both sides have only marmots, so the likely reading is a loss for both players.
- **"Nobody takes damage"** follows Battlegrounds' tie rule, which the rulebook keeps. The suggestion is ours.
- **Related:** whether the fight ends at once in the first place (question 7).

**The original question (prototype question 8):**
> "Marmot-only stalemates. In 200 bot games, 21 of 8,667 fights ended with only Marmot Lookouts (Whistle) left on both sides. Today that's a draw (library entry 10, rulebook 9.9.1). Should a board with only Whistle units left count as a draw, or as a loss?"

Sources: `proto/main:docs/prototype/OWNER-QUESTIONS.md`, `docs/prototype/SPEC.md` section 9 (soak finding).
