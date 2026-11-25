# Owner rule: bots decide from the game state, and their makers log why

Said in chat on 26 November 2026, to the card power session. It had found that both league bots tier up on a fixed curve (blue at set rounds in every game; red by a round-by-round target with a few fixed exceptions) and never weigh tiering up against buying.

First, asking how the bots decide:

> In poker there's a moniker that people use, CATO. It stands for "consider all the options". It's designed to get you to consider options that aren't part of your heuristics, because sometimes it's better to deviate from the patterns you know and are familiar with. In Battlegrounds you often follow a specific curve when levelling, but sometimes it's worth deviating. Are the bots not evaluating doing early tier-ups or later tier-ups in specific game states? I would hope we wouldn't have to force them to tier up earlier.

Told that neither bot weighs the option, and offered the suggestion that the teams make tiering a choice the bot scores each turn against buying, named as one of the two fresh strategies each team restarts from:

> Sure, that's a really good suggestion. I think fixed rules in the bots are pretty poor indeed. We want to force them to be able to be more flexible and adapt to situations, because that's the point of an RNG game. There should be situations where you want to deviate from your normal plans.

> I think also the makers of the bots, the agents that make the bots, should be reporting the reasons why they're doing things into some sort of documentation. A, for themselves, so that they last across compactions and new sessions. But B, so that we can take balance learnings from them. If they have ideas that they're finding are performing better, we need to look at those ideas and go: hey, is this the kind of gameplay we're trying to encourage? And if it's not, and it is performing better than the gameplay we're trying to encourage for whatever reason, we need to examine it and make sure that it's not that it's optimal *[probably: check whether that play really is the best, or whether]* the bots are not at a local maximum, not at an actual maximum, etc.

Where it is applied: [the third-run brief](../../workstreams/third-run/third-run-brief.md), sections 6, 8 and 10, and [the balance plan](../../workstreams/balance/plan.md), step 3.

*[Editor note: dictated. "tear up" was heard for "tier up", "fixed rules and the bots" for "fixed rules in the bots", and "balanced learnings" for "balance learnings".]*

*[Editor note: the last sentence trails off. The session's reading: when an idea the game doesn't mean to encourage is winning, find out whether it is truly the best play, which is a balance problem, or only looks best because the bots have stopped at a local maximum. The owner confirmed it: "Yeah, that's exactly what I meant. Your reading of my dictation is correct."]*
