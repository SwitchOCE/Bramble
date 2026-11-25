# How Sword-heir, Old Brock, Brock Cub and Overrun got through

Traced on 25 Nov 2026. Every quote was read at its source that day. The short answer: the process flagged these cards four times between 16 and 22 Nov and changed nothing. It did not miss them; it had no way to act on what it found. Overrun's chaining, and what Brock Cub gathers over a game, were never measured by any stage.

## What each stage said, and what happened to it

| When | Stage | What it said | What happened |
|---|---|---|---|
| 16 Nov | Tribe design | "the tribe probably runs hot against wide boards … Grudge and the Fury numbers are the first things to turn down." | Not followed. Three days later both were raised |
| 18 Nov | The blue team's own fight table | "Old Brock (T6) is the strongest fight card everywhere." Sword-heir "fight like T5s" | Stayed in the team's folder. The league brief keeps each team's card values out of what it hands over |
| 19 Nov | Balance pass 1 | No bot played Badgers, so they read as the weakest tribe. The owner: "They're very undertuned. So just try and fix them." | Fury and Grudge were buffed. Brock Cub has both |
| 20 Nov | Fix round, answering the owner's "Surely he's considered to be overpowered" | Old Brock is "on target mid-game, about 3x over late". Recommended he count printed stats only | Handed to the balance session |
| 20 Nov | Badger pitch | Tested one made-up round-11 board. "Old Brock is on target at round 11"; the rework "would double-tap the weakest tribe". Sword-heir: "Leave … it can't run away." Brock Cub: leave | The narrower test won. The owner took the picks unread: "I'll take your picks anyway, and we can revisit." All three unchanged |
| 21 Nov | Power check | About 1,300 fights of generic effects on plain boards | None of the four cases was in it |
| 22 Nov | League | A bot told to play Badger comes first in 84% of games. Sword-heir on 96% of its final boards, Brock Cub 88%, Old Brock 51%. "likely too strong … Not passed, so no change yet." | Held until a bot passed its stopping test |
| 23 Nov | League | red-c14 passed | The hand-over to balance waited for the owner until 25 Nov |

The same pitch page noted that on a board twice as big Old Brock "reads about 13 bodies" against a target of 6, and explained it as normal growth.

## The missing pieces

1. **No measure of one card's power reached balance.** The league's per-card numbers say which cards sit on winning boards. The one real test (18 Nov) was private to a team.
2. **A flag could not lead to action.** Everything waited for a bot to pass its stopping test, then for the owner. The rule came from the owner's 20 Nov words that bots "need to be tested and at least reach a local maximum"; agents turned that into "tune only from bots that passed".
3. **When two stages disagreed, nothing settled it.** The fix round and the pitch gave opposite answers on Old Brock. The owner was shown only the second, as a pick.
4. **The costing method cannot price an effect that grows with the board.** Nothing compares the same effect at two tiers, and no guardrail covers unlimited growth in a fight or chained damage.
5. **A tribe the bots don't play reads as weak.** Badgers were buffed on that reading.
6. **Nobody asked for a first-sight read.** The owner's was right on at least two cards "within two seconds of seeing them" and was never collected.
7. **The climbing field was too weak** (found 25 Nov). 8,000 of its 15,000 runs are from the two starting bots, so the 22 Nov "first in 84% of games" overstated the tribe, and a weak field over-reads cards that punish weak boards.

## Effort that could not have caught these cards

- The 21 Nov power check: generic effects on plain boards.
- The pitch's made-up round-11 fights. Their scripts were not kept, so they cannot be rerun.
- Stopping tests as a gate for card changes: four chains of 27 to 37 matches, 6 to 8 hours each. They test the bot; an obvious outlier does not need them.
- The league's nine per-card numbers. None separates a strong card from a strong board, and none was run in the third run.

## Sources

- `/home/alex/league/blue/tools/league/bots/blue/tools/CARDPOWER.md` (the 18 Nov fight table)
- `docs/workstreams/fix-round-20-nov/design/old-brock.md`
- `/data/balance2/pitch-badger/index.html`, `/data/balance2/batch-notes.md`, `/data/balance2/powercheck/report.md`
- `docs/ideation-track-2/tribes/badger/README.md`, `docs/design/sources/2026-11-19b-tribe-rework-directions.md`
- `docs/design/owner-notes/2026-11-20a-strong-bots-for-balance.md`, `docs/workstreams/balance/plan.md`
- `/data/third-run/stopping/red-2/results.txt`, and the threads "Balance Orchestrator 2" and "Referee"

What to change is in [proposals.md](proposals.md).
