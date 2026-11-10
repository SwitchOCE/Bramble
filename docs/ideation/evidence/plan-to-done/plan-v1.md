# Plan to Done (10 Nov 2026)

Basis: `docs/ideation/PLAN.md` ("Done means" and "sharpened"), plan v3 (`plan-scale-rework.md`), `DECISIONS.md` up to 10 Nov, and the seven gap notes in this folder. ideation/main is at `814793b9`.

## In short
- **Two tracks, joining at build 9.**
  - The pool track (wave 2b, step 5, checkpoint 1, build 8, round 6) is about 5 worker-days.
  - The UI track (declutter batches 1–4, with the tutorial) is about 7–9 worker-days. It is the long pole.
- **Builds:**
  - 8 (checkpoint 1: the owner plays the scale fix);
  - 9 (release candidate, judged by the final verdict);
  - 10 only if that verdict fails.
- **Six plan changes** (§1) shorten the path. Log them first.
- **Five Done-means criteria are rewritten** to at most two deciding criteria each (§4). This follows 09i and the 9 Nov working rule.

## 1. Plan changes to log first
These go in one DECISIONS entry, after a plan-interrogate pass by a fresh agent.

1. **Retiring the 38 prototype bodies comes off the critical path.** The pool settles once Oozes, Hedgerow and the neutrals merge.
   - **Why:**
     - `full_game` already excludes these bodies (`pool_filter` 'slice').
     - 54 test files call `GameConfig.defaults()`, so the retirement would collide with the faster-suite session's test edits.
     - No Done-means bar needs it.
   - **Later, if at all:** move them into a test-only fixture library.
   - **Now:** one check that no player-facing screen lists them.
2. **Checkpoint 1 testers don't wait for declutter batches 2–4.**
   - Plan v3 step 3 put the declutter before checkpoint 1. But both deciding criteria are read from game logs and lobby data, and CLI testers never see the screen. Waiting would hold the 09a verdict for days.
   - Build 8 ships whatever declutter batches have merged by then, batch 1 at least.
3. **Raise the branch limit.**
   - The v2 rule "at most two code branches" becomes three Codex branches plus three cloud code branches.
   - Each branch owns files no other open branch touches (§3).
   - **Why:** gates run on Actions since 10 Nov (DECISIONS "Gate plumbing merged"), so the shared local gate slots no longer limit us. Review throughput is the real limit.
4. **Recapture the strong-field library again for build 9** if checkpoint 1 or round 6 changed any dial or card.
   - "Recapture once" (v3 step 5) was meant to stop re-fitting during measurement.
   - Rivals captured on pre-cut dials would misstate "how far can I get".
5. **The verdict is on the exported build.** The /goal says the reviewers "each played the latest build", and that build is exported with `latest` pointing at it.
   - Items agreed in round 6 are fixed before build 9.
   - If round 7 passes, its agreed non-blocking items go on the owner's list and stay out of the build.
   - Any change after the verdict needs a new fresh trio.
6. **Declutter scope is set by "very good", not beyond it.**
   - **Batch 3:**
     - the removals 09e requires;
     - the standings sort;
     - the Lobby rules page;
     - new animations only where a removed element needs motion to replace it.

     The rest of animations 33–35, 37 and 46–65 is deferred.
   - **Rules hub:** the 8 topic pages, with still pictures. Looping demos only where they reuse batch 1–3 animations.
   - **Tutorial:** as specified, the scripted 4-round game. 09e requires it.

## 2. Critical path

### Track A, the pool
Everything balance-sensitive waits on this track.

| Step | What | Who | Size | Waits on |
|---|---|---|---|---|
| A1 | **Oozes in.** <br>1. Triage Pot Luck (×1.251 against the ×1.3 bar) with the triage skill. <br>2. The fix. <br>3. The orchestrator merges ideation/main into wave2b (it lacks the Actions trigger). <br>4. Actions gate and scope review. <br>5. Merge. | w7, plus a workflow for the triage | small | nothing |
| A2 | **Hedgerow light pass.** <br>Keep a signature that isn't Blood Gems: Dozey's slot clock and the Standing Committee. <br>Keep economy tied to the tribe: the Larder and Mast. <br>Its line must grow ×1.3 a round (wave 2b brief). | w7 | medium | A1 |
| A3 | **Neutrals.** <br>Change Ballooning Spider, Charcoal Burner and Whirligig Beetle. <br>Decide Pipistrelle Echo by the brief's rule. <br>Add Shieldbug and Click Beetle, with art from S7. <br>**Once this merges, the pool is settled.** | w7 | medium | A2 |
| A4 | **Step 5 measurement** on the checkpoint config: <br>- the line gate; <br>- 150+ line lobbies each for B and C, on cloud shards while the local slots are busy; <br>- fields at R6–16; <br>- designed setups (Granny regenerated on pass 3 Oozes, the Whistlers, each tribe's carry against a board with one answer); <br>- the splash audit; <br>- the damage table; <br>- a 200-game soak on the reworked soak; <br>- the strong-field library recaptured for B and C, and committed. <br>**Deciding read:** checkpoint criterion 2, growth ×1.3 R8–R14. Triage only v3's three extreme misses. <br>Then tell the owner plainly whether the scale problem is fixed. | S3, plus cloud shards | medium–large | A3, S4, S3's harness follow-ups |
| A5 | **Checkpoint 1.** <br>3+ reward-lens cloud testers play blind, in assigned order (XYXY or YXYX), against the strong field, at most 2 games per variant. <br>Check each moment against the logs (fun-probe method), tally the two criteria, pick the default. <br>Cut back from C dial by dial (w7). | cloud testers; a workflow verifies | medium | A4, S5a, W-c |
| A6 | **Build 8 export** (§5) | S3 | small | A5, S5b, S3's field flip, S7 |
| A7 | **Round 6.** <br>Five fresh cloud testers (the five lenses plus the reward lens). Each plays 2 full games of build 8's source commit through `play.sh`, with the build's screen pack. <br>Tally the agreed items. Fixes go to w7 (content), w5 (UI) and S3 (tools). | cloud testers, then the workers | medium, plus medium for fixes | A6, W-d |

### Track B, the UI (long pole)

| Step | What | Who | Size | Waits on |
|---|---|---|---|---|
| B1 | **Declutter batch 1.** <br>1. The orchestrator merges ideation/main into ideation/declutter (the worker refuses merges). <br>2. The four visual fixes. <br>3. Port Bog's marks. <br>4. Reshoot the named moments. <br>5. A fresh cold reader. <br>6. Actions gate, then merge. | w5 | small | nothing |
| B2 | **Batch 2:** <br>- tiles (words at rest go from about 65 to 0); <br>- the board; <br>- scouting; <br>- the reader; <br>- recruit animations. <br>Ooze marks once A1 merges; neutral cues once A3 merges. | w5 | large | B1 |
| B3 | **Batch 3, trimmed** (§1.6) | w5 | medium | B2 |
| B4 | **Batch 4.** <br>The tutorial and Rules hub, wired in from S9's new files. <br>The coach overlay, the settings and game-over edits (spec 2.7), and sounds for new cues. <br>**Gate:** a first-timer agent finishes the tutorial, then plays one real game. | w5 + S9 | large | B3, A3 |

### Join: build 9

| Step | What | Who | Size |
|---|---|---|---|
| J1 | Round 6 fixes, B4 and all art merged. Recapture the field library if any dial moved (§1.4). | w7, w5, S3 | small–medium |
| J2 | **Final evidence on the build 9 tree, in parallel:** <br>- the 2,000-game soak (cloud); <br>- 20 scripted UI games (local, Codex); <br>- the DM2 line-lobby spread on the shipped default (cloud shards); <br>- Naive sanity, 300 games; <br>- placing (a) and (b), reported; <br>- a fresh cold reader on the build's fight strips; <br>- `interesting-designs.md` finished; <br>- the neutral-economy report. <br>On a failure: fix it, then rerun only what the fix touches. | S3, w5, cloud, workflows | medium |
| J3 | Export build 9 (§5) | S3 | small |
| J4 | **Round 7:** 3+ fresh reviewers give the verdict. <br>- **Pass:** done. <br>- **Fail:** fix the blockers, export build 10, then round 8 with a new fresh trio. <br>- **Two failed rounds:** run the triage skill before any more fixes. <br>Tell the owner plainly where things stand. | cloud reviewers | medium |

## 3. Start now, in parallel: who owns which files

| Stream | Resource | Owns these files, and only these | Done when | Starts |
|---|---|---|---|---|
| **S1:** wave 2b, A1–A3, then checkpoint cuts and round 6 content fixes | w7, `-balance` | `content/units`, `content/pass3`, `content/bots/strategies`, `src/core/bots`, tribe rules and their tests, `tests/ui/test_portraits.gd`, `docs/ideation/content/pass3` | each part is one reviewed hand-off, gated, with its ×1.3 line criterion | now |
| **S2:** declutter B1–B4 | w5, `-tribes2` | `src/ui/**`, `tests/ui/**` and `evidence/declutter/**`, except the files S5b and S6 hold | each batch passes its cold reader and the Actions gate | now, once the orchestrator has merged main in |
| **S3:** measurement and delivery | w6, `-sol`, once Quilboar merges | `tools/sim/**`, `content/fields/**`, `export_presets.cfg`, `scripts/export_smoke.sh`, `build/*.sh` | 1. **Harness follow-ups:** drop contaminated trials (fail above 2%), label low rolls, simplify the seated-line check, store per-seed lists once. <br>2. **Decoy arm** promoted from `evidence/review-placing/xprobe.gd.txt` into `tools/sim`. <br>3. **One export script** taking build number, source commit, README and certificate. <br>Then A4, the field-library flip (include it in all four presets; the smoke test requires it and checks Quilboar is absent), A6 and J3. | after the Quilboar merge (orchestrator: merge main in, scope review, gate, merge) |
| **S4:** soak rework | cloud session | `tools/checks/soak.gd`, `scripts/soak.sh` and their tests. Not `check.sh`, not `ci.yml`. | `soak.sh N` plays N real `full_game` lobbies: about 60% on the default preset, 20% on the other shipped preset, 20% with a strong-field seat. Synthetic cards only behind a flag and counted separately. 200 games on today's tree with 0 violations. | now; must merge before A4 |
| **S5a:** blind variant in `play.sh` | cloud session | `tools/play/**` | `new --variant X\|Y` maps to B or C through a mapping not in the tester's brief. It is stored in the save, replays exactly, and has a test. | when a test-suite session merges; needed before A5 |
| **S5b:** preset setting and record (same session) | cloud session | the preset row in `settings_screen.gd`, the preset line in `core_port.gd`, `src/ui/records.gd`, `tests/ui/test_records.gd` | Settings offers both presets, with A5's pick as the default. The record counts only games on default settings (log that call now). | after B1 merges; w5 stays off these files until it merges |
| **S6:** UI driver seat (same session after S5b, or Codex) | cloud session | the decision code in `tests/ui/player_driver.gd`, the arguments of `full_ui_run.sh` | The scripted player uses the Hard policy. In a 4-game run, at least 2 games reach turn 12. | after B1 merges |
| **S7:** art | Codex image tool; a local workflow writes the prompts | a new prompt file in `tools/art/prompts/`; outputs go to scratch. The orchestrator commits the images and `content/portraits_pending.json`. | 16 images: the 12 pending units, Golden Egg, Slice, Shieldbug and Click Beetle. **Slice first,** handed to w7 so w7 never touches `portraits_pending.json`. | now |
| **S8:** decisions and briefs | local Claude workflows (no Godot) | drafts in scratch only. The orchestrator commits `PLAN.md`, `DECISIONS.md` and the briefs. | **W-a:** §1 and §4 → plan-interrogate → logged. <br>**W-b:** Pot Luck triage. <br>**W-c:** checkpoint brief fixed (neutral labels, no sizes, assigned order, library and seeds named, phone question dropped). <br>**W-d:** briefs for round 6 and the final review, asking the §4 questions in the "alone stops very good" format. <br>**W-e:** `interesting-designs.md` for Birds, Fairies, Bog and Hunters now; Oozes after A1, Hedgerow after A2. | now |
| **S9:** tutorial and Rules hub content | cloud session | new files only: `src/ui/screens/rules_hub*.gd`, `content/rules/**`, `src/core/tutorial/**`, `content/tutorial/**` | **Rules hub:** pages for every keyword now in the pool (Quarry, Pelt, Pounce, Pack, Mire and so on). Eat, Digest and the neutrals are added after A3. <br>**Tutorial:** the scripted 4-round game (fixed shops, boards and the coach steps), after A3. | when the second test-suite session merges |
| **Orchestrator, directly** | n/a | n/a | 1. Back up the debug keystore to a path the portal doesn't serve (not `/data/bramble-builds`), and record the path in RESTART §7. <br>2. Ask the `portal/main` session to point `playtest` in `tools/portal/workstreams.json` at `docs/ideation/PLAYTEST.md` on ideation/main. Fallback: put `PLAYTEST.md` in each build folder and name it in the README. <br>3. The Quilboar merge. <br>4. Unblock B1. | now |

**Godot:**
- w5, w7 and S3 run Godot only through the slot wrapper. Sims take the harness lock. Heavy runs go to the cloud. Gates run on Actions.
- The test-suite sessions own `scripts/check.sh`, `ci.yml` and the shared test helpers. S1 and S4 merge ideation/main in before gating.

## 4. Done means: what to rewrite, and what later direction already changed
Each criterion has at most two deciding criteria (09i; DECISIONS 9 Nov "Two criteria decide checkpoint 1": "each step names at most two deciding criteria"). The rest is reported, and triaged only on an extreme miss. Write all of this now, before A4's numbers exist, so the bars aren't fitted to them.

**1. Whole game.**
- **Already changed:**
  - five of six tribes per lobby, for variety (DECISIONS 8 Nov "Commit review B", item 7, citing the 27 Oct owner note);
  - PLAN still says "unless measured shop thinness": reword it.
  - The pool counts are met: 6 tribes of 16, 13 neutrals, 18 spells.
- **Deciding:**
  1. 2,000 real `full_game` lobbies on the build 9 tree (S4's split), with 0 violations and 0 crashes.
  2. The 20 scripted UI games (shared with item 5) pick a hero and play 8-player games to game over.
- **Reported:**
  - a final reviewer's one line on filler units;
  - A4's 200-game soak, as a rehearsal.
- **Evidence:** `evidence/soak2000-build9.md`, `evidence/ui-run-build9.md`.

**2. Depth.**
- **Rewrite due:**
  - plan v3 step 7, with DECISIONS 9 Nov "Plan v3 approved", moves the bar onto the harness;
  - 09d: simulations over bot play, and judge frequency, not the top 1%;
  - 09c: fun over balance.

  Not yet written.
- **Deciding:**
  1. **Several ways to win, none dominant.** In 150+ line lobbies on the shipped default preset, with every tribe's committed lines seated, at least 5 lines from at least 4 tribes each take 6% or more of firsts where they sit, and none takes more than 25%. These are the 6 Nov numbers moved onto line lobbies. A miss is cut at the outlier dial (generous first), never fixed by moving the bar.
  2. **Real decisions.** Most final reviewers report a real decision on most turns.
- **Reported:**
  - the pinned bench spread;
  - Naive, 300 games (an extreme miss means the bot is broken);
  - placing (a) and (b) on pass 3 boards (an extreme miss is an interval that includes 0);
  - placing (c) and "3+ builds that felt different", from reviewers;
  - A4's answers-against-carries setups.
- **Dropped as a bar, with a logged reason:** the head-to-head promotion test.
  - 09d: bots are "okay at best".
  - Its gains are about 0.05 of a place.
  - DECISIONS 8 Nov already dropped its floor.
- **Evidence:** `evidence/depth-build9.md` and the round 7 tally.

**3. Interesting.**
- Unchanged (02h for economy).
- **Deciding:**
  1. `evidence/interesting-designs.md`, built from shipped content. For each tribe: its signature, the nearest Battlegrounds analogue and why it differs, and at least one economy card tied to the tribe's own action.
  2. No tribe is called a re-skin by two or more final reviewers. The brief asks about each tribe by name.
- **Reported:**
  - tribe gold against neutral gold, from A4's lobbies (the 02h risk);
  - Quilboar absent from the pack.

**4. Bots.**
- **Already changed:**
  - one strength (owner 08a and 08b; DECISIONS 8 Nov "What bots are for");
  - the dealt lines count as the flavours "for now" (same entry);
  - 09d lowers the weight of bot strength;
  - strong field is the playtest default (v2 step 4), and the checkpoint build turns it on (DECISIONS 10 Nov "Strong-field follow-up review", Ask 1).
- **Deciding:**
  1. The exported build's default opponents are the strong field, built from top-4 trajectories on the shipped pool and dials. Its library loads from the APK and Windows packs, and fails loudly if it is missing.
  2. The record (best placement and wins, default settings) shows on the main menu and at game over, on build 9 screenshots at both sizes.
- **Reported:**
  - Naive sanity;
  - "were the opponents worth beating" (extreme miss: most reviewers say pushovers, which means triage);
  - distinct dealt lines.
- **Evidence:** `delivery-build9.md` (the pack listing and the load line), `evidence/records-build9/`.

**5. Release feel.**
- **Already extended:**
  - 09e, in the sharpened text since 9 Nov;
  - the declutter spec;
  - DECISIONS 10 Nov (the third batch 1 reader) moves the rule-knowledge gaps to the Rules page;
  - the scope trim in §1.6.
- **Checklist,** checked by tests or facts, not judged:
  - one theme;
  - `portraits_pending.json` empty and `test_portraits` passing (Pelt's borrowed portrait logged as deliberate);
  - a sound for each new cue (unheard, and PLAYTEST says so);
  - the tutorial;
  - the Rules hub covering every keyword in the pool;
  - settings;
  - game over;
  - no dev tools in exports.
- **Deciding:**
  1. 20 scripted UI games on the build 9 tree, 10 at 1920×1080 and 10 at 1688×780: 0 crashes, 0 layout failures, smallest phone text at least 31, and at least 10 games reaching turn 12. This needs S6. If S6 still can't reach that, log a changed coverage bar.
  2. A fresh cold reader passes build 9's fight strips at the batch 1 mark: who hits, what triggered, why it died.
- **Evidence:** `evidence/ui-run-build9.md`, `evidence/declutter/final-reader.md`.

**6. Delivered.**
- Unchanged. Plan v3 step 6 adds the B/C setting.
- **Deciding:**
  1. The build folder holds `Bramble.apk`, `Bramble-windows.zip` and `README.txt`. README line 1 has no parentheses and the README names the source commit. `latest` points at the folder, and the portal's `/builds` lists it.
  2. `PLAYTEST.md` matches that build, is frozen at its commit, can be reached from the portal, and says no real device was tested.
- **Evidence:** `delivery-build8.md`, `delivery-build9.md`.

**7. Agreed.**
- Tightened by the /goal (§1.5).
- **Deciding:**
  1. 3+ fresh reviewers each play at least one full game (two if the session allows) of build 9's source commit, with its screen pack, and say "very good for a playtest".
  2. No agreed blocker is open. Round 6's agreed items are fixed, or rejected with a logged reason. In round 7, no item has two reviewers agreeing it stops "very good".
- The phone clause comes from item 5's first criterion and the no-device line in PLAYTEST.
- **Evidence:** `evidence/final-review/` and `tally.md`.

**Checkpoint 1.** It already has two deciding criteria (DECISIONS 9 Nov "Two criteria decide checkpoint 1" and "Generous first"). Keep them. Fix only the brief (W-c).

## 5. Builds, in order

| Build | When | Contents | Checks | Played by |
|---|---|---|---|---|
| 8 | after A5 | - the settled pool with the checkpoint cuts <br>- strong field on, with the B and C libraries in the pack <br>- the preset setting <br>- every declutter batch merged by then (batch 1 at least) <br>- the 16 portraits <br>- PLAYTEST for build 8 | - export smoke, with the library required and Quilboar absent <br>- Wine and Linux boots <br>- certificate match <br>- A4's soak <br>- a 4-game UI run | the owner; round 6 |
| 9 | after J2 | - round 6 fixes <br>- declutter batches 1–4, the tutorial and the Rules hub <br>- the record for default settings <br>- the field recaptured if any dial moved | all of J2 | round 7 (the verdict) |
| 10 and on | only if round 7 fails | the blocker fixes | rerun only what the fixes touch | a new fresh trio |

There are no other exports. Every export:
- uses the one export script;
- has README line 1 "Ideation build N: ...";
- repoints `latest`;
- gets a delivery evidence file.

## 6. Risks
- **The UI track is the long pole.** Batch 1 took 58 commits and three reader rounds. Don't run the verdict on a cluttered UI: the 9 Nov visual comparison gave the UI 3/10 and blamed the clutter.
- **No report has ever said "very good"** (0 of 17). The recurring blockers, snowballs and one huge unit deciding fights, can return at C. Round 6 exists to surface them before the verdict.
- **DM2's first criterion may fail.** Fairies Court took 31.6% of firsts in B (`wave1-rebase.md`), and Birds sit under 6%. Cut the outlier dial; don't move the bar.
- **Full-pool growth in B may land near ×1.3.** The shipped config reads ×1.301 with an interval below 1.3, and Pot Luck reads ×1.251. C has margin: ×1.80, in lobbies conditioned on Birds and Fairies.
- **Today's export smoke fails any pack that contains a field library.** If the flip is missed, the strong-field default breaks on Android. Check the APK's pack listing.
- **Cloud testers are expensive.** C games run longer, at one Godot replay per action. Cap testers at 2 games per variant, and commit saves as they go.
- **Review throughput.** This plan has about 15 merges, each with a scope review and an Actions gate. Batch the small tooling merges.
- **Blindness at checkpoint 1 is on the honour system.** Keep the mapping out of the brief, and tell testers not to open `rates.json`, DECISIONS or the evidence folder.

File: /tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/done-gap/plan.md
