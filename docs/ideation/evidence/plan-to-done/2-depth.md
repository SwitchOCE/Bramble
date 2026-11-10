# Done means 2 (strategic depth): gap notes, 10 Nov 2026

Repo: /home/alex/code/Bramble-ideation @ 814793b9 (ideation/main).

## The bar now
- Text: docs/ideation/PLAN.md lines 57-62 ("Done means, sharpened", 6 Nov). It hasn't been edited since.
  - Sim: 8 pinned strategy bots, 2,000+ games, 5+ distinct strategies at 6-25% wins, none above 25%.
  - Skill: the best bot among 7 Naive gets top-4 >=85% and wins >=45%. The current best beats the previous best head to head on fresh seeds (BOTS.md; DECISIONS 8 Nov "Promote measured bot gains without a fixed place floor": a 95% margin that excludes 0, no 0.15 floor).
  - Placement (DECISIONS 8 Nov "Replace the position matters bar"; (b) reworded on the review's simplify): (a) search beats the rule layout by >=+5 points, 95% CI above 0; (b) searching against the real opponent beats searching against a decoy board from the same round by >=5, CI above 0; (c) most fresh playtesters name a fight that placement decided.
  - Reviewers: a real decision on most turns, and 3+ builds that felt different.
- How the bar has been loosened: plan v3 (plan-scale-rework.md step 7) says "Done means 2 is rewritten onto the harness here, before build 8 sign-off". DECISIONS 9 Nov "Plan v3 approved" says "the Done means 2 rewrite moves to step 7". v2's rule was "Bot lobbies are only a sanity line". The owner's notes 09d, 09c and 09i point the same way: constructed setups over bot lobbies, tribes within an order of magnitude, two deciding criteria.
- **No rewrite has been logged.** PLAN.md still has the 6 Nov text, and no DECISIONS entry rewrites it. The bots-plan interrogation (8 Nov) also proposed shrinking the Naive bar to a 300-game regression check. That isn't logged as adopted either.

## Latest numbers
| Bar | Latest | Where / date | Pool |
|---|---|---|---|
| Sim spread (2,000 games) | 8 strategies inside, 0 above, TOO CLOSE (neutrals_economy 24.6% +-2.0) | evidence/bench-latest.md, 7 Nov | 2-tribe slice |
| Sim spread (1,000 games) | PASS: 19 at 6-25%, top oozes_second_helpings 22.3% | evidence/commit-spread.md, 8 Nov, b872a6b | pass 2, five tribes |
| Pass 3 line lobbies (not this instrument) | B: fairies_court 31.6% of lobby firsts, fairies_ring 23.1%, Birds 1.2-1.9% (4 lines + 4 Hard) | evidence/wave1-rebase.md, 10 Nov | wave 1 re-base |
| Naive yardstick | Hard among Naive: 100% top 4, 100% wins (500 games) | bench-latest.md, 7 Nov | slice |
| Head to head | carrier_upgrade promoted, +0.048 +-0.042 (fresh 161001-161500). Acorn Stash failed, +0.011 +-0.045 (failure 1 of 2) | BOTS.md, bots-yardstick.md, 8 Nov | pre-engines |
| Placing (a) | +23.8 [19.4, 28.2]; reviewer's rerun +24.1 | placing-bar.md, review-placing.md, 8 Nov, 3aac44b | build 6, pre-wave-1 |
| Placing (b) | real minus decoy +17.7 [12.0, 23.4] (reviewer's decoy arm) | review-placing.md, 8 Nov | build 6 |
| Placing (c) | 3 of 3 round-4 testers named one | pt4-a/b/c.md, 8 Nov | build 6 |
| Reviewers: builds | 3/3/3 builds that felt different | pt4-a/b/c, build 6 (927b0b7) | build 6 |
| Reviewers: decisions | A: most turns from T3. B: mid-game only, "rounds 1 to 5 rarely". C: most turns | pt4-a/b/c | build 6 |

DECISIONS 8 Nov "The position bar is met" counted (a), (b) and (c) as met on build 6.
Since then pass 3 changed combat: `Pass3Combat` timing comes on whenever the pool holds pass 3 cards (tools/sim/HARNESS.md "Combat-version boundary"). So every number above is from a superseded pool or combat. The fun probe (9 Nov) didn't ask about decisions or builds.

## Missing
1. Rewrite Done means 2 onto the harness, with a DECISIONS entry and a fresh interrogation. Small, can start now. Suggested shape: line lobbies plus designed setups decide; the pinned spread becomes a sanity line; Naive becomes a regression check.
2. Spread (or its harness replacement) on the full pass 3 pool, B (and C). Medium. Depends on wave 2b and step 5. Could read the step 5 line lobbies if the rewrite makes them 8 pinned lines. The old 21 pinned bench strategies are pass 2 names, and some will die when the 38 prototype bodies retire.
3. Naive yardstick rerun, 300-500 games. Small. After the pool settles.
4. Head to head: current Hard (with each tribe's Hard-bot fixes) against the 8 Nov Hard, on fresh seeds on the pass 3 pool. Medium. After the pool settles. BOTS steps 5-6 were never finished (re-measure the spread with the promoted bot).
5. Placing (a)/(b) rerun with tools/sim/placing_bar_run.gd. The decoy arm lives only as evidence/review-placing/xprobe.gd.txt and needs promoting into tools. Small to medium. After the pool settles.
6. Placing (c) and the reviewer bars: playtest round 6 on build 8 (step 7), with questions that ask for them explicitly. Large, since it waits on checkpoint 1 and build 8.

## Risks
- The fairies_court lobby-firsts share (31.6%) hints that the 25% ceiling could fail on pass 3.
- Bot-vs-bot gains are about 0.05 places. A gain that small can pass the margin rule and still say little.
- Early rounds were reported as thin of decisions (pt4-b, playtest-3). The declutter screen and scale changes haven't been checked for this.
