# Third run: referee notes

The referee's log for the third run (`third-run-brief.md`). The match 1 and 2 notes are on the archived branch `archive/branches/league/t3-amend`.

## Setup, 21 Nov 2026

- **Go.** The owner, in the Ghost Build Orchestrator's thread: "You can start the third run".
- **Engine tag.** `third-run-engine-v1` is dev at `86b17dcb` (rules `fa1d51ec`), pushed.
- **Clones.** The tag was not merged into the clones as written. Dev holds both teams' full m2 bot folders, so a merge would give each team the other's code and history (league brief section 6; third-run brief section 8: "never code or numbers").
  - Each clone instead got one commit with the engine tree. The other team's folder stays at the league-engine-v1 stub.
  - Two lines that are only for the referee are left out: third-run-brief.md line 13's last sentence, and hand-over.md line 53.
  - In each clone, `third-run-engine-v1` is a parentless commit of that tree, made from `refs/league-base/<colour>` in the main repo; team diffs are checked against it.
  - The fetched dev objects were purged, and a check found neither the other team's `lib.rs` blob nor the two lines anywhere in either clone.
  - The team's own folder is kept as the team left it; only `BRIEF.md` takes dev's version (practice opponent `flow`).
- **Harness bug.** `check-crate` fails for every bot at this tag: its check tree misses `bramble-ghosts`. The fix is commit `a5c90160` on this branch, sent to the Ghost Build Orchestrator for dev. The referee uses its own fixed build at `/data/third-run/referee-tree/tools/league/target/release/league`. red-m2 and blue-m2 both pass.
- **THIRD-RUN.md** was written from brief section 10 and committed in each clone.
- **Knobs file instead of an env flag.** Brief section 7 proposed an environment flag per mechanic. Two problems:
  - check-crate bans `env!` and `std::env` in bots.
  - In a paired match both versions of a bot run in one process, so one flag would switch off both.
  - So each bot reads `data/knobs.txt` (numbers, `off.*`, `stay_tribe`), and the referee edits it in its own copy of the crate.
- **Pins.** The `league-pin` service runs from this tree: red core 0, blue core 1, by working folder, with log `/data/third-run/pin.log`. Referee matches use cores 2–5 with 4 threads.
- **Leads.**
  - Red: the existing Opus thread, briefed.
  - Blue: a new Codex `gpt-6.2-astra` thread in League Blue, "Blue lead: third run" (`mcp:launch:ed315f9f977cbc5a338cbc621a50d5ab2423ceb9ea5b65f4b99cc3374afd443a`), briefed from blue's notes. The old blue thread stays idle.
- **Approval watch** is running in the background while blue's Codex session is up.
- **Climbing match.** `tools/league/climb_match.sh COLOUR NEW CUR [GAMES]` builds in `/data/third-run/match-tree`, with NEW as `<colour>` and CUR as `<colour>-cur`. It then plays a paired ghost match on the climbing field, runs analyze and check_ghost_match, and writes `verdict.txt`. Output goes in `/data/third-run/matches/`.

## Kept versions

| Team | Kept | Since | Verdict line |
|---|---|---|---|
| red | red-c14 | 22 Nov | red-c14 vs red-c10: 1,000 games, gap −0.242 ± 0.161 (2.062 against 2.304) |
| blue | blue-c17 | 23 Nov | blue-c17 vs blue-c13: 1,000 games, gap −0.164 ± 0.150 (1.844 against 2.008) |

## Log
- **21 Nov, Ghost Build Orchestrator:** it accepted both points. It is landing the check-crate fix (`a5c90160`) on dev on its own, and will send each future engine port as a dev tag for the referee to bring in the same way. When the fix is merged, bring it into both clones as one referee commit, and move each clone's `third-run-engine-v1` to the engine tree plus the fix, so the teams can run check-crate themselves.
- **Ruling, off switches (blue asked; both told):** a switch turns off the bot's own choices for that mechanic (placing, routing, holding, using, and any buy or keep value given for it). The cards stay in the pool and passive triggers still happen. Each switch is described in `knobs.txt` and must show in the decision log.
- **blue-c1** (`6adfe665`, pre-rework placement lift discounted from 100 to 35) against blue-m2: 1,000 games, gap +0.198 ± 0.205 (4.576 against 4.378). **Rejected.** The match was clean (500 pairs, 3,500 distinct runs, no clock-outs or faults), took 254 s, and was pruned to 20 KB.
- **Check-crate fix in the clones.** It merged to dev as PR 246 (dev `66949460`), with `checkcrate.rs` identical to `a5c90160`. Each clone got it as one referee commit (red `01e215aa`, blue `b4450a10`), and its `third-run-engine-v1` moved to the base plus the fix. Tags made before these commits would fail the diff check on that one file.
- **Old scripts.** The orchestrator's reviewer noted that `practice_match.sh:30` and `official_match.sh:30` still diff against `league-engine-v1`. The third run doesn't use them: `climb_match.sh` checks against `third-run-engine-v1` in the clone.
- **blue-c2** (`f190366c`: with a full board, recruits up to the Reserve limit and keeps reinforcements in hand for combat; lift weight back to 100) against blue-m2: 1,000 games, gap −1.094 ± 0.210 (3.256 against 4.350). **Kept.** The match was clean. The gain is plausible: blue-m2 predates batch 1's Reserve rework and never held reservists.
  - **Into the field.** It was cut into a scratch store (1,000 runs, verified), and only the 500 `blue-c2` runs were copied into the climbing field. The cut tool has no label filter. Reindexed and verified: 8,500 runs (red 4,000, blue 4,000, blue-c2 500). Match pruned.
  - **Interim report to Balance Orchestrator 2** (section 8). blue-c2's main tribes on the final board, counting 4 or more units and ignoring the hand: Pigeon 40.8% (place 4.10), none 34.2% (2.21), Locust 22.2% (3.55), Briar 2.8% (1.36). Hand at the end: 5.2 units, against 3.4 for blue-m2.
  - **For later kept versions:** take tribe picks from the cut runs, because pruning deletes `games.jsonl`.
- **red-c1** (`43f82c68`: holds Reserve units in hand on a full board, returns a Reserve unit to hand instead of selling it, drops Colonel hand-stocking; built after blue-c2's summary) against red-m2: 1,000 games, gap −0.914 ± 0.204. **Kept.** The match was clean.
  - Cut with the new `keep_version.sh`. The first run stopped at the tribe tally on an empty board slot (`None`), which is now fixed; the field had already verified at 9,000 runs.
  - Tribe picks: Locust 77.0% (2.40), none 15.0% (3.99), Pigeon 5.4% (6.56), Briar 2.2%, Mouse 0.4%; 2.6 units in hand at the end. Interim report sent to Balance Orchestrator 2, and the method summary to blue.
- **blue-c3** (`f013c890`: moves unused front-row Lance Corporals back so they issue their Renown order before combat) against blue-c2: playing.
  - blue-c3 against blue-c2: 1,000 games, gap −0.044 ± 0.169 (3.360 against 3.404). **Rejected** (within noise). The match was clean and is pruned.
- **red-c2** (`c82fcdd6`: card table refit for the new cards, from a fight model on red's own ghost fights; 97 cards moved by a capped step, 18 new rows) against red-c1: 1,000 games, gap −0.452 ± 0.217 (2.432 against 2.884). **Kept.** The match was clean; field now 9,500.
  - Tribe picks: Locust 78.6% (2.12), none 16.6%, Briar 2.6%, Pigeon 2.0%, Mouse 0.2%; 2.4 in hand.
- **blue-c4** (`717ecf77`: on a full board with at most one free hand slot, sells a weaker non-Reserve hand unit before a board sale; c3 removed) against blue-c2: 1,000 games, gap −0.198 ± 0.168 (3.480 against 3.678). **Kept.** The match was clean; field now 10,000.
  - Tribe picks: Pigeon 50.0% (3.92), none 30.8% (2.52), Locust 17.0% (4.19), Briar 2.0%, Mouse 0.2%; 4.3 in hand.
  - blue-c2 placed 3.678 here against 3.404 in its last match: the field is getting stronger as kept versions join it.
- Method summaries and interim reports for both were sent. No bot picks Badger, and Mouse is under 1%.
- **blue-c5** (`206e212a`: clears weak non-Reserve hand units from three free hand slots instead of one) against blue-c4: 1,000 games, gap −0.096 ± 0.177 (3.502 against 3.598). **Rejected** (within noise). The match was clean and is pruned.
- **Ruling, off switches and whole-card values (blue asked; both told):** whole-card values learned from play (fit coefficients, lift tables, refit card tables) stay intact with a switch off. A switch turns off only the explicit choices and value terms for that mechanic. If a mechanic's value lives only in whole-card numbers, a switch that costs nothing is reported as that, with the team's line from `knobs.txt`.
- **blue-c6** (`8039682d`: capped whole-card fight-value adjustments to buys and keeps; free-slot threshold back to c4's 1, stopping neighbours 0 and 2) against blue-c4: 1,000 games, gap −0.936 ± 0.230 (2.702 against 3.638). **Kept.** The match was clean. Method summary sent to red.
  - **Switch fix `14f28bdf`** (blue, after the tag): it removes a broad search disable on Pile on and Hand-me-down boards, so those switches now only annotate reports. Read by the referee: with the switches at 0, play is unchanged. Switch tests of blue-c6 use `14f28bdf`.
  - blue-c6 field cut: 10,500 runs, verified. Tribe picks: Locust 50.0% (3.20), none 34.4% (2.16), Pigeon 15.2% (2.28), Mouse 0.4%; 4.6 in hand. It moved from Pigeon to Locust once it valued cards from fights. Interim report sent.

### Harness bug: stale bot builds (21 Nov, 22:35–22:52)

- **Found.** A head-to-head of red-c2 against blue-c6 showed red-c2 at 4.09. Two replays of red-c2 against red-c1 then showed it about 1 place *behind* red-c1, on today's field and on a copy of the field as it was when red-c2 was kept.
- **Cause.** `git archive` stamps files with their commit time. With cargo 1.100's build-dir layout (`target/release/build/<pkg>/<hash>/out/`), `cargo clean -p` leaves the artifacts in place. Cargo then rebuilds a crate only if a file is newer than its last compile. So a tag committed before that crate's last compile plays whatever was compiled last; here that was the red stub, compiled at 21:42:30 during blue-c4's match.
- **Audit of the 8 climbing matches.** Each NEW tag was committed after its crate's last compile, so each was built fresh. Each CUR side's placement matches that version's other results. **No climbing verdict or field cut is affected.** Only the head-to-head and the two replays (all referee checks) played the stub.
- **Fix.** `climb_match.sh` now touches every bot file after extraction. After the build it stops unless both team crates' rlibs are newer than a marker made just before the touch.
  - Proved by a 400-game replay of red-c2 against red-c1: −0.615 ± 0.334 (2.630 against 3.245), in line with its keep match.
  - `head_to_head.sh` has the same guard. The invalid outputs were deleted.
- **Head-to-head, red-c2 against blue-c6** (fixed build, climbing field of 10,500 runs): 1,000 games, red 2.636, blue 2.952, gap −0.316 ± 0.244. **Red ahead.** The match was clean and is pruned to its summary.

### Machine restart (23 Nov, overnight; resumed 08:36)

- The restart killed both stopping-test chains and the approval watch. Red-2 had 19 of 36 matches done; none was lost. Blue-2 was still building ref-3 (a 7.7 GB partial live match, deleted).
- Resumed at 08:36: ref-3 rebuilt from red-c14 and blue-c17, then blue-2's 27 matches; red-2 resumes at reserve_value+. Both teams were told.

## Daily report, 21 Nov (sent to the owner)

- Kept: red-c1 and red-c2 (2 of 2 hand-ins); blue-c2, blue-c4 and blue-c6 (3 of 6).
- Gap: red-c2 places 0.32 ± 0.24 better than blue-c6 in the same lobbies.
- Stopping test: not started for either bot. Both are still climbing, and both have written STOPPING.md.
- Harness bug found and fixed (stale builds). No team verdict was affected.
- **Ghost Build Orchestrator, on the build trap:** its dev tools aren't exposed. make_field.sh and smoke_final_bots.sh build from the working tree, and the Windows and export scripts use no cargo. Only the league-only official_match.sh and practice_match.sh share the trap, and this run doesn't use them.
- **red-c3** (`5179a2c0`: levels one round later; tier 2 at round 5, 3 at 8, 4 at 11, 5 at 13) against red-c2: 1,000 games, gap −0.338 ± 0.165 (2.450 against 2.788). **Kept.** The match was clean, and it was the first played with the rebuild guard. Field now 11,000.
  - Tribe picks: Locust 86.2% (2.10), none 8.8%, Briar 3.0%, Pigeon 1.8%, Mouse 0.2%; 2.5 in hand. Interim report sent, and the method summary to blue.
- **Busy machine, 23:51.** Load average 30 on 6 cores from other sessions: a `league match` in the sound-engine worktree and several Godot review and test runs. Match wall time went from 0.27 to 1.09 s a game.
  - Results are unaffected: the bot clock is per-thread CPU time, and there were no clock-outs or faults.
  - Not stopped. The owner was asked whether to pause (brief section 8 lists a busy machine).
- **Heartbeat 22 Nov 00:34.** Load is back to about 6, so the busy spell is over. No unplayed tags. Red is waiting on its number probes. Blue had been idle for 43 minutes with nothing running, so it was nudged.
- **blue-c7** (`aef302d5`: +25 whole-card buy/keep value for Sword-heir, from measured replacement fights) against blue-c6: 1,000 games, gap −0.274 ± 0.158 (2.686 against 2.960). **Kept.** The match was clean; field now 11,500.
  - Tribe picks: Locust 50.6% (3.19), none 31.4% (2.31), Pigeon 17.2% (1.92), Briar 0.4%, Mouse 0.4%; 4.7 in hand. Interim report and method summary sent.
- **Referee slip, 00:44–02:13.** The step meant to queue blue-c8 behind blue-c7's field cut waited on `pgrep -f keep_version.sh`, which matched its own shell. It hit its 90-minute limit without playing, so blue-c8 waited about 90 minutes. Started directly at 02:13, and blue was told. From now on, wait for a step by its task notice, never by pgrep on a name the waiting shell contains.
- **blue-c8** (`0a8b7333`: tier 2 delayed from round 3 to 4) against blue-c7: 1,000 games, gap −0.570 ± 0.202 (2.478 against 3.048). **Kept.** The match was clean; field now 12,000.
  - Tribe picks: Locust 42.8% (3.04), none 34.8% (2.32), Pigeon 22.0% (1.65), Mouse 0.4%; 4.7 in hand. Interim report and method summary sent.
- **red-c4** (`3419e496`: positioning search scores by margin, 0.4 per surviving unit) against red-c3: 1,000 games, gap −0.072 ± 0.152 (2.470 against 2.542). **Rejected**: not better. The match was clean.
- **blue-c9** (`80b63def`: Sword-heir buy/keep bonus 25 → 50) against blue-c8: 1,000 games, gap −0.558 ± 0.143 (1.938 against 2.496). **Kept.** The match was clean; field now 12,500.
  - Tribe picks: none 53.6% (1.81), Locust 28.0% (2.61), Pigeon 17.4% (1.28), Badger 0.8%, Briar 0.2%; 4.8 in hand.
  - Sword-heir on the final board: blue-c8 4.4% of runs, blue-c9 40.6% (place 2.27 with it, 1.71 without), red-c3 0.2%. Interim report and method summary sent.
- **blue-c10** (`4685dd3e`: combat evaluator samples up to 5 opponents instead of 3, 3 seeds each) against blue-c9: 1,000 games, gap +0.014 ± 0.117 (2.258 against 2.244). **Rejected**: not better. The match was clean. blue-c9 places 2.244 here against 1.938 in its own match, because the field now holds its runs.
- **blue-c11** (`6b13a3be`: pair bonus 6 → 12) against blue-c9: 1,000 games, gap −0.038 ± 0.130 (2.064 against 2.102). **Rejected**: not better. The match was clean.
- **red-c5** (`20a50816`: positioning search budgets 60% of the remaining clock each round, was 90%; adds options off by default) against red-c3: 1,000 games, gap +0.036 ± 0.157 (2.782 against 2.746). **Rejected**: not better. The match was clean.
- **red-c6** (`4a8f2a83`: positioning search tries each Pile on and Hand-me-down unit in every slot first) against red-c3: 1,000 games, gap −0.030 ± 0.138 (2.658 against 2.688). **Rejected**: not better. The match was clean.
- **blue-c12** (`49a7fc5c`: spare-gold threshold 6 → 4) against blue-c9: 1,000 games, gap −0.010 ± 0.130 (2.130 against 2.140). **Rejected**: not better, though blue's 400-pair practice showed −0.147 ± 0.134. The match was clean.
- **red-c7** (`ed9700bc`: uses units' Actives before buying instead of after; adds a tribe-lock option, off) against red-c3: 1,000 games, gap +0.154 ± 0.144 (2.738 against 2.584). **Rejected**: worse, just outside the margin. The match was clean.
- **red-c8** (`d0dbef40`: main tribe fixed from round 4 to whichever leads then) against red-c3: 1,000 games, gap +0.056 ± 0.154 (2.810 against 2.754). **Rejected**: not better. The match was clean.
- **Red near a local maximum (06:30).** Red reports that since red-c3 it has probed every stopping number, tier-curve step, search setting and mechanic in practice, and found nothing beyond ±0.15. One card-table refit is still running. After that, red will ask for the stopping test on its kept version.
- **Disk (06:35).** / rose from 62% to 68% in four hours, almost all of it practice output: red/out 12 GB, blue/out 6.7 GB. Both teams were asked to keep only summaries of finished practice runs.
  - Pruned: red/out 12 GB → 1.1 GB, blue/out 6.7 GB → 7 MB. Both kept every finished run's summary and scores.
- **red-c9** (`ec276ce7`: card table refit from red-c3's on 5,000 games with each tribe held in turn; 95 cards move; adds a reservist value-floor option, off) against red-c3: 1,000 games, gap −0.648 ± 0.195 (2.228 against 2.876). **Kept.** The match was clean; field now 13,000.
  - Tribe picks: Locust 81.8% (1.99), none 14.2% (3.25), Briar 3.4% (3.59), Badger 0.4%, Mouse 0.2%; 2.3 in hand. Interim report and method summary sent.
- **blue-c13** (`984fb04c`: commits to Badger from turn one by default) against blue-c9: 1,000 games, gap −0.826 ± 0.210 (1.634 against 2.460). **Kept.** The match was clean; field now 13,500.
  - All 500 field runs end on Badger; 1st in 420 (84%). Sword-heir is on 96% of its final boards, Brock-cub 88%, Sett shield-bearer 71%. Before it, 6 of 13,000 field runs ended on Badger. Flagged to Balance Orchestrator 2.
- **red-c10** (`a5bf0142`: second tribe-diverse card-table refit, from red-c9's table on 2,000 new games plus red-c9's 1,000 test games) against red-c9: 1,000 games, gap −0.242 ± 0.175 (2.238 against 2.480). **Kept.** The match was clean; field now 14,000.
  - Tribe picks: Locust 69.4% (2.05), none 22.0% (2.91), Badger 6.8% (1.29), Briar 1.0%, Pigeon 0.8%; 2.3 in hand. Red now picks Badger by itself and places best on it, a second sign that Badger is strong. Interim report and method summary sent.
- **Leads stalled, 08:38–10:40.** Both team threads stopped at about 08:38 and lost their background jobs, though blue's last trial finished at 08:39. No tags for two hours. Both were nudged at 10:40 to collect their results and carry on.
- **Blue idle, 11:42–12:35.** Its scaling trial finished at 11:42, but the thread had stopped watching it after the earlier stall. Nudged.
- **red-c11** (`ebe4c508`: main tribe fixed from round 1, as soon as one tribe leads) against red-c10: 1,000 games, gap −0.066 ± 0.153 (2.286 against 2.352). **Rejected**: not better. The match was clean.
- **Ruling (12:40), the 8 ideas in the stopping test** (red asked; it applies to both teams). Rejected tags still count after a later version is kept, because the test replays them at stopping-test size against the version taken into it. Each must be expressible on that version, as a knob (preferred) or a patch. Practice results that were never tagged don't count. The 8 must cover economy, tribe choice, board order and each reworked mechanic. For red, c4–c8 (plus c11 if rejected) leave economy and holding reservists uncovered.
- **blue-c14** (`cd3b0150`: recruits freely in round 1, commits to Badger from round 2; knob `badger_from`) against blue-c13: 1,000 games, gap +0.096 ± 0.173 (1.912 against 1.816). **Rejected**: not better. The match was clean.
- **blue-c15** (`2be7142e`: same-row swap to route Hand-me-down Attack toward a piler or Needle Sister; knob `route_inheritance`) against blue-c13: 1,000 games, gap +0.042 ± 0.109 (1.774 against 1.732). **Rejected**: not better. The match was clean.
- **red-c12** (`61562128`: holding reservists; Quartermaster +15 to buy/keep at the reserve limit, Recruit aimed at the best hand unit without Reserve; knob `qm_bonus`. Also adds knobs, all off, for c4–c8, c11 and sell_dead) against red-c10: 1,000 games, gap +0.022 ± 0.136 (2.244 against 2.222). **Rejected**: not better. The match was clean.
- **red-c13** (`9ea2e7c5`: economy; with a full board, sells a hand unit that would never be played; knob `sell_dead`) against red-c10: 1,000 games, gap −0.002 ± 0.133 (2.258 against 2.260). **Rejected**: not better. The match was clean. Red's 8 ideas are now complete (c4–c8, c11, c12, c13).
- **blue-c16** (`1a651e9a`: Pile on units get first preference for back-row slots; knob `shelter_pilers`) against blue-c13: 1,000 games, gap −0.050 ± 0.135 (1.940 against 1.990). **Rejected**: not better. The match was clean.
- **blue-c16** rejected (above); blue asked for its stopping test on `d6d25427`. That commit plays as blue-c13: the diff gates every new behaviour behind a knob at its committed value, and Badger-from-round-1 equals c13's always-Badger.
- **Stopping tests 1 started (14:19).** The reference field `/data/third-run/ref-1` is cut from 1,500 live games of red-c10 against blue-c13 (`tools/league/ref_field.sh`). Then red's test runs on red-c13 with `sell_dead 0`, which plays as red-c10 (diff read), followed by blue's on `d6d25427`. Plans: `stopping-red-1-plan.tsv` (37 matches) and `stopping-blue-1-plan.tsv` (27).
  - Each number a step each way and each of the 8 ideas: 2,900 games (1,450 pairs). A neighbour that beats the test version is replayed once on fresh seeds.
  - Report-only, 1,000 games each: each tribe held with `stay_tribe`, and the 4 off switches.
  - Not used: early stopping at 500 pairs. It needs one match split in two without reusing runs, which the tool can't do, so every match runs at full size.
  - Runs detached (`tools/league/stop_chain_1.sh`, log `/data/third-run/stopping/chain.log`). Every match on cores 2–5 now takes `flock /data/third-run/cores.lock`, so climbing matches and test matches take turns.
- **Approval watch killed (13:13, 14:15, 14:24).** Three times the whole shell running the watch died with code 144, and at 14:24 every other session's watch died too: something on the machine kills processes matching `t3-approval-watch`. The referee now runs a renamed copy, which matches neither name.
- **Reference field ready (15:12).** `/data/third-run/ref-1`: 12,000 runs from 1,500 live games of red-c10 against blue-c13 (labels `red`/`blue`, 6,000 each), verified. On it the test version places about 4.05, where red-c10 placed about 2.2 on the climbing field: half the reference field is blue-c13.
- **Red test, first results.** `swap_margin+` (−3 → −1) **beats** the test version: −0.236 ± 0.099. Its replay on fresh seeds is queued at the end of the plan (`swap_margin+replay`). `swap_margin-` is worse (+0.228 ± 0.111). Both `pair_bonus` neighbours show no clear difference.

## Daily report, 22 Nov (sent to the owner)

- Kept since the last report: red-c3, red-c9 and red-c10 (3 of 11 hand-ins); blue-c7, blue-c8, blue-c9 and blue-c13 (4 of 10).
- Gap: in the reference field's 1,500 live games of red-c10 against blue-c13 (4 seats each), red averages 4.25 and blue 4.75, but blue wins more often (16.6% of seats first, red 8.4%). Four live Badger players share one pool there, which ghost play never has.
- Badger flag: blue-c13 plays Badger in every game and won 84% of its climbing-field runs. Red's card refits started picking Badger on their own (6.8% of runs, best mean place). Sent to Balance Orchestrator 2.
- Stopping test, red (red-c10): 11 of 37 matches done. One neighbour beats it: swap_margin −1 (−0.236 ± 0.099), replay queued. Three are worse, seven show no clear difference. Ends about 02:00 on 23 Nov. *(Stopped at 19:05; see below.)*
- Stopping test, blue (blue-c13): queued after red's, about 7 hours.
- Incidents: both team leads stalled 08:38–10:40 (nudged). Approval watches were killed by name across sessions; the referee's now runs renamed.
- **red-c14** (`c219a71d`: swap_margin −3 → 5, a shop unit must beat the worst board unit by 5 to replace it) against red-c10: 1,000 games, gap −0.242 ± 0.161 (2.062 against 2.304). **Kept.** The match was clean. It came from the stopping test's `swap_margin+` result and red's practice sweep of swap_margin (−1 to +12, a plateau from +1 to +8).
- **Red-c10's stopping test stopped at 19:05**, 14 of 37 matches done, because red-c14 was kept and red-c10 can no longer pass. Results are in `/data/third-run/stopping/red-1/results.txt` and were sent to red. Worse: swap_margin −5, growth_turns 0.05, max_refresh 8, syn_per_unit 2. Beats: swap_margin −1. No clear difference: the other 8. Blue's test started at once (`tools/league/stop_chain_1b.sh`), on the same reference field.
  - red-c14's tribe picks: Locust 70.0% (1.99), none 22.6% (2.23), Badger 5.6% (1.75), Briar 1.4%, Pigeon 0.4%; 2.1 in hand. Field now 14,500. Interim report sent.
- **Blue test, first 5 of 27 (20:34).** Worse: up2 3, up3 7, lift_w 125. No clear difference: up2 5, up3 9. None beats it. The test version places about 4.5 on the reference field. Sent to blue.
- **Blue test, 11 of 27 (22:34).** `replace_margin+` (4 → 7) **beats** the test version: −0.123 ± 0.102. Its replay is queued at the end. Like red's swap_margin, it makes the bot less ready to replace a board unit. No clear difference: lift_w 75, replace_margin 1, free_hand_slots 2 and 0, idea-c3 (deploy_corporal).
- **red-c15** (`aeb0b5ea`: red-c14 with sell_dead 1, selling never-played hand units when the board is full) against red-c14: 1,000 games, gap −0.040 ± 0.130 (2.086 against 2.126). **Rejected**: not better. The match was clean.
- **red-c16** (`4728c58d`: tier curve one round later on red-c14; tier 2 at round 6, 3 at 9, 4 at 12, 5 at 14) against red-c14: 1,000 games, gap −0.110 ± 0.124 (2.082 against 2.192). **Rejected**: not better. The match was clean.
- **Blue test, 17 of 28 (00:31).** Ideas c5, c10, c11, c12, c15: no clear difference. idea-c14 (badger_from 2): worse, +0.342 ± 0.121. Sent to blue.
- **Red test 2 queued (00:36), on `4b9d95cd`.** That commit plays as red-c14: only knob lines changed, all at red-c14's values. Its reference field `/data/third-run/ref-2` is cut fresh from red-c14 against blue-c13. The plan has 36 matches (`stopping-red-2-plan.tsv`): 20 neighbours, 7 idea replays (c13 and c15 share `sell_dead`), and 9 report matches. They take turns with blue's test under the cores lock (`tools/league/stop_chain_2r.sh`).
- **Blue test, report matches (to 04:15).** Held to one tribe, placing against the test version's ~4.6: Badger 4.63 (no clear difference: Badger is what it plays), Locust 5.77, Briar 6.70, Pigeon 6.96, Mouse 6.99. Blue's bot plays only Badger well, so these measure the bot as much as the tribes (brief, section 6 caution).
  - Off switches: `off.reservists` costs +0.712 ± 0.197 and `off.actives` +0.230 ± 0.185, so blue uses both mechanics. `off.pilers` shows no clear difference, and `off.hand_me_down` came out "better" (−0.186 ± 0.156). Both switches only gate knobs that are off by default (`shelter_pilers`, `route_inheritance`). `off.hand_me_down` changes nothing but a report label, so the "better" result is chance: an identical bot passing the 95% bar, about 1 time in 40. Blue's bot makes no dedicated Pile on or Hand-me-down choices.
- **Red test 2, first 8 of 36.** Worse: triple_bonus 8, growth_turns 0.05. No clear difference: swap_margin 8 and 2, pair_bonus 11 and 5, triple_bonus 16, growth_turns 0.25. None beats it.
- **Blue's stopping test 1: not passed (06:13).** The `replace_margin` 7 replay beat the test version again on fresh seeds: −0.147 ± 0.111, after −0.123 ± 0.102. So blue-c13 is not at a local maximum, and blue climbs on. Everything else, 10 numbers' other steps and all 8 ideas, showed no clear difference or worse. Full results in `stopping-blue-1-results.txt` (red-1's are in `stopping-red-1-results.txt`). The reference field `ref-1` is deleted: no test uses it now.
- **blue-c17** (`1056d710`: replace_margin 4 → 7, from blue's stopping test) against blue-c13: 1,000 games, gap −0.164 ± 0.150 (1.844 against 2.008). **Kept.** The match was clean. Blue's practice found no further gain at 8 or 10.
- **Blue test 2 queued (06:35), on blue-c17.** Its reference field `/data/third-run/ref-3` is cut from red-c14 against blue-c17. The plan is blue-1's with replace_margin centred on 7 (10 and 4): 27 matches (`stopping-blue-2-plan.tsv`, `tools/league/stop_chain_2b.sh`). It takes turns with red's test 2.
  - blue-c17 runs added (500, all Badger, mean place 1.84); field now 15,000. Interim report sent, with blue-c13's test findings.
- **Blue test 2, 14 of 27 (14:31).** `lift_w-` (100 → 75) **beats** blue-c17: −0.216 ± 0.117; replay queued (`lift_w-replay`). `idea-c5` (free_hand_slots 3) **beats** it: −0.104 ± 0.098; replay queued (`idea-c5-replay`). Worse: up2 3, up3 7, lift_w 125, replace_margin 4. No clear difference: up2 5, up3 9, replace_margin 10, free_hand_slots 2 and 0, ideas c3 and c10.
- **red-c14 PASSED its stopping test (14:31).** None of its 27 neighbours beats it: 20 number steps (worse: triple_bonus 8, growth_turns 0.05; the rest no clear difference) and 7 idea replays (all no clear difference). Report matches so far, each tribe held all game: Badger 3.62 against 3.80 (−0.184 ± 0.183, report only, not replayed), Mouse and Locust no clear difference, Pigeon worse (+0.210 ± 0.174). Briar and the 4 off switches are still running. Red is told to hold its restart climbs until the owner has heard (a pass is a stop-and-ask case).
- **Red test 2 complete (15:46).** Last report matches: Briar held, no clear difference. Off switches: reservists +0.720 ± 0.188 and actives +0.200 ± 0.168 (both used); pilers −0.122 ± 0.146 and hand_me_down −0.038 ± 0.153 (no clear difference: red's bot gets nothing from those two). Results in `stopping-red-2-results.txt`; `ref-2` deleted. Sent to red.
- **Blue test 2, 25 of 30 (16:31).** `idea-c15` (route_inheritance 1) **beats** blue-c17: −0.113 ± 0.094; replay queued. idea-c14 (badger_from 2) worse again (+0.213); ideas c11, c12, c16 no clear difference. Held to one tribe: Badger no clear difference (4.53 against 4.60), Locust 5.81, Briar 6.69, Pigeon 6.88, Mouse 7.10. Off switches: reservists +0.704 ± 0.204 (used), actives no clear difference (+0.092 ± 0.171).
- **Blue test 2 complete (17:16): not passed.** `idea-c5-replay` (free_hand_slots 3) beat blue-c17 again: −0.143 ± 0.097, after −0.104 ± 0.098. The other two first wins failed their replays: lift_w 75 (−0.088 ± 0.119) and route_inheritance (−0.008 ± 0.092). Off switches pilers and hand_me_down: no clear difference. Results in `stopping-blue-2-results.txt`; `ref-3` deleted. Sent to blue, which climbs on.
- **Gap, from ref-3's live games** (1,500 games of red-c14 against blue-c17, 4 seats each, cut at 09:17): red 4.13 mean place, first 9.5%, top four 57.4%; blue 4.87, first 15.5%, top four 42.6%.

- **Ruling (23 Nov, asked by blue): a kept idea leaves the 8; its reverse step is not an idea.** When a rejected idea is later kept, it drops out of the 8, and the reverse change does not replace it: that is the old setting, which just lost, so replaying it tests nothing the climb did not. The 8 must still cover each area (economy, tribe choice, board order, each reworked mechanic), so the team hands in another rejected climbing tag for the area that lost its idea. Sent to blue; methods summary to red.
- **blue-c18** (`ca7869df`: free_hand_slots 1 → 3, the confirmed c5 replay) against blue-c17: playing (18:40).

## Daily report, 23 Nov (sent to the owner)

- Kept since the last report: red-c14 (swap_margin 5) and blue-c17 (replace_margin 7). Both make the bot slower to swap a board unit for a shop unit. No tags handed in today: both teams held their bots still for the stopping tests.
- Gap: in 1,500 live games of red-c14 against blue-c17, red averages 4.13 and blue 4.87, but blue wins more often (15.5% first against 9.5%). Same pattern as yesterday: blue's all-Badger bot wins big or goes out early.
- Stopping test, red-c14: **passed** (27 neighbours, none better). Held for the owner's answer on restarts and on handing it to balance.
- Stopping test, blue-c17: not passed. Keeping 3 hand slots free beat it twice; blue climbs on.
- Incident: the machine restarted overnight; both tests resumed at 08:36 with no results lost.
- **blue-c18** (`ca7869df`: free_hand_slots 1 → 3) against blue-c17: 1,000 games, gap +0.072 ± 0.134 (2.076 against 2.004). **Not better**; the match was clean. **Parked for the owner, not rejected:** the same change beat blue-c17 twice on the reference field (strong: red-c14 and blue-c17 runs only), but not on the climbing field, which is 8,000 m2 runs plus 500 per kept version, where kept bots place about 2.0. A Fable advisor recommends, for the owner: a stopping-test neighbour that counted (won twice) is kept when tagged as that exact change, unless its climbing match shows it significantly worse; ageing the m2 runs out is the longer-term fix, for a next run. Blue climbs on meanwhile.
