---
id: lobby-pace
group: plays
size: big
headline: How big should everyone's boards get by the late game?
source: design/tribes-and-budget:docs/design/review-queue.md#B3
option: Modest, about 8/9 units by turn 12
option: In between, about 13/13
option: Battlegrounds-sized, about 19/20
---
In Battlegrounds, boards get huge by the late game, because so many cards keep growing. How fast everyone's boards grow is the "pace" of a lobby, and it isn't set by any one card: it's the sum of all the growing cards in the game.

With the stats printed on our cards alone, a full board on turn 12 has about 120 Attack and Health in total, roughly an 8/9 per unit. A Battlegrounds-like pace would be about 270, nearer 19/20 per unit, and we also looked at a middle pace of about 180, around 13/13.

The good news is that this barely changes how we price cards: by 13% at most, inside your tolerance. What it does change is feel. In a faster lobby late boards look bigger, and a lead from a growing card is worth less, because everyone else is growing too.

**What we need from you:** how big should late-game boards feel? Modest and readable, Battlegrounds-sized, or somewhere in between?

**Why it matters:** it becomes the target for how much growing text the game prints overall, so it shapes the whole content pool and how wild late fights look.

We'd suggest pricing at the modest pace for now and picking the target by feel once you've played. The whole-game bot would then measure where the real game lands.

## Detail

- **The proposal (budget draft v1, B3):** price at the printed-stats pace (about 120 SP on the board at turn 12; the model's 118), and set the target pace for feel, not for prices. A pool with scaling text will run faster; the bot measures how much.
- **Why pricing hardly moves:** with the lobby growing 1 SP per unit per turn (turn-12 boards about 180 SP), the growth charge falls 0–6%; at 2.5 (about 270 SP, Battlegrounds-like), 0–13%, most at Tier 1. Both are inside the ±25% band for growing cards. This figure is marked [scratch] in the budget draft: from a model run not committed in the repo.
- **What pace does change:** at 180 SP, growing cards' turn-12 surplus is about a third smaller than at 118. In the first review, at 2.5 SP per unit per turn every scaling lead roughly halved.
- **Per-unit figures** (8/9, 13/13, 19/20) are our arithmetic: board total ÷ 7 units, split into Attack and Health. They are there to help picture it, not from the model.
- **How it would be held:** lobby pace is the sum of all scaling text, so it is a design target, tracked as a pace guardrail (power-budget section 8 step 7).
- **Risk:** the model adds the lobby's growth to every board as a pool, so it can't see growing builds racing each other.

**The original question (review queue, B3):**
> "Target lobby pace. A lobby as fast as Battlegrounds halves every scaling lead."

Sources: `design/tribes-and-budget`: `docs/design/review-queue.md`, `docs/design/power-budget-review.md` section 7, `docs/design/power-budget.md` sections 3.2 and 10 (B3).
