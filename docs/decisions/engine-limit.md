---
id: engine-limit
group: plays
size: big
headline: How much power should the best gold-spending combos make?
source: design/tribes-and-budget:docs/design/power-budget.md#B8
option: Test a limit of about 4 times normal
option: Test a looser limit, about 5 times
option: No limit for now
suggested: Test a limit of about 4 times normal
---
Some cards reward you for spending gold, like Battlegrounds' Fleet Admiral Tethys ("after you spend 10 gold, get a random Pirate"). Stack a few and a long turn turns gold into a huge pile of stats. Rising refresh prices stop a turn going on forever, but they don't stop it being enormous: in our model, an extreme build with two golden copies of one such Battlegrounds card turns a 30-gold turn into about 920 Attack and Health.

So the budget needs a sense of how much power a gold-spending combo should make. Without one, a player with no engine gets about 2 stats per gold late in the game. A starting point to test: the strongest likely combo makes at most about 4 times that, around 8 stats per gold.

That limit already fails one strong board we tried, which makes about 5 times as much. So either the limit is nearer 5 times, or cards like that one get weaker.

**What we need from you:** how big should the best economy turns get? About 4 times a normal player's, a bit more, or no limit until the whole-game bot can test it?

**Why it matters:** it sets how explosive the best economy combos can be. You've said you want big engines that run "for a very, very long time, but not infinitely", and this would set how much a long turn makes (that link is ours).

We'd suggest testing about 4 times as a starting point, not a rule yet, and confirming it in the whole-game bot before it becomes one.

## Detail

- **The proposal (budget draft v1, B8):** "adopt as an open test, not yet a rule. Starting point: the strongest plausible engine makes at most about 4× the no-engine SP per gold on a 30-gold bank, about 7.7 SP per gold at Tier 6 with S(t) = 5. That limit already fails one strong plausible board, so the number is the owner's call."
- **Evidence (bound_summary.csv):** no engine 1.9 SP per gold; strong Rogers 7.3–7.6; strong scaler (golden Gunpowder Courier) 9.9, about 5×, which fails a 4× limit; ceiling Rogers 13. Two golden Rogers, a ceiling build, pass every shop limit and make about 920 SP from 30 gold; with Hoggarr, about 3,100.
- **Why:** shop limits don't limit power (economy-bounding §4.4).
- **Risk:** the Rogers figures take Bounty text at face value, and SP per gold needs the combat link this model lacks. Confirm in the bot before it becomes a guardrail.
- **Cards named:** Sky Admiral Rogers (Tier 6: "After you spend 9 Gold, get a random Bounty"); Fleet Admiral Tethys (Tier 6: "After you spend 10 Gold, get a random Pirate"), from the Battlegrounds card library as quoted in the 2 Nov owner note.
- **Your words are about turn length** (how long a turn can run before gold runs out). Linking them to how much a turn makes is our reading.
- **Your words (2 Nov):** "Something like a Tethys, or a Sky Pirate Rogers … is able to go infinite. In our game, I want it to go for a very, very long time, but not infinitely."
- **"About 2 stats per gold" and "around 8"** round 1.9 and 7.7. The suggestion follows v1's recommendation.

**The original question (power-budget §10, B8):**
> "Engine SP per gold (new, from economy-bounding §4.4). Recommendation: adopt as an open test, not yet a rule. Starting point: the strongest plausible engine makes at most about 4× the no-engine SP per gold on a 30-gold bank, about 7.7 SP per gold at Tier 6 with S(t) = 5. That limit already fails one strong plausible board, so the number is the owner's call."

Sources: `design/tribes-and-budget:docs/design/power-budget.md` section 10 (B8); `docs/design/economy-bounding.md` section 4.4; owner note `2026-11-02-pre-development-design-pass.md`.
