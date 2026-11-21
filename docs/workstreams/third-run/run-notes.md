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
| red | red-m2 | start | — |
| blue | blue-m2 | start | — |

## Log
- **21 Nov, Ghost Build Orchestrator:** it accepted both points. It is landing the check-crate fix (`a5c90160`) on dev on its own, and will send each future engine port as a dev tag for the referee to bring in the same way. When the fix is merged, bring it into both clones as one referee commit, and move each clone's `third-run-engine-v1` to the engine tree plus the fix, so the teams can run check-crate themselves.
- **Ruling, off switches (blue asked; both told):** a switch turns off the bot's own choices for that mechanic (placing, routing, holding, using, and any buy or keep value given for it). The cards stay in the pool and passive triggers still happen. Each switch is described in `knobs.txt` and must show in the decision log.
- **blue-c1** (`6adfe665`, pre-rework placement lift discounted from 100 to 35) against blue-m2: 1,000 games, gap +0.198 ± 0.205 (4.576 against 4.378). **Rejected.** The match was clean (500 pairs, 3,500 distinct runs, no clock-outs or faults), took 254 s, and was pruned to 20 KB.
