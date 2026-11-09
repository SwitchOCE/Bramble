# Ideation log

What was done, what is in flight, what is next. Newest at the bottom.

### 6 Nov 2026 — Branch created

`ideation/main` from `proto/main`, with `design/tribes-and-budget`, `design-lab/main` and `portal/main` merged in. The plan and rules are in place; the orchestrator session starts next.

### 6 Nov 2026, evening — Foundations done

Plan reviewed and reordered. Position test passed with caveats. Engine v2 merged. Woodcraft UI built on `ideation/ui`, not yet merged. Tribes designed and reviewed; slice settled in `content/SLICE.md`. Art pipeline proved. In flight: content worker, UI merge, bots and bench.

### 7 Nov 2026 — Ideation build 1

Bots at three levels, varied lobbies, sim bench and real scouting merged after two scope reviews. Build 1 exported, `latest` points at it. Bench bars not yet met: Hard among Normal (3.49 in the varied lobby, 3.73 free; bar 3.5), win spread, distinct strategies (3 of 8 by overlap); no economy line tested. Next: three fresh reviewers play it.

- 7 Nov: cloud routine trig_01MUBWuFgq4rMr3hfzhDSBHb reviews Oozes and Birds (tribes2 f51eefa).
- 7 Nov: cloud routine trig_01GVNKtoGYg1fFFU2pds8Ld9 works on placing value, branch ideation/c-placing from tribes2.
- 7 Nov, next on restart: Sol fixes freed cards in combat_screen.gd on ideation/balance (33e4406, 4 of 22 UI runs fail), then rerun the UI run, merge balance, read the two routines.
### 7 Nov 2026 — Balance step

Runaways capped, spells cheaper in rate, bodies raised, 12 units and 6 spells added with portraits, shops draw by tier odds, 40 Health. A median seat now goes out at round 14, up from 11; Dozey on 28.2% of boards, down from 82.8%; 8 of 9 builds inside 6-25% wins at 2000 games. Three bars read too close to call. Before and after: `evidence/balance-1.md`.

### 7 Nov 2026 — Balance step, after scope review

Easy plays worse, and Normal among Easy is 2.50 ±0.26. Rounds 1-2 now offer a choice of opening, level for bots at about 4.5. Mast tied to buying, Partner bounded, Chaser's finish back. Placing fails its bar: 0.14 ±0.27 at 300 games against 0.5, cause unknown; no suspect tested is shown to be it.

### 7 Nov 2026 — Oozes and Birds

Third and fourth tribes on `ideation/tribes2`: 14 units each plus Drip and the Egg, 30 portraits. Belly and Fly South in rules, fights, screens, `tools/play`, the guide, and bots at Easy, Normal and Hard, with six new builds. 200-game soak clean, every new unit seen. Spread at 120 games: the new builds win 4.9-23.1% against a fair 12.5%; none above 25%, Oozes and the Passage on the low side, and the sample is small. Not re-run: the ladder and the placing test. Numbers: `evidence/tribes2.md`.

### 7 Nov 2026 — Fight callbacks end with their cards

The build 2 gate caught a real lifetime bug: a reduced-motion death frees its card after 0.3 seconds, before the hit flash's 0.45-second callback. Godot reports the freed lambda capture before its validity guard can run. A focused regression reproduces it without added load. Flash, summon and attack tweens now belong to their cards, so freeing a card cancels its callbacks. The regression fails before the fix and passes after it; the full gate passes. No test was weakened and no log allowlist changed. A fresh deep UI run on the committed fix is required before exporting build 2.

### 7 Nov 2026 — Ideation build 2

Build 2 ships four tribes, with Oozes and Birds new, longer games, fewer runaway units and spells, an opening choice in rounds 1 and 2, and bot levels further apart. The gate on 39510b1 passes 954/954 tests. The full deep UI run at dc7d005 has 0 failed of 22; on 39510b1 nine games were clean before the detached run hit its 45-minute limit under load (exit 124). There is no full run on the fixed commit. The owner chose not to rerun and to export now; recorded in DECISIONS.md. The completed UI evidence is unchanged. The earlier 200-game soak had 0 violations. Windows, Linux and Android exports use build 1's layout under /data/bramble-builds/. No real phone tested; nobody has heard the sounds. Placing last read 0.14 ±0.27 against 0.5; the full bench on 2a12020, before the fight callback fix, is still running. Fresh reviewers are playing it; next, read their reviews and the bench and fix what they find.
- 7 Nov: playtest round 2 on 458ed0f, cloud routines A trig_01JPVRj6PM2UC9jgNeHKYDac, B trig_01NRuzaD2gCCQyndQ3TRAchR, C trig_01E6ULcbBRuEJ1QaEzx42Mt3. Tribes 5 and 6 design: trig_01AqSn8wc3i6uYQt17T5Rpuj. Placing and sticky boards: trig_01GVNKtoGYg1fFFU2pds8Ld9.

### 7 Nov 2026 — Round 3 agreed playtest fixes

On `ideation/round3`, implemented the six requested items in order, each with its own tested commit and push. A separate rule-clarity follow-up corrects the first Nest notice: Goose's away power survives replacement. Golden Changeling now triggers once; CLI stable hand handles, readable phone geometry, current-tier shop odds, 4-to-12 loss curve, bounded Acorn conversion and Treasurer aura, and Money Spider's smaller savings threshold are in. Full gate: 977/977 tests. Soak: 100 games, seeds 41–140, 1,751 rounds, 5,331 fights, zero violations or crashes. Evidence and limits: `evidence/round3-fixes.md`. No actions denied; no merges, PRs or exports. No Ooze/Bird strength tuning or tribes 5/6. Next: larger bench and fresh playtests.

### 7 Nov 2026 — Cloud review of round 3 addressed

Eight fixes on `ideation/round3`, separately committed with focused tests, plus isolated follow-ups for copied Hex and printed-cap validation/borrowed doubling. Read cloud review on `origin/ideation/c-review-round3`. Selected-bird/scout renders inspected. Seeds 53–64: largest 67/90 Alderman Dozey → 54/36 Cluricaun. Full gate 991/991; soak 100 games, 5,331 fights, zero violations/crashes. Snail: working savings, missing activation reporting; final soak 105 purchases/82 gains. Evidence: `evidence/round3-fixes.md`. No denied actions, exports, main merges or PRs; other worktrees and their benches untouched.

### 7 Nov 2026 — Follow-up review: attribution and phone cosmetics

Read the follow-up review (zero cut items) and the empty portal inbox. Corrected the Hiring Fair attribution in `1fa1d82` and pushed it to `ideation/round3`. Fixed SHOP clipping, BACK drawing beneath the tray, Posset's counter/Belly overlap and the detached Ring chip within the 20-minute cosmetic budget. Inspected the actual 1688×780 selected-bird render; focused phone suite passes 7/7 with 97 assertions. Final gate: all ten steps pass, 992/992 tests, 11,880 assertions, strict hook clean. Compact Ring headers may omit the short name; tapping shows it. Evidence and the screenshot are in `evidence/round3-fixes.md`. PLAYTEST adds a returning-player tip and labels bench numbers as older; PLAN records delivery still pending.

No automatic approval rejection or denied action. The session's developer instruction restricts commits/pushes to `ideation/round3`, so the ideation/main merge, merged-tree validation, short full-UI run and build-3 export remain for a session authorised for that branch. No other worktree or bench changed. `latest` remains `/data/bramble-builds/1107-1953-ideation2`.

### 8 Nov 2026 — Ideation build 3

Round3 and c-review-round3 merged (730669a). Fixed phone names (7cf805f) and late-shop tap targets (e579fd1). Gate 994/994. Final UI: 2 per size plus 2 late checks, 0 failures, normal engine clock, hard 25-minute limit. Required Android export and Linux/Wine boots passed. Delivered `/data/bramble-builds/1108-0125-ideation3`. Bench numbers are older; no depth-bar UI run or full bench on this commit, no real device test; nobody has heard the sounds. Inbox empty.

### 8 Nov 2026 — Ideation build 4

All six tribes on merged 70366f7. Portal inbox empty. UI found crowded Scout shop targets, fixed in e80ee58 without lowering minimums; the rerun found inert lane-guide examples intercepting input, fixed in ef27d6f consistently with other guide illustrations. Final gate 1,152/1,152. Complete UI rerun: 2 per size plus 2 late checks, zero UI problems; one cached-shader warning cleared by a full affected-game retry, normal clock, hard 30-minute limit, three-core allowance after old bench ended. Required Android export and Linux/Wine boots passed. Delivered `/data/bramble-builds/1108-0239-ideation4`. No depth-bar UI run or full bench completed on this commit, no real device test; sounds not checked by ear. Six-tribe spread and level ladder bench starts detached separately with three cores and a hard three-hour timeout.


### 8 Nov 2026 — Round 4 fixes on ideation/round4

Six items in order, one commit per item: legal bot decision limits; ten-page core-loop guide with card-local keyword help; geometry highlights and isolated Shy action previews; hero/cost/log fixes and Mag Pye regressions; phone/card/first-hit polish; and one round toll. All design calls are in DECISIONS. No cloud card power/tribe/Birds work was touched.

Final gate: 1,175/1,175, all steps pass. Then soak 100 seeds 41–140: zero violations, exit 0 (1,527 rounds, 4,820 fights). Paired final mean places: plain among Easy 1.70, Normal among Easy 1.00, Hard among Normal 2.63, Hard among Easy 1.00 (30 each). Round toll: Normal lobbies 18.80→15.90 rounds, Hard 18.75→15.30 (20 each); draws now cost Health, but draw rate and spare gold did not improve. Full report and per-round stats: evidence/round4-fixes.md and round4-stats.csv.

Push to ideation/round4 was rejected by automatic approval review over external-publication authorization. No retry/workaround; local commits are ready for the orchestrator to push. No merge, PR or main changes. Remaining: historical human Mag Pye replay and 56-gold case unreproduced, cloud integration, exports, device/audio checks, fresh reviewers and full PLAN acceptance runs.

### 8 Nov 2026 — Ideation build 5

Exported ideation/main game source 04b1a96 (8c78def plus opening-name and waiting-hit-panel fixes and the guide-checker scope correction): tribe commitment rewards (Stand Behind Me, Bread from the Back, Harvest Supper, Hiring Fair), visible tribe bonus, five tribes per lobby; one bot strength (Easy and Normal removed at the owner's request); Bird Eggs and visible Nest stats; round toll and picture guide. Copied and adapted build 4's export, finish and delivery scripts for build 5, using core 3 only. Portal inbox read and empty.

Headless import and all ten gate steps passed (1,255/1,255 tests). Short UI `tests/ui/full_ui_run.sh 2 1000`: four games at desktop/phone sizes plus two forced late checks; one whole-game guide vocabulary false-positive cleared by a full affected-phone-game retry, normal engine clock, hard 40-minute timeout, original minimums retained. Required Android export, pack/archive/APK checks and Linux/Wine boots passed; both boots reached `boot: main scene ready`. Delivery path is recorded below. No depth-bar UI run or full bench on this source, no real device test, nobody has heard the sounds. Burner remains provisional and bot-tuned; Old Tern/One Swallow small-Bird flights beside larger buffed Birds remain human-play watch items. No balance or strategic-depth claim follows from these checks.

Initial UI run on 8c78def found seven raw Bot-number labels behind the opening hero choice: bot heroes intentionally wait for the human's pick. Stopped that failing run and retained logs in build/ui-ideation5-initial. The reviewed fix displays “Choosing a hero” until the hero exists; the real-lobby regression now checks before and after the human's choice. No rule, bot policy or UI minimum changed. The full gate and complete short UI suite were rerun on the fix before delivery.

The first name fix also replaced explicit non-hero scenario names; the gate caught the Old Tansy regression. Narrowed the placeholder to generated Bot names and added an explicit-name assertion before the final reruns.

The next UI run passed desktop seed 1000 (12 turns, tier 6) but seed 1001 found the waiting first-attack label outside the window after a no-attack fight. Preserved logs in build/ui-ideation5-name-fix. A regression that lays out the panel after zero-width creation fails before the fix (73/75 assertions) and passes after (75/75). The label now uses three explicit short lines at its original font size, avoiding stale autowrap minimum height. Full import, gate and complete short UI suite rerun on the reviewed fix; no UI minimum lowered.

Final four-game suite: three games clean; phone seed 1101 flagged only Ooze references in the whole-game guide because that lobby lacked Oozes. Corrected the checker's scope for HowToPlay alone; raw IDs, bot numbers, grammar and every layout/action check remain enabled. Reviewer accepted the scope correction; full affected-game retry passed. Original failed row and logs are retained, as for build 4's affected-game retry. No game rule or minimum changed.

Initial export attempt found no templates in the fresh temporary build-5 data directory. Linked the installed pinned 4.7.2 templates, matching build 4’s setup, and reran required export smoke and boots; latest stayed unchanged until successful delivery.

Exported /data/bramble-builds/1108-1004-ideation5; finish validation stopped on Wine CRLF line endings before README/latest. Latest remained build 4.

Normalized Wine CRLF for the exact ready-line finish check and preserved the shared debug signing key used by build 4, then repeated required exports and boots. No game or UI checks changed.

Delivered /data/bramble-builds/1108-1006-ideation5; latest is updated only after all checks and the delivery commit.

### 8 Nov 2026 — Ideation build 6

Build 6 exports ideation/main at c8693ae: Harvest Supper from tier 3; the Last Four lifts the damage cap with four heroes left; Last Stand saves each hero once from a lethal hero loss at 2+ Health, leaving 1, only in the last four and never against ghosts; Last Blow awards a mutual wipe to the side that struck last, crediting the finishing effect's owner (Start of Combat wipes remain ties). Bot strength unchanged from build 5. Copied and adapted build 5's export, finish and delivery scripts, core 2 only. Portal inbox read and empty.

Initial import and tests passed (1,279/1,279), but editing the running shell wrapper caused Bash to resume at an invalid offset, breaking the next command and overwriting the gate log. Repeated import and full gate with the final, unchanged wrapper before the UI suite. No game fix or test minimum change.

Fresh headless import and all ten gate steps passed (1,279/1,279 tests, 16,546 assertions, strict hook clean). Short UI `tests/ui/full_ui_run.sh 2 1000` passed all four games and both forced late checks with zero problems or errors, normal engine clock, core 2 only, hard 40-minute timeout, original minimums retained. No UI fix commits were needed. Required Android export, pack/archive/APK checks and Linux/Wine boots passed; both boots reached `boot: main scene ready`. APK signing certificate verified identical to build 5. No depth-bar UI run or full bench on this source, no real device test, nobody has heard the sounds. Burner remains provisional and bot-tuned; small-Bird flights remain human-play watch items. No balance or strategic-depth claim follows from these checks.

Delivered /data/bramble-builds/1108-1442-ideation6; latest is updated only after all checks and the delivery commit.

### 8 Nov 2026 — v0.5 damage, ideation/damage

Implemented selectable round-base plus own starting-survivor damage; combat snapshots identities before Start of Combat and preserves returns while excluding combat creations and enemy units. Legacy mode retains the old tier/cap/toll rules; v0.5 replaces toll with base and has no cap. Last Blow attribution and Last Stand remain.

Registered five schedules before measurements, ran 200 paired best-bot games per arm plus baseline on cores 1–4 with 50-minute batch timeouts. D wins four targets by the registered simplicity tie-break: streak elimination R10→R13, first elimination R9→R12, performance 28.50%, comeback 22%→30%. T2 fails: median games R17→R21; every candidate misses it. E also misses T3. Default slice/full_game now D at 40 Health. Updated rules/help/preview and old numeric/fixture expectations; all explanations are in DECISIONS.md and test comments.

Independent implementation/methodology, UI/test, and final selection reviews found no remaining material issues after fixing the occupied-output guard. Final check.sh passed all steps (1,309 tests, 17,988 assertions); afterward a soak of 100 games on fresh seeds 91847001–91847100 passed 1,827 rounds/5,644 fights with zero violations. Raw data, checksums, logs, and all candidate results: evidence/damage-v05.md and evidence/damage-v05/. No build exported or branch pushed.

### 8 Nov 2026 — Owner reprioritises wording; damage stays selectable only

Supersedes the preceding default promotion. The playable game and slice retain legacy damage. v0.5 schedule D is explicitly selectable through GameConfig.full_game("v05"), with counting, summons/returns/theft/golden, Last Blow, and Last Stand tests. Restored all changed UI/help/preview/rulebook files exactly to b99b5ad; wording work owns those surfaces. Original legacy numeric regressions are restored. No player-facing text changes remain relative to the task base.

All 1,200 simulations and raw evidence remain complete: A–D pass four registered targets; E passes three. D wins simplicity, but all candidates fail game-length T2. Current check.sh passed all steps: 1,310 tests, 17,916 assertions, strict GUT clean. No new soak was run under the revised instruction. The prior default-enabled gate/soak are archived separately and identified with revision 9d3006c. No push.

### 8 Nov 2026 — Ideation build 7

Build 7 exports ideation/main at the requested 2ac67e8: much shorter card and keyword text, about Battlegrounds' length, with the same effects; explanations open on hover or tap on a smaller italic slip; consistent words for each idea; the Bog folk Belladonna is now Lady Belladonna. Adapted build 6's export, finish and check scripts for build 7. All six cores available, LP_NUM_THREADS=6, normal engine clock. No game source or tests changed and no layout fix was needed.

Headless import followed by one full `./scripts/check.sh` invocation passed all ten steps: 1,321/1,321 tests, 18,687 assertions, strict hook clean. Includes existing reminder-slip hover/tap, italic text, size and bounds regressions at both resolutions. Short UI `tests/ui/full_ui_run.sh 2 1000`, hard 40-minute timeout: four games at 1920×1080 and 1688×780 plus two forced late-game checks, all passed with zero problems or errors and original minimums retained. Evidence: `evidence/ui-run.md`; report's legacy Naive labels do not describe actual bots, which use the game's sole strength.

Required Android, Windows and Linux exports and pack contents passed. Windows ZIP and APK CRC integrity passed. APK signing verified and certificate matched both builds 5 and 6. Linux and Windows (Wine) reached `boot: main scene ready`. No depth-bar UI run, full bench on this source, real device or listening test; nobody has heard the sounds. Burner remains provisional and bot-tuned; small-Bird flights remain human-play watch items. These checks do not establish balance or strategic depth.

Delivered /data/bramble-builds/1108-2016-ideation7; latest is updated only after all checks and the delivery commit. No push; owner pushes.

### 8 Nov 2026 — Playtest round 5 on build 7

Five fresh cloud playtesters on b2c3f01, each pushing `evidence/pt5-{a..e}.md` to `ideation/c-pt5-{a..e}`: A depth trig_01QBxBhUx1VjJsLi4qDdP2j5, B newcomer trig_01HUK894tDNTtR8Ai8h7xrCo, C tribes trig_01Jqb2NAxZXo22r8MBJtN252, D reading trig_01HVw1cVhB6ajWhU6pmYSs1n, E economy trig_01LEUJXDkoaD1nE2SvWWkQDW. Meanwhile w18 merges main into content5 and words its four cards (Horseshoe, Barn Owl, Redwing, Market Stall).
- 10 Nov: wave 1 fun probe (plan v3 step 4; brief `briefs/wave1-fun-probe.md`), cloud routines A trig_01GXxumcX3aARXz3SNUKquwh (session cse_013aVwzAJXEDFQfUjMmyApc8), B trig_01T498Kyc14Qvv5bVkTNE1kR (cse_013aVwz9VCQXzuWzsiwmxYzw), C trig_015Cq8RGqhzeEfDAPUHxWxhW (cse_013aVwz9NybmhM1tbVD1E6ri). Branches ideation/c-funprobe-{a,b,c}.
- 10 Nov: test-suite pass (owner note 10a). Cloud profiling routine trig_013zH8bkta7kjJGQ49XuqKNB (session cse_013aVwz99ZxFnJax89A3USJA): per-step and per-test times, peak memory, sharding into 2-4 processes, on branch ideation/c-testprofile. Alongside it, an analysis workflow (wf_1b38cd8f-fad, no Godot) mines the test runs since 6 Nov, profiles the suite, designs the scheduling, and lists tests to prune.
- 10 Nov: gate plumbing (owner note 10a): cloud routine trig_01AK9fNeUVHZQaFqCxRfrM54 (session cse_013aVwz8HFHWotZyM4s8svPr), branch ideation/c-gate-plumbing; merged as 405bd57b. Per-game profile and combat fast paths: trig_01GtoRWGU6rww9LLCYASvfvh (cse_013aVwzAdTGUmZVpidhVbqhT), branch ideation/c-gameprofile; merged as 66289bc5. The fallback Claude cloud gate: trig_01Bu2zM5LeTNEw9jLVYeUtB1 (cse_013aVwzBJr76yXztWUedWGN2), branch ideation/c-gate-next.
- 10 Nov: orchestrator hand-off from Remote Control to SSH. Restart guide `docs/ideation/RESTART.md`; independent review `evidence/review-restart-guide.md`.
