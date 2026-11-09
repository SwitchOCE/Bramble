# Checkpoint 1 playtest brief: the scale build (draft, 9 Nov 2026)

For three or more fresh players, each running in their own cloud session. Fill in the `<…>` values when build 8a exists.

## What you're testing

Bramble is an auto-battler in the Battlegrounds family. Until now its numbers grew in a straight line: about +13 stats a round, with no big moments. Build 8a turns on mechanics that let power compound: engines that grow, answers to big units, and units that hold their stats. It changes no tribe designs. It comes in two variants:
- **A:** shaped like Battlegrounds in September 2025, about ×1.5 a round from round 8;
- **B:** steeper.

The owner's bar, in their words:
- "Does it feel like it has a nice flow?"
- "Does it allow for a nice player progression, where the jumps in power level make the player actually feel stronger, feel like they're accomplishing something?"
- "If it's not fun, it's not a game."
- "Rewards give the player power, always."

## How to play

- Branch `<branch>`, commit `<sha>`. Start with `tools/play/play.sh` (`tools/play/README.md` explains the commands).
- Play `<n>` full games of each variant, alternating A and B, at seeds `<seeds>`. Opponents: `<strong-field mode or Hard>`.
- Read no earlier playtest reports.
- Play to win. Commit to a plan each game, and try at least once to beat a bigger board with an answer or placement.

## Your lens

Everyone reports on rewards and progression. Each player also has one extra focus:

| Player | Extra focus |
|---|---|
| 1 | Engines: does investing pay off, and when? |
| 2 | Flow and snowballs: when did each game feel decided, and was it fair? |
| 3 | Answers and clever play: can a smaller board win, and how? |

## Report

Keep it under 250 words, or put it in a file on your branch.

**Per game:**
- variant, placement and build;
- the round you felt strongest, and the biggest jump you felt (what caused it, and its size);
- the round the game felt decided, if it did;
- any fight you won against a bigger board, and how.

**Per variant:**
- does it feel like progress (yes, partly or no), with the moment that decided your answer;
- did snowballs feel common;
- did the big numbers read on a phone-size screen?

**Verdict:** which variant flows better and why, and the single change that would most improve the one you prefer.
