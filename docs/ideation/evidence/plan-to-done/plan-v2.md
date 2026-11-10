# Plan to Done, v2 (10 Nov 2026)

Basis: plan v1 (`plan.md` in this folder), its critique (`critic.md`), the seven gap notes, and the repo: ideation/main at `3cfd1f0c`, with the live branches checked by `git diff --stat` and a trial `git merge-tree` (§3). The goal, in the owner's words: "run continuous iterative development as the plan says, deciding everything yourself. The goal is met only when every "Done means" criterion in docs/ideation/PLAN.md is met with evidence, at least three fresh independent reviewers who each played the latest build judge it very good for a playtest, and that build is exported to /data/bramble-builds/ with latest pointing at it. Never merge anything into main."

## In short
- **The scale gap gets its own step (A3.5).** Before the big measurement, presets B and C are set from the boards the game really produces, not from paper. The Quilboar copy shows our engine can reach Battlegrounds' size: about 750 at round 12 with Battlegrounds' own card text. It also shows that our "overly generous" C is only about half of Battlegrounds' scale for that tribe. If B still reads far below 900 after A3.5, checkpoint 1 plays C against a bigger C, and B becomes the fallback.
- **Reviewers play the exported build's own code.** They play by commands on the export's exact commit, with its field library, at default settings. A new render tool then shows each of their turns and fights on the build's real screens, at phone and PC size. The tutorial gate uses the same tools.
- **Depth is decided by two things:** field fights at rounds 10, 12 and 14 (simulation, 09d), and what reviewers report. Bot-lobby win shares become a sanity line. The new fight bar must first flag Battlegrounds-text Quilboar as dominant on the Quilboar archives, or it doesn't decide anything.
- **A pass means no agreed items at all.** Three fresh reviewers say "very good", and no problem is raised by two of them. Anything agreed is fixed in the next build, and a new trio plays that build. Plan for one failed round.
- **The pool track is now the long pole,** at about 5 worker-days. The UI track is about 3: batch 1 took 6.5 hours. Merge order: Quilboar, declutter batch 1, Oozes, then batch 2.
- **Heavy runs go to GitHub Actions.** Three Codex workers write the code. Claude cloud is kept for playtesters and three code sessions: about 14 sessions, plus 3 if a second verdict round is needed.

## 0. Where things stand (checked 10 Nov)

| Branch | Tip | State |
|---|---|---|
| ideation/main | `3cfd1f0c` | Wave 2a in. Realized R12 boards: about 300–400 in B (Oozes lines 262 and 200), against 900. |
| Quilboar squash | `1511dc22` on `3cfd1f0c` | Gating on Actions, with a narrow scope check running. After the merge it is test-only and its sim work stops. |
| ideation/declutter (batch 1) | `a1378361` | Gate passed on `d400831e`. The cut, the three asks and the gaps are fixed in 7 commits since then. Ask 3 isn't in the commits yet: one Bog fight shot before and after, read by a fresh cold reader. |
| ideation/declutter-b2 | `2474292e` (WIP) | Batch 2 started. It branches from `d400831e`, so it lacks batch 1's 7 fix commits; a trial merge shows they merge cleanly. `recruit_screen.gd` is at 1,025 lines, over the 1,000 cap. |
| ideation/wave2b | `85756e5f` | Oozes part 1 has review fixes (`21a65947`, `ba80977e`). A WIP Hedgerow light pass sits on top (`85756e5f`), and so does Slice's portrait. `recruit_rules.gd` is at 1,003 lines, over the cap. The Pot Luck triage is running separately. |
| ideation/c-gate-shards | `e6b9783f` | Sharding the gate (cloud). |
| ideation/c-faster-suite | not pushed | Brief: tests across `tests/**`, plus a test-only knob in `game_config.gd`. |
| origin/main | `156e8c11` | Must stay there. |

Quilboar lessons (`quilboar-lessons/lessons.md`) hadn't landed when this was written. Its drafts had: `bars.md`, `process.md` and `questions.md`. This plan takes their measured findings now, because the bars must be written before A4's numbers exist. §6 lists them. W-f checks them against the final file and changes this plan only where the final file differs.

## 1. Plan changes to log first
These go in one DECISIONS entry, after a plan-interrogate pass by a fresh agent (W-a).

1. **New step A3.5: set B and C from realized boards** (§2, "A3.5 in detail"). It runs after the pool settles and before A4 and any library capture.
2. **The 38 prototype bodies come off the critical path** (kept from v1). `full_game` already excludes them. J2 adds a soak check that no unit without a set appears in a `full_game` lobby.
3. **Checkpoint 1 doesn't wait for declutter batches 2–4.** Its two criteria come from logs, and CLI testers never see the screen. But the build 8 export waits for batch 2 if batch 2 merges within 24 hours of A5's pick, because batch 2 is where most of the words at rest go (about 65 to 0).
4. **Workers and machines.**
   - **Three Codex workers:** w7 (content), w5 (UI) and w6 (measurement and delivery, after Quilboar).
   - **Three cloud code sessions:** sharding (which then adds the sim job and the soak rework), the faster suite, and S5 (play tools).
   - **The local cap is still two Godot processes** (14 GB; more RAM is pending with the owner). So lobbies, soaks and library captures run on Actions, and local Godot runs only targeted tests, renders, UI runs and exports.
5. **Sims and soaks run on Actions.** The sharding session adds a sim workflow, since only cloud sessions can push workflow files.
   - A run starts when a branch `ideation/sim/<id>` is pushed with its config, like the gate. The orchestrator relays pushes for Codex workers.
   - Results come back as a commit on that branch, so nothing depends on downloading artifacts.
   - Actions is free for this public repo and runs up to 20 jobs at once. That saves the owner's Claude budget (CLOUD.md, 7 Nov: "I'm near my Claude budget").
6. **One shipped field library, recaptured last.**
   - Strong field is the default only on the default preset. The other preset uses normal Hard lobbies, so one library is enough.
   - The library is recaptured as the last step before every export, and its SHA goes in the README.
   - A4 captures throwaway libraries for B and C for the checkpoint testers only.
7. **"Played the latest build" means:**
   - the same source commit as the export, tagged `ideation-build-N`;
   - the pack's content hashes and the library SHA match the README;
   - default settings;
   - played by `tools/play` commands, with the reviewer's own turns and fights rendered by that commit's UI at 1688×780 and 1920×1080.

   Each verdict reviewer plays 2 full games, since the sharpened text says "full games".
8. **The pass rule** (DM7): 3+ fresh reviewers say "very good", and no problem is raised independently by 2+ of them.
   - A fresh tally agent decides what counts as the same problem.
   - Every agreed item, blocking or not, is fixed in the next build, and a fresh trio plays that build.
   - Items one reviewer raises go on the owner's list in PLAYTEST.
   - After two failed rounds, run the triage skill before more fixes.
9. **Round 6's agreed design items are triaged before they're fixed** (the triage skill), because 0 of 17 reports so far have said "very good".
10. **Declutter scope is set by "very good"** (kept from v1 §1.6): batch 3 is trimmed, the Rules hub uses still pictures, and the tutorial is as specified.
11. **Approved v2 step 4 items:**
    - **Owner's games logged: adopted** (small). From build 8, each finished game's seed and actions are written to `user://games/`, and PLAYTEST says how to send them. "That is our only strong-player anchor."
    - **"Bots buy an answer when the scout shows a carry": dropped,** with a logged reason. The default opponents replay captured trajectories and can't react to the player. 09d says bots will be "okay at best". Revisit if round 6 agrees the opponents never answer.
12. **Loosenings logged with reasons** (W-a):
    - DM1's "no filler" becomes a count (0 units without rules text) plus a reviewer line;
    - DM2's head-to-head promotion bar is dropped (09d; gains about 0.05 of a place; its floor was already dropped on 8 Nov);
    - placing (a) and (b) become reported, with an extreme miss triaged;
    - the dealt lines stay the "flavours" (logged 8 Nov);
    - checkpoint testers play 1 game per variant, with a second pair only if a tester can't pick (budget);
    - round 6 drops to 4 testers, because checkpoint 1 already covers the reward lens.
13. **A new bar is checked on a known case before it decides** (Quilboar draft, `process.md` §1.1: the accounting gate "could not tell a bad port from a bad model").
    - Before A4, w6 runs DM2's field-fight read once on the Quilboar H1 boards, on Actions.
    - It must flag BG-text (uncut) Quilboar as dominant, and must not flag the frozen arm.
    - If it can't tell them apart, it doesn't decide. The lobby-firsts band then decides instead, because the drafts show it is the only bar that flagged uncut Quilboar.
    - This reads the archives and runs fights. It isn't new reference sim work, which stays stopped.
14. **Growth is read on the same seats** (`bars.md` §1–2).
    - Checkpoint criterion 2, and every growth or late-round read, uses the same cohort: the median over seats alive at R14.
    - The survivor median and the share of seats alive are reported beside it.
    - Why: survivor medians rise because weak seats die (after R12 the survivor median grew 1.36–1.42 a round, while the same seats grew 1.21–1.22).
    - It is a tightening, written before A4's numbers exist.
    - The order-of-magnitude extreme miss is read at both R12 and R15, because a takeoff at R12 is invisible at R12.

## 2. Critical path

Each step names at most two deciding criteria (09i: "Get good at one or two things and then start fixing other issues"). Everything else is reported.

### Track A: the pool and the scale (long pole, about 5 worker-days)

| Step | What | Who | Size | Waits on | Decides |
|---|---|---|---|---|---|
| A1 | **Oozes in.** <br>1. Pot Luck call from the triage. If the cause is the dial level, A3.5 fixes it and no card changes now. <br>2. The orchestrator merges ideation/main in, which brings in Quilboar: 3 conflict hunks in `bot_brain.gd`, `combat_unit.gd` and `check_units.py`. <br>3. `recruit_rules.gd` goes back under the cap. <br>4. Actions gate, narrow scope check, merge. | w7; the orchestrator merges | small | the Quilboar merge | 1. the review's cut fixed, with its test <br>2. each Ooze line grows ×1.3 a round, or the triage logs why A3.5 covers it |
| A2 | **Hedgerow light pass,** already WIP on wave2b. <br>Keep a signature that isn't Blood Gems: Dozey's slot clock and the Standing Committee. <br>Keep economy tied to the tribe: the Larder and Mast. <br>It lands with A1 if it's reviewable within half a day of A1's fixes; otherwise it is its own hand-off. | w7 | medium | A1 | 1. a fresh reviewer finds a non-Blood-Gem signature <br>2. its line grows ×1.3 a round |
| A3 | **Neutrals.** <br>Change Ballooning Spider, Charcoal Burner and Whirligig Beetle. <br>Decide Pipistrelle Echo by the brief's rule. <br>Add Shieldbug and Click Beetle, with art from S7. <br>**Once this merges, the pool is settled.** | w7 | medium | A2 | 1. text equals behaviour, with a known-answer test per changed card <br>2. each card meets its stated role (the reviewer's rule (b)) |
| A3.5 | **Set B and C from realized boards** (below) | w6 (S3) on Actions | small–medium | A3, the sim job, S3's harness follow-ups | 1. each tribe's engine line at R12 is within 0.75–2× of its preset's target <br>2. lobby growth is ×1.3+ a round, R8–R14, same cohort, on both presets |
| A4 | **Step 5 measurement** on the checkpoint config, on Actions: <br>- the line gate; <br>- 150+ line lobbies each for B and C; <br>- field fights at R6–16 (this is DM2's first read, see §4); <br>- designed setups: Granny regenerated on pass 3 Oozes, the Whistlers, each tribe's carry against a board with one answer; <br>- the splash audit; <br>- the damage table; <br>- 200 games of the reworked soak; <br>- throwaway B and C libraries for the checkpoint testers. <br>Reported per line: <br>- the R6–R11 and R11–R15 medians, because the Quilboar run shows scale arrives as a step; <br>- the share of seats alive; <br>- the line gate beside each line's win rate, since mean place hides boom-or-bust. <br>**Then tell the owner plainly whether the scale problem is fixed.** | w6 (S3), Actions | medium | A3.5, S4, the bar check (§1.13) | 1. checkpoint criterion 2: growth ×1.3 R8–R14, same cohort <br>2. none of v3's three extreme misses (any found are triaged before A5) |
| A5 | **Checkpoint 1.** <br>3 reward-lens cloud testers play blind, against the strong field. Each plays 1 game per variant, in an assigned order (XY or YX). <br>Each named moment is checked against the logs (fun-probe method). Pick the default. <br>Cut back dial by dial, at the outlier (w7). | cloud testers; a workflow checks the moments | medium | A4, S5a, W-c | the two approved criteria: 1. felt progress at a log-checked moment <br>2. growth ×1.3 |
| A6 | **Build 8 export** (§5). The default library is recaptured first. | w6 (S3) | small | A5, w5's preset setting, the memory budget, S7 | §5's checks |
| A7 | **Round 6.** <br>4 fresh cloud testers, one per non-reward lens, each play 1 full game of build 8 as defined in §1.7, with renders. <br>Tally the agreed items, triage the design ones (W-g), then fix: w7 (content), w5 (UI), w6 (tools). | cloud testers, then the workers | medium, plus medium for fixes | A6, S5's render tool, W-d | each agreed item fixed, or its triaged cause fixed |

#### A3.5 in detail
Generous first (09h): "giving out power overly generously and then dialing it back, rather than starting from too weak and dialing up". The targets are already realized medians (DECISIONS 10 Nov: "the realized median of a committed line in real lobbies, not a paper board"). Paper overstates real boards for every tribe, by different amounts (0.12–0.72× at R12), so the dials are set from runs, not paper.

1. **One path per tribe.** The paper workflow already gives every engine dial a B value and a C value.
   - Define d(t) = B × (C / B)^t. Integer dials are rounded up, and dials that are equal in B and C stay fixed.
   - t = 0 is today's B and t = 1 is today's C.
   - Each tribe gets its own t for B and for C.
   - The Quilboar run says the biggest lever is the axis that grows the size of a buff (gem size: freezing it cut the BG-text R12 median from 825.5 to 175.5). The B→C path already raises engine rates rather than bodies.
2. **Run 1** (Actions, the settled pool, checkpoint config): 48 line lobbies at t = 0 and 48 at t = 1, with every tribe's committed lines seated across them.
   - Fit each tribe's engine-line R12 median (same cohort, §1.14), on a log scale, against t.
   - Paper ranks the dials and realized runs set the levels. The Quilboar drafts found paper's ratios held to about 10% while its levels were 0.12–0.23×.
   - Solve for the t that reaches 900 (B) and 1,800 (C), and round it up.
3. **Run 2:** 48 lobbies each at the new B and the new C. Pass means both deciding criteria hold.
   - If a tribe misses, make one more fit from all its points, then stop. The stop rule is set before the run, as in the Quilboar H1.
4. **A tribe that responds weakly** (solved t above 2 for B, or above 3 for C) runs at that cap in run 2.
   - If it is still under 0.75× its target, its engine doesn't compound by R12. Record it, triage it with the Quilboar lesson as one hypothesis (no growing size axis), and don't raise it further.
5. **Reported beside each tribe:**
   - R15 ÷ R12 and the share of seats alive;
   - whether it flattens after R12 (the drafts found ×1.07–1.29 a round for legacy native lines);
   - its field-fight win rate.

   Stat totals aren't equal power across tribes: at equal totals the wide gem board won only 18–25% of fights (`questions.md` Q4). So relative power is read from fights at A4, not from totals.
6. **Ownership:** w6 commits `content/pass3/rates.json` presets for A3.5 and A4 only. Then the file goes back to w7 for A5's cuts.

**If A4 still reads B far below 900.** "Far below" means the median of the six engine lines' R12 medians is under 600. There is no third raise, since that would be fitting during measurement.
- **If C reads 900 or more:** checkpoint 1 plays C (as variant X or Y) against C+, which is the C path taken one more step (t_C + 1). The old B becomes the fallback.
  - This keeps generous first, and the testers play at target.
  - Before A5, one 48-lobby run checks C+ for growth and the three extreme misses only.
- **If C also reads under 900:** hold checkpoint 1.
  - Run the triage skill on "committed lines don't compound by R12", with the Quilboar lessons as hypotheses: a missing size axis, and the step arriving after R12.
  - Tell the owner plainly that the scale isn't fixed yet, and why.

### Track B: the UI (about 3 worker-days)

| Step | What | Who | Size | Waits on | Decides |
|---|---|---|---|---|---|
| B1 | **Batch 1 finish:** <br>1. Ask 3's Bog fight shots (pending gains, kisses, Toll) before and after; <br>2. a fresh cold reader on them; <br>3. Actions gate on the tip; <br>4. merge. <br>It conflicts with nothing live. | w5; the orchestrator merges | small | nothing | the fresh reader reads the reshot moments right |
| B2 | **Batch 2,** WIP on declutter-b2: <br>- tiles; <br>- the board; <br>- scouting; <br>- the reader; <br>- recruit animations. <br>First merge batch 1's fixes in (clean), and bring `recruit_screen.gd` under the cap. <br>After A1 merges: resolve the 5 hunks with wave2b (`recruit_screen.gd`, `recruit_view.gd`, `card_view.gd`), and re-face `ooze_marks.gd` and `hedgerow_marks.gd`. Neutral cues come after A3. | w5 | large | B1; A1 for the Ooze marks | 1. words at rest on tiles about 0 (counted) <br>2. a fresh cold reader passes the recruit and scout strips |
| B3 | **Batch 3, trimmed:** <br>- the removals 09e requires; <br>- the standings sort; <br>- the Lobby rules page; <br>- motion only where a removed element needs it. <br>Also the preset row and the record (S5b work moved to w5). | w5 | medium | B2 | 1. static marks at rest counted and cut <br>2. a cold reader passes the lobby strips |
| B4 | **Batch 4:** <br>- the tutorial and the Rules hub screens, built on w7's data; <br>- the coach overlay; <br>- settings and game-over (spec 2.7); <br>- sounds for new cues; <br>- the scripted player's Hard seat (S6 work moved to w5). <br>**Tutorial gate:** one fresh cloud first-timer plays the tutorial with `play.sh --tutorial` plus renders (coach slip shown), then one real game, and lists anything it met that neither had taught. | w5, w7's tutorial data, 1 cloud first-timer | large | B3, A3, w7's tutorial data | 1. nothing on that list is a core rule (gold, tiers, triples, freeze, fight order, damage) <br>2. the cold reader passes 3 fights using only the tutorial and Rules pages (spec §6, item 7) |

### Join: build 9

| Step | What | Who | Size |
|---|---|---|---|
| J1 | Round 6 fixes, B4 and all art merged. Recapture the default library (always). | w7, w5, w6 | small–medium |
| J2 | **Final evidence on the build 9 tree, in parallel:** <br>- the 2,000-game soak, on Actions; <br>- the field fights and the line-lobby spread on the shipped default, on Actions; <br>- 20 scripted UI games, local; <br>- Naive sanity, 300 games; <br>- placing (a) and (b); <br>- a pool recount; <br>- the no-set soak check; <br>- a fresh cold reader on build 9's fight strips; <br>- `interesting-designs.md` and its fresh check; <br>- the neutral-economy report; <br>- the visual-tier re-score (reported). <br>On a failure: fix it, then rerun only what the fix touches. | w6, w5, Actions, workflows | medium |
| J3 | Export build 9 (§5) | w6 | small |
| J4 | **Round 7:** 3 fresh reviewers, 2 full games each, starting from the tutorial. Apply the pass rule (§1.8). <br>- **Pass:** done. <br>- **Fail:** fix every agreed item, export build 10, and run round 8 with a new trio. <br>- **Two fails:** triage first. <br>Tell the owner plainly where things stand. | cloud reviewers | medium |

## 3. Who owns which files

### What the live branches touch today (against `3cfd1f0c`)

| Branch | Files outside its own area | Trial-merge conflicts |
|---|---|---|
| Quilboar `1511dc22` | **Core:** `bot_brain.gd`, `combat_unit.gd`, `game_config.gd`, `game_session.gd`, `player_state.gd`, `recruit_rules.gd`, `recruit_unit.gd`, `recruit_context.gd`, plus new `session_views.gd` and `bot_aim.gd`. <br>**Other:** `effects.json`, `export_presets.cfg`, `tools/sim/bench*.gd`, `check_units.py`, `ui/widgets/tribe_bonuses.gd`. | with wave2b: 3 hunks (`bot_brain.gd`, `combat_unit.gd`, `check_units.py`). None with declutter or b2. |
| wave2b `85756e5f` | **UI:** `card_view.gd`, `card_detail.gd`, `recruit_screen.gd`, `recruit_view.gd`, plus new `recruit_oozes.gd`, `ooze_marks.gd` and `hedgerow_marks.gd`. <br>**UI tests:** `test_followup_tribes56.gd`, `test_fixture_port.gd`, `test_portraits.gd`, `test_pass3_ooze_ui.gd`. <br>**Sim:** `line_brain.gd`, `committed_line_brain.gd`, `upset_combat.gd`, `wave2b_lines.gd`, `lines/oozes.json`, `lines/hedgerow.json`, and the upset audit JSON. <br>**Other:** `check_units.py`, `effects.json`, rulebook, `slice.jpg`. | with b2: 5 hunks (`recruit_screen.gd` 2, `recruit_view.gd` 1, `card_view.gd` 2); with Quilboar: 3. None with declutter batch 1. |
| declutter `a1378361` | `ui/adapter/core_port.gd`, `ui/app.gd`, `settings_screen.gd`, `how_to_play.gd` | none |
| declutter-b2 `2474292e` | `effects.json` (the Pass keyword text), `core/effects/recruit_context.gd` (fields in the buff log), rulebook 12.1.6 | with wave2b: 5, above. These three files merge cleanly. |
| c-gate-shards `e6b9783f` | `ci.yml`, `check.sh`, `CLOUD_SETUP.md`, `tools/checks/test_shards.py`, `test_times.json` | none |
| c-faster-suite (not pushed) | per its brief: `tests/**`, plus a test-only knob in `game_config.gd` | unknown until pushed. It merges ideation/main in before its last measurement. |

**Merge order: Quilboar → declutter batch 1 → Oozes (A1) → batch 2.** Quilboar and batch 1 are ready, and they conflict with nothing except Quilboar's 3 hunks against wave2b. If Quilboar waited, its squash would have to be redone on a moving tip. The orchestrator resolves each merge into a worker branch, since the workers refuse merges. Count the lines of any near-cap file on every merged tree (LEARNINGS, 10 Nov).

### Who owns what from now on

| Stream | Who | Owns these files, and only these | Starts |
|---|---|---|---|
| **S1: content** | w7, `-balance`, ideation/wave2b | `content/units`, `content/spells`, `content/bots/**`, `content/schema/effects.json` (effects, and keyword text on request), `content/pass3/rates.json` (except during A3.5–A4), `content/tutorial/**` and `content/rules/**` (v1's S9 tutorial and Rules data, moved here, after A3), `src/core/**` (except files held below), `src/core/tutorial/**`, `tests/core/**`, `tools/sim/lines/**`, its own tribe helpers (like `wave2b_lines.gd`), its tribes' entries in the UpsetCombat audit, `tools/checks/soak_<tribe>_check.gd`, `check_units.py`, `docs/ideation/content/pass3/**`, rule sections of the rulebook. <br>**Hands over** `ooze_marks.gd`, `hedgerow_marks.gd` and `recruit_oozes.gd` to S2 at the A1 merge, and adds no UI after that: a needed mark goes to w5 as a request. Shared harness files (`line_brain.gd`, `committed_line_brain.gd`, `upset_combat.gd`) take only one-line calls into its helpers. | now |
| **S2: UI** | w5, `-tribes2`, declutter, then declutter-b2 | `src/ui/**`, which covers: <br>- every mark, including the files from wave2b; <br>- the Rules hub screens; <br>- the coach overlay; <br>- the preset row in `settings_screen.gd`; <br>- the preset line in `core_port.gd` (strong field on the default preset only); <br>- `records.gd` (the record counts default settings only); <br>- the hook for the game log. <br>Plus `tests/ui/**` (including the decision code in `player_driver.gd` and the slot table in `full_ui_run.sh`), `evidence/declutter/**`, and b2's three core-side edits listed above. | now |
| **S3: measurement and delivery** | w6, `-sol` | `tools/sim/**` (except `lines/**` and w7's helpers), `content/fields/**`, `src/core/field_library.gd` (load cost and the memory budget), `content/pass3/rates.json` presets during A3.5–A4, `export_presets.cfg` (including adding `content/tutorial/*` and `content/rules/*` to `include_filter`), `scripts/export_smoke.sh`, `build/*.sh`, and the one export script. <br>**First:** <br>1. the harness follow-ups (drop contaminated trials, failing above 2%; label low rolls; simplify the seated-line check; store per-seed lists once); <br>2. promote the decoy arm into `tools/sim`; <br>3. the export script (build number, commit, README, certificate, library SHA); <br>4. the memory budget; <br>5. the bar check on the Quilboar H1 boards (§1.13). | after the Quilboar merge |
| **S4: soak rework, then the sim job** | the sharding session, after sharding | `.github/workflows/sim.yml`, `tools/checks/soak.gd`, `soak.sh`, `soak_plant.sh`, `soak_content.gd`, `soak_bot.gd`, `soak_coverage.gd`, `soak_seed_trace.gd`, `soak_copy_check.gd`, and their tests. Not the per-tribe checks. <br>**Done when:** <br>- `soak.sh N --preset P [--library L]` plays N real `full_game` lobbies; <br>- the mix is about 60% on the default preset, 20% on the other, and 20% with a field seat, and field seats are skipped and counted when there is no library; <br>- synthetic cards run only behind a flag, counted separately; <br>- 200 games on today's tree with 0 violations. | after sharding merges; needed before A4 |
| **S5: play tools** | 1 cloud session | `tools/play/**`, plus the new `src/ui/game_record_log.gd`. <br>**S5a:** `new --variant X\|Y`, mapped to presets outside the tester's brief, stored in the save and replayed exactly, with a test. <br>**Render tool:** `render.sh <save> [--turn N\|--all]` replays a save through `CorePort` on the same commit, then writes the recruit screen and a fight frame strip at both sizes, with the state hash. <br>**Tutorial mode:** `play.sh --tutorial`, once w7's tutorial data lands. <br>**Game log:** the file that writes owner game logs. <br>Renders run under xvfb and Mesa, which cloud sessions have (CLOUD_SETUP). | now; S5a before A5, the render tool before A7 |
| **S7: art** | the orchestrator runs `tools/art/run-codex-image.sh` (`codex exec`, not a bridge thread); a local workflow writes the prompts | A new prompt file in `tools/art/prompts/`; outputs go to scratch. The orchestrator commits the images and `content/portraits_pending.json`. <br>**15 images:** the 12 pending units, Golden Egg, Shieldbug and Click Beetle. Slice is already done on wave2b. | now |
| **S8: decisions and briefs** | local Claude workflows, no Godot | Drafts in scratch only. The orchestrator commits PLAN, DECISIONS and the briefs. <br>- **W-a:** §1 and §4 → plan-interrogate → logged. <br>- **W-b:** Pot Luck triage (running). <br>- **W-c:** the checkpoint brief (neutral labels, no sizes, assigned order, library and seeds named, no phone question). <br>- **W-d:** round 6 and verdict briefs: §1.7's definition, §1.8's rule, per-tribe "re-skin?" questions, decisions by round range, plus early flex and the slow early game (§6, items 3 and 10). <br>- **W-e:** `interesting-designs.md` now for 4 tribes; Oozes after A1, Hedgerow after A2. <br>- **W-f:** Quilboar lessons (§6). <br>- **W-g:** triage round 6's agreed items. <br>- **W-h:** the tallies. | now |
| **S10: faster suite** | its cloud session | per its brief | running |
| **Orchestrator** | n/a | Merges, Actions relays, the main guard. <br>- After every cloud session ends, check that `origin/main` is still `156e8c11`. <br>- Every brief says "never push main, open no PR". <br>- Ask the `portal/main` session for a per-workstream playtest link, rather than repointing the prototype's guide. Fallback: put PLAYTEST.md in each build folder and name it in the README. | now |

**Godot:** the workers run Godot only through the two-slot wrapper. Gates run on Actions, and sims and soaks run on the Actions sim job. The test-suite sessions own `check.sh` and `ci.yml`. S1 and S4 merge ideation/main in before gating.

## 4. Done means: what to rewrite
Each criterion has at most two deciding criteria (09i; working rule of 9 Nov). The rest is reported, and triaged only on an extreme miss. All of this is written in W-a before A4's numbers exist, so the bars aren't fitted to them.

**1. Whole game.**
- **Text fix:** five of six tribes per lobby, for variety (DECISIONS 8 Nov, "Commit review B", item 7).
- **Checklist:** the pool count on the build 9 tree, and 0 units without rules text.
- **Deciding:**
  1. 2,000 real `full_game` lobbies on the build 9 tree (S4's mix, on Actions): 0 violations, 0 crashes, and no unit without a set appearing.
  2. The 20 scripted UI games (shared with item 5) pick a hero and play 8-player games to game over.
- **Reported:** one line from a final reviewer on filler units.

**2. Depth.** 09d: "rely far more on empirical simulation data than on observational bot play"; "I don't want you to force it". 09c: tribes "the same order of magnitude".
- **Deciding:**
  1. **Field fights at R10, R12 and R14** (constructed simulation at turn thresholds). On the shipped default preset:
     - each committed line's boards from that round, plus each tribe's designed strong board, fight the round's field;
     - placer layouts, both orientations.

     It passes when at least 5 lines from at least 4 tribes beat the field in 40%+ of fights at R12 or R14, and no line or designed board beats it in 80%+ at both R12 and R14.
     - It is checked on the Quilboar archives first (§1.13).
     - The first read is at A4, so a miss is cut then, at the outlier dial (generous first).
     - It is decided at J2, and the bar never moves.
  2. **Reviewers:** most final reviewers report a real decision on most turns, and each found 3+ builds that felt different. Decisions are asked by round range (R1–5, R6–10, R11+). The ranges are reported, and "most turns" overall decides.
- **Reported:**
  - line-lobby firsts (the old 6–25% band, as a sanity line);
  - answers against carries, and distribution against totals (v3's designed bars);
  - placing (a) and (b) (an extreme miss is an interval that includes 0);
  - Naive, 300 games (an extreme miss means the bot is broken);
  - decisions in R1–5. If round 6 agrees they're thin, W-g triages it.
- **Dropped:** the head-to-head bar (§1.12).

**3. Interesting.**
- **Deciding:**
  1. `evidence/interesting-designs.md`, from shipped content. For each tribe: its signature, the nearest Battlegrounds analogue and why it differs, and an economy card tied to the tribe's own action (02h). A fresh reviewer checks it against `docs/research/battlegrounds/`.
  2. No tribe is called a re-skin by 2+ final reviewers. The brief asks about each tribe by name.
- **Reported:**
  - tribe gold against neutral gold (the 02h risk);
  - Quilboar absent from the pack.

**4. Bots.** One strength (08a, 08b), and the dealt lines are the flavours (8 Nov).
- **Default-opponent call:** the strong field is the default on the default preset, if two things hold:
  - a field start adds at most 300 MB of peak memory over a normal start, on the Linux export (today it is about 1.15 GB; shrink the library, not the data stored);
  - the library loads from the APK and Windows packs, and fails loudly when missing.

  Otherwise the default is normal Hard lobbies, and the call is logged.
- **Deciding:**
  1. The build 9 export's default opponents are as called above. Its library SHA is in the README, and the pack listing shows the library.
  2. The record (best placement and wins, default settings only) shows on the main menu and at game over, on build 9 screenshots at both sizes.
- **Reported:**
  - "were the opponents worth beating" (an extreme miss is most reviewers saying pushovers, which means triage);
  - Naive sanity;
  - distinct dealt lines.
  - The rivals replay strong games and don't react to the player. PLAYTEST says so; it is the owner's 09a ghost question.

**5. Release feel.**
- **Checklist** (tests or facts):
  - one theme;
  - `portraits_pending.json` empty and `test_portraits` passing (Golden Egg gets its own art);
  - a sound for each new cue, unheard, and PLAYTEST says so;
  - the tutorial;
  - the Rules hub covering every keyword in the pool;
  - settings;
  - game over;
  - no dev tools in exports.
- **Deciding:**
  1. 20 scripted UI games on the build 9 tree, 10 at 1920×1080 and 10 at 1688×780: 0 crashes, 0 layout failures, and phone text at least 31. The script's own depth bar applies as written: 10 games reach turn 12, 3 reach turn 15, one is won, 3 ghost fights happen, and tiers 5 and 6 are reached.
     - The scripted player uses Hard.
     - The slot table is fixed before the run: at least 10 games at default settings, and the rest in lobbies chosen to reach the late game.
     - There is no fallback bar.
  2. A fresh cold reader passes build 9's fight strips at batch 1's bar: who hits, what triggered, why it died.

**6. Delivered.**
- **Deciding:**
  1. The build folder holds `Bramble.apk`, `Bramble-windows.zip` and `README.txt`.
     - README line 1 has no parentheses.
     - The README names the commit tag and the library SHA.
     - `latest` points at the folder, and the portal's `/builds` lists it.
  2. PLAYTEST.md matches that build, is frozen at its commit, can be reached from the portal, and says no real device was tested.

**7. Agreed.**
- **Deciding:**
  1. 3+ fresh reviewers each play 2 full games of the build as defined (§1.7), and say "very good for a playtest".
  2. No problem is raised by 2+ of them, and round 6's agreed items are fixed (§1.8).

**Checkpoint 1:** keep its two criteria. Criterion 2 is read on the same cohort (§1.14). Fix the brief (W-c).

## 5. Builds, in order

| Build | When | Contents | Checks | Played by |
|---|---|---|---|---|
| 8 | after A5 (held for batch 2 if it merges within 24 h) | - the settled pool and A3.5's dials, with A5's cuts <br>- the default library, recaptured last <br>- strong field on the default preset (if within the memory budget) <br>- the preset setting <br>- the declutter batches merged so far <br>- the 15 portraits <br>- owner game logs <br>- PLAYTEST for build 8 | - export smoke: library required, Quilboar absent <br>- the memory budget <br>- Wine and Linux boots <br>- certificate match <br>- a 200-game soak <br>- a 4-game UI run | the owner; round 6 |
| 9 | after J2 | - round 6 fixes <br>- batches 1–4, the tutorial and the Rules hub <br>- the record <br>- the library recaptured | all of J2 | round 7 (the verdict) |
| 10 and on | only if a verdict round fails | every agreed item fixed | rerun what the fixes touch; recapture the library | a new fresh trio |

Every export:
- runs the one export script;
- is tagged `ideation-build-N`;
- has README line 1 "Ideation build N: ...";
- repoints `latest`;
- gets a delivery evidence file;
- gets a status-block update.

## 6. What the Quilboar reference has taught us (from the facts and the lessons drafts; W-f confirms)
The owner asked: "What have we learned from it? And does it help us improve any of our processes or challenge any of our assumptions?" W-f answers in the next status report, in plain words, and routes each lesson. A lesson that changes a tribe goes through that tribe's design step. None becomes a new deciding criterion (09i).

**What we learned about the game**
1. **Our engine can reach Battlegrounds' size.** BG-text Quilboar reaches 747–825 at R12. That is 0.98–1.09× Battlegrounds' September 2025 mean (759). So the gap is in our dials and content, not the engine. → A3.5.
2. **Our "overly generous" C isn't generous by Battlegrounds' standard.**
   - At C's dials Quilboar reaches 422 at R12, against 825.5 for BG text on the same version: 0.51×.
   - B is about a third (259 against 747).
   - C is generous on paper only. → The "far below" branch (C against C+). Testers may well prefer C.
3. **Scale arrives as a step, at about R12.**
   - BG text goes 140 → 747 → 2,494 from R11 to R13; at B's dials, 109 → 259 → 811 → 1,341 by R14.
   - Every tribe looks alike from R6 to R11. Our lines jump earlier and smaller (Birds at R10; Bog, Hunters, Oozes and Hedgerow at R8–R10), except Fairies (R13–R15).
   - An R12-anchored read gets the order wrong: B Quilboar is 0.84× Birds at R12 and 2.47× at R14. → R12 and R15 both (§1.14), and A3.5 doesn't chase R12 alone.
4. **The third axis carries the lead.** Freezing gem size cut the BG-text R12 median from 825.5 to 175.5 (÷4.7). None of our tribes grows its buff size additively; Fairies' Ring size is closest. → A3.5's weak-response rule.
5. **In bot play, our lines flatten after R12** (×1.07–1.29 a round, legacy profiles), while Quilboar keeps compounding. Paper's "proportional tribes catch up" never happened. → A4 reports the same-cohort R12–R15 growth for the pass 3 lines.
6. **Equal totals aren't equal power.** At equal totals the wide gem board wins only 18–25% of fights. This fits the owner's 09a and 09d ("Distribution of stats beats the total"). → DM2 decides on fights, not totals.

**What it says about our process**
7. **Our growth bar can't see a dominant tribe.** The lobby median reads the 4th–5th seat. One Quilboar seat moved it 0.01–0.05 while its own board varied tenfold, and it failed ×1.3 in every arm. Survivor medians flatter lines whose weak seats die. → §1.14. The order-of-magnitude extreme miss carries the dominance check.
8. **Validate a bar on a known case before it decides.** The accounting gate had already failed on 3 of 4 native lines before it gated the reference. → §1.13.
9. **Paper ranks, runs set levels.** Paper levels were 0.12–0.23× of real at R12, but its ratios held (the size dial within about 10%). → A3.5's path.
10. **The harness can't measure flex or pivots.** Every bot, Hard included, fixes its line at R1. → The early-flex lesson (09f: "Early units should be somewhat flexible as well as enabling") goes to round 6 as a question, not to the harness.
11. **The stop rule worked, but it also halted the lessons.** The designed setups that answer early flex, wide against tall, and retroactive against future-only size (D1, D4, D5) never ran. Next time, a step whose purpose is lessons decides on "lesson X can be read", and runs designed setups first (09d). W-f decides whether D1, D4 and D5 run now. They need no bot shop, run on Actions in a w6 gap, and never block.

## 7. Risks
- **The pass rule can loop.** Every agreed item means a new build and a new trio, and no report has said "very good" yet (0 of 17). Round 6 and the triage exist to empty the list before round 7. Budget is set for one failed round.
- **A3.5 can overshoot into snowballs.** That's allowed under generous first. A4 triages the three extreme misses, and A5 cuts at the outlier.
- **R12 is noisy because the step sits there.** Read R12 and R15 on the same cohort, and don't chase R12 alone.
- **The same-cohort growth read is stricter.** Checkpoint criterion 2 may now fail where the survivor median would pass. That's the honest read. A miss is triaged, and the bar isn't moved.
- **Memory on Android.** Untested on a device. If the budget can't be met, the default is normal Hard lobbies.
- **Review throughput.** About 14 merges, each with a scope review and an Actions gate. Batch the small tooling merges.
- **The lint cap at merges.** wave2b and b2 are already over it on one file each. Count lines on every merged tree.
- **Blindness at checkpoint 1 is on the honour system.** The mapping stays out of the brief, and testers don't open `rates.json`, DECISIONS or evidence.
- **Claude budget.** About 14 cloud sessions, plus 3 contingent. If the owner says the budget is out, round 6 drops to the render-only screen check by a local workflow, and the verdict rounds keep their trio.
- **Main.** Cloud sessions start on main with admin rights. The guard check runs after each one.

## 8. Critique calls

| # | Critique item | Call | Reason |
|---|---|---|---|
| 1 | Verdict doesn't meet the /goal; pass rule contradicts DM7 | **Adopt, adapted** | The render tool, the logged meaning of "played the latest build", 2 full games, and "no item raised by 2+" are all taken. Adapted: a fresh tally agent defines "the same problem", and the tutorial gate uses `play.sh --tutorial` with renders and one cloud first-timer. |
| 2 | Nothing closes the scale gap; no branch if B stays low | **Adopt** | New A3.5 interpolates each tribe along its own B→C path, with two runs and a stop rule. If B reads under 600 at A4: C against C+ when C reaches 900, otherwise hold and triage. The Quilboar facts set both rules (C is about half BG scale; the step lands at R12–R13). Following the lessons drafts, it reads the same cohort and reports R15 beside R12. |
| 3 | DM2 rewrite goes against 09c, 09d and v3, and is read too late | **Adapt** | The deciding sim becomes field fights at R10, R12 and R14, a constructed simulation at turn thresholds (09d), read first at A4. Its band is loose and only blocks dominance (09c). It must first flag BG-text Quilboar on the archives (§1.13). Designed setups and placing are reported: only two can decide (09i). R1–5 decisions are asked and reported, not deciding. The early-rounds triage waits for round 6 to agree it's a problem (09i: get good at one or two things first). |
| 4 | Ownership table false; merge order | **Adopt the table, reject the order** | The table is rebuilt from `git diff --stat` and trial merges at the live tips. Taken: all marks go to S2, S3 adds the tutorial and Rules folders to `include_filter`, S2 owns all screens, and S4's paths are corrected. The order is Quilboar → batch 1 → Oozes → batch 2, not Oozes first. Quilboar and batch 1 are ready, they conflict with nothing except Quilboar's 3 hunks against wave2b, and redoing Quilboar's squash on a moving tip costs more. |
| 5 | Library order, two libraries, soak arguments, Android memory | **Adopt, simplified** | Recapture last before every export, with the SHA in the README. The soak takes preset and library arguments. The memory budget is 300 MB above a normal start, or normal Hard lobbies become the default; this call is logged. One library only, because strong field runs only on the default preset. |
| 6 | §1.3's reason partly wrong (local cap) | **Adopt** | Two local Godot slots still bind. Lobbies, soaks and captures move to Actions, and local runs are only targeted tests, renders, UI runs and exports. |
| 7 | Claude budget | **Adopt** | The Actions sim job is added by the sharding session. v1's S5b and S6 move to w5, and v1's S9 moves to w7's idle window after A3. Round 6 has 4 testers, and checkpoint testers play 1 game per variant. That is about 14 sessions, plus 3 contingent. |
| 8 | Loosenings with no reason | **Adopt** | The UI-run depth bar is kept whole, with no fallback. The slot table is fixed before the run. The four loosenings are logged in W-a. |
| 9 | v2 step 4 items missing | **Adapt** | Owner game logs: adopted (small, S5 plus a hook from w5). Answer-buying bots: dropped with a reason. The default rivals replay captured games and can't react, and 09d says bots will be "okay at best". Revisit if round 6 agrees. |
| 10 | Triage round 6's design complaints | **Adopt** | W-g runs the triage skill on round 6's agreed design items before any fix. |
| 11 | Build 8 for the owner; track B estimate | **Adopt** | Build 8 waits for batch 2 if it merges within 24 h of A5. Track B is re-estimated at about 3 worker-days, so the pool track is the long pole. |
| 12 | Stale steps | **Adopt** | Refreshed to the 10 Nov tips (§0): B1 is down to Ask 3, the reader and the gate; wave2b has the review fixes plus WIP Hedgerow and Slice art; Quilboar is gating. |
| 13 | DM3 grades the agents' own work | **Adopt** | A fresh reviewer checks `interesting-designs.md` against `docs/research/battlegrounds/`. |
| 14 | Smaller J2 items | **Adopt, one adapted** | Taken: the recount, the no-set soak check, and the visual-tier re-score (reported). The UI games: 10 of 20 at default settings, the rest set before the run for late-game coverage, because default settings and the strong field shorten games. |
| 15 | Portal playtest link | **Adopt** | Ask for a per-workstream link; fallback is PLAYTEST in the build folder. |
| 16 | Main guard | **Adopt** | Check `origin/main` = `156e8c11` after every cloud session; the line goes in every brief. |
