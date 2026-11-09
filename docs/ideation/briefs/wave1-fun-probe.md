# Wave 1 fun probe (10 Nov 2026)

Plan v3, step 4: three reward-lens playtesters in cloud sessions. Each plays two wave 1 games, one Birds and one Fairies, in counterbalanced order, plus one old-tribe game as a control, against the standard bot lobby.

**The one criterion (go/no-go before any wave 2 merge):** at least two of the three testers each name a moment that is checked against their game log and beats their control game. Otherwise wave 2's merge is held and the problem triaged.

The orchestrator checks every named moment against the committed save and the `log` output, comparing the board before and after.

| Tester | Seeds | Game 1 | Game 2 | Game 3 |
|---|---|---|---|---|
| A | 501–520 | Birds | Fairies | an old tribe |
| B | 601–620 | Fairies | Birds | an old tribe |
| C | 701–720 | Birds | Fairies | an old tribe |

Each routine's prompt is the brief: `LOG.md` has the routine ids, and the text is below.

## Tester A

```
Bramble ideation, not the supervised track. Your session starts on `main`: don't follow `docs/orchestration/`. Run `git fetch origin && git checkout ideation/main`, then read `CLAUDE.md` and `docs/ideation/CLOUD.md`, and follow those. Later messages from this routine that start `Orchestrator:` are instructions. Never push to or merge into `main`.

You are playtester A in the wave 1 fun probe. Change no game code.

**What you're testing.** Bramble is a Battlegrounds-style auto-battler. Until now its numbers grew in a straight line, with no big moments. Birds and Fairies have just been rebuilt so their power compounds. Birds fly south and come home stronger. Fairies grow Rings on their slots. The other four tribes (Bog, Hunters, Oozes, Hedgerow) are still the old, flat versions.

The owner's bar, in their words:
- "Does it allow for a nice player progression, where the jumps in power level make the player actually feel stronger, feel like they're accomplishing something?"
- "Rewards give the player power, always."
- "If it's not fun, it's not a game."

**How to play.** Use `tools/play/play.sh`. Read `tools/play/README.md` and run `tools/play/play.sh help` first. Play three full games to the end against the standard bot lobby:
- Game 1: commit to Birds.
- Game 2: commit to Fairies.
- Game 3, the control: commit to one of Bog, Hunters, Oozes or Hedgerow.

Use seeds from 501–520. If a seed's lobby lacks the tribe you need, move to the next seed. Play to win, and try to make your tribe's engine work. Read no earlier playtest reports or evidence.

**Evidence.** Create branch `ideation/c-funprobe-a` from `ideation/main`. In `docs/ideation/evidence/fun-probe/tester-a/`, put each game's save file and the output of `tools/play/play.sh <save> log`. Put your report there as `report.md`. Commit and push the branch.

**Report.** Your final message must be under 250 words, with the same text in `report.md`.
- **Per game:**
  - tribe, placement and final round;
  - the round you felt strongest;
  - the biggest power jump you felt: round, cause, and your board's total stats (Attack + Health) before and after, taken from the log.
- **Your best reward moment** across the three games, with its game and round. Say whether it beat everything in your control game (yes or no, and why).
- Did anything feel too strong or unfair?
- The one change that would most improve Birds or Fairies.
```

## Tester B

```
Bramble ideation, not the supervised track. Your session starts on `main`: don't follow `docs/orchestration/`. Run `git fetch origin && git checkout ideation/main`, then read `CLAUDE.md` and `docs/ideation/CLOUD.md`, and follow those. Later messages from this routine that start `Orchestrator:` are instructions. Never push to or merge into `main`.

You are playtester B in the wave 1 fun probe. Change no game code.

**What you're testing.** Bramble is a Battlegrounds-style auto-battler. Until now its numbers grew in a straight line, with no big moments. Birds and Fairies have just been rebuilt so their power compounds. Birds fly south and come home stronger. Fairies grow Rings on their slots. The other four tribes (Bog, Hunters, Oozes, Hedgerow) are still the old, flat versions.

The owner's bar, in their words:
- "Does it allow for a nice player progression, where the jumps in power level make the player actually feel stronger, feel like they're accomplishing something?"
- "Rewards give the player power, always."
- "If it's not fun, it's not a game."

**How to play.** Use `tools/play/play.sh`. Read `tools/play/README.md` and run `tools/play/play.sh help` first. Play three full games to the end against the standard bot lobby:
- Game 1: commit to Fairies.
- Game 2: commit to Birds.
- Game 3, the control: commit to one of Bog, Hunters, Oozes or Hedgerow.

Use seeds from 601–620. If a seed's lobby lacks the tribe you need, move to the next seed. Play to win, and try to make your tribe's engine work. Read no earlier playtest reports or evidence.

**Evidence.** Create branch `ideation/c-funprobe-b` from `ideation/main`. In `docs/ideation/evidence/fun-probe/tester-b/`, put each game's save file and the output of `tools/play/play.sh <save> log`. Put your report there as `report.md`. Commit and push the branch.

**Report.** Your final message must be under 250 words, with the same text in `report.md`.
- **Per game:**
  - tribe, placement and final round;
  - the round you felt strongest;
  - the biggest power jump you felt: round, cause, and your board's total stats (Attack + Health) before and after, taken from the log.
- **Your best reward moment** across the three games, with its game and round. Say whether it beat everything in your control game (yes or no, and why).
- Did anything feel too strong or unfair?
- The one change that would most improve Birds or Fairies.
```

## Tester C

```
Bramble ideation, not the supervised track. Your session starts on `main`: don't follow `docs/orchestration/`. Run `git fetch origin && git checkout ideation/main`, then read `CLAUDE.md` and `docs/ideation/CLOUD.md`, and follow those. Later messages from this routine that start `Orchestrator:` are instructions. Never push to or merge into `main`.

You are playtester C in the wave 1 fun probe. Change no game code.

**What you're testing.** Bramble is a Battlegrounds-style auto-battler. Until now its numbers grew in a straight line, with no big moments. Birds and Fairies have just been rebuilt so their power compounds. Birds fly south and come home stronger. Fairies grow Rings on their slots. The other four tribes (Bog, Hunters, Oozes, Hedgerow) are still the old, flat versions.

The owner's bar, in their words:
- "Does it allow for a nice player progression, where the jumps in power level make the player actually feel stronger, feel like they're accomplishing something?"
- "Rewards give the player power, always."
- "If it's not fun, it's not a game."

**How to play.** Use `tools/play/play.sh`. Read `tools/play/README.md` and run `tools/play/play.sh help` first. Play three full games to the end against the standard bot lobby:
- Game 1: commit to Birds.
- Game 2: commit to Fairies.
- Game 3, the control: commit to one of Bog, Hunters, Oozes or Hedgerow.

Use seeds from 701–720. If a seed's lobby lacks the tribe you need, move to the next seed. Play to win, and try to make your tribe's engine work. Read no earlier playtest reports or evidence.

**Evidence.** Create branch `ideation/c-funprobe-c` from `ideation/main`. In `docs/ideation/evidence/fun-probe/tester-c/`, put each game's save file and the output of `tools/play/play.sh <save> log`. Put your report there as `report.md`. Commit and push the branch.

**Report.** Your final message must be under 250 words, with the same text in `report.md`.
- **Per game:**
  - tribe, placement and final round;
  - the round you felt strongest;
  - the biggest power jump you felt: round, cause, and your board's total stats (Attack + Health) before and after, taken from the log.
- **Your best reward moment** across the three games, with its game and round. Say whether it beat everything in your control game (yes or no, and why).
- Did anything feel too strong or unfair?
- The one change that would most improve Birds or Fairies.
```
