# Criterion 7 (Agreed) + plan v3 checkpoint 1 — gap notes (10 Nov 2026)

## Bar now
- PLAN.md "Done means" 7 and "sharpened" 7 (6 Nov): three fresh reviewers who each played full games say "very good for a playtest"; their agreed items fixed; phone checks are layout measurements/screenshots, PLAYTEST.md says no real device tested. Not loosened anywhere in DECISIONS.
- Checkpoint 1 (plan-scale-rework.md v3 step 6 + "What decides checkpoint 1"; DECISIONS 9 Nov "Two criteria decide checkpoint 1", "Generous first"): 3+ reward-lens testers play B and C blind, counterbalanced, against the strong field. Deciding: (1) every tester names a log-checked moment of feeling stronger, most say their preferred preset "feels like progress"; (2) lobby median grows x1.3+/round R8-R14 (pre-start boards). Totals (B~900, C~1,800 at R12) are dial targets, not bars. Only 3 extreme misses triaged before owner plays.
- Order: checkpoint 1 (step 6) -> step 7 (build 8, playtest round 6, Done means 2 rewrite) -> final 3-reviewer verdict.

## How testers play
- tools/play/play.sh: one CLI action per call, replays a save through real rules; `log` gives boards by round. `--field-library` for strong-field. NO preset flag (play_game.gd _begin uses GameConfig.full_game(), pass3_preset defaults to B in pass3_rates.gd). NO screenshot command; tests/ui/player_driver.gd does not replay play.sh saves.
- Cloud routines (CLOUD.md): Claude cloud sessions, `ideation/c-<slug>` branch, report <250 words + file. Workflow agents can't run Godot, so testers must be cloud sessions.
- Moment check method: evidence/fun-probe/verification.md (board A+H before/after from log).

## Last rounds found
- Rounds 1-5 (builds 1-7, 7-8 Nov; playtest-1/2/3.md, pt4-a/b/c, pt5-a..e on origin/ideation/c-pt5-*): never "very good". Best: "good" (round 2 all three; pt5-b). Round 5: 4 okay, 1 good. Tally (plan-triage-redesign.md): unclear rules/log 14, loss snowball 14, one huge unit decides / commit doesn't pay 11, Birds trap 8, Ring piles 7, Chaser 6...
- Wave 1 fun probe (10 Nov, 3 testers, B, standard bot lobby, not strong field): go 3/3. Moments verified (Fairies 262->660, 293->1,249; golden Lump). Raised: flat tribes ~25x behind, Birds homecoming runaway (Old Tern 19->208; Lump 820/1082), slow early Fairies/Birds. No verdict question asked.

## Growth criterion status
- wave1-rebase-B.md: all seats x1.420 [1.410,1.429]; C x1.795. Shipped 5-tribe config x1.301 [1.290,1.312] (review-harness-6.md). Wave 2a head x1.38 (review-wave2a-hunters-narrow.md). Oozes Pot Luck line x1.251 < 1.3 (PLAN status). Needs remeasure on full pool (step 5).
- Realized B R12 ~300-400 vs 900 target (PLAN status).

## Before checkpoint 1 can run
1. Wave 2b merged (Oozes review/gate pending; Hedgerow, neutrals, retire 38 bodies to do). Large. Pool.
2. Step 5 full-pool measurement: line gate, 150+ lobbies/preset, designed setups, soak 200, strong-field library recaptured once (none committed: strong-field.md:7). Medium-large. Pool.
3. play.sh preset selection with blind labels stored in the save. Small. Now.
4. Brief fixes: brief currently names B/C and their sizes (not blind), says "alternating" not a per-tester counterbalance, asks phone legibility of CLI players who see no screen. Small. Draft now, fill after pool.
5. Declutter must land before checkpoint 1 (v3 step 3): batch 1 in third repair, batches 2-4 (tutorial, Rules page) not started. Large. Batch 4 rules content waits on pool.
6. Portal build with B/C as a Settings choice: no settings code today. Small-medium. Code now; export after pool.

## Criterion 7 proper (after step 7)
- 3+ fresh cloud reviewers, full games on the final build via play.sh, plus frame strips/phone screenshots of the same build for feel; collect agreed items, fix, re-review. Large; depends on everything.
