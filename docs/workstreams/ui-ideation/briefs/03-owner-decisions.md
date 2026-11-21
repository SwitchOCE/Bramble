# Brief: list the owner's earlier decisions about screens

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). Everything outside quotation marks is my proposal.

## Why

On this branch the owner has opened almost everything about Bramble's UI to new proposals:

> "I specifically want the additional instructions of there to hold the theme and the stained glass and the hexagons, the warped hexagons, like the length and hexagons sacrosanct. Everything else is up for debate. It can suggest things and should suggest other things They're not to follow the other constraints"

So designers may reverse earlier owner decisions about the screens. When one does, its notes must name the decision, so the owner sees what they would be reversing. For that, designers and the council need one list of those decisions. This task writes that list. It is a reading task: change nothing else.

## What to produce

`docs/workstreams/ui-ideation/owner-decisions.md`: every decision, rule or stated preference of the owner's that shapes what is on screen or how the player acts. One row each:

| # | The decision, in one plain line | The owner's words (short quote) and date | Source file | Fixed on this branch, or open? |

- **Fixed** means it is part of one of the three fixed things: the woodland theme (animal folk, fairies, oozes), lead and stained glass for cards and the whole UI, and units and cards as tall, stretched hexagons in lead. Everything else is **open**. Where you are unsure which side a decision falls on (for example how fighters are drawn, or the tier colours), mark it "unsure" and say why in a line; do not guess.
- Group the rows: the look; cards and what a card shows; the board and slots; the shop and economy controls; the hand; the fight and its pacing; tooltips, keywords and wording; screen flow and menus; teaching and clutter; platforms, window and input; sound and motion.
- Separate what the owner said from what agents chose. A layout an agent built and the owner accepted in general ("I am happy with ... the UI", 17 Nov) is not the same as a rule the owner gave. Put agent choices that are now in the build in a second, shorter table, "Today's choices made by agents", only where a designer might mistake them for owner rules.
- Rules of the game that a UI concept could bump into (the board is 4 in front and 3 behind, the hand, free moving between hand and board, selling from the hand, the turn timer if any) go in a third short table, with the rulebook section.

## Where to look

- `docs/design/owner-notes/` (all), `docs/design/sources/`, `docs/design/owner-ideas-log.md`, `docs/design/direction-summary.md`, `docs/design/owner-taste.md`
- `docs/design/art-direction/README.md`, `docs/workstreams/glass-dial-in.md`, `docs/workstreams/glass-frames.md`
- `docs/ideation-track-2/` (README, HANDOVER, SCREEN-CONTRACT, mockups/README), `docs/workstreams/ideation-track-2.md`
- `docs/workstreams/fix-round-20-nov/` (PLAN, design, interrogation), `docs/workstreams/night-18-nov/`, `docs/workstreams/sound/`
- `.claude/skills/design-critique/`, `design-system/`, `accessibility-review/`, `ux-copy/` (their rules often quote the owner)
- `docs/design/rulebook.md` for the third table, `docs/design/review-queue.md`, `docs/STATUS.md`, `docs/AGENT-BLIND-SPOTS.md`
- `git log` on those folders if a quote's date is unclear.

Quote the owner exactly and keep quotes short. If two sources disagree, list both and say which is later. Do not include decisions about unit numbers, balance, bots or the build toolchain.

## Rules

- Write only that one file. Do not commit: another worker writes in this checkout at the same time, and I commit both.
- End your report with a **Disk** section: anything you wrote outside the checkout (expected: nothing).

## Report

A short summary: how many decisions in each table, the ones marked "unsure", and anything in the sources that contradicts the reading of the three fixed things above.
