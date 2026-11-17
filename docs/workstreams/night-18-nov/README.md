# Night run, 17-18 Nov 2026

The overnight run on the [backlog briefs](../backlog-briefs.md), on `dev`, following the global `overnight-run` skill. Each brief is its own branch off `dev` and PR into `dev`, passing `scripts/check.sh` and a scope review before it merges.

## What the owner settled before sleeping

Asked, 17 Nov evening: "go" or "options only" on three things the run would build on that the owner had not judged.

- **A.** The tooltip mock-up's second round (keyword marks off the art). The run's pick between its two layouts: the **bottom border** between Attack and Health.
- **B.** The card browser mock-up's second round (Units / Spells switch, Cards button on the start screen and top right of the recruit screen). Golden versions left out tonight.
- **C.** Hit replaced by a smaller first strike that happens once per fight, named Ambush.

The owner: "Yeah, I'm happy for you to go on all three ... A, B, and C are all approved. So yeah, you can try out the smaller first strike that only goes once per fight. It's still very strong, but yeah, it's probably quite balanceable at that stage."

## Order

Recruit screen, one branch at a time so they don't collide: briefs 1 + 3 (coin, prices, refresh counter), 4 (duplicate glow), 2 (keywords and tooltips), 9 (card browser), 5 (triple animation).
Alongside: 6 then 7 (power check, then Hit made weaker), 8 (game records), 10 (fight animations).
Dropped first if the night runs short: 10, then 5.

## Files

- `taste-*.md`: the taste calls, one file per brief, as the workers made them.
- Films and shots: in Cloudflare R2 under `docs/workstreams/night-18-nov/media/` (pull with `tools/assets/assets.py`).

## The orchestrator's calls

- **Power check (brief 6), one more round, 21:20.** The first trial missed the bar on Cleave (×1.25; Hit ×2, Master of Engines ×4, +50% buff ×1.5). Options: accept and report the miss, or one more round. A Fable advisor was consulted (the owner's rule for unforeseen calls). Chose one round, capped: the reason is that the measure failed its own control (a +50% buff read ×1 in three of ten cases), not the Cleave miss. The measure is fixed against the buff control only, then frozen; rungs above ×4 added; "built-around" and "all ten" reported separately, a rule fixed before the rerun. Both tables kept. Risk: the "built-around" split was chosen after seeing results. Brief 7's two numbers come from the frozen second version.
