# Merge and tidy, 21 Nov 2026: what was done, and what blocks progress

The owner's words, 21 Nov (dictated): "I want to get all branches merged. And not all branches. All relevant branches that are required from improvements that I've asked for merge from dev in domain. All old work trees and branches cleaned up on both this PC and the Ocuplex, and I also want to get all outstanding issues that prevent forward progress logged in a report."

Then: "I want you to get us a full playable build. [...] I want all things blocking us fixed." And on the loose ends: "Can you fix the loose ends? I would like you to fix them. I agree with all the actions you imply."

This report covers the Optiplex. The assurance session cleans the PC.

## 1. Where things stand

- **The playable build is done.** `Bramble-windows-340224dc8-1121-1043-ghosts-batch-1.zip` (169 MB) went to the owner's PC by Taildrop on 21 Nov.
  - It plays against 8,000 ghosts from 1,000 bot games, with balance batch 1.
  - It finished a whole ghost game on the Linux runtime and under Wine.
  - No one has played it on real Windows hardware yet.
- **`main`:** PR 216 carries everything on `dev` (see section 3).
- **Optiplex:** cleaned (section 4). 27 worktrees are now 10, and 80 local branches are now 12.

## 2. What still blocks progress

### Waiting on the owner

| What is stopped | The decision | Where |
|---|---|---|
| Fix round steps 1–7, 11, 12 (the bugs you raised, shop layout, type line, tooltips, keyword looks, animations) | Plan decisions 1–9, 12 and 13 | One message in the fix-round thread, with its [recommendation page](https://claude.ai/artifact/LuKsXGPJzCxSkneGpM8kAc) |
| Batch 1's agent defaults (8.4.1a, the order within 9.6.1, 9.6.1a, 9.6.2a) | You'll test the build and come back ("I'll test and come back with feedback") | Tagged PROPOSED until then |
| Golden Supply | Does a golden double Supply N? (rulebook 7.3.5a, PROPOSED; plays as before) | Nothing waits on it yet |
| The reworks mock-up (`docs/ideation-track-2/mockups/recruit_tribes.json`) shows pre-tuning numbers | Update it, or leave it as the look reference? Recommended: leave it; the real numbers live in `units.json` | Balance session |
| Owner notes | Edit a changed instruction into the existing note, or write a new one? `CLAUDE.md` says new note; the 20 Nov rule says edit in place. Recommended: edit in place, and change `CLAUDE.md` | — |
| Codex worker briefs | Change the `codex-workers` skill's "remove your scratch files" to "never run `rm -rf`; list leftovers"? Recommended: yes | Your skill |
| PR 204 (CI result on docs-only PRs) | Two answers the assurance session is waiting on | Assurance session |
| Old review-queue items | Rulebook's ~45 proposed defaults; the unreviewed pillars; the unnamed board-lock keyword (`docs/design/review-queue.md` 16–20) | Not blocking today's work |

### Unfinished work

- **Balance is not measured.** The final league bots predate batch 1's cards, so the ghosts test the system, not balance. A balance reading needs bots that pass the stopping test, on the current cards. (Balance Orchestrator 2, then the third run)
- **Step E:** comparing whole fight logs between the game and the Rust engine; then the third-run briefs for you. (Ghost Build Orchestrator, next)
- **`t3-approval-watch.py`** once exited with code 144 and no output for the fix-round session; it runs with the arguments `30 60`. (Unowned)
- **The `check.sh` log scan drops every "Error G1" line** (`scripts/check.sh:206`). A test that hits G1 by accident would not fail on that line. The build and export checks still fail with no ghosts, so it is minor. (Ghost Build Orchestrator)

## 3. What was merged

Into `dev`, 21 Nov:

| PR | What | By |
|---|---|---|
| 213 | Rust engine port of 208, 209, 212 | Ghost Build Orchestrator |
| 214 | Balance batch 1: your card picks, 8 tribeless cards, Hopper overflow, dead-unit rules | Balance Orchestrator 2 |
| 217 | Your calls: rulebook 2.1.11 and 2.1.12; a fixed thread count for scored matches | Ghost Build Orchestrator |
| 218 | `tools/look` and `tools/feel` clear the desktop input method, as `check.sh` does | This session |
| 219, 223 | Balance hand-over brought up to date; your picks retagged BRAMBLE | Balance Orchestrator 2 |
| 220 | The game against ghosts: no save on a mid-game quit, Past boards kept, no ghosts is "Error G1" and fails the build and tests, every build ships a field at its rules | Ghost Build Orchestrator |
| 221 | The recruit screen plays the start-of-turn payouts | Fix-round session |
| 222 | Rust engine port of batch 1 | Ghost Build Orchestrator |
| 224 | Rulebook 7.3.5: the golden rule is yours, in your words; `STATUS.md` says the game plays ghosts | This session |

`dev` into `main` is PR 216. Your say-so, 21 Nov: batch 1 "can go to main"; "the four agent calls we will keep as proposed"; the golden rule "comes directly from me".

Its gates:
- `check.sh` passed on `dev` c2b25876; each later PR passed it on its own merge.
- Two scope reviews, at c2b25876 and at 340224dc: no cuts. All their asks are answered above. Only docs changed after 340224dc.

## 4. What was deleted on the Optiplex

Each one was clean, had every commit on GitHub, and had its work on `main` or `dev`. Unmerged branches were tagged `archive/branches/<name>` on GitHub before they were deleted.

- **14 worktrees:**
  - 7 T3 worker worktrees at 13f44dd9, which is on `main`.
  - 6 `.claude/worktrees` held by Claude desktop sessions from 18 Nov. Those sessions were closed first.
  - `league-t3-amend`, after its branch was pushed.
- **Local branches:** about 65.
  - In `main` or `dev`, or on `dev` as identical patches (`git cherry` lists none missing).
  - Batch 1's and ghost step B and C's worker branches, after their PRs merged.
- **Remote branches, archive-tagged first:**
  - `engine/badgers`, `engine/badgers-port`, `engine/pass1-cleave`, `engine/night-integration`: their only commits not on `dev` were rules-pin refreshes for old fingerprints.
  - `engine/refight`: the `league refight` command, on an old engine. The balance session will ask for a port if it needs it.
  - `league/engine`, `league/t3-amend`: the league's engine history and the referee's amendments, including `pin_teams.sh`.
  - `ideation/track-2`: frozen 17 Nov, already on `dev`.
- **Remote branches already merged:** `orch/ghost-system`, `design/pigeon-mouse-reworks`, `night/keywords-action-strip`.
- **Stopped:** `pin_teams.sh` (running since 18 Nov; its last pin was on 19 Nov). The League Data and Storage session has been told.
- **Folders:**
  - `/data/bramble-builds/1112-0603-ideation9` (2.4 GB, a 12 Nov build), superseded.
  - `/data/balance-endcheck` and `/data/measure/reworks-scripts`: the balance hand-over called them safe.
  - This session's own gate folders.
- `~/code/Bramble` is at `origin/main`.

## 5. What was left, and why

| Thing | Why kept | Next |
|---|---|---|
| Live sessions' worktrees: `orch-balance-2-*`, `orch-ghost-build-*`, `/data/worktrees/fix-round-dev` | In use | Their owners remove them when done |
| Ghost session's worker worktrees and `/data/ghost-b`, `/data/ghost-c`, `/data/port-b1` (3.8 GB), `/data/port-fr` (9.1 GB) | The ghost session's | It removes them; it keeps `port-b1`, the reference data at batch 1's rules, until the next card change |
| `~/league/*` (57 GB, on `/`, now 87% full) and its four git worktrees | The owner asked for a separate session | League Data and Storage session |
| `measure/baseline`, `measure/arm-b`, `measure/arm-c` and `/data/measure` (2.8 GB) | The only league readings of balance pass 1 | Archive once the third run's readings replace them |
| `design/glass-mockups` | Your mock-ups; `tools/glass/pull_mockups.py` and `compare.py` read them from this branch | Keep |
| `orch/balance-2`, `orch/ghost-build`, `plan/fix-round-dev-20-nov`, `ci/docs-only-result` | Live sessions and open PRs | — |
| `/data/bramble-reference` (432 MB), `/data/bramble-gallery` (112 MB), `/data/bramble-builds/region-compare-2026-11-17` and `track-2` (274 MB) | Reference pictures of other games, art-direction gallery images, and screen compares. None is in git, and I couldn't confirm a copy in R2 | Upload to R2 or delete: your call |
| `/data/bramble-art` (1.4 GB) | `fix-round-20-nov` (71 MB) waits on the art pick (plan decision 5) | Check the rest is in R2, then delete |
| `~/.codex/sessions` (7.8 GB, on `/`) | Codex's own session logs | Trim the oldest if `/` gets tight |

## 6. Is the problem fixed?

- **The full playable build:** yes. It is on your PC.
- **Asked-for work merged into `main`:** yes, once PR 216 merges.
- **Old worktrees and branches on the Optiplex:** done, apart from what live sessions and the league session hold (section 5).
- **Blockers logged:** section 2. The fix round's 12 decisions block the most.
