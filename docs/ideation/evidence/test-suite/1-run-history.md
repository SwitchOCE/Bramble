# Gate and test runs, 6 Nov 00:00 (+11) to 9 Nov 20:08Z

I counted 1,674 Godot runs, of which 307 were full gates. 337 runs failed, and only 28 of those were real regressions caught. 136 failures were tests run red on purpose while the code was being written. Sims, not tests, took most of the Godot time.

**Sources:** 362 Codex rollouts (`~/.codex/sessions/2026/11/05–10`), 52 Claude transcripts (orchestrator `5369878e…jsonl`, its 50 subagents, and session `842d73a8`), `/tmp/codex-bridge/*.jsonl`, worktree reflogs, and gate output and log files where they still exist.

**Method:** I parsed every command that launched Godot. Each failure is classed by what happened next: the agent's own next message, and the edits made before the next pass. All 79 failures the rules couldn't settle were classed by hand. Classes are judgement calls, not ground truth.

## 1. Totals

| Run type | Runs | Godot wall time |
|---|---|---|
| Full gates (254 full, 49 `--keep-going`, 4 `--docs-only` of which 2 refused) | 307: 181 pass, 113 fail, 13 unknown | about 15.5 h of gate time, of which about 13.2 h was Godot steps |
| Targeted GUT | 544 | 156 min (median 2 s of test time each) |
| Full GUT outside the gate | 33 | 40 min |
| Sims, benches, soaks, probes | 416 | about 31 h (measured on 392) |
| Screenshot runs | 84 | 82 min |
| Imports, compile and other Godot runs | 289 | about 4.7 h |

- **Total:** about 54 h of Godot process wall time. Sims are 58% of it; gates and GUT together are about 31%.
- **Gate time basis:** 130 gates printed their step times (408 Godot-minutes). The other 177 are estimated from their verdict and the median gate (247 s for a passing gate; the tests step alone is 205 s).
- **Lock adoption:** `bramble-godot.lock` first appears 8 Nov 11:51Z; the harness lock 9 Nov 08:29Z. 356 runs were wrapped in a lock.
- **Measured lock wait:** 67 min across 111 single-run commands. 18 of them waited more than a minute (median 130 s, max 5.8 min). Looped commands add up to 61 min more. 126 min of the measured wait fell on 9 Nov. Background runs were not measurable, so this is a lower bound; scaled to all 356 lock runs it is roughly 3–6 h.
- **Timeouts:**
  - 3 `flock -w` timeouts: one gate at 9 Nov 11:47Z and two sims at 12:58Z.
  - 2 of the 13 Codex "Turn timed out" notices came while the command was sitting on flock (session w3, 9 Nov 13:14Z and 15:36Z).
  - 75 runs ended in exit 124/130/137/143 (timeout, interrupt or kill); 19 of them were lock-wrapped.

## 2. Failed runs by class

| Class | Gate | GUT | Example evidence |
|---|---|---|---|
| (a) Real regression, then fixed in code | 15 | 13 | "One integration test caught raw `bog_patch` text leaking into the play log" (7 Nov 11:34Z) |
| (b) Intended change, test re-pinned | 20 | 21 | "found roster-count expectations and portrait checks that still assume four tribes" (7 Nov 11:31Z) |
| (c) Environment or flaky | 11 | 29 | "Godot cannot save settings under `/opt/godot-config`" (7 Nov 14:51Z); `flock -w 180` expiry |
| (d) Test bug | 2 | 3 | "One Clover test hit an unintended triple in its setup" (9 Nov 00:19Z) |
| Dev loop (new or just-edited test run red, red-first, mutation checks) | 2 | 134 | "The new check fails on the unchanged layout" (8 Nov 03:02Z) |
| Static step (lint 24, compile 18, format 9, other 6) | 57 | – | |
| GUT invocation error (no script matched) | – | 15 | |
| Unclear | 6 | 9 | |
| **Total** | **113** | **224** | |

- The 28 class (a) runs cover about 19 separate incidents. 13 of them were on 6 Nov, and 4 on 9 Nov.
- The orchestrator ran 41 gates, mostly merge gates. They caught **no** real regressions: one merge re-pin (`test_benchmark_boards.gd`, 8 Nov 23:15Z), the rest environment failures.

## 3. Per test file (top 15 by failed runs)

| File | Failed runs | (a) | (b) | (c) | Dev loop |
|---|---|---|---|---|---|
| core/test_game_session | 13 | 2 | 8 | 1 | 2 |
| core/test_bot_brain | 13 | 0 | 2 | 3 | 6 |
| ui/test_phone_layout | 12 | 2 | 0 | 1 | 9 |
| core/test_unit_library | 12 | 1 | 8 | 0 | 2 |
| ui/test_cards | 10 | 2 | 2 | 0 | 6 |
| core/test_balance_2 | 9 | 0 | 3 | 0 | 4 |
| core/test_slice_keywords | 9 | 0 | 6 | 0 | 3 |
| ui/test_polish | 9 | 3 | 3 | 0 | 2 |
| ui/test_portraits | 9 | 2 | 5 | 0 | 2 |
| ui/test_fixture_port | 8 | 1 | 5 | 0 | 2 |
| core/test_bot_held | 8 | 0 | 4 | 0 | 4 |
| ui/test_engines | 8 | 0 | 0 | 0 | 8 |
| core/test_combat | 7 | 1 | 3 | 0 | 3 |
| ui/test_round4_finish | 7 | 0 | 0 | 1 | 3 |
| core/test_content5_bots | 7 | 0 | 0 | 1 | 5 |

- **Caught at least one real regression (19 files):** test_bots, test_combat, test_discover, test_game_session, test_hunters, test_mech_hoglet_mother, test_unit_library, test_cards, test_core_port, test_fixture_port, test_followup_tribes56, test_log_effect_words, test_milestone_b, test_phone_layout, test_playthrough, test_polish, test_portraits, test_review_fixes, test_round4_guide. Six more catches don't show the file because the log was cut by `tail`.
- **What those catches are:** mostly UI, contracts and content consistency (raw IDs in logs, view-key fixtures, chips and portraits, layout). Core balance tests caught none.
- **Failed only as re-pins (23 files):** for example test_balance_1, test_balance_2, test_bot_held, test_belly, test_fly_south, test_engine_docs, test_slice_keywords, test_triples.
- **Never failed:** 72 of the 182 test scripts now on ideation/main. The 157 in the brief is out of date; the last gate ran 180 scripts. 137 of the 182 never failed as (a), (b) or (d).
- **Caveat:** about 45 failed gates don't show which files failed, so the per-file counts are low.

## 4. Redundant runs

Gates by who ran them: Codex workers 146, Claude subagents 92, orchestrator 41, Codex review/fix sessions 20, Codex merge/export 8.

- **Same tree gated again** (no edit and no reflog tree change since the last pass in that worktree): 16. Orchestrator 7, Claude subagents 8, Codex 1.
- **Merge gates on a merge whose tree equals the branch tip:** 5. The worker had already gated that tree.
- **Reviewer re-gates:** 5 of the 23 reviewer gates were run before the reviewer had changed anything.
- **What the change was since the last passing gate:** docs only in 9 gates (8 orchestrator gates per `git diff`, 1 subagent), tests and docs only in 12, formatting only in 12.

Estimated savings, at about 4 min of lock time per gate:

| Change | Gates saved | Lock time saved |
|---|---|---|
| `--docs-only` | about 9 | about 35 min |
| Tree-hash result cache | about 21 | about 85 min |
| Reviewer reuses the worker's gate log | about 5 | about 20 min |
| All three (with overlap) | about 30 | about 2 h of about 15.5 h of gate time |

## 5. Lock contention (sampler)

The sampler has only 39 samples, from 19:49Z to 20:08Z on 9 Nov; it started about 20 minutes before this run.

- 97% of samples had waiters: median 3, max 5, all on the shared lock. The harness lock sat idle.
- The lock was held in 38 samples. In 4 of those (11%) the holder was running no Godot.
- Gate step timings agree: for lock-wrapped gates, 13% of the hold time is non-Godot steps (median 33 s per gate).
- Available memory never fell below 5.8 GB; swap stayed at 2.9 GB.

## Files

- Per-run CSV (1,674 runs): `/tmp/claude-1000/runhist.Prqr/runs.csv`
- Per-file CSV: `/tmp/claude-1000/runhist.Prqr/per_file.csv`
- Hand-review sheets: `/tmp/claude-1000/runhist.Prqr/review_gate.txt`, `/tmp/claude-1000/runhist.Prqr/review_gut.txt`
- Sampler snapshot: `/tmp/claude-1000/runhist.Prqr/lock-samples-snapshot.csv`
- Scripts: `/tmp/claude-1000/runhist.Prqr/scripts/`
