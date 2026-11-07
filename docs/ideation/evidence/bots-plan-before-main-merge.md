Historical branch proposal, preserved verbatim below from e25acf3f0883caf2e4cfff10f41c4ff27ceca37b. The active plan is ../BOTS.md.

# Plan: the best bots we can make

The owner, 8 Nov 2026 (`docs/design/owner-notes/2026-11-08a-bots-and-data.md`, `2026-11-08b-remove-easy-medium.md`):

> "I think if we make bots, we should make them the best players we possibly can."
> "if one strategy is consistently beating other strategies, we should have that bot get better"
> "I think that we should be designing around the best bots we can. Maybe have different flavors of them with different strategic quirks."
> "human players will find stuff the bots haven't because our bots are pretty immature."
> "Remove altogether. No easy, no medium bot."

Everything below this quote is the orchestrator's proposal.

## Steps

1. **Remove Easy and Normal.** Implemented on `ideation/commit`; validation: [bots-step1.md](evidence/bots-step1.md). Levels, menu choice, level-only bot rules, per-level records, guide text and their tests go. The game has one bot strength. The record shows best placement and wins, with no level. Naive stays only as a test yardstick in tools; players never meet it.
2. **Head-to-head yardstick.** A tool seats 4 of a candidate bot against 4 of the current best in one lobby, with strategies spread evenly and honest noise margins. A bot only replaces the current best if it beats it clearly on fresh seeds.
3. **Find what the bots miss.** Fresh cloud players play by hand and try to beat the current best bot, and read the bot code for blind spots: economy, tempo, pivots, position, each tribe's signature lines. Output: a ranked list of lines people find and bots don't.
4. **Make the bot stronger.** Work down that list. Buying and tier-up choices may test options with real fight simulations, within a time limit per turn that keeps the game responsive on a phone. Each change passes step 2 or doesn't ship.
5. **Flavours.** A lobby's bots share one strength but play differently: a few quirks such as greedy economy, early tempo, late pivot and one-tribe purist. Each flavour must stay within sight of the best in head-to-head play. Flavours reuse the 21 pinned strategies where they can.
6. **Rule for imbalance.** When a strategy keeps winning, first improve the bots playing against it and the bots playing the others. Change cards only when hand play confirms the finding, or stronger bots still show it.
7. **Re-measure.** Spread and placing bars run with the best bot. Engine and Bird conclusions drawn from older bots get re-read.

## Done-means changes

- "Easy, Normal, Hard with a measured ladder" and "1 Hard among 7 Normal" are removed (owner's words). The bot bars become: 1 best bot among 7 Naive places top 4 at least 85% and wins at least 45%, and the current best beats the previous best in head-to-head play on fresh seeds.
- Expert bot is no longer deferred: this work is it, under one name.
