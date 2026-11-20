# Merge and tidy, 21 Nov 2026: what was done, and what blocks progress

The owner's words, 21 Nov (dictated): "I want to get all branches merged. And not all branches. All relevant branches that are required from improvements that I've asked for merge from dev in domain. All old work trees and branches cleaned up on both this PC and the Ocuplex, and I also want to get all outstanding issues that prevent forward progress logged in a report." Read as: merge the asked-for work into `dev`, then `dev` into `main`; clean up both machines; report the blockers.

This report covers the Optiplex. The assurance session cleans the PC.

## 1. The owner's answers (21 Nov)

The owner, dictated: "I want you to get us a full playable build. So I don't want PR213 merged. I want all things blocking us fixed. [...] I agree with the calls. The passport [Past boards] screen, actually, I don't mind that. [...] If it's been added already, no reason to take it out. If it's not been added, then don't add it to scope yet [...] No ghost to play against in this version. That should be a failing bug. We should always generate ghosts right now. You can have an error code for it, I guess, but it shouldn't ever occur for failure tests."

*[Read as "not only PR 213": merge it, and fix everything that blocks. "The calls" are this report's recommendations.]*

- PR 213: merge. Done.
- Ghost step B: no save on a mid-game quit; keep the Past boards screen (it is built); no ghosts is an error ("Error G1"), and the build and tests fail on it. In progress.
- Fixed thread count for scored matches; rulebook 2.1.11 and 2.1.12 accepted. Done (PR 217).
- `dev` into `main` after 214 and its Rust port, in one merge.

## 2. The owner's decisions still open, most blocking first

| # | What is stopped | The decision | Owner of the work | Recommendation |
|---|---|---|---|---|
| 1 | Fix round steps 1–5 (the bugs you raised) | Plan decisions 1–5 on PR 206: hand overflow pile; buying to the board with a full hand and swapping; the Skip button; duplicate marks; art A or B for 16 cards | Fix-round session | It is putting them to you in one message, with its recommendations |
| 2 | Fix round steps 6, 7, 11, 12 (shop layout, type line, tooltips, animations) | Plan decisions 6–9 and 13 | Fix-round session | The same message |
| 3 | `dev` into `main` (PR 216) | Is rulebook 7.3.5's golden rule ("stats and the signature double", "twice becomes three times", caps stay) decided? It is tagged decided by delegation, but plan decision 10 isn't settled, and it replaces your 27 Oct "doubles every number" | Fix-round session | Confirm it, or it is tagged PROPOSED before `main` |
| 4 | Golden Supply | Does a golden double Supply N? (rulebook 7.3.5a, PROPOSED; plays as before) | Balance and fix-round sessions | Your call; nothing waits on it yet |
| 5 | Owner notes | Edit a changed instruction into the existing note, or write a new note? `CLAUDE.md` says new note; the 20 Nov rule says edit in place | Any | Edit in place, and change `CLAUDE.md` to match |
| 6 | Codex worker briefs | Change the `codex-workers` skill's "remove your scratch files" to "never run `rm -rf`; list leftovers"? (It caused the overnight stalls) | Your skill | Yes |
| 7 | The reworks mock-up (`docs/ideation-track-2/mockups/recruit_tribes.json`) shows pre-tuning numbers | Update it, or leave it as the look reference? | Balance Orchestrator 2 | Leave it; the real numbers live in `units.json` |
| 8 | PR 204 (CI result on docs-only PRs) | Two answers the assurance session is waiting on | Assurance session | — |
| 9 | Old review-queue items | Rulebook's ~45 proposed defaults (skim, flag); the unreviewed pillars; the unnamed board-lock keyword; the build's agent calls (`docs/design/review-queue.md` 16–20) | Owner | Not blocking today's work |

## 3. The road to a full playable build

The Ghost Build Orchestrator's order and estimates, 21 Nov:

1. **Worker C (running, 4–6 hours, then 1–2 for gates):** finishes step B as above; `make_field.sh` plays the final bots and cuts a field; `build_windows.sh` always ships a field that matches the build's rules, `index.jsonl` included; the exported game plays a whole ghost game at boot as a check.
2. **Interim build, `before-balance-batch-1`:** from C's commit, with a 1,000-game field, sent to your PC by Taildrop.
3. **PR 214** (balance batch 1) merges, then its Rust port: about a day, the biggest risk, since the dead-unit rule changes combat.
4. **The real field** (1,000 games, about 8,000 runs) and **the final Windows build**: about 2 hours.

About 1.5 days in all if nothing breaks. Other unfinished work:

- **No balance number can be measured yet.** It needs step 3, then bots that pass the stopping test. The final league bots predate batch 1's cards, so the field tests the system, not balance. (Balance Orchestrator 2)
- **The recruit screen doesn't show start-of-turn payouts** (Grudge, Relic Seeker, Old Campaigner pay silently), and PR 209's to-dos (Molt and Root tooltips say "once"; Brood Mother's wording at 1). Asked to start now. (Fix-round session)
- **`t3-approval-watch.py`** exited with code 144 and no output for the fix-round session; it runs for this one. (Unowned)

## 4. What was merged

- PR 213 (Rust engine port of 208, 209, 212), PR 217 (2.1.11, 2.1.12, fixed thread count): by the Ghost Build Orchestrator.
- `tools/look` and `tools/feel` clear the desktop input method, as `check.sh` does (`fix/tools-xmodifiers`): by this session.
- Waiting: PR 214 (merges next), PR 206 (the plan, not decided), PR 204 (the assurance session's), PR 216 (`dev` into `main`, after the port).
- PR 216's gates on `dev` c2b25876: `check.sh` passed all 13 steps; scope review: no cuts, two asks (decision 3, and the Rust proof, now fixed by 213). It carries PRs 199–203 and 207–212. Three change play: 208 (end-of-fight effects pay at the start of the next turn; Grudge N; delegated by you), 209 (golden data and rule text, no power change), 212 (a golden doubles Charge and Pile on; your "Double them too").

## 5. What was deleted on the Optiplex

Each one was clean, had every commit on GitHub, and had its work on `main` or `dev`.

- **7 worktrees** (108 MB each) at 13f44dd9, which is on `main`: `t3/tune-mouse-pigeon`, `t3/tune-round3-mice`, `t3/tune-pigeon-round-four`, `t3/mouse-pigeon-round2-tuning`, `t3/fix-recruit-pitch-timing`, `t3/pile-on-jab-timing`, `t3/pile-on-jab-impact`.
- **48 local branches**: 43 already in `main` or `dev`, and 5 whose commits are on `dev` as identical patches (`git cherry` lists none missing): `t3/rust-level-dev-rework-s6`, `-s7`, `t3/port-created-unit-sell`, `t3/rust-engine-dev-rework`, `t3/tribebot-pigeon-mouse`.
- **Dead remote branches**, tagged `archive/branches/<name>` first: `engine/badgers`, `engine/badgers-port`, `engine/pass1-cleave`, `engine/night-integration`, and their local copies. Their only commits not on `dev` are rules-pin refreshes for old fingerprints; the ghost session agreed.
- **`engine/refight`** (the `league refight` command, built on an old engine), tagged `archive/branches/engine/refight` first, on the balance session's word: it will ask for a port if it needs the command again.
- **Merged remote branches**: `orch/ghost-system`, `design/pigeon-mouse-reworks`, `night/keywords-action-strip`.
- Other sessions removed their own at the same time: `balance/endcheck-films` (worktree and both branches), `t3/golden-card-shapes`, and four merged balance branches.

Result: 27 worktrees became 18, and 80 local branches became 23. `~/code/Bramble` was brought up to `origin/main`.

## 6. What was left, and why

| Thing | Why kept | Recommendation |
|---|---|---|
| Worktrees of the live orchestrators (`orch-balance-2-*`, `orch-ghost-build-*`), `/data/worktrees/fix-round-dev`, `t3-b6e69f25` (PR 213's source) | In use | Their owners remove them when their PRs merge |
| `t3-27a05123` on `t3/play-against-ghosts`, and `/data/ghost-b` (127 MB) | Ghost step B, pushed as `ghost/b-play-against-ghosts`; worker C finishes it | The ghost session removes them when C merges |
| Six `.claude/worktrees/` (`admiring-hopper`, `gifted-lumiere`, `night-18-nov`, `recursing-williamson`, `resource-guardrails`, `league-engine-463b0c`) | Each has a Claude desktop session process running since 18 Nov. All their work is on `main`, except `league-engine-463b0c`, which is the league's | Close those six desktop sessions; then the five can go |
| `league-t3-amend` worktree and `league/t3-amend` (47 commits not on GitHub), `claude/league-engine-463b0c`, remote `league/engine` | The league referee's. `pin_teams.sh` (pid 386835) still runs from it, last pinning on 19 Nov | Stop `pin_teams.sh`; push or bundle `league/t3-amend`; then archive all three |
| `~/league/*` (57 GB on `/`; `blue` 24 GB, `fights` 15 GB, `matches` 7.5 GB) | The old league's teams and match data. Plan decision 6d carries the team sessions over | The biggest thing filling `/` (88% full). Keep until you've seen the third-run briefs, then move `fights` and `matches` to `/data` or R2 |
| `measure/baseline`, `measure/arm-b`, `measure/arm-c` and `/data/measure` (2.8 GB) | The only league readings of balance pass 1 | Archive once the third run's readings replace them |
| `design/glass-mockups` | Your mock-ups. `tools/glass/pull_mockups.py` and `compare.py` read them from this branch, so it is live | Keep; or, on your say-so, move them onto `main` |
| `ideation/track-2` (remote) | Frozen 17 Nov; on `dev` already | Can go whenever you like |
| Batch 1's worker branches (`t3/ignore-dead-units`, `t3/add-neutral-pool-mechanics`, `t3/badger-mouse-card-updates`, `t3/hopper-overflow-locust-briar`) | Their work is in PR 214, not yet on `dev` | Delete when 214 merges |
| `balance/batch-1`, `plan/fix-round-dev-20-nov`, `orch/*` | Open PRs and live sessions | — |

## 7. Folders outside git, for you to decide

| Folder | Size | Recommendation |
|---|---|---|
| `/data/port-fr` and `/data/cargo-target/port-fr` | 9.1 GB + 2.0 GB | PR 213's proof output. The ghost session deletes them when 213 merges |
| `/data/bramble-builds` | 2.7 GB | Keep the newest build; delete the rest |
| `/data/cargo-target` | 2.4 GB | Build cache. Safe to delete any time; it rebuilds |
| `/data/bramble-art` | 1.4 GB | `fix-round-20-nov` (71 MB) waits on the art pick (plan decision 5). Check the rest is in R2, then delete |
| `/data/bramble-reference` | 432 MB | Old reference data. Delete if nothing names it |
| `/data/bramble-gallery` | 112 MB | The gallery server on port 8790 isn't running any more. Delete |
| `/data/bramble-portal` | gone | — |
| `/data/night-19nov` | 72 KB (was 11 GB) | Already cleared; keep `brief-common.md` |
| `/data/balance-endcheck`, `/data/measure/reworks-scripts` | small | The balance hand-over says safe to delete |
| `/data/balance2`, `/data/ghost-b`, `/data/orch-ghost` | small | Live sessions' notes; they clear them |
| `~/.codex/sessions` (7.8 GB, on `/`) | 7.8 GB | Old Codex session logs. Trim the oldest if `/` gets tight |
| `/data/tmp-tidy`, `/data/cargo-target/tidy` | — | This session's gate run; I deleted them at the end |

## 8. What this does not fix yet

The owner asked for a full playable build, and for the asked-for work merged into `main`. Neither is done yet. The interim build comes when worker C lands (section 3). The final build and the `dev` into `main` merge come after PR 214's Rust port. The fix round waits on your decisions in section 2.
