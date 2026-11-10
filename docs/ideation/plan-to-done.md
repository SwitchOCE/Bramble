# Plan to Done, v3 (10 Nov 2026)

*[Approved by the orchestrator on 10 Nov, with the twelve calls in §11 taken as recommended: DECISIONS "Plan to Done v3 approved". Supporting drafts, the interrogation and the critique are in `evidence/plan-to-done/`. In this file, "w5", "w6" and "w7" name roles (UI, measurement and delivery, content), not today's Codex threads.]*

Basis: plan v2 (`evidence/plan-to-done/plan-v2.md`), its interrogation by a fresh agent (`evidence/plan-to-done/interrogate-v2.md`), the three skeptic checks of the Quilboar lesson drafts (`reference/quilboar/lessons/check-bars.md`, `check-process.md`, `check-questions.md`), and the repo at about 11:00 AEDT: tips, trial `git merge-tree` runs and line counts redone against ideation/main `5425c907` (§0, §3). `reference/quilboar/lessons.md` had still not landed. W-f is the step that uses it (§3, S8).

The goal, in the owner's words: "run continuous iterative development as the plan says, deciding everything yourself. The goal is met only when every "Done means" criterion in docs/ideation/PLAN.md is met with evidence, at least three fresh independent reviewers who each played the latest build judge it very good for a playtest, and that build is exported to /data/bramble-builds/ with latest pointing at it. Never merge anything into main."

## In short
- **The scale step (A3.5) now starts with a dial check.** In `rates.json`, Bog has only one dial that differs between B and C (Soak keep, plus its golden twin), and Oozes have two. Sliding them from B to C can't get to 900. So before run 1, the paper workflow names the extra dials that will carry each raise and w7 confirms them. Shared dials stay at their preset's value.
- **Oozes part 1 merges with Pot Luck still open, as logged.** Pot Luck gets its own step (A1b): two route arms and a constructed board, then a card change if the arms miss. It lands before the neutrals. Only the Oozes' level gap goes to A3.5. Part 1 is gating now as `53ff356a`.
- **The Quilboar bar check is done from the archives, with no Godot run, so it no longer blocks A4.** At R12–14, BG-text Quilboar wins 0.89 of its fights and the frozen arm 0.54, one each side of the 80% cap. If the field read later flags nothing, the round-15 order-of-magnitude check takes over. Lobby firsts can't be the fallback, because they would flag Birds.
- **Done means: every change now sits beside the 6 Nov text.** The reviewers together have to find 3+ builds that felt different, not each of them. The Naive bar comes back as a pass/fail check at J2. Three more loosenings are now logged: placing (c), the "2+ reviewers" re-skin rule, and the replaced 6–25% band.
- **Reviewer briefs and the tally carry the owner's 09d line,** so a rare highroll in a good game doesn't fail a round.
- **Cut back:** the decoy arm, the splash audit, the line gate and three of S3's four harness follow-ups now wait. Owner game logs stay, and the round 6 triage (W-g) now reads them.
- **Twelve calls are still open** (§11). The biggest one is whether A3.5 run 1 moves up to right after A1, which would give the owner a per-tribe scale answer days sooner.

## 0. Where things stand (checked 10 Nov, about 11:00)

| Branch | Tip | State |
|---|---|---|
| ideation/main | `5425c907` | **Quilboar is in** (test-only), merged on top of the docs commit `ff0fe759` (the Pot Luck call). Realized R12 boards in B are about 300–400 (Oozes lines 262 and 200), against a target of 900. |
| A1 merge | `53ff356a` | Oozes part 1 (`ba80977e`) merged onto the Quilboar squash `b19a0af6`, and **gating on Actions now**. Part 1 on its own failed on lint only (run 42722128746). `recruit_rules.gd` is 991 lines on the merged tree, and `recruit_screen.gd` 999. |
| ideation/declutter (batch 1) | `cea9d0e2` | The Pounce and Mire cues are in, and so are Ask 3's Bog before/after shots. **Still owed:** a fresh narrow reader on those reshoots (DECISIONS, "fourth cold reader": "After the fixes, one narrow reshoot … goes to a fresh reader before the merge"; the follow-up note says "No new cold reader/scorer or full gate was run"), the Actions gate, and the merge. The trial merge onto main is clean. **Also:** the worker's DECISIONS edit in `cea9d0e2` pasted a whole entry into the file's Format line. Fix that at the merge. |
| ideation/declutter-b2 | `344a5e75` (WIP) | Batch 1 is merged in (`593e0740`). Recruit animations are in, and a label-budget report is failing on dense boards. `recruit_screen.gd` is at 1,047 lines, over the 1,000 cap. It merges cleanly onto main. Against the A1 merge it conflicts in 3 files (`recruit_screen.gd`, `recruit_view.gd`, `card_view.gd`), and against the wave2b tip in 5 (the same 3, plus `recruit_layout.gd` and `test_pass2_ui.gd`). |
| ideation/wave2b | `0b2fcb88` | Part 1, then Hedgerow on top of it: WIP `85756e5f`, fixtures, and parity after the native bot guard. `recruit_rules.gd` is 1,003 lines, but 998 trial-merged with main. Against main it conflicts in 4 files (`engine.md`, `bot_brain.gd`, `combat_unit.gd`, `check_units.py`). |
| ideation/c-gate-shards | `e6b9783f` | Its gate passed and it isn't merged yet. Its trial merge is clean. |
| ideation/c-faster-suite | `4c572c86` (pushed) | It touches 92 files, all in `tests/**`. It merges cleanly onto main, but conflicts in 2 core tests against the A1 merge (`test_belly.gd`, `test_pass3_pool_replays.gd`) and in 3 UI tests against b2 (`test_pass2_ui.gd`, `test_polish.gd`, `test_round4_finish.gd`). |
| origin/main | `156e8c11` | Must stay there. |

**Corrections to v2 and to the interrogation's refresh:**
- The task's live facts said main was at `3cfd1f0c`, and the interrogation said `ff0fe759`. It is now `5425c907`, which is v2's "merge Quilboar first" step done.
- The interrogation said B1 needs only the gate and the merge. One fresh narrow reader is still owed, as shown in the table above.
- Same-cohort reads move per-line growth by up to 0.05, not 0.03 (check-bars §3). No line changes between pass and fail.
- `recruit_rules.gd` over the cap belongs to Hedgerow (A2), not to part 1.

## 1. Plan changes to log first
These go into one DECISIONS entry (W-a). Changed or new since v2: items 8, 11, 12 and 13.

1. **New step A3.5: set B and C from realized boards** (§2, "A3.5 in detail"). It starts with a dial check.
2. **The 38 prototype bodies come off the critical path** (kept). `full_game` already leaves them out. J2 adds a soak check that no unit without a set appears in a `full_game` lobby.
3. **Checkpoint 1 doesn't wait for declutter batches 2–4.** Its two criteria come from logs, and CLI testers never see the screen. But the build 8 export waits for batch 2 if batch 2 merges within 24 hours of A5's pick, because batch 2 removes most of the words at rest (about 65 down to 0).
4. **Workers and machines** (kept).
   - Three Codex workers: w7 (content), w5 (UI), and w6 (measurement and delivery).
   - Three cloud code sessions: sharding (which then adds the sim job and the soak rework; the order is open call C3), the faster suite, and S5 (play tools).
   - Two local Godot slots. Lobbies, soaks and library captures run on Actions. Local Godot runs only targeted tests, renders, UI runs and exports.
5. **Sims and soaks run on Actions** (kept). A run starts when `ideation/sim/<id>` is pushed with its config, and its results come back as a commit on that branch. The repo is public, so large raw captures never go there.
6. **One shipped field library, recaptured last** (kept). Strong field is the default only on the default preset. The library is recaptured as the last step before every export, and its SHA goes in the README. A4 captures throwaway B and C libraries for the checkpoint testers only.
7. **"Played the latest build" means** (kept):
   - the same source commit as the export, tagged `ideation-build-N`;
   - the pack's content hashes and the library SHA match the README;
   - default settings;
   - played by `tools/play` commands, with the reviewer's own turns and fights rendered by that commit's UI at 1688×780 and 1920×1080.

   Each verdict reviewer plays 2 full games.
8. **The pass rule** (DM7): 3+ fresh reviewers say "very good", and no problem is raised independently by 2+ of them.
   - A fresh tally agent decides what counts as the same problem. What counts as a "problem" at all is open call C4.
   - **New, from 09d:** "don't let reviewers fail good work on power-budget concerns that don't matter, if the thing happens very, very rarely and it produces a good game in general." W-d quotes this line in every round 6 and verdict brief. The tally sets aside a power complaint when the thing happened in only one of a reviewer's games and that reviewer still called the game good. It goes on the owner's list instead.
   - Every agreed item that counts is fixed in the next build, and a fresh trio plays that build.
   - Items only one reviewer raises go on the owner's list in PLAYTEST.
   - After two failed rounds, run the triage skill before more fixes.
9. **Round 6's agreed design items are triaged before they're fixed** (kept). 0 of 17 reports so far have said "very good".
10. **Declutter scope is set by "very good"** (kept). Batch 3 is trimmed, the Rules hub uses still pictures, and the tutorial is as specified.
11. **Approved v2 step 4 items:**
    - **Owner's games logged: kept, and now with a reader.** From build 8, each finished game's seed and actions go to `user://games/`, and PLAYTEST says how to send them. W-g reads any that arrive before round 6's triage, and any later step that needs strong-player boards reads them too. The interrogation proposed a deferral; why v3 doesn't take it is in §10.
    - **"Bots buy an answer when the scout shows a carry": dropped,** with a logged reason. The default rivals replay captured trajectories and can't react, and 09d says bots will be "okay at best". Revisit if round 6 agrees the opponents never answer.
12. **Loosenings logged with reasons** (W-a). Each one appears in §4 beside the 6 Nov text it changes:
    - DM1's "no filler" becomes a count (0 units without rules text), plus a reviewer line;
    - **DM2's 6–25% lobby band no longer decides, and field fights decide instead.** Reason: the band "flags whichever line leads this field, whatever the scale" (`bars.md` §5). It flags Birds at 36% (B) and 50% (frozen), against the logged "Birds: no nerf". 09d prefers constructed sims ("rely far more on empirical simulation data than on observational bot play"). The band is still reported;
    - DM2's head-to-head promotion bar is dropped (09d; it gains about 0.05 of a place, and its floor was already dropped on 8 Nov);
    - **placing (a) and (b) become reported, and so does (c), which v2 dropped without a line.** Placing (c) becomes a question in the verdict brief. Reason: placing was met on build 6 (real minus decoy +17.7), and DM2 already has its two deciding criteria (09i);
    - **DM3's "Reviewers don't call it a re-skin" becomes "no tribe is called a re-skin by 2+ final reviewers".** Reason: one reviewer's call is a single report, and 06a acts on independent agreement. A single report goes on the owner's list;
    - the dealt lines stay the "flavours" (logged 8 Nov);
    - checkpoint testers play 1 game per variant, with a second pair only if a tester can't pick (budget);
    - round 6 drops to 4 testers, because checkpoint 1 already covers the reward lens.
    - **Not a loosening any more:** the Naive bar is back in DM2 as a checklist pass/fail (§4).
13. **A new bar is checked on a known case before it decides: done, from the archives.** The interrogation is right that the captures are outside git: they sit in `Bramble-ideation-sol/build/quilboar-h1-captures/`, with a backup in `/home/alex/backups/`, and the repo is public. The read already exists, in `check/ck_captures.txt` F9: Quilboar's fight win rate against its lobby, by round band, with draws counted as half.

    | Arm | R12–14 | R15+ |
    |---|---|---|
    | BG text (uncut) | 0.89 | 0.96 |
    | C dials | 0.84 | 0.88 |
    | B dials | 0.75 | 0.76 |
    | frozen gem size | 0.54 | 0.61 |

    - DM2's 80% cap flags uncut Quilboar and doesn't flag the frozen arm, so the cap can decide. It doesn't block A4, and nothing new runs on the reference.
    - **Caveat (logged):** these are fights against lobby opponents, not the strong field. So they check the cut point on a stand-in.
    - **Fallback.** Suppose A4's first field read flags no line at all, while the order-of-magnitude read fires. Then the order-of-magnitude read decides dominance, and the cap is triaged. That read is: the best line's median ÷ the median of the other lines, same cohort, at R14 and R15, firing at 10×. It fires on uncut Quilboar from R14 and on B Quilboar at R15. It doesn't fire on our lines alone, which spread 5.9–7.0× best ÷ worst at R15 (check-bars §19–20).
    - Lobby firsts aren't the fallback, because they flag Birds.
14. **Growth is read on the same seats** (kept).
    - Checkpoint criterion 2, and every growth or late-round read (A1b and A2 included), uses the median over seats alive at R14. The survivor median and the share of seats alive are reported beside it.
    - Why: after R12 the survivor median grew 1.36–1.42 a round, while the same seats grew 1.21–1.22.
    - The order-of-magnitude read names its round, its ratio and its population (item 13).

## 2. Critical path

Each step names at most two deciding criteria (09i). Everything else is reported.

### Track A: the pool and the scale (long pole, about 5 worker-days)

| Step | What | Who | Size | Waits on | Decides |
|---|---|---|---|---|---|
| A1 | **Oozes part 1 in.** <br>1. `53ff356a` (part 1 onto the Quilboar squash) is gating on Actions. <br>2. A narrow scope check, then a merge into ideation/main. The only commits on main since `b19a0af6` are docs, so a docs-only check covers the merge commit. <br>3. Pot Luck stays open (DECISIONS 10 Nov, Pot Luck call, item 5). <br>4. The Ooze marks go to S2. | the orchestrator; w7 for any fixes | small | its gate | 1. the review's cut (no Soup on Shy offers) fixed, with its known-answer test <br>2. the gate passes on the merge commit |
| A1b | **Pot Luck's route,** on wave2b, as logged: <br>1. Two arms on the same 32 seeds at B: (a) save 3 gold before scheduled climbs; (b) Little Dollop raised to match the route's R1–4 step. Alongside them, a constructed R8 Pot Luck board, with gold, shop tier and Belly contents logged (09d). <br>2. If an arm reaches ×1.3, the line file takes it. If not, change one card so it grows active board units (09a, 09h). Nothing that grows Belly insides. <br>3. The two bot fixes that stand: the line's `engine_pieces` protected in `best_belly`, and no split-gap cap for tempo. <br>It lands before A3. | w7. The arms run on the Actions sim job if it's live, otherwise locally (64 lobbies) | small–medium | A1 | 1. Pot Luck grows ×1.3 a round, R8–R14, same cohort (the triage's figure on this read is ×1.222) <br>2. the constructed board shows the line playing the route it was costed on |
| A2 | **Hedgerow light pass** (WIP on wave2b). <br>- Keep a signature that isn't Blood Gems: Dozey's slot clock and the Standing Committee. Keep economy tied to the tribe: the Larder and Mast. <br>- **New (Pot Luck process rule, now in LEARNINGS):** check the line's gold and save rules and its written priority against its paper route, and log gold and shop tier in its line lobbies. <br>- **New:** `recruit_rules.gd` under the cap. It is 1,003 on the tip and 998 on the trial merge, so count it on the merged tree. <br>- The `BotHedgerow.aim` early return goes at the top of `BotAim.best_slot`, as logged. | w7 | medium | A1 | 1. a fresh reviewer finds a signature that isn't Blood Gems <br>2. its line grows ×1.3 a round, same cohort |
| A3 | **Neutrals.** Change Ballooning Spider, Charcoal Burner and Whirligig Beetle. Decide Pipistrelle Echo by the brief's rule. Add Shieldbug and Click Beetle, with art from S7. **Once this merges, the pool is settled.** | w7 | medium | A1b, A2 | 1. text equals behaviour, with a known-answer test per changed card <br>2. each card meets its stated role |
| A3.5 | **Set B and C from realized boards** (below) | step 0: the paper workflow, then w7. Runs: w6 on Actions | small–medium | step 0; the sim job; the contamination drop (S3); A3, or A1 and A1b for run 1 (open call C1) | 1. each tribe's engine line at R12 is within 0.75–2× of its preset's target <br>2. lobby growth is ×1.3+ a round, R8–R14, same cohort, on both presets |
| A4 | **Step 5 measurement** on the checkpoint config, on Actions: <br>- the 150+ line lobbies each for B and C; <br>- field fights at R6–16 (DM2's first read); <br>- designed setups: Granny regenerated on pass 3 Oozes, the Whistlers, and each tribe's carry against a board with one answer; <br>- the damage table (with `replay_starting_belly_survivors` on and off, as logged); <br>- 200 games of the reworked soak; <br>- throwaway B and C libraries for the checkpoint testers. <br>**Only if the same lobbies give them for free:** the splash audit and the line gate. Otherwise they wait. <br>Reported per line: the R6–R11 and R11–R15 medians, the share of seats alive, and the order-of-magnitude read at R14 and R15. <br>**The report states A3.5's method and assumptions** (09a; open call C8). **Then tell the owner plainly whether the scale problem is fixed.** | w6, Actions | medium | A3.5, S4's soak rework | 1. checkpoint criterion 2: growth ×1.3, R8–R14, same cohort <br>2. none of v3's three extreme misses (any found are triaged before A5) |
| A5 | **Checkpoint 1.** 3 reward-lens cloud testers play blind against the strong field, 1 game per variant, in an assigned order (XY or YX). Each named moment is checked against the logs (the fun-probe method). Pick the default. Cut back dial by dial, at the outlier (w7). | cloud testers; a workflow checks the moments | medium | A4, S5a, W-c | 1. felt progress at a log-checked moment <br>2. growth ×1.3 |
| A6 | **Build 8 export** (§5). The default library is recaptured first. | w6 | small | A5, w5's preset setting, the memory budget, S7, the game-log hook | §5's checks |
| A7 | **Round 6.** 4 fresh cloud testers, one per non-reward lens, each play 1 full game of build 8 as defined in §1.7, with renders. The brief carries 09d's line (§1.8). Tally the agreed items, triage the design ones (W-g), then fix them: w7 (content), w5 (UI), w6 (tools). | cloud testers, then the workers | medium, plus medium for fixes | A6, S5's render tool, W-d | each agreed item fixed, or its triaged cause fixed |

#### A3.5 in detail
Generous first (09h): "giving out power overly generously and then dialing it back, rather than starting from too weak and dialing up". The targets are realized medians (DECISIONS 10 Nov: "the realized median of a committed line in real lobbies, not a paper board"). Paper overstates real boards for every tribe, and by different amounts (0.17–0.72× at R12), so runs set the levels and paper only seeds the paths.

0. **Dial check, before run 1 (new).**
   - **What moves today.** The dials that differ between B and C in `rates.json` (wave2b `0b2fcb88`) are:
     - Birds 10, Hunters 9 and Fairies 6;
     - Hedgerow 4 (two are Dozey twins);
     - Oozes 2 (`oozes_elder_share` 0.5→0.75, `oozes_soup_share` 1/8→1/6);
     - **Bog 2: `bog_soak_keep` 2→3 and its golden twin.** The paper presets (`docs/ideation/content/pass3/presets.json`) give Bog that same single dial.

     Oozes need about ×3.4–4.5 at R12. Bog is one of the flat tribes ("Birds: no nerf; the problem is the flat tribes").
   - **Extra dials.** For Bog and Oozes, and for any tribe whose path can't plausibly reach its target, the paper workflow proposes which more engine dials join the path, with B and C values on paper. Bog, for example, has its frog multiplier, kiss period and Hopkin share. w7 checks each one against the card's text. This happens before run 1, so the plan doesn't report "scale not fixed" by construction.
   - **Limits.** w7 states each dial's limit from its card's text, for example a share that can't pass 1, or a period that can't go under 1. Path values are clamped there, and each clamp is logged. Hunters' Glutton and Lodger shares reach 1 at t = 1 and pass it beyond.
   - **Shared dials.** `scale_hero_spell_percent` (B 10, C 20) takes its preset's own value and sits on no tribe's path, because one per-tribe t can't set a dial every tribe shares.
1. **One path per tribe.**
   - d(t) = B × (C / B)^t. Integer dials are rounded up, and the limits from step 0 apply.
   - t = 0 is today's B, and t = 1 is today's C.
   - Each tribe gets its own t for B and its own t for C.
   - The Quilboar run says the biggest lever is the axis that grows a buff's size (freezing gem size cut the BG-text R12 median from 825.5 to 175.5, ÷4.7).
2. **Run 1** (Actions, checkpoint config): 48 line lobbies at t = 0 and 48 at t = 1, with every tribe's committed lines seated across them.
   - It runs on the settled pool, or on the five pass 3 tribes right after A1 and A1b (open call C1).
   - Fit each tribe's engine-line R12 median (same cohort) against t, on a log scale.
   - Solve for the t that reaches 900 (B) and 1,800 (C), and round it up. Whether R15 guards the fit is open call C2.
3. **Run 2:** 48 lobbies each at the new B and the new C. A pass means both deciding criteria hold. If a tribe misses, make one more fit from all its points, then stop. The stop rule is set before the run.
4. **A tribe that responds weakly** (solved t above 2 for B, or above 3 for C) runs at that cap in run 2. If it is still under 0.75× its target, record it and triage it. The Quilboar lesson (no growing size axis) is one hypothesis. Don't raise it further.
5. **Reported beside each tribe:**
   - R15 ÷ R12 and the share of seats alive;
   - whether it flattens after R12. Legacy Bog, Hunters and Oozes flattened (×1.03–1.13 a round), while Birds and Fairies didn't;
   - its field-fight win rate. Stat totals aren't equal power across tribes (`questions.md` Q4).
6. **Ownership:** w6 commits the `content/pass3/rates.json` presets for A3.5 and A4 only, and the file then goes back to w7 for A5's cuts. Step 0's dial list is w7's commit.

**If A4 still reads B far below 900.** "Far below" means the median of the six engine lines' R12 medians is under 600. There is no third raise, since that would be fitting during measurement.
- **If C reads 900 or more:** checkpoint 1 plays C against C+, which is the C path taken one more step (t_C + 1). The old B becomes the fallback. Before A5, one 48-lobby run checks C+ for growth and the three extreme misses only.
- **If C also reads under 900:** hold checkpoint 1. Run the triage skill on "committed lines don't compound by R12", with the Quilboar lessons as hypotheses: a missing size axis, and the step arriving after R12. Tell the owner plainly that the scale isn't fixed yet, and why.

### Track B: the UI (about 3 worker-days)

| Step | What | Who | Size | Waits on | Decides |
|---|---|---|---|---|---|
| B1 | **Batch 1 finish:** <br>1. One fresh narrow cold reader on the `cea9d0e2` reshoots: the Bog fight before and after (Ask 3: pending gains, kisses, Toll), rival 025 and combat 045, after the Pounce and Mire cues. <br>2. The Actions gate on `cea9d0e2`. <br>3. Restore DECISIONS.md's Format line, and carry the worker's note into the orchestrator's own merge entry. <br>4. Merge. It conflicts with nothing live. | a fresh reader; the orchestrator merges | small | nothing | the fresh reader reads the reshot moments right |
| B2 | **Batch 2,** WIP on declutter-b2: tiles, the board, scouting, the reader, and recruit animations. <br>- Fix the failing dense label-budget report. <br>- Bring `recruit_screen.gd` under the cap: it is 1,047 now, and 999 on the A1 merge before b2's additions. <br>- After A1 merges, resolve its 3 files and re-face `ooze_marks.gd`. <br>- After A2, resolve `recruit_layout.gd` and `test_pass2_ui.gd`, and re-face `hedgerow_marks.gd`. Neutral cues come after A3. | w5 | large | B1; A1 for the Ooze marks | 1. words at rest on tiles about 0 (counted) <br>2. a fresh cold reader passes the recruit and scout strips |
| B3 | **Batch 3, trimmed:** the removals 09e requires, the standings sort, the Lobby rules page, and motion only where a removed element needs it. ×4 effect waits scale with speed (logged). Also the preset row and the record. | w5 | medium | B2 | 1. static marks at rest counted and cut <br>2. a cold reader passes the lobby strips |
| B4 | **Batch 4:** the tutorial and the Rules hub screens on w7's data (the Pounce and Mire rules included, as logged), the coach overlay, settings and game-over (spec 2.7), sounds for new cues, and the scripted player's Hard seat. <br>**Tutorial gate:** one fresh cloud first-timer plays the tutorial with `play.sh --tutorial` plus renders (coach slip shown), then one real game. It lists anything it met that neither had taught. | w5, w7's tutorial data, 1 cloud first-timer | large | B3, A3, w7's tutorial data | 1. nothing on that list is a core rule (gold, tiers, triples, freeze, fight order, damage) <br>2. the cold reader passes 3 fights using only the tutorial and Rules pages |

### Join: build 9

| Step | What | Who | Size |
|---|---|---|---|
| J1 | Round 6 fixes, B4 and all art merged. Recapture the default library (always). | w7, w5, w6 | small–medium |
| J2 | **Final evidence on the build 9 tree, in parallel:** <br>- the 2,000-game soak, on Actions; <br>- the field fights and the line-lobby spread on the shipped default, on Actions; <br>- **the Naive check, 300 games: 1 best bot among 7 Naive places top 4 in at least 85% and wins at least 45%** (DM2 checklist, restored); <br>- 20 scripted UI games, run locally; <br>- a pool recount; <br>- the no-set soak check; <br>- a fresh cold reader on build 9's fight strips; <br>- `interesting-designs.md` and its fresh check; <br>- the neutral-economy report, from the soak data; <br>- the visual-tier re-score (reported, 09f). <br>**Placing (a) and (b):** cite build 6's result. If a J2 slot is free, run the existing `xprobe.gd.txt` once instead. <br>On a failure: fix it, then rerun only what the fix touches. | w6, w5, Actions, workflows | medium |
| J3 | Export build 9 (§5). | w6 | small |
| J4 | **Round 7:** 3 fresh reviewers, 2 full games each, starting from the tutorial. Apply the pass rule (§1.8). <br>- **Pass:** done. <br>- **Fail:** fix every agreed item, export build 10, and run round 8 with a new trio. <br>- **Two fails:** triage first. <br>Tell the owner plainly where things stand. | cloud reviewers | medium |

### Where the owner hears plainly how things stand
1. After A3.5's dial check and run 1: which tribes reach their target on their dials, and which need design (09a: "Large amounts of design need to be completely reworked, and that's okay").
2. After A4: whether the scale problem is fixed, with the method and its assumptions.
3. At the build 8 export: the owner can play.
4. After round 6's tally: whether "very good" is in reach.
5. After J4.
6. **Also:** the Quilboar answer, when W-f has the lessons (§6; timing is open call C5).

## 3. Who owns which files

### What the live branches touch today (against `5425c907`)

| Branch | Files outside its own area | Trial-merge conflicts |
|---|---|---|
| A1 merge `53ff356a` | Part 1's core, sim, UI and content files (as in v2's wave2b row, without Hedgerow) | none with main or batch 1. With b2: 3 files (`recruit_screen.gd`, `recruit_view.gd`, `card_view.gd`). With the faster suite: 2 core tests. |
| wave2b tip `0b2fcb88` | the above, plus Hedgerow: `hedgerow_marks.gd`, `lines/hedgerow.json`, `bot_brain.gd` (`BotHedgerow.aim`), `recruit_rules.gd` | with main: 4 (`engine.md`, `bot_brain.gd`, `combat_unit.gd`, `check_units.py`). With b2: 5. With the faster suite: 3–4 tests. |
| declutter `cea9d0e2` | `ui/adapter/core_port.gd`, `ui/app.gd`, `settings_screen.gd`, `how_to_play.gd`, `docs/ideation/DECISIONS.md` (the broken Format line) | none |
| declutter-b2 `344a5e75` | `effects.json` (the Pass keyword text), `core/effects/recruit_context.gd` (buff-log fields), rulebook 12.1.6, plus batch 1's files | none with main. With A1: 3. With wave2b: 5. With the faster suite: 3 UI tests. |
| c-gate-shards `e6b9783f` | `ci.yml`, `check.sh`, `CLOUD_SETUP.md`, `tools/checks/test_shards.py`, `test_times.json` | none |
| c-faster-suite `4c572c86` | only `tests/**` (92 files; no `game_config.gd` change yet) | listed above |

**Merge order:**
1. Quilboar: done.
2. A1, which is gating now, and batch 1, after its reader. They don't conflict, so either can go first.
3. Gate shards, whenever. They're clean.
4. The faster suite, right after A1 (open call C11).
5. Batch 2.
6. Then wave2b's Hedgerow (A1b and A2) and the neutrals (A3).

The orchestrator resolves each merge into a worker branch, since the workers refuse merges. Count the lines of every near-cap file on every merged tree: `recruit_screen.gd` 999 and `recruit_rules.gd` 991–998 are the tight ones.

### Who owns what from now on

| Stream | Who | Owns these files, and only these | Starts |
|---|---|---|---|
| **S1: content** | w7, `-balance`, ideation/wave2b | As in v2: `content/units`, `content/spells`, `content/bots/**`, `content/schema/effects.json`, `content/pass3/rates.json` (except during A3.5's runs and A4), `content/tutorial/**`, `content/rules/**`, `src/core/**` (except the files held below), `tests/core/**`, `tools/sim/lines/**`, its own tribe helpers, its tribes' UpsetCombat audit entries, `tools/checks/soak_<tribe>_check.gd`, `check_units.py`, `docs/ideation/content/pass3/**`, and the rule sections of the rulebook. <br>**New:** A1b's line and bot fixes, A3.5 step 0's dial list and limits, and rulebook 4.6.2 if C10 is adopted. <br>It hands `ooze_marks.gd`, `hedgerow_marks.gd` and `recruit_oozes.gd` over to S2 at the A1 merge. | now |
| **S2: UI** | w5, `-tribes2`, declutter-b2 | As in v2: `src/ui/**` (every mark, the Rules hub screens, the coach overlay, the preset row, the preset line in `core_port.gd`, `records.gd`, and the game-log hook), `tests/ui/**`, `evidence/declutter/**`, and b2's three core-side edits. | now |
| **S3: measurement and delivery** | w6, `-sol` | As in v2: `tools/sim/**` (except `lines/**` and w7's helpers), `content/fields/**`, `src/core/field_library.gd`, the `rates.json` presets during A3.5's runs and A4, `export_presets.cfg` (with `content/tutorial/*` and `content/rules/*` added to `include_filter`), `scripts/export_smoke.sh`, `build/*.sh`, and the one export script. <br>**First:** <br>1. drop contaminated trials, failing above 2% (the only follow-up that touches A3.5's numbers); <br>2. the export script (build number, commit, README, certificate, library SHA); <br>3. the memory budget. <br>**After A3.5:** label low rolls, simplify the seated-line check, and store per-seed lists once. <br>**Deferred:** promoting the decoy arm (trigger: J2 needs placing (b) as a run). The Quilboar bar check is done (§1.13). | now (Quilboar is in) |
| **S4: sim job and soak rework** | the sharding session, after sharding | `.github/workflows/sim.yml`, `tools/checks/soak.gd`, `soak.sh`, `soak_plant.sh`, `soak_content.gd`, `soak_bot.gd`, `soak_coverage.gd`, `soak_seed_trace.gd`, `soak_copy_check.gd`, and their tests. Not the per-tribe checks. <br>The order is open call C3: the sim job first is recommended, since A1b and A3.5 need it and only A4 needs the soak. <br>**Done when:** the sim job takes a pushed config and commits its results back; `soak.sh N --preset P [--library L]` plays N real `full_game` lobbies at the v2 mix; synthetic cards run only behind a flag; and 200 games on today's tree show 0 violations. | after sharding merges |
| **S5: play tools** | 1 cloud session | `tools/play/**` and `src/ui/game_record_log.gd`. <br>- S5a: `new --variant X\|Y`. <br>- The render tool. <br>- Tutorial mode. <br>- The game-log writer (kept, §1.11). | now; S5a before A5, the render tool before A7 |
| **S7: art** | the orchestrator runs `tools/art/run-codex-image.sh`, and a local workflow writes the prompts | 15 images: the 12 pending units, Golden Egg, Shieldbug and Click Beetle. | now |
| **S8: decisions and briefs** | local Claude workflows, no Godot | Drafts go in scratch only. The orchestrator commits. <br>- **W-a:** §1 and §4 (with the 6 Nov text beside each change), plan-interrogate, then the log. <br>- **W-b:** the Pot Luck triage. Done (ff0fe759). <br>- **W-c:** the checkpoint brief. <br>- **W-d:** the round 6 and verdict briefs: §1.7, §1.8 with 09d's line, per-tribe "re-skin?" questions, decisions by round range, placing (c) as a question, early flex, and the slow early game. <br>- **W-e:** `interesting-designs.md`. <br>- **W-f, the Quilboar lessons (concrete):** <br>  - trigger: `reference/quilboar/lessons.md` exists; <br>  - read it with the three skeptic checks; <br>  - change §6 and this plan only where they differ; <br>  - write the owner's answer in plain words (timing: C5); <br>  - route each lesson to its tribe's design step, to LEARNINGS, or to the owner's list. None becomes a new deciding criterion. <br>- **W-g:** triage round 6's agreed items, plus any owner game logs that have arrived. <br>- **W-h:** the tallies. <br>- **W-i** (only if C6 is adopted): the early-rounds triage. <br>- **The paper workflow** (A3.5 step 0): the extra dials, with B and C values. | now |
| **S10: faster suite** | its cloud session | per its brief; pushed at `4c572c86` | merges after A1 (C11) |
| **Orchestrator** | n/a | Merges, Actions relays, and the main guard: <br>- check that `origin/main` is still `156e8c11` after every cloud session; <br>- every brief says "never push main, open no PR"; <br>- **new:** every worker brief says "don't edit DECISIONS.md; put notes in evidence"; <br>- ask the `portal/main` session for a per-workstream playtest link (fallback: PLAYTEST.md in each build folder). | now |

**Godot:** workers run Godot only through the two-slot wrapper. Gates run on Actions, and sims and soaks run on the Actions sim job. The test-suite sessions own `check.sh` and `ci.yml`. S1 and S4 merge ideation/main in before gating.

## 4. Done means: what to rewrite
Each criterion has at most two deciding criteria (09i). The rest is a checklist (facts or tests that must hold) or is reported, and a reported item is triaged only on an extreme miss. W-a writes all of this before A4's numbers exist, and keeps the 6 Nov text beside each change, so that meeting "every Done means criterion" can't be confused with redefining them.

### The 6 Nov text beside each change

| # | 6 Nov sharpened text (quoted) | v3 | Kind |
|---|---|---|---|
| 1 | "each lobby uses all six unless measured shop thinness justifies rotation" | five of six tribes per lobby (DECISIONS 8 Nov, "Commit review B", item 7) | logged 8 Nov |
| 1 | "No filler stat-line units unless a reviewer would call it a deliberate vanilla body" | 0 units without rules text (counted), plus a final reviewer's line | loosening, §1.12 |
| 1 | "2,000-game soak with rules checks, 0 violations, 0 crashes" | kept, on S4's mix, plus "no unit without a set appears" | tightening |
| 2 | "At least 5 distinct strategies … each win 6–25% of lobbies they appear in. Nothing above 25%." | field fights at R10, R12 and R14 decide. The band is reported | loosening, §1.12 |
| 2 | "1 best bot among 7 Naive places top-4 at least 85% and wins at least 45%" | **kept, as a checklist item at J2** | unchanged |
| 2 | "The current best bot clearly beats the previous best head to head on fresh seeds" | dropped | loosening, §1.12 |
| 2 | placing (a), (b) and (c) | all three reported. (c) is a verdict-brief question | loosening, §1.12 |
| 2 | "Reviewers who played: a real decision on most turns, and they found at least 3 builds that felt different" | **kept as written.** "They" is the reviewers together, and decisions are asked by round range | unchanged |
| 3 | "Every tribe has at least one signature mechanic Battlegrounds doesn't have. Every tribe has some economy … Reviewers don't call it a re-skin." | an evidence file with a fresh check against `docs/research/battlegrounds/`; no tribe called a re-skin by 2+ final reviewers | the re-skin part is a loosening, §1.12 |
| 4 | "One strength … 'How far can I get' shows as a visible record" | kept, plus the default-opponent call | unchanged |
| 5 | "20 scripted full UI games at phone and PC sizes without a crash or a layout failure"; "Fights read clearly … who hits, what triggered, why it died" | kept, plus the script's own depth bar, a fixed slot table and a cold reader | tightening |
| 6 | "Windows and Android builds on the portal, each with a README.txt, and PLAYTEST.md" | kept, plus the tag, the library SHA and `latest` | tightening |
| 7 | "Three fresh reviewers who each played full games say "very good for a playtest", with their agreed items fixed" | kept, plus §1.7's definition and §1.8's pass rule (no counted agreed item left) | tightening, with 09d's filter |

### The criteria

**1. Whole game.**
- **Checklist:** the pool count on the build 9 tree, and 0 units without rules text.
- **Deciding:**
  1. 2,000 real `full_game` lobbies on the build 9 tree (S4's mix, on Actions): 0 violations, 0 crashes, and no unit without a set appearing.
  2. The 20 scripted UI games (shared with item 5) pick a hero and play 8-player games to game over.
- **Reported:** one line from a final reviewer on filler units.

**2. Depth.** 09d: "rely far more on empirical simulation data than on observational bot play"; "I don't want you to force it". 09c: tribes "the same order of magnitude".
- **Deciding:**
  1. **Field fights at R10, R12 and R14**, on the shipped default preset. Each committed line's boards from that round, plus each tribe's designed strong board, fight the round's field, with placer layouts and both orientations.
     - It passes when at least 5 lines from at least 4 tribes beat the field in 40%+ of fights at R12 or R14, and no line or designed board beats it in 80%+ at both R12 and R14.
     - The 80% cap was checked on the Quilboar archives (§1.13), and its fallback is the order-of-magnitude read.
     - First read at A4, where a miss is cut at the outlier dial. Decided at J2. The bar never moves.
  2. **Reviewers:** most final reviewers report a real decision on most turns, and **together they found at least 3 builds that felt different.** Decisions are asked by round range (R1–5, R6–10, R11+). The ranges are reported, and "most turns" overall decides.
- **Checklist:** the Naive check (J2): 1 best bot among 7 Naive places top 4 in at least 85% of 300 games and wins at least 45%.
- **Reported:**
  - line-lobby firsts (the 6–25% band);
  - answers against carries, and distribution against totals;
  - placing (a) and (b), from build 6 unless rerun (an extreme miss is an interval that includes 0);
  - placing (c), from the verdict brief;
  - decisions in R1–5. If round 6 agrees they're thin, W-g triages it (see C6).

**3. Interesting.**
- **Deciding:**
  1. `evidence/interesting-designs.md`, from shipped content. For each tribe: its signature, the nearest Battlegrounds analogue and why it differs, and an economy card tied to the tribe's own action (02h). A fresh reviewer checks it against `docs/research/battlegrounds/`.
  2. No tribe is called a re-skin by 2+ final reviewers. The brief asks about each tribe by name.
- **Reported:** tribe gold against neutral gold (the 02h risk), and Quilboar absent from the pack.

**4. Bots.** One strength (08a, 08b), and the dealt lines are the flavours (8 Nov).
- **Default-opponent call:** the strong field is the default on the default preset, if two things hold:
  - a field start adds at most 300 MB of peak memory over a normal start, on the Linux export;
  - the library loads from the APK and Windows packs, and fails loudly when missing.

  Otherwise the default is normal Hard lobbies, and the call is logged.
- **Deciding:**
  1. The build 9 export's default opponents are as called above, with the library SHA in the README and the library in the pack listing.
  2. The record (best placement and wins, default settings only) shows on the main menu and at game over, on build 9 screenshots at both sizes.
- **Reported:**
  - "were the opponents worth beating" (an extreme miss is most reviewers saying pushovers);
  - distinct dealt lines.
  - PLAYTEST says the rivals replay strong games and don't react to the player (the owner's 09a ghost question).

**5. Release feel.**
- **Checklist:**
  - one theme;
  - `portraits_pending.json` empty and `test_portraits` passing;
  - a sound for each new cue, unheard, and PLAYTEST says so;
  - the tutorial;
  - the Rules hub covering every keyword in the pool;
  - settings;
  - game over;
  - no dev tools in exports.
- **Deciding:**
  1. 20 scripted UI games on the build 9 tree, 10 at 1920×1080 and 10 at 1688×780: 0 crashes, 0 layout failures, and phone text at least 31.
     - The script's own depth bar applies as written: 10 games reach turn 12, 3 reach turn 15, one is won, 3 ghost fights happen, and tiers 5 and 6 are reached.
     - The scripted player is Hard.
     - The slot table is fixed before the run: at least 10 games at default settings, and the rest in lobbies chosen to reach the late game. There is no fallback bar.
  2. A fresh cold reader passes build 9's fight strips at batch 1's bar: who hits, what triggered, and why it died.

**6. Delivered.**
- **Deciding:**
  1. The build folder holds `Bramble.apk`, `Bramble-windows.zip` and `README.txt`.
     - README line 1 has no parentheses.
     - It names the commit tag and the library SHA.
     - `latest` points at the folder, and the portal's `/builds` lists it.
  2. PLAYTEST.md matches that build, is frozen at its commit, can be reached from the portal, and says no real device was tested.

**7. Agreed.**
- **Deciding:**
  1. 3+ fresh reviewers each play 2 full games of the build as defined (§1.7), and say "very good for a playtest".
  2. No problem is raised by 2+ of them (§1.8, with 09d's filter and C4's definition), and round 6's agreed items are fixed.

**Checkpoint 1:** keep its two criteria. Criterion 2 is read on the same cohort (§1.14). W-c fixes the brief.

## 5. Builds, in order

| Build | When | Contents | Checks | Played by |
|---|---|---|---|---|
| 8 | after A5 (held for batch 2 if it merges within 24 h) | - the settled pool and A3.5's dials, with A5's cuts <br>- the default library, recaptured last <br>- strong field on the default preset (if within the memory budget) <br>- the preset setting <br>- the declutter batches merged so far <br>- the 15 portraits <br>- owner game logs <br>- PLAYTEST for build 8 | - export smoke: library required, Quilboar absent <br>- the memory budget <br>- Wine and Linux boots <br>- certificate match <br>- a 200-game soak <br>- a 4-game UI run | the owner; round 6 |
| 9 | after J2 | round 6 fixes; batches 1–4, the tutorial and the Rules hub; the record; the library recaptured | all of J2 | round 7 (the verdict) |
| 10 and on | only if a verdict round fails | every counted agreed item fixed | rerun what the fixes touch; recapture the library | a new fresh trio |

Every export:
- runs the one export script;
- is tagged `ideation-build-N`;
- has README line 1 "Ideation build N: ...";
- repoints `latest`;
- gets a delivery evidence file;
- gets a status-block update.

## 6. What the Quilboar reference has taught us
This comes from the facts, the lesson drafts and their three skeptic checks. W-f confirms it against `lessons.md`. The owner asked: "What have we learned from it? And does it help us improve any of our processes or challenge any of our assumptions?" A lesson that changes a tribe goes through that tribe's design step, and none becomes a new deciding criterion (09i). All of this is bot data from 100–150 lobbies an arm. The native seats ran fixed rates: Birds and Fairies in pass 3, the other four on legacy profiles, with the broad Busker guard on.

**What we learned about the game**
1. **Our engine can reach Battlegrounds' size.**
   - BG-text Quilboar reaches 747–825 at R12, which is 0.98–1.09× Battlegrounds' September 2025 mean (1.2–1.4× mean against mean).
   - The bot is thin early and finds Hogrider late, so that figure is a floor.
   - So the gap is in our dials and content, not the engine. → A3.5.
2. **Quilboar at its own C dials is about half its BG-text board at R12** (C ÷ uncut 0.51 at R12 and 0.44 at R15; B ÷ uncut 0.33 and 0.25).
   - This is the port's own C. Our tribes' C was never tested, so it doesn't prove our C is stingy.
   - It does say that "overly generous" on paper may not be generous on the board. → the C against C+ branch. Testers may prefer C.
3. **Scale arrives as a step.**
   - BG text goes 140 → 747 → 2,494 from R11 to R13, and at B's dials 109 → 259 → 811 → 1,341 by R14.
   - After the step it still compounds (×1.65–2.13 at R14).
   - Our lines step earlier and smaller: Birds at R10, the legacy four at R8–R10, and Fairies at R15.
   - An R12 read gets the order wrong in B and frozen, though not in C or uncut. → R12 and R15 both (§1.14), and C2.
4. **The third axis carries the lead.**
   - Freezing gem size cut the BG-text R12 median ÷4.7, and R15 ÷9.6.
   - None of our tribes grows its buff size additively. Fairies' Ring size is closest.
   - This is one tribe, so it doesn't generalise to "any additive tribe". → A3.5's weak-response rule, as one hypothesis.
5. **Legacy Bog, Hunters and Oozes flatten after R12** (×1.03–1.13 a round). Birds and Fairies don't, and Fairies speed up. → A4 reports same-cohort R12–R15 growth for the pass 3 lines.
6. **Equal totals aren't equal power.** At equal totals the wide gem board wins only 18–25% of fights, against a 0.45–0.50 baseline. 09d says the same: "Distribution of stats beats the total". → DM2 decides on fights.

**What it says about our process**

7. **The lobby-median growth bar can't see a dominant tribe.** One Quilboar seat moved it 0.01–0.05. Plan v3's two per-line extreme misses already exist, and the fix is reading them at R14–R15 with a named population. → §1.13 and §1.14.
8. **Check a bar on a known case before it decides.** → §1.13. Done from the archives.
9. **Paper ranks roughly, and runs set levels.**
   - The B→C size step tracked paper at 81–94% on a log scale.
   - The frozen dial missed by 1.6×, so paper's ranks are only a seed. → A3.5 fits each tribe's slope from runs.
10. **Flex and pivots are partly measurable.** The engine has an unpinned Hard that re-picks its build until R9, and H1 pinned it (check-questions F12). The early-flex lesson (09f: "Early units should be somewhat flexible as well as enabling") stays a round 6 question. An unpinned-Hard arm can be reported if one is ever needed.
11. **The designed setups D1, D4 and D5 never ran.** The check corrects the draft here: stopping the reference's sim work was a logged choice (Ask 3, 09i), not an error. So running them reopens that call. → C9.
12. **New: the T6 upgrade cost drifted.**
    - Rulebook 4.6.2 says 11, while `game_config.gd` and `full_game()` use 13.
    - Every pass 3 paper model copied 11, so paper R12 sits about 7% high.
    - Realized targets were measured at 13. → C10.
13. **New, the assumption it challenges** (the owner's "challenge any of our assumptions"), corrected by check-process §7:
    - `power-budget.md` prices each effect alone and sums them ("Linear growth only"). The doc says so itself, and it was never run on this content.
    - The measured part: axes multiply. Freezing one cut the board ÷4.7.
    - Its fixed reference of 2 free plays a turn at T5–6 sits below the paper line's 3–6 Choose One plays a turn.
    - → The input for budget v2, deferred as plan v3 says. Goes in the owner's answer (C5).

## 7. Risks
- **The pass rule can loop.** Every counted agreed item means a new build and a new trio, and no report has said "very good" yet (0 of 17). Round 6, the triage, 09d's filter and C4 exist to empty the list before round 7. Budget for one failed round.
- **A3.5's lever.** The dial check fixes the path's shape, but a tribe may still respond weakly. That is recorded and triaged, not forced (09d).
- **A3.5 can overshoot into snowballs.** That's allowed under generous first. A4 triages the three extreme misses, and A5 cuts at the outlier.
- **R12 is noisy because the step sits there.** Read R12 and R15 on the same cohort.
- **The same-cohort read is stricter.** Pot Luck reads ×1.222 on it, not ×1.251, and checkpoint criterion 2 may fail where a survivor read would pass. That's the honest read, and the bar doesn't move.
- **The F9 check is a stand-in** (lobby opponents, not the field). The fallback is the order-of-magnitude read.
- **Memory on Android.** Untested on a device. If the budget can't be met, the default is normal Hard lobbies.
- **Review throughput.** About 15 merges, each with a scope review and an Actions gate. Batch the small tooling merges.
- **Near-cap files at merges:** `recruit_screen.gd` (1,047 on b2, 999 on A1), and `recruit_rules.gd` (1,003 on wave2b, 998 merged). Count lines on every merged tree.
- **Workers editing orchestrator files.** `cea9d0e2` broke DECISIONS' Format line. Briefs now forbid it.
- **Test conflicts from the faster suite** across A1, b2 and wave2b. One resolution after A1 (C11).
- **Blindness at checkpoint 1 is on the honour system.** The mapping stays out of the brief.
- **Claude budget.** About 14 cloud sessions, plus 3 contingent. Scope reviews, cold readers, tallies and the W workflows cost Claude too (C7). If the owner says the budget is out, round 6 drops to a render-only screen check by a local workflow, and the verdict rounds keep their trio.
- **Main.** Cloud sessions start on main with admin rights. The guard check runs after each one.

## 8. Critique calls (`evidence/plan-to-done/critic.md`), updated

| # | Critique item | Call | Reason (v3 changes marked) |
|---|---|---|---|
| 1 | Verdict doesn't meet the /goal; pass rule contradicts DM7 | **Adopt, adapted** | Taken: the render tool, the logged meaning of "played the latest build", 2 full games, and "no item raised by 2+". A fresh tally agent defines "the same problem", and the tutorial gate uses `play.sh --tutorial` with renders. **v3:** 09d's line goes in the briefs and the tally, and the definition of "problem" is C4. |
| 2 | Nothing closes the scale gap; no branch if B stays low | **Adopt** | A3.5 slides each tribe along its own B→C path, with two runs and a stop rule. There is a C against C+ branch if B is under 600 at A4. **v3:** step 0 first gives Bog and Oozes enough dials, sets limits, and keeps shared dials off the paths. Run 1's timing is C1 and R15's role is C2. |
| 3 | DM2 rewrite goes against 09c, 09d and v3, and is read too late | **Adapt** | Field fights at R10, R12 and R14 decide, first read at A4. The band is loose and only blocks dominance. **v3:** the 80% cap is checked on F9 from the archives, with the order-of-magnitude read at R14–R15 as its fallback (not lobby firsts). The reviewers' 3 builds are counted together, and the Naive bar is a checklist. |
| 4 | Ownership table false; merge order | **Adopt the table, reject the order** | Rebuilt from trial merges at the live tips (§3). **v3:** Quilboar is done. A1 is gating and batch 1 needs its reader, in either order. The faster suite goes after A1 (C11), then batch 2. |
| 5 | Library order, two libraries, soak arguments, Android memory | **Adopt, simplified** | Recapture last, with the SHA in the README. The soak takes preset and library arguments. The memory budget is 300 MB. One library only. |
| 6 | §1.3's reason partly wrong (local cap) | **Adopt** | Two local Godot slots still bind, so lobbies, soaks and captures run on Actions. |
| 7 | Claude budget | **Adopt** | The Actions sim job. S5b and S6 move to w5, and S9 to w7. Round 6 has 4 testers. About 14 sessions, plus 3. **v3:** the workflow cost goes in §7 (C7). |
| 8 | Loosenings with no reason | **Adopt** | The UI-run depth bar is kept whole, and the slot table is fixed before the run. **v3:** the list is complete: the band, placing (c) and the re-skin rule were added, and the Naive bar is restored. |
| 9 | v2 step 4 items missing | **Adapt** | Owner game logs adopted. Answer-buying bots dropped, with a reason. **v3:** W-g reads the logs (§10). |
| 10 | Triage round 6's design complaints | **Adopt** | W-g runs the triage skill before any fix. |
| 11 | Build 8 for the owner; track B estimate | **Adopt** | Build 8 waits for batch 2 if it merges within 24 h of A5. Track B is about 3 worker-days. |
| 12 | Stale steps | **Adopt** | **v3:** refreshed again at about 11:00. Quilboar is merged, A1 is gating as `53ff356a`, B1 owes one reader, b2 has batch 1, and the faster suite is pushed. |
| 13 | DM3 grades the agents' own work | **Adopt** | A fresh reviewer checks `interesting-designs.md` against `docs/research/battlegrounds/`. |
| 14 | Smaller J2 items | **Adopt, one adapted** | The recount, the no-set soak check and the visual-tier re-score are in, and the UI-game slots are set before the run. **v3:** placing cites build 6 unless a slot is free, and the Naive check is added. |
| 15 | Portal playtest link | **Adopt** | A per-workstream link, with the build folder as the fallback. |
| 16 | Main guard | **Adopt** | `origin/main` = `156e8c11` after every cloud session. |

## 9. Interrogation v2: what was applied

| Item | Verdict | Where in v3 |
|---|---|---|
| Must-fix 1: DM2's "each found 3+ builds" | applied | §4 DM2 deciding 2 ("together") |
| Must-fix 2: the Naive bar and unlogged loosenings | applied | Naive in DM2's checklist and in J2. The band, placing (c) and the re-skin rule are logged (§1.12). The 6 Nov text sits beside each change (§4 table). |
| Must-fix 3: 09d in briefs and the tally | applied | §1.8, W-d, A7 |
| Must-fix 4: A3.5's lever for the flattest tribes | applied, plus one addition | A3.5 step 0. Added: shared dials (`scale_hero_spell_percent`) are kept off the per-tribe paths. |
| Must-fix 5: §1.13 can't run on Actions; its fallback | applied, with a caveat and a named fallback | §1.13 (see §10) |
| Must-fix 6: A1 against the Pot Luck call | applied | A1 rewritten. A1b added, lands before A3. |
| Shrink: S3's four harness follow-ups | applied | only the contamination drop comes before A3.5 |
| Defer: decoy-arm promotion | applied | S3 "Deferred" |
| Shrink: A4's reported bundle | applied | splash audit and line gate only if free |
| J2 extras: keep only the cheap ones | applied | placing from build 6; neutral economy from soak data |
| A2: add the Pot Luck process rule | applied | A2 |
| Defer: owner game logs | **not applied** | §10 |
| Asks 1–8 | open | C1–C8 in §11 |

## 10. Not applied

| Item | Interrogator's verdict | What v3 does instead | Why |
|---|---|---|---|
| §1.11a, owner game logs | Defer. Trigger: a step needs strong-player boards, or the owner sends games. | Keeps them, and names W-g as their reader. This is the interrogator's own stated alternative. | The deferral's trigger can't work after the fact. Build 8 is the owner's first play at the new scale, and a game that wasn't logged can't be recovered when a step later needs it. 08a: "I suspect that human players will find stuff the bots haven't". The cost is small: S5's writer and a w5 hook. |
| Must-fix 5's fallback | "Replace its fallback", with nothing named | Names the order-of-magnitude read (best ÷ median of the others, same cohort, R14 and R15, at 10×) as the fallback, and logs F9 as a stand-in. | F9 is fights against lobby opponents, not the strong field DM2 uses, so on its own it doesn't fully check the bar as specified. The order-of-magnitude read is the one other read that flags uncut Quilboar without flagging our lines (check-bars §19–20). This changes nothing that blocks. |
| Refresh: "B1 … What's left is the Actions gate and the merge" | a fact in the refresh | Keeps one fresh narrow reader in B1 | DECISIONS ("fourth cold reader"): "After the fixes, one narrow reshoot … goes to a fresh reader before the merge". `9649747c`'s reader came before the Pounce and Mire cues, and the follow-up note says "No new cold reader/scorer or full gate was run." |

## 11. Calls the orchestrator still has to make

- **C1 (ask 1), A3.5 run 1 timing.** Run it right after A1 and A1b on the five pass 3 tribes, with run 2 after A3 as the confirmation. Recommend: adopt. The owner gets a per-tribe answer days sooner, and it costs only Actions time.
- **C2 (ask 2), the A3.5 fit and R15.** Fit on R12. In run 2, a tribe whose same-cohort R15 median is over 3× the median of the other tribes' R15 medians steps its t back halfway (Fairies is the likely case). Recommend: adopt.
- **C3 (ask 3), S4's order.** The sim job first, then the soak rework. Recommend: adopt. A1b and A3.5 need the sim job, and only A4 needs the soak.
- **C4 (ask 4), what counts as a "problem" in the tally.** An agreed item counts if at least one reviewer who raised it says it should change before this playtest. Other agreed items go in PLAYTEST as known issues. Recommend: adopt, logged as a reading of DM7's "agreed items fixed", so the pass rule can end.
- **C5 (ask 5), the owner's Quilboar answer.** Send it in the next status update after `lessons.md` lands, not at "the next status report", and include §6 item 13 in its corrected, narrow form. Recommend: adopt.
- **C6 (ask 6), the early-rounds triage now.** One small local triage workflow (W-i) on the existing reports and logs (playtest-3 #3, pt4-b, the fun probe), with no new sims, after A3.5 run 1. Its fix waits for round 6 to confirm. Recommend: adopt.
- **C7 (ask 7), counting the Claude cost of workflows.** Add a rough count to §7: about 15 scope reviews, about 6 cold readers, 3 tallies, and W-a to W-i. Batch the small tooling merges into shared scope reviews. Recommend: adopt.
- **C8 (ask 8), A3.5's method and assumptions in the A4 report** (09a). Recommend: adopt.
- **C9, the D1, D4 and D5 designed setups from the Quilboar lessons.** Recommend: don't run them now, since stopping the reference's sim work was a logged choice (09i). Reopen if round 6 agrees on early flex or wide against tall.
- **C10, the T6 upgrade cost** (rulebook 11, code 13). Recommend: the rulebook follows the code (13), since every realized target was measured at 13. w7 edits 4.6.2, and the paper models note the 7%.
- **C11, when the faster suite merges** (`4c572c86`, tests only). Recommend: right after A1, with its cloud session resolving the 2 Ooze test conflicts. b2 and wave2b then take it in when they next merge main.
- **C12, gate shards** (`e6b9783f`, gate passed, merges cleanly). Recommend: run its scope review and merge it now, so the sharding session can start S4.
