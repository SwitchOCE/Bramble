# Criterion 5: release feel (assessed 10 Nov 2026, ideation/main 814793b9)

## Bar now
PLAN.md "Done means, sharpened" #5 (6 Nov, extended by owner note 09e on 9 Nov): one look, no switcher; unique art on every unit, hero and spell; text readable on phone (nothing under the phone minimum, full text one tap away); fights read through animation, not static labels, arrows or a running log; main game space assumes a player who knows the rules (no tutorial text, rule reminders, static pointers); teaching in a tutorial and how-to-play; fight and UI sound; tutorial, how-to-play, settings, game-over summary; no dev tools in the player's path; 20 scripted full UI games at phone and PC sizes without a crash or layout failure.
Refinements: DECISIONS 6 Nov `placeholder-portraits` (unique art per unit, after balance); 6 Nov "Sound nobody has heard" (ship synthesized sounds, guide says unheard); 7 Nov art sequencing (`content/portraits_pending.json`, entries removed in the art step); 9 Nov declutter calls + `ui-declutter-spec.md` (4 batches; tutorial = scripted 4-round game; Rules hub replaces the 14-page guide); 10 Nov batch-1 third reader call (rule-knowledge gaps such as Pounce timing, Pack, Mire go to Batch 4). Phone minimum: 31 canvas units (11 pt at 1688x780), tap 44 pt (`tests/ui/layout_check.gd`). Big numbers: compact notation at the minimum font (evidence/big-numbers, 9 Nov). No loosening logged for any sub-item.

## Sub-items
| Sub-item | Status | Evidence / gap |
|---|---|---|
| One look | met (look); quality risk | `src/ui/ui_theme.gd`, no switcher. Declutter visual comparison rates visual tier 4/10 (art 6, UI 3): the clutter, not the art. |
| Art: units | partly | 119 slice units; 107 own art. 12 on tribe fallback in `content/portraits_pending.json`: cuckoo, grey_agnes, old_isegrim, mr_pym, mrs_clover, mrs_mallow, goodman_hayward, squire_lollop, signor_ranocchio, lantern_man, lob_lie_by_the_fire, silky. No prompt file exists for 11 of them (Cuckoo has one). Pass 3 docs keep every creature, name and portrait, so names are settled. |
| Art: wave 2b | not started | `slice` token (on ideation/wave2b, no art, not in pending list: test_portraits will fail), Shieldbug, Click Beetle (not built yet). Wave 2b brief has no art step. |
| Art: heroes | met | 9/9. |
| Art: spells | met with one caveat | 24/24 resolve; golden_egg reuses nest_egg (test exempts it), pelt wears prey art by design. Golden Egg reuse is not logged as a loosening. |
| Phone text | met on old tree | ui-run 8 Nov (2ac67e8, build 7): smallest text 31 at phone. Big-number renders 9 Nov. Not rerun on pass 3 tree or declutter. |
| Fights by animation | partly, in flight | ideation/declutter batch 1: 58 commits, 3 repair rounds; attackers/hits/deaths read 57/57; 4 visual gaps fixed in 7b7a5fb7, awaiting fresh reader on reshot moments + cloud gate, then merge. Batches 2 (tiles/board/scout/reader), 3 (HUD/lobby) not started. |
| Fight and UI sound | met (unheard) | 25 synthesized sounds `assets/audio`, `src/ui/sfx.gd`, `combat_sounds.gd`. No sounds for pass 3 verbs (eat, pelt, homecoming) or new motion cues. |
| Tutorial | not started | No tutorial code on any branch. Spec section 4 / batch 4. |
| How-to-play | partly | 14-page guide `src/ui/screens/how_to_play.gd` (582 lines). Spec replaces it with a Rules hub with animated demos. No pass 3 Hunter/Ooze words (Quarry, Pelt, Eat, Digest). |
| Settings | met (base) | `settings_screen.gd`: speed, reduce motion, volume, how to play, Ask for Kin, version. Spec adds Replay tutorial, Experiments heading, cuts "Changes save". Checkpoint 1 wants B/C preset as a setting: not built. |
| Game-over summary | met (base) | `game_over_screen.gd`. Spec 2.7 changes (animated arrival, standings) in batch 4. |
| No dev tools in path | met | Dev panel and Sandbox behind 7 taps on version line (off by default); strong-field gated by `OS.has_feature("strong_field")`; exports exclude tools/tests/fields; Quilboar editor-only. Recheck on final export. |
| 20 scripted UI games | not met on current tree | Last 20-game pass: 7 Nov (2a120201, pre pass 2). Since then 4-game runs only (8 Nov, depth bar "not judged"; 0 games reached turn 12). Scripted player only outlasts Naive, and the game now has one bot strength: depth bar likely fails without a stronger scripted player or a logged change. `playthrough.gd` pins text the declutter removes. |

## Missing work
1. 12 pending portraits: small, art via Codex image tool, can start now.
2. Wave 2b art (Slice, Shieldbug, Click Beetle, any other new token): small, after wave 2b names land (can be done on the planned names now).
3. Golden Egg: own portrait or a logged call: small, now.
4. Declutter batch 1 finish + merge: small, in flight.
5. Batch 2: large. Batch 3: medium-large. Both can start after batch 1 merges; new wave 2b verbs need cues (depends on pool).
6. Batch 4 (tutorial, Rules hub, settings/game-over edits): large; tutorial boards should be built on the settled pool; keyword pages need wave 2b.
7. Sound for new cues/verbs: small, after batches 1-3 and wave 2b.
8. Scripted UI driver update + depth-bar fix (best-bot policy as the scripted player, or log a change): medium, after batch 1; then the 20-game run on the final tree at 1920x1080 and 1688x780, including the tutorial: medium, after everything lands.
9. Final dev-tool check on the exported build: small, at build time.
