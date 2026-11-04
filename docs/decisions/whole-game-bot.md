---
id: whole-game-bot
group: prototype
size: big
headline: Build a bot that plays whole games to check card prices
source: design/tribes-and-budget:docs/design/review-queue.md#B7
option: Yes, in the real engine's first milestone
option: Later, once there are more cards
option: No, keep pricing from the model
suggested: Yes, in the real engine's first milestone
---
Most of our card prices rest on guesses about how people play: how long you keep a card before selling it, when you upgrade, and how fast everyone else's boards grow. Today those come from a simple model of one player on their own. A bot that plays whole games against other bots would measure them instead of guessing.

We suggested building it as part of the first milestone of the real game's engine, before many cards are priced. Designing tribes and test cards doesn't have to wait: the first ones can start from today's numbers.

The overnight prototype already has bots that play whole games (it ran 200 of them in under half a minute), which might be a head start, though they weren't built to measure prices.

**What we need from you:** should this bot come next, with the real engine, before cards are priced in earnest?

**Why it matters:** until it exists, every price in the budget leans on guesses, and the ones that move prices most (how long cards are kept, what late gold buys, how fast lobbies grow) can only be measured in whole games.

## Detail

- **The proposal (budget draft v1, B7):** yes, as part of the headless engine's first milestone, before content is costed past the first test cards. First test cards may start from v1's numbers.
- **Why:** the inputs that move results most are hold time, the player's policy, the late sink and lobby pace (review §7). All need a whole-game run.
- **Known in band:** the rows-study cards after their re-prices, and scaling at the growth caps and gold at 1.8–2.5 against the one-player model.
- **Known out, or untested:** Lone Stag on full boards (by design), Drummer Hare on small boards (−15–22%), Divine Shield on bodies that trade, Reborn on bodies far from V(t), every [guess] class in taxonomy 3.4, and anything on a banked turn (B8).
- **Your direction (2 Nov):** the Python budget model stays the interim tool; the real one belongs in the engine.
- **The prototype's bots:** the 200-game soak ran 8,667 fights in 19 s on one core (prototype lessons). Whether they could measure holds, policy and pace is our guess, not tested.

**The original question (review queue, B7):**
> "Build the whole-game bot next, to measure real hold times?"

Sources: `design/tribes-and-budget`: `docs/design/review-queue.md`, `docs/design/power-budget-review.md` sections 5 and 7, `docs/design/power-budget.md` section 10 (B7); `proto/main:docs/architecture/prototype-lessons.md`.
