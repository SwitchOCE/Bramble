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
- **Records (brief 8), smaller fight boards, 21:45.** The scope review found 86% of a 543 KB record is fight-board snapshots carrying fixed card data, and asked whether that is "relatively efficient and non-wasteful". The brief leaves the format to the agent and needs the boards for ghosts. Chose: keep each player's board at each fight, store only what differs from the card. Also cut: test and soak games were writing records into the real records folder (~20 MB per check run).
- **Shop (briefs 1, 3), spells in the hand keep the cream cost disc, 21:47.** The build had put the gold coin on spells in the hand too. The approved mock-up keeps the cream disc there and brief 1 says "Ask first: prices on cards outside the shop", so the build goes back to the mock-up. If the owner wants gold on owned spells, it is one switch.

## Questions for the morning

- **The five rulebook gaps have no slot tonight.** Moving board to hand (7.2.4), selling from the hand (4.3.7), play effects on recruit (7.2.3), recruit effects for units gained without buying (7.2.6), and the Triple Reward when the triple forms (7.3.6) are not in any brief. Workers follow the rulebook where a brief meets them, but none is building them. When selling from the hand lands, the sell cue must cover hand units too. Recommendation: one brief of its own, early next run.
- **Power check (brief 6) review, 22:00: two questions put to the owner, with defaults.** (1) One number or two: default, the built-around number is what a designer pitches; all-ten stays in the method page as the setup cost. (2) Is a partial, non-blind pass enough to rate brief 7: default yes, because brief 7 compares each card with its old self on the same check. Fixes queued regardless: restore three deleted skill lines (one approved by the owner on 16 Nov), delete an unsupported sentence, call the buff control a wiring check, plain one-screen skill step, history out of the method page, loader for all five tribes.
- **Fight animations (brief 10) merged into dev, 21:55 (PR 124).** Both gates passed (check.sh on the orchestrator's run; scope review: no cut, no ask, one comment fixed). Question for the morning: keeping fights no longer kept the wind-up small (4 frames, 12 px); Galaxy spends about 0.3 s on a big lift and lean. If the motion feels timid, the fix is more time per attack, which the brief says to ask about first.
- **Shop (briefs 1, 3) merged into dev, 22:00 (PR 121).** check.sh passed on the orchestrator's run; scope re-review: no cut, no ask. Records (brief 8) rebased on it and re-gated: re-review no cut, no ask; records 543 KB to 234 KB raw, 26.8 KB to 10.7 KB zipped.
- **Duplicate glow (brief 4) sent back, 22:05.** The scope reviewer measured the films: the "breathing" pulse the worker chose between two candidates never drew (pixel-identical frames). A shader dropped the fade, and the test checked a property, not pixels, so it passed anyway. For the morning pack's "what nothing could see": a worker's motion choice was made from films that showed no motion. Fix: make the pulse draw, a test on drawn pixels proved to fail on the old shader, refilm both candidates and choose again. Also: a card marked as not combining must not glow for a triple.
- **Records (brief 8) merged into dev, 22:10 (PR 122),** after check.sh passed on it rebased over the shop merge (so dev with shop, fight and records together passed).
- **Ambush (brief 7), made stronger, 22:20.** The worker's first version (a quarter of Attack, once per unit per fight) put nearly every former Hit card at ×1 on the frozen check: Ambush added about nothing. Options: keep quarter, half, or full with a cap. Chose half Attack, once per unit per fight, because of the owner's words tonight ("It's still very strong, but ... balanceable") and their standing balance direction to start generous and dial back; the bar is "well below today's Hit", not worthless. Dame Bodkin, the capstone, makes pile-on Ambushes full Attack (the owner kept free damage for "singular cards and or capstone effects"). Pigeon Lieutenant: the worker had swapped the row volley for temporary Health; changed to each unit in the full row making an ordinary attack on the enemy across (it takes damage back), to keep the row-charge fantasy. Both quarter and half numbers go in the doc.
- **Ambush frozen at half Attack, 22:45.** The frozen check still reads ×1 for most former Hit cards at half (it cannot see damage that doesn't change who survives); Bodkin 2 / 1.5; King Speck 3 / 1.5. All three versions (original, quarter, half) are in docs/design/ambush-check.md. No more tuning: the bar is "well below today's Hit", met. Balance waits for the owner's hands.
- **Card browser (PR 125) and triple animation (PR 126) opened, 22:45,** both rebased on dev; gates running.
- **Card browser review, 22:55.** The worker had taken the tribe picker off the game's start screen to match the mock-up's compact start; nothing the owner said asked for that. Chose: restore the picker, with Cards between Play and Quit in it. Kept the amber ring on the start-screen Cards button as the approved mock-up draws it. Morning questions: should the picker go, and is the ring wanted or only the mock-up's "new" marker?
- **Triple animation review, 23:00.** No problem with the main path. Sent back: a made-up stand-in card appeared under the screen centre for copies the screen hadn't drawn (a Discover pick included); now unseen copies come from where they really were. Also: any redraw cut the animation short; a press snapped every moving card, not just the triple; a fixed "0 s lock" number was written into reports as if measured. Two untested-on-film paths (full-hand board landing, Discover-pick triple) to be filmed. Morning questions: brisk (1.80 s) or ceremonial (2.16 s); and, already in the core before tonight, a triple formed with a full hand whose golden goes to the board loses its Triple Reward (core cites rulebook 7.1.2).
