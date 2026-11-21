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
| red | red-c3 | 21 Nov | red-c3 vs red-c2: 1,000 games, gap −0.338 ± 0.165 (2.450 against 2.788) |
| blue | blue-c9 | 22 Nov | blue-c9 vs blue-c8: 1,000 games, gap −0.558 ± 0.143 (1.938 against 2.496) |

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
