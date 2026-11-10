# Criterion 1, whole game: gap notes (10 Nov 2026, ideation/main 814793b9)

## Bar now
- PLAN.md "Done means, sharpened" item 1 (6 Nov): human picks a hero, plays 8-player games to the end through the real UI; 6 tribes x 12+ units across T1-6, plus neutrals, 10+ tavern spells; all six per lobby unless measured shop thinness justifies rotation; no filler stat-line units; 2,000-game soak, rules checks, 0 violations, 0 crashes.
- Rotation loosened: DECISIONS 7 Nov "Six tribes in every lobby" (keep 6) was superseded by DECISIONS 8 Nov "Commit review B", item 7: "Keep five tribes for rotation variety", citing owner note 2026-10-27. Code: GameConfig.full_game() sets tribes_per_lobby = 5 (src/core/game_config.gd:114). PLAN text not updated; the reason is variety, not measured thinness.
- Owner notes 09a-i / 10a don't change this criterion directly. Plan v3 step 5 asks only a 200-game soak on the full pass 3 pool; Done means still asks 2,000.

## Live pool (full_game: pool_filter "slice", pass3_content on), counted from content/ with python3 -I
| Tribe | T1-T6 | Total | Version |
|---|---|---|---|
| Birds | 3/3/3/3/2/2 | 16 | pass 3 |
| Bog folk | 3/3/3/3/2/2 | 16 | pass 3 |
| Fairies | 3/3/3/3/2/2 | 16 | pass 3 |
| Hunters | 3/3/3/3/2/2 | 16 | pass 3 |
| Oozes | 3/3/3/3/2/2 | 16 | pass 2 (wave 2b rebuilding) |
| Hedgerow folk | 3/3/3/3/2/2 | 16 | pass 2 (wave 2b light pass next) |
| Neutral | 3/3/3/2/1/1 | 13 | wave 2b: keep 9, change 4, add Shieldbug + Click Beetle |
- 109 pool units, all with rules text; 0 vanilla bodies. The 38 no-set prototype bodies (25 pool:false, 13 pool:true in the old library) aren't in full_game.
- 18 pool tavern spells (T1 3, T2 7, T3 2, T4 3, T5 2, T6 1). 9 heroes.
- Wave 2b branch (a2f4295f + c66a88e5): same counts; Oozes rebuilt in place.

## UI
- Hero pick: recruit_screen.gd:388-389 "Choose your hero" via Discover overlay; core_port uses GameConfig.full_game().
- Latest full-UI evidence: docs/ideation/evidence/ui-run.md, 8 Nov, 2ac67e8 (build 7, pre pass 3): 4 games + 2 late checks, 0 failed; 0 games reached turn 12, 0 won.
- Fun probe (10 Nov) played full games through tools/play (commands), not the screen.
- Declutter branch (ideation/declutter) is changing the combat screen.

## Soak
- Only 2,000-game soak: evidence/soak2000-build6.md, 8 Nov, build 6 927b0b7: 0 violations, 0 crashes, 29 min on 4 cores. Before wave 1 and wave 2a: doesn't cover pass 3 content.
- Latest soak of any size: evidence/pass2-followup/soak.log (66afe504, 9 Nov): 200 games, 0 violations. Before the wave 1 and 2a merges (2fa5247f, 10 Nov). No soak on the current tree. The gate (scripts/check.sh) doesn't soak.
- soak.gd: seed%3==0 plays defaults() on the no-set prototype library; seed%3==2 plays SoakContent synthetic cards plus the same prototype pool; only seed%3==1 (~667 of 2,000) plays the real full_game slice lobby. Retiring the 38 prototype bodies (wave 2b, last) empties the legacy pool.

## Missing
1. Soak harness rework for the retirement: the legacy third gets a non-empty library or moves to full_game; synthetic games stop depending on prototype bodies; real-pool share up. Small. Has to land with or before the wave 2b retire commit.
2. 2,000-game soak on the settled pool (after wave 2b + retire), pass 3 on, checkpoint config: 0 violations, 0 crashes. Small (about 30-60 min on 6 cores). Depends on the pool settling.
3. Fix PLAN criterion 1 text (5 of 6 per lobby, variety reason) or re-justify by measuring shop thinness on the pass 3 pool. Small. Can start now (text); the measurement depends on the pool.
4. Evidence of a full 8-player game through the real UI to game over on the pass 3 pool with hero pick (full_ui_run on the declutter build). Small to run, medium if the declutter UI breaks the driver. Depends on declutter merge; shared with criterion 5's 20-game bar.
5. Reviewer check for filler: one line from a fresh reviewer on the settled pool that no unit is a filler stat line (Pill Bug "dead from R6" and the like). Small, in the final reviews. Depends on the pool.
6. Neutrals: wave 2b step 3 (Shieldbug, Click Beetle, 4 changed). Medium, in flight. Count passes already.
