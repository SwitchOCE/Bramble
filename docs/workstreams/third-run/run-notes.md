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
| red | red-c2 | 21 Nov | red-c2 vs red-c1: 1,000 games, gap −0.452 ± 0.217 (2.432 against 2.884) |
| blue | blue-c4 | 21 Nov | blue-c4 vs blue-c2: 1,000 games, gap −0.198 ± 0.168 (3.480 against 3.678) |

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
