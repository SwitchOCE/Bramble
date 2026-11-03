# Owner decision: the refresh schedule and free refreshes

Said by the owner in chat on 2 November 2026, answering Claude's question on how to close the loops the bounding fallback leaves open.

## The refresh schedule

A combination of answers to question one. Let's try a model of 15 one-gold refreshes, and then the next 5 cost 2, the next 5 cost 3, the next 5 cost 4, the next 5 cost 5, et cetera. Just plus 1 after every 5 more refreshes at the same price, so that there's a rising refresh model.

## Free and triggered refreshes

And yes, anything that gives access to free rerolls or triggered rerolls (which is the same as free, because you're not paying for it) should not have any way of making it infinite, or even close to infinite or unbounded. It can give a few, but it should be mathematically impossible to go infinite.

For example, you couldn't have 70% of the cards in the shop say "when sold, refresh the shop without paying", because at that point, with 5 units in the shop, you're mathematically going to go on for a very, very long time, even if the shop costs would otherwise rise. But if something had a 1% or 3% chance of showing up in the shop and gave you some free refreshes, it's fine. Mathematically, you're never going to be able to go infinite.

## The target

It's an option we've deferred. I will keep changing the target here, and we will keep experimenting, as the gameplay feel matters the most. With the system I just gave, 15 one-gold refreshes and then rising costs, I think it's pretty likely that different builds will see different numbers of shops, but that people will stay around 20 or so.

*[Editor notes:*
- *The question offered: an exact wording for guardrails G1 and G1b (no repeatable free refreshes, including effect refreshes; nothing gives back as much gold as was spent); a refresh cost that keeps rising past 3; or leaving it for later. The owner combined the first two and did not address G1b's gold-back wording.*
- *The schedule replaces the 27 October thresholds (1–10 cost 1, 11–20 cost 2, 21+ cost 3) in rulebook 4.4.2 and 4.4.3.*
- *Claude ran the schedule through the bounding model the same day; the results are in economy-bounding.md, "The owner's schedule".]*

## Answers on the wording

The owner chose from wordings Claude proposed:

- **Guardrail G1:** "Yes, use it."
- **Rulebook 3.1.2:** "Yes, use it."
- **A guardrail against cards that give back at least as much gold as was spent (G1b):** I think that we do not need that guardrail whatsoever. We are relying on our system design of refreshes to be our primary guardrail. It should be okay if a rare unit does that; not most units, obviously, or maybe not obviously, we don't know. Our primary guardrail against infinites is our refresh system, and we can explore other types of content design. We don't need to be so restricted.

*[Editor notes: the wordings as Claude proposed them:*
- *G1: "G1. Free and triggered refreshes can’t chain without end. Any refresh the player doesn’t pay for (a free Refresh, or an effect that refreshes the shop) must be limited so that an endless chain is mathematically impossible: on the strongest legal board, the expected number of unpaid refreshes each shop leads to stays well below 1. A rare card that gives a few is fine; a common trigger such as ‘when sold, refresh the shop’ on most shop units is not. Purpose: unpaid refreshes skip the rising price, so with no turn timer they are the one way a turn could run forever."*
- *3.1.2: "How many shops a turn sees is tuned by playtesting, and the target will move. With the prices in 4.4, builds will differ, but most long turns should see around 20 shops (N8)."*
- *G1b: "No card or combination of cards gives back as much gold as was spent to trigger it. Purpose: gold back at 1 per gold makes spending free, which no refresh price can stop."]*
