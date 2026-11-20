# Owner rule: balance is measured with strong bots; TribeBot is not a balance bot

Said in chat on 20 November 2026. The balance orchestrator had tuned the Mouse and Pigeon reworks from TribeBot games. The owner asked: "These are the best bots we have access to with iteration, right? Not some naive bots". Told that TribeBot is a simple greedy baseline, the owner said:

> The entire point of the league was to create stronger bots because TribeBot is absolutely inadequate, absolutely inadequate at measuring balance. We do not use that bot anymore. It should be archived, deprecated, whatever. We need strong bots for balance.

Straight after:

> And they need to be tested and at least reach a local maximum. They have to hill climb and at least reach a local maximum. Even if it's not the actual maximum, we need to at least reach local. And I prefer not to get stuck at a local maximum.

**TribeBot's one remaining use.** It plays no match, ghost match or field, and nothing measures balance with it. It stays only as the driver of the engine check `league selfcheck --bots tribe`, which proves the tribe mechanics play the same in Rust and in the game, because the simple bots rarely trigger them. It goes once the league bots use every tribe mechanic in their own games. The owner, asked whether removing it was going too far ("I don't want to measure balance with a weak bot, but am I going too far in removing the TribeBot?"), took that recommendation: "Okay, that's fine. I'm happy to take your recommendation on that. Act accordingly".

How the strong bots are made and tested: [the third run, step 5 of the ghost plan](../../workstreams/third-run/ghost-plan.md).

Read with [2026-11-19a-balance-reads-bot-preferences.md](2026-11-19a-balance-reads-bot-preferences.md).

*[Editor note: dictated. "tripod" was heard for TribeBot, and "spots" for bots.]*

*[Editor note: the Mouse and Pigeon tuning (PR 196) was measured with TribeBot. The owner accepted it as a generous start; it still needs measuring with the league bots.]*
