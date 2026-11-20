# Merge and tidy, 21 Nov 2026: what was done, and what blocks progress

The owner's words, 21 Nov (dictated): "I want to get all branches merged. And not all branches. All relevant branches that are required from improvements that I've asked for merge from dev in domain. All old work trees and branches cleaned up on both this PC and the Ocuplex, and I also want to get all outstanding issues that prevent forward progress logged in a report." Read as: merge the asked-for work into `dev`, then `dev` into `main`; clean up both machines; report the blockers.

This report covers the Optiplex. The assurance session cleans the PC.

## 1. The owner's decisions, most blocking first

| # | What is stopped | The decision | Owner of the work | Recommendation |
|---|---|---|---|---|
| 1 | PR 213 (Rust engine port of 208, 209, 212). Behind it: PR 214, the batch's Rust port, the ghost field, every bot run and climb, and `dev` into `main` (see 3) | Merge 213 with two Rust functions that have no caller yet (`GhostRun::parse_with_info`, `RecordReplay::rebuild_with_observer`)? They mirror GDScript, as `PORTING.md` requires | Ghost Build Orchestrator | Yes |
| 2 | `dev` into `main` | Is rulebook 7.3.5's golden rule ("stats and the signature double", "twice becomes three times", caps stay) decided? It is tagged decided by delegation, but plan decision 10 isn't settled and its source doc says "proposal, not decided". It replaces your 27 Oct "doubles every number" | Fix-round session | Confirm it, or re-tag it PROPOSED before `main` |
| 3 | `dev` into `main` | Merge now, or after 213? Until 213 lands, the Rust league proof fails on `dev`, and would fail on `main` too | This session | After 213, then 214 too: one merge that keeps the game and the Rust engine in step |
| 4 | Fix round steps 1–5 (the bugs you raised) | Plan decisions 1–5 on PR 206: hand overflow pile; buying to the board with a full hand and swapping; the Skip button; duplicate marks; art A or B for 16 cards | Fix-round session | Answer on PR 206 |
| 5 | Fix round steps 6, 7, 11, 12 (shop layout, type line, tooltips, animations) | Plan decisions 6–9 and 13 | Fix-round session | Answer on PR 206 |
| 6 | Ghost step B, the game played against ghosts (built, checked, on the local branch `t3/play-against-ghosts`) | Three calls: drop saving a run on a mid-game quit; remove the unplanned "Past boards" screen; no-ghosts message "No ghosts to play against in this version." | Ghost Build Orchestrator | Yes to all three |
| 7 | Golden Supply | Does a golden double Supply N? (rulebook 7.3.5a, PROPOSED; plays as before) | Balance and fix-round sessions | Your call; nothing waits on it yet |
| 8 | Third run's scored matches | One fixed thread count for scored matches, since the final bots aren't byte-identical across thread counts? | Ghost Build Orchestrator | Yes |
| 9 | Rulebook 2.1.11 and 2.1.12 (ghost seats) | Still PROPOSED | Ghost Build Orchestrator | Accept |
| 10 | Owner notes | Edit a changed instruction into the existing note, or write a new note? `CLAUDE.md` says new note; the 20 Nov rule says edit in place | Any | Edit in place, and change `CLAUDE.md` to match |
| 11 | Codex worker briefs | Change the `codex-workers` skill's "remove your scratch files" to "never run `rm -rf`; list leftovers"? (It caused the overnight stalls) | Owner's skill | Yes |
| 12 | Balance | Swarm-lord counting every Locust death (built, then removed); Wing Commander rework now or at the third run's first stop; update the reworks mock-up's numbers or leave it | Balance Orchestrator 2 | See the balance hand-over §7 |
| 13 | PR 204 (CI result on docs-only PRs) | Two answers the assurance session is waiting on | Assurance session | — |
| 14 | Old review-queue items | Rulebook's ~45 proposed defaults (skim, flag); the unreviewed pillars; the unnamed board-lock keyword; the build's agent calls (`docs/design/review-queue.md` 16–20) | Owner | Not blocking today's work |

## 2. Blockers that are unfinished work, not decisions

- **No balance number can be measured yet.** It needs PR 213, then PR 214, then a Rust port of the batch (about a day), then bots that pass the stopping test. Until then the balance problem is neither fixed nor measured. (Balance Orchestrator 2)
- **Ghost step B** is pushed as `ghost/b-play-against-ghosts` (7dc2255a) and waits only on decision 6. (Ghost Build Orchestrator)
- **The recruit screen doesn't show start-of-turn payouts** (Grudge, Relic Seeker, Old Campaigner pay silently). Step 8's screen half, waiting on the design steps. (Fix-round session)
- **PR 209's to-dos:** the Molt and Root tooltips say "once", and Brood Mother's wording at 1 is wrong. They matter once the new goldens are on. (Fix-round and balance sessions)
- **The Windows build with ghosts** needs the ghost `index.jsonl` in the export filter and a way to ship about 250 MB of runs. (Ghost Build Orchestrator)
- **`league refight` isn't on `dev`.** It is on `engine/refight` only. The balance hand-over wrongly calls it merged. Balance says it's the ghost session's call (it owns `tools/league`); the ghost session says ask balance. Recommendation: the balance session decides if it still needs the command; if yes, open a PR. (Both)
- **`tools/look` and `tools/feel` outside the gate** still inherit `XMODIFIERS` (a one-line fix, as in `scripts/check.sh`). (Unowned)
- **`t3-approval-watch.py`** exited with code 144 and no output for the fix-round session. (Unowned)

## 3. What was merged

Nothing new merged into `dev`: every open PR waits on a decision above.

- PR 213 waits on decision 1. PR 214 waits on PR 213 (both orchestrators agreed this order). PR 206 is the plan, not decided. PR 204 is the assurance session's.
- `dev` into `main`: the PR is open, not merged (decisions 2 and 3). The gates: `scripts/check.sh` on `dev` (c2b25876) passed all 13 steps; scope review: no cuts, the two asks above. It carries PRs 199–203 and 207–212. Of those, three change play: 208 (end-of-fight effects pay at the start of the next turn; Grudge N; delegated by you), 209 (golden data and rule text, no power change), 212 (a golden doubles Charge and Pile on; your "Double them too").

## 4. What was deleted on the Optiplex

Each one was clean, had every commit on GitHub, and had its work on `main` or `dev`.

- **7 worktrees** (108 MB each) at 13f44dd9, which is on `main`: `t3/tune-mouse-pigeon`, `t3/tune-round3-mice`, `t3/tune-pigeon-round-four`, `t3/mouse-pigeon-round2-tuning`, `t3/fix-recruit-pitch-timing`, `t3/pile-on-jab-timing`, `t3/pile-on-jab-impact`.
- **48 local branches**: 43 already in `main` or `dev`, and 5 whose commits are on `dev` as identical patches (`git cherry` lists none missing): `t3/rust-level-dev-rework-s6`, `-s7`, `t3/port-created-unit-sell`, `t3/rust-engine-dev-rework`, `t3/tribebot-pigeon-mouse`. The stale local `engine/refight` pointer (90dcaa67, on `main`) was one of them; the remote branch stays.
- **Dead remote branches**, tagged `archive/branches/<name>` first: `engine/badgers`, `engine/badgers-port`, `engine/pass1-cleave`, `engine/night-integration`, and their local copies. Their only commits not on `dev` are rules-pin refreshes for old fingerprints; the ghost session agreed.
- **Merged remote branches**: `orch/ghost-system`, `design/pigeon-mouse-reworks`, `night/keywords-action-strip`.
- Other sessions removed their own at the same time: `balance/endcheck-films` (worktree and both branches), `t3/golden-card-shapes`, and four merged balance branches.

Result: 27 worktrees became 18, and 80 local branches became 23. `~/code/Bramble` was brought up to `origin/main`.

## 5. What was left, and why

| Thing | Why kept | Recommendation |
|---|---|---|
| Worktrees of the live orchestrators (`orch-balance-2-*`, `orch-ghost-build-*`), `/data/worktrees/fix-round-dev`, `t3-b6e69f25` (PR 213's source) | In use | Their owners remove them when their PRs merge |
| `t3-27a05123` on `t3/play-against-ghosts`, and `/data/ghost-b` (127 MB) | Ghost step B, now pushed as `ghost/b-play-against-ghosts` | Waits on decision 6 |
| Six `.claude/worktrees/` (`admiring-hopper`, `gifted-lumiere`, `night-18-nov`, `recursing-williamson`, `resource-guardrails`, `league-engine-463b0c`) | Each has a Claude desktop session process running since 18 Nov. All their work is on `main`, except `league-engine-463b0c`, which is the league's | Close those six desktop sessions; then the five can go |
| `league-t3-amend` worktree and `league/t3-amend` (47 commits not on GitHub), `claude/league-engine-463b0c`, remote `league/engine` | The league referee's. `pin_teams.sh` (pid 386835) still runs from it, last pinning on 19 Nov | Stop `pin_teams.sh`; push or bundle `league/t3-amend`; then archive all three |
| `~/league/*` (57 GB on `/`; `blue` 24 GB, `fights` 15 GB, `matches` 7.5 GB) | The old league's teams and match data. Plan decision 6d carries the team sessions over | The biggest thing filling `/` (88% full). Keep until you've seen the third-run briefs, then move `fights` and `matches` to `/data` or R2 |
| `engine/refight`, `t3/add-league-refight-command` | The `league refight` command, not on `dev` | Section 2 |
| `measure/baseline`, `measure/arm-b`, `measure/arm-c` and `/data/measure` (2.8 GB) | The only league readings of balance pass 1 | Archive once the third run's readings replace them |
| `design/glass-mockups` | Your mock-ups. `tools/glass/pull_mockups.py` and `compare.py` read them from this branch, so it is live | Keep; or, on your say-so, move them onto `main` |
| `ideation/track-2` (remote) | Frozen 17 Nov; on `dev` already | Can go whenever you like |
| Batch 1's worker branches (`t3/ignore-dead-units`, `t3/add-neutral-pool-mechanics`, `t3/badger-mouse-card-updates`, `t3/hopper-overflow-locust-briar`) | Their work is in PR 214, not yet on `dev` | Delete when 214 merges |
| `balance/batch-1`, `plan/fix-round-dev-20-nov`, `orch/*` | Open PRs and live sessions | — |

## 6. Folders outside git, for you to decide

| Folder | Size | Recommendation |
|---|---|---|
| `/data/port-fr` and `/data/cargo-target/port-fr` | 9.1 GB + 2.0 GB | PR 213's proof output. The ghost session deletes them when 213 merges |
| `/data/bramble-builds` | 2.7 GB | Keep the newest build; delete the rest |
| `/data/cargo-target` | 2.4 GB | Build cache. Safe to delete any time; it rebuilds |
| `/data/bramble-art` | 1.4 GB | `fix-round-20-nov` (71 MB) waits on decision 5. Check the rest is in R2, then delete |
| `/data/bramble-reference` | 432 MB | Old reference data. Delete if nothing names it |
| `/data/bramble-gallery` | 112 MB | The gallery server on port 8790 isn't running any more. Delete |
| `/data/bramble-portal` | gone | — |
| `/data/night-19nov` | 72 KB (was 11 GB) | Already cleared; keep `brief-common.md` |
| `/data/balance-endcheck`, `/data/measure/reworks-scripts` | small | The balance hand-over says safe to delete |
| `/data/balance2`, `/data/ghost-b`, `/data/orch-ghost` | small | Live sessions' notes; they clear them |
| `~/.codex/sessions` (7.8 GB, on `/`) | 7.8 GB | Old Codex session logs. Trim the oldest if `/` gets tight |
| `/data/tmp-tidy`, `/data/cargo-target/tidy` | — | This session's gate run; I deleted them at the end |

## 7. What this does not fix

The owner's problem was "get the asked-for work merged into `main`". It isn't fixed yet. Everything waiting is listed in section 1: decision 1 (PR 213) unblocks the most. After it: PR 214 merges, then one `dev` into `main` merge carries all of it.
