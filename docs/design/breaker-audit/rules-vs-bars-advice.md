# Hard rules or soft bars: guidelines for Bramble

**Short answer: your instinct is right.** A hard rule fits only where one miss is very costly and the rule fits in a sentence or two. Exponential growth passes the first test, not the second. So make the *verdict* hard and the *detection* a judgement question.

## 1. Which tool, and a test you can apply

Ask three questions:

1. **Is one miss very costly?** A slightly strong card is cheap to fix. Mrs Mallow at x3 a turn breaks every game she's in.
2. **Can you say it in two sentences that two fresh agents apply the same way to ten known cards?**
3. **Has agent judgement already failed here?** Mallow passed every run-1 review.

- **All three yes: hard rule.**
- **1 or 3 yes, 2 no: soft bar with a hard consequence** (see section 4).
- **1 no: soft bar.** Example: "power fantasy or degenerate?"
- **The answer is a fact: neither, run it.** "Does this board grow x3 a turn?" is a six-turn script, not an opinion.
- **The answer is taste: neither, you play it.** You found Mallow by playing.

Hard rules work best on *what counts as evidence and who judges*, not on card text. Rule 3 ("a sim median never clears a card") is short and checkable. Keep it hard.

## 2. What makes a hard rule safe

- **Test it on the pool before it binds.** The breaker audit showed why: the first draft would have killed twenty-odd healthy cards (Treasurer, Hayward, Redbreast, Jack Daw, Aunt Aspic, every Hunter trophy) and missed about eight loopholes (Charcoal Burner's gold cost, Dozey's "every 3 turns", Fly South replaying "one-shot" cards, spell scaling).
- **Keep two lists: must-catch and must-keep.** Must-catch: Mallow, Dozey, Standing Committee, Charcoal Burner, Squire Lollop, Fly South. Must-keep: Treasurer, Hayward, Redbreast, Aunt Aspic, a Hunter trophy, Cluricaun. Give a fresh agent only the rule text and the cards. Trust the rule when two different agents get both lists fully right.
- **Length limit:** the rule plus its exceptions in about three sentences.
- **Demote it to a soft bar when:** each fix adds a clause; two reviewers disagree on the same card; healthy cards keep dying; or designs start meeting the wording but not the intent (paying gold, adding a period).

Rule 1 is at that edge now: after one rewrite it carries definitions of "cap" and "one-shot" and a coverage list, and it is untested. One of its own examples of a cap, "up to three times a game", allows x27 on a tripler. The two-Hunters-facing-each-other loop is still open.

## 3. Soft bars with AI agents

**How they fail:**
- **Rationalising.** The run-1 panel called Mallow "a spread compounder that limits itself by design" by picturing an even board.
- **Reading medians.** Bots under-play engines, so the average looked fine.
- **Grading their own work.** The designer's framing reaches the reviewer.
- **Never binding.** The geometric-growth warning in `power-budget.md` was never enforced.
- **Piling up.** 235 decisions in five days.

**How to make one bite:**
- **One concrete question that forces shown work.** Not "is the growth healthy?" but "write this card's gain per turn on its best play as a formula."
- **One pass and one fail example from this pool,** next to the question.
- **A fresh judge who didn't design the card,** briefed to break it, given your words quoted.
- **A fixed set of verdicts,** and a stated consequence for each.
- **Few of them.** Your two-criteria-per-step limit is right.

## 4. The hybrid for exponential growth

**Hard (one sentence, no exceptions):** *No number may grow by a share of itself turn after turn, by any route, unless the most it can ever multiply by in a game is stated and small.* A card found doing it must change.

**Soft (the breaker's question):** *"Can what this card gives ever raise the number it was measured from: directly, through another card, a copy, a golden, a return to hand, or a system rule? Show the formula."*
- Pass: Honorary Treasurer. He reads gold in the Larder; his stats never raise the gold.
- Fail: Squire Lollop. He skips the biggest unit, but a receiver overtakes it and becomes the next source.

That single question covers nearly every loophole the four reports found (not the two-Hunters loop, which reads the enemy). The "a cost isn't a cap" bullets become the reviewer's worked examples, not rule text.

**Test:** any card the breaker flags or is unsure of gets its best line scripted for six turns. A steady ratio above 1 between turns means it compounds.

**Fully soft:** power fantasy or degenerate, and how often it comes together. This is what protects cool designs: the audit kept Treasurer, Hayward, Elder Ooze and Golden Egg.

## 5. Be careful of

- **A hard rule nobody has run against the pool.** It is a guess.
- **Patching.** Each clause closes the last loophole, not the next.
- **A soft bar with no consequence.**
- **Rules in code but not on cards.** Several guards and Mast's cap sit behind switches.
- **Over-kill passing unnoticed.** A wrongly killed card makes no noise. Always ask what the rule would wrongly kill.
- **Trusting any of this over playing.** One evening of you trying to break the pool is still the best check.
