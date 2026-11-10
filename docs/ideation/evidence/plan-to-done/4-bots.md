# Criterion 4: bots worth beating (ideation/main @ 814793b9, 10 Nov 2026)

Status: PARTLY met.

## Bar now
- PLAN.md "Done means" 4 and "sharpened" 4: one strength, the best players we can make, several flavours with different strategic quirks (owner 08a/08b), visible record of best placement and wins. Hard is the implementation; Naive is tools-only.
- BOTS.md "Done-means changes": best bot among 7 Naive gets top 4 >=85% and wins >=45%; current best beats previous best head to head on fresh seeds (promotion rule: 95% margin excludes 0, floor dropped 8 Nov, DECISIONS 1125/1121).
- Flavours = the open strategies dealt one per seat (DECISIONS 8 Nov line 1153: "21 strategies count as flavours for now because the owner said 'Maybe'"; BOTS.md: new quirk axes wait until step 5 ends).
- Loosened by owner 09d: bots "okay at best"; constructed sims outweigh bot play, so bot strength is not the measuring bar. 09i: at most two deciding criteria per step.
- "How far can I get" moved onto strong-field mode: plan v2 step 4 "Strong-field mode is the playtest default"; plan v3 step 5 recaptures the top-4 library, step 6 checkpoint 1 plays against the strong field (DECISIONS 10 Nov, ask 1: flag turns on in the checkpoint 1 build).

## Exists
- One strength: src/core/bots/bot_level.gd has only naive and hard; no Easy/Normal in UI (commit 75291836, 8 Nov; evidence/bots-step1.md).
- Record: src/ui/records.gd (best/wins/games, legacy migration), main menu "Your records" panel (src/ui/screens/main_menu.gd:57-66), "New best!" on game over (game_over_screen.gd:59,94; app.gd:248-253). Test: tests/ui/test_records.gd. Screens: evidence/bots-step1-ui/menu_records-{phone,desktop}.jpg (8 Nov) show "Best 1st · 1 win". PLAYTEST.md:37 mentions it.
- Flavours: content/bots/strategies/ has 21 open lines + plant_bad (pin_only). BotLobby.resolve deals them without repeats per lobby (src/core/bots/bot_lobby.gd). Lines differ by tribe, curve, shape; a few have non-tribe quirks (neutrals_purse saves, neutrals_economy fast tier, neutrals_low_roll triples, oozes depth_first). Pass 3 engine-aware Hard policies for Birds/Fairies/Bog/Hunters (77acaf25, 9f03fe0b, dc274897; 9-10 Nov). Splash rule: flexible before R4 / <3 bodies (DECISIONS ~284).
- Head to head: carrier promoted +0.048 ±0.042 (evidence/bots-yardstick.md, 8 Nov); Acorn Stash failed (pre-engines). BOTS step 5 stopped at 1 promotion, 1 failure; steps 5-6 not finished.
- Naive floor: PASS 100%/100% on 500 games (evidence/bench-latest.md, 7 Nov, commit 1d12de0, old pool). NOT RUN since (evidence/pass2-followup/free-choice.md:89).
- Strong field: merged 10 Nov (adacf49 / 4bea1f8), off in all export presets (export_presets.cfg custom_features=""), no shipped library. Hard in human seat places 5.10 vs top-4 field against 3.95 in normal lobbies (+1.15 [0.08, 2.22]) (evidence/review-strong-field-followup.md).
- Exported build /data/bramble-builds/latest -> 1108-2016-ideation7 (8 Nov) has one strength and the record, but pre-pass-3 bots and no strong field.

## Missing
1. Strong-field recapture from the full pass 3 pool, flag on, library in presets, positive export smoke (strong-field.md "Library"). Medium. Depends on pool settling (v3 step 5). Codex worker (local Godot).
2. Naive floor rerun on the final pool with the final Hard. Small. Depends on pool. Codex worker; fold into the 2,000-game soak.
3. Record vs mode: one record mixes Bots and Strong field games. Orchestrator call (separate record per field, or record only strong field once it is the default) then a small UI change + test + menu screenshot at phone/PC. Small. Decision can start now; code after the declutter branch merges (main menu may move). Codex worker.
4. Flavour bar: log the call that the 21 lines (+ wave 2b Hedgerow/neutral lines) meet "different strategic quirks", or add one cross-tribe quirk axis (greed/econ vs tempo, answer-buying when scouted carry) per v2 step 4 "bots buy an answer when the scout shows a carry". Decision small now; axis medium, after pool. Local Claude for decision; Codex worker for code.
5. Head-to-head: no fresh-seed confirmation that the pass 3 engine-aware Hard beats the 8 Nov Hard (rules changed, so a pre-pass-3 Hard may not run). Orchestrator should log that BOTS step 2/5 promotion bar is superseded by 09d (lines measured by harness) or run one h2h. Small decision now.
6. Reviewer evidence: no reviewer has judged bot/field strength. Checkpoint 1 / final reviews should ask "did the opponents feel worth beating". Depends on items 1 and the pool. Cloud Claude reviewers.

## Risks
- Wave 2b retires 38 prototype units and rebuilds Oozes/Hedgerow; strategy JSONs and bot_*.gd tribe code must follow, or lines go stale (bot_ooze.gd on wave2b already).
- Fun-probe testers (agents) placed 1st in 2 of 3 games on new tribes (evidence/fun-probe), so normal Hard lobbies are beatable; strong field is the hardness lever and it is non-adaptive (scripts over captured trajectories).
- Quilboar bot (ideation/quilboar) must stay test-only and out of BotKnowledge's open strategies.
