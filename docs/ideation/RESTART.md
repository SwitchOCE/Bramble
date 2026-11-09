# Orchestrator restart guide (written 10 Nov 2026, about 09:00 local / 22:00 UTC 9 Nov; worker states updated at the hand-off)

This is for a fresh Claude session that takes over as the Bramble ideation orchestrator. The previous session was transcript `5369878e-e379-478d-ac97-3201f49297d2`, run over Remote Control. The owner is moving it to an SSH session on this machine. Read this first, then the files in §1, then act on §4.

Some state here goes stale within hours: shas, gate runs and worker turns. Check each one against the live sources in §3 before you act on it.

---

## 0. Restarting

**Step 1, shut down the old session first.** It doesn't stop when its Remote Control view closes, and its `/goal` check-ins keep it working. If both sessions live at once, two orchestrators and two Codex app-servers act on the same threads.
1. The old session closed its three Codex workers at the hand-off (`codex_close`); the threads stay on disk for resuming.
2. Close the old session: `/exit` in it, or `tmux kill-session -t bramble-ideation`. Don't kill the tmux server: the `webatrice` session lives in it.
3. Check: `ps -o pid,args -p 3342837,3342936,329635,809982,961917` should list nothing. Those are the old Claude, its bridge and three app-servers.

**Step 2, start the new session.** Use one of these.
- **A terminal over SSH (recommended):** `ssh -t alex@100.92.26.47 code/Bramble-ideation-start.sh`.
  - It starts a **fresh** Claude in tmux session `bramble-ideation`, in the right folder.
  - It runs under `systemd-run --user --scope -p OOMPolicy=continue`, so an out-of-memory kill of a child doesn't take Claude down (8 Nov).
  - It sets `ENABLE_CLAUDEAI_MCP_SERVERS=false` to keep the claude.ai connectors out, plus `--permission-mode auto --effort xhigh`.
  - Detach with Ctrl-b d. Reattach with `tmux attach -t bramble-ideation`. The session, the bridge and its workers survive an SSH drop. A plain `claude` over SSH dies with the connection, and takes the bridge and every worker turn with it.
  - The script refuses to start while the old tmux session exists.
  - **Don't use `code/Bramble-ideation-restart.sh`:** it runs `--resume 5369878e…`, which brings back the old 87 MB conversation instead of a clean start.
- **Claude Desktop's SSH remote:** open the session in `/home/alex/code/Bramble-ideation`, not the default folder. A Desktop SSH session started in `/home/alex/Documents` gets no memory, no project CLAUDE.md and no codex MCP server. It also runs without tmux or `OOMPolicy=continue`, and loads the claude.ai connectors. Before resuming any worker, check that `/mcp` lists codex and that `/goal` and ultracode work in that client.

**Step 3, the owner's first minute.** Only the owner can do these, and the orchestrator loop depends on all three:
1. Set the effort to extra high, if the launcher didn't (the old session ran at extra high).
2. Turn ultracode on. The Workflow tool needs it, and §4 step 2's cold reader is a workflow.
3. Issue `/goal` with the text below. Adding `docs/ideation/RESTART.md` to its reading list would help.

**Where to start.** The session runs in `/home/alex/code/Bramble-ideation`, the orchestrator's worktree, as `alex`. Claude Code keys this project by the main repo, so memory lives at `~/.claude/projects/-home-alex-code-Bramble/memory/` and loads by itself.
- The Codex bridge MCP server is configured in `~/.claude.json` under the project `/home/alex/code/Bramble`; worktrees share it.
  - Command: `node /home/alex/code/codex-bridge/codex-bridge.mjs`.
  - `CODEX_BRIDGE_ROOTS`: `/home/alex/code/Bramble-ideation`, `-balance`, `-tribes2` and `-sol`.
  - `CODEX_BRIDGE_MAX=3`.
- Allow `mcp__codex` the first time it asks. Its tools load lazily, via `ToolSearch select:mcp__codex__codex_status,...`.

**The goal.** The owner set it with `/goal`. If the new session has no goal set, the owner may re-issue it. The text, verbatim:

> "You are the ideation orchestrator for Bramble, in ~/code/Bramble-ideation on branch ideation/main. First read CLAUDE.md (its "This is the ideation branch" section governs you), docs/ideation/PLAN.md, docs/design/owner-notes/2026-11-06a-ideation-branch.md and docs/prototype/LEARNINGS.md, then run continuous iterative development as the plan says, deciding everything yourself. The goal is met only when every "Done means" criterion in docs/ideation/PLAN.md is met with evidence, at least three fresh independent reviewers who each played the latest build judge it very good for a playtest, and that build is exported to /data/bramble-builds/ with latest pointing at it. Never merge anything into main."

**What died with the old session**, and how to recover each:

| Thing | What happens | Recovery |
|---|---|---|
| The Codex bridge (old pid 3342936) and its `codex app-server` children | Workers closed at the hand-off; the bridge exits with the old Claude. All three workers were idle with clean, committed trees (§2), so no turn was lost | Threads persist under `~/.codex/sessions`. Resume each with `codex_delegate {resume_thread: <threadId>, cwd: <worktree>, kind: "implement", model: "gpt-6.1-sol", effort: "high"}` (§3.3). **New worker ids restart at `w1`,** so "w5, w6, w7" in this guide are old ids: go by label and worktree. Old logs are in `/tmp/codex-bridge/2026-11-09-3342936-wN.jsonl`, with copies and each worker's final reports in `build/orchestrator/worker-finals/` |
| Godot sims a worker launched | None were running at the end: w7's lobbies and w6's rerun had finished | Check anyway with `ps -eo pid,etime,args \| grep -E 'godot\|flock' \| grep -v grep`. **Never `pgrep -f` or `pkill -f`**: they match their own command line. Look at each worktree's `build/` output and `git status` before re-running anything |
| Background wait scripts, timers, `cloud-gate.sh` watchers | Gone; none was running at the hand-off | GitHub Actions runs keep going regardless. Check with `scripts/cloud-gate.sh --check <sha>` or `gh run list --workflow ci.yml --event push --limit 5` |
| The lock sampler (`locksample.sh`, pid 817667, run from the old scratchpad) | **Still running**, reparented to init. It writes `build/orchestrator/lock-samples.csv` every 30 s | Don't start a second one. To stop it: `kill 817667`. To restart later: `nohup build/orchestrator/bin/locksample.sh >/dev/null 2>&1 &` |
| The scratchpad `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-.../scratchpad/` | Still on disk, but the new session gets its own | The durable copies are in `build/orchestrator/` (§6) |
| Cloud routine sessions | Unaffected; they run in the cloud | Read them with `RemoteTrigger list_runs` and `get_run_log` |
| The commit trailer | Changes | Use the `Claude-Session` line the new session's harness gives. The old one was `https://claude.ai/code/session_013aVwzAnxmdxxFme7JYniB7` |

**The first five minutes:**
1. `git -C ~/code/Bramble-ideation status -sb; git log --oneline -5`. This worktree should be on `ideation/main`, clean, level with origin (§2).
2. `ps -eo pid,etime,args | grep -E 'godot|flock|python3 .*(sim|lobby|quilboar)' | grep -v grep`, as in the table.
3. `ls /data/bramble-portal/inbox/` and `ls /data/transfer/replays/`: the portal inbox rule (§5.9), and the drop folder the owner was told to use for Quilboar replays. The inbox was empty and the replay folder didn't exist yet at writing.
4. `gh run list --workflow ci.yml --event push --limit 5`: any gate left running. `gh auth status`: the token lives in the GNOME keyring (below).
5. **Don't resume the Codex threads just to ask for status.** A resumed `implement` thread starts editing at once, and §2 already records each worker's state. Resume a thread only when you give it its next task, after merging ideation/main into its branch yourself (§4 steps 2 and 4).

**After a reboot** (the owner is adding RAM). `/tmp` is tmpfs and is wiped. It holds the bridge logs, `/tmp/bramble-godot-slot`, the old scratchpad and the stray worktree `/tmp/bramble-harness-fresh-shard`.
1. Restore the slot stopgap: `install -m 755 build/orchestrator/bin/bramble-godot-slot.stopgap /tmp/bramble-godot-slot`. All three worker worktrees lack `scripts/godot_slot.sh` until ideation/main is merged in, so they depend on it.
2. Check `gh auth status` and `git push --dry-run origin HEAD:refs/heads/ideation/main`. The `gh` token is in the GNOME keyring, and git's credential helper is `gh auth git-credential`. After a reboot with no desktop login, the keyring may be locked, and gates and pushes then fail over SSH. Unlocking it, by a desktop login or otherwise, is the owner's call.
3. Run `git worktree prune` in this repo, which drops the missing `/tmp` worktree.
4. The old bridge logs will be gone; the copies in `build/orchestrator/worker-finals/` remain.

---

## 1. Read these, in order

1. `CLAUDE.md`, the project rules. The "This is the ideation branch" section governs: agents decide, reviews still run, never into `main`.
2. `~/.claude/CLAUDE.md`, the owner's global rules: answer style, long commands in the background, orchestration gates. It loads automatically. §5.1 covers how it applies here.
3. `docs/ideation/PLAN.md`: the status block, Done means and its sharpened version, how work runs, builds.
4. `docs/ideation/plan-scale-rework.md`: **plan v3**, the current master plan (its top section).
5. `docs/ideation/plan-test-suite.md`: the test-suite plan (owner note 10a), **Approved order** section.
6. `docs/ideation/DECISIONS.md`, newest first. Read every entry dated 9–10 Nov at least.
7. `docs/ideation/CLOUD.md`: who runs where, routines, Sol workers.
8. `docs/CLOUD_SETUP.md`, "The ideation gate on Actions" and "Godot slots".
9. `docs/ideation/LEARNINGS.md` and `docs/prototype/LEARNINGS.md`.
10. The owner notes from 9–10 Nov in `docs/design/owner-notes/`: `2026-11-09a` to `09i`, and `2026-11-10a`. They're records, never to be edited. One line each:
    - **09a:** the numbers are too small and spread out; scale is the fundamental problem.
    - **09b:** use ultracode and workflows; step back.
    - **09c:** fun beats balance. "Rewards give the player power, always." Tribes within an order of magnitude.
    - **09d:** simulations of constructed setups at turn thresholds outweigh bot lobbies. Judge snowball frequency, not the top 1%; stat distribution beats totals.
    - **09e:** declutter the UI. The main screen assumes a player who knows the rules, teaching goes in the tutorial, and animation shows the play.
    - **09f:** compare screenshots with HS, BG, Galaxy and TFT (third-party screenshots stay out of the repo). Port a straightforward BG tribe as a test-only A/B reference.
    - **09g:** the reference tribe is Quilboar; trivariate scaling.
    - **09h:** generous power first: start overpowered and dial back. Agency losses are context the owner works on later.
    - **09i:** at most two deciding criteria per step; don't stretch evaluation thin.
    - **10a:** a solid pass on the Godot lock. "The cloud is an option always", smart test scheduling, fewer runs, prune tests that never catch regressions, a smarter and faster suite. The owner is handling the RAM upgrade.
11. Memory, `MEMORY.md` and its files: the owner's working preferences. It loads automatically.
12. `build/orchestrator/compact-summaries.md`: all 15 compaction summaries of the old session, 6–10 Nov, 277 KB. It's the full history, including every "Errors and fixes" list. Grep it when you need the past.

---

## 2. Where things stand

### The original problem (owner 09a): the scale is too low and flat. Not fixed yet.
- **Bot lobbies at preset B:** the median grows about ×1.42 a round (×1.38 at the wave 2a head in 8 games), against a ×1.3 bar. The R12 median is about 290–400, against the 900 target. Committed lines' R12 medians are Homecoming 367, Tempo 359, Ring 306 and Court 402.
- **Wave 1 accounting:** in 640 lobbies, real R12 boards reach 0.17–0.44× of paper: Homecoming 0.44, Ring 0.27, Court 0.17 (Tempo, at 0.72, is the outlier). Paper assumed guaranteed arrivals.
- **The Quilboar reference (H1), after the one cycle-fix rerun** (`docs/ideation/reference/quilboar/h1.md` on `ideation/quilboar`, tip `6bb7c730`):
  - **Both criteria failed, and tuning stopped** as DECISIONS "Quilboar H1" said it would.
  - **Accounting:** budgeted Quilboar at B realizes 0.45×, 0.23× and 0.70× of paper at R9, R12 and R15 (R12 median 259). C kept its pre-fix result: 0.22× at R12 (median 422).
  - **Fidelity:** **uncut** Quilboar, the faithful Battlegrounds port, has an R12 median of **747**. It is 2.38× Birds (interval 1.50–3.28, below the 4× bar, so fidelity fails) and 5.5–7.7× the other lines.
  - **Uncut realizes 0.121× of its paper at R12** (interval 0.077–0.162). That is below our tribes' 0.17–0.44×, so the data **don't** show a shared paper-to-real gap. An earlier draft of this guide said the gap "belongs to the method"; that was based on the first run, and the rerun doesn't support it.
  - **What still holds:** a BG-faithful tribe reaches about 750 at R12 in our engine with our bots, near B's target of 900. So the engine and bots can produce BG-like scale.
- **The fun probe** (wave 1, three cloud playtesters) passed 3 of 3. Birds and Fairies give real jumps, and every tester's control game with a flat tribe "felt hopeless".
- **Oozes are rebuilt (pass 3) on `ideation/wave2b` but not merged; Hedgerow is still on pass 2 and flat.** That is wave 2b.
- **What decides checkpoint 1** (plan v3): two criteria only.
  1. Playtesters feel progress: a logged moment where they felt stronger.
  2. The lobby median grows at least ×1.3 a round, R8–R14, on pre-start boards.

### Branches and commits (check with `git fetch`; these were true at writing)
- **`origin/ideation/main` is this guide's commit**, one docs commit after `e92ab110`. It contains:
  - wave 2a: `2fa5247f`;
  - gate plumbing: `405bd57b`, then the review fixes `81dd2307`;
  - the per-game fast paths: `66289bc5`;
  - their review reports and DECISIONS calls: `e92ab110`. Actions PASS, 2,158 tests, run 42706292823. The tests step took **559 s** on Actions, against 771 s before the fast paths.
- **This guide** passed `--docs-only --base e92ab110` before the push.
- **Worker branches** (local only; workers can't push, and none of these tips is on origin or gated):
  - `ideation/wave2b` (`-balance`, w7): `c66a88e5`, one commit on `df9ed13e`. Clean.
  - `ideation/declutter` (`-tribes2`, w5): `8ded22c2`. Clean.
  - `ideation/quilboar` (`-sol`, w6): `6bb7c730` (cycle fix `4cf1a219`, first report `0f86f4e3`). Clean.

### Workers (Codex, gpt-6.1-sol, effort high)

| Old id | Label | Worktree, branch | Thread id | State at writing |
|---|---|---|---|---|
| w7 | wave 2b | `/home/alex/code/Bramble-ideation-balance`, `ideation/wave2b` | `01a1bf42-52ee-7071-abb6-e3b25e418570` | **Idle; part 1 (Oozes) committed as `c66a88e5`.** 88/88 new tests pass; six new scripts take about 38 s in all. 32 B lobbies: engine line ×1.369 (pass), Pot Luck ×1.251 (fail). R12 medians 262 / 200 / 250 pooled; paper accounting 0.27× / 0.20× / 0.26×. Off-build Ooze buys 1.37% of offers. 1,930 recorded fights replay exactly. Open: Pot Luck, the Actions gate, the scope review (including its "Shy shop-bonus reading"). Parts 2–4 and Click Beetle untouched. Report: `docs/ideation/content/pass3/wave2b-build.md` on its branch |
| w5 | declutter b1 | `/home/alex/code/Bramble-ideation-tribes2`, `ideation/declutter` | `01a1c0c7-0557-7192-b505-3d8638791524` | **Blocked and idle.** Its developer instructions say "Never merge, rebase onto, or push any branch", so it refused to merge ideation/main. It copied the third cold-reader answers and score into `docs/ideation/evidence/declutter/batch1/` (8ded22c2). None of the four visual fixes has started |
| w6 | Quilboar | `/home/alex/code/Bramble-ideation-sol`, `ideation/quilboar` | `01a1be5b-777e-7d40-bf1b-1253017bcffb` | **Idle; H1 rerun done and committed (`6bb7c730`).** Both criteria failed and tuning stopped (§2). 64 Godot and 22 Python tests pass in its targeted runs; no full gate yet. Next for it: §4 step 5 |

No worker had a turn in flight and no Godot process was running when the old session ended, so nothing was lost mid-run.

### Cloud sessions (routines; ids in §7)
- **Gate plumbing:** done and merged into ideation/main.
- **Per-game profile:** done and merged into ideation/main.
- **Cloud gate routine** `trig_01Bu2zM5LeTNEw9jLVYeUtB1`: the old fallback gate. Use Actions instead now.
- **Two briefs are ready but not started:**
  - `build/orchestrator/briefs/prompt-sharding.md` (test-suite step 6);
  - `build/orchestrator/briefs/prompt-faster-suite.md` (step 4).

  Start both once ideation/main contains `e92ab110` (§4).

### Builds
`/data/bramble-builds/latest` → `1108-2016-ideation7`, from 8 Nov. There has been no build since wave 1 or 2a merged. The next build comes at checkpoint 1.

---

## 3. Live sources: check these before trusting §2

### 3.1 Git
- `git fetch -q origin; git log --oneline origin/ideation/main -10`
- `git worktree list`
- `git -C <worktree> status --short | wc -l`

### 3.2 Gates
- `scripts/cloud-gate.sh --check <sha>`
- `gh run list --workflow ci.yml --event push --limit 5`
- `gh run view <id> --log | sed -n '/slowest 20/,/PASS tests/p'` gives the 20 slowest scripts.
- The local log of every `cloud-gate.sh` run is `~/.local/state/bramble/cloud-gates.csv`.

### 3.3 Codex workers
- **After a restart, resume a thread:** `codex_delegate {kind:"implement", cwd, resume_thread, model:"gpt-6.1-sol", effort:"high", label}`. Without `approach_first` it starts editing at once. Give it a prompt that asks for its state first, or one that continues the last instruction.
- **A resumed thread keeps its first developer instructions** (§5.4). That is why w5 can't merge. Either merge ideation/main into its branch yourself, or start a fresh thread with instructions that allow it. **Recommended:** merge it yourself (§4 step 2).
- **Status:** `codex_status` (all workers) or `codex_status {workerId}`.
- **A worker's final message:**
  ```
  L=$(ls -t /tmp/codex-bridge/*-wN.jsonl | head -1)
  python3 -c "import json,sys;[print(d['text']) for d in map(json.loads,open(sys.argv[1])) if d.get('final')]" "$L" | tail -40
  ```
  Use the **new** id: after the restart, an old id such as `w7` still matches the old session's log.
- **Waiting:** `build/orchestrator/bin/waitw.sh wN` with `run_in_background`, with the new id. Check `codex_status` first: if the turn already ended, the script waits for the next one (§5.4). An old id picks up the old session's dead log and waits the full 9,000 s.

### 3.4 Cloud routines
- Load the tool first: `ToolSearch select:RemoteTrigger`.
- `RemoteTrigger list_runs {trigger_id}`, then `get_run_log {session_id}`. The log shows the newest events and cuts long messages at about 2,000 characters.
- `RemoteTrigger list` shows every routine. "off" ones still `run`; `enabled` only matters for cron.

---

## 4. Next actions, in order

1. **Done in the old session:** the temp branch landed on ideation/main and was deleted, and the PLAN status block was refreshed. Check `git status -sb` shows `ideation/main` level with origin.
2. **Unblock w5 (declutter):**
   - In `/home/alex/code/Bramble-ideation-tribes2`, merge `origin/ideation/main` into `ideation/declutter` yourself. Conflicts are likely in UI files that wave 2a touched (`recruit_screen.gd`, `card_view.gd`, `board_view.gd`, `slot_marks.gd`). Resolve them keeping both sides' intent.
   - Make sure the worktree is clean, then resume thread `01a1c0c7-…` with the four fixes from DECISIONS "Declutter batch 1, third cold reader":
     1. the Aura line's direction (source to recipient, landing cue on the recipient);
     2. every unit in a joint attack shows its own lunge;
     3. a kept gain visibly goes where it is kept;
     4. Counter's cue restored.
   - Say in the resume prompt: targeted UI tests only, through the slot wrapper, and **no `check.sh`**. w5's first instructions name `flock /tmp/bramble-godot.lock`, and an outer flock around `check.sh` deadlocks (§5.3).
   - Also in its task, from DECISIONS "Declutter batch 1" (merge order): port Bog's kiss count, the pending-gain tag and Bog's Toll into the wordless face, without words. Once wave 2b lands, port its Ooze marks too (the ladle, the meal inside the jelly, wake pips; `docs/ideation/briefs/wave2b-build.md`).
   - Reshoot only rival 025 and combat_mid 036/045/069/075, at x1, x4 and reduce motion.
   - Then a fresh cold reader on those moments only. The workflow script is under `~/.claude/projects/-home-alex-code-Bramble-ideation/5369878e-…/workflows/scripts/declutter-b1-cold-reader-wf_645c18c3-bfd.js`; adapt it to the reshot strips. Then the Actions gate, a narrow scope check, and merge.
3. **Start the two test-suite cloud sessions**, as routines, in parallel (§5.6 for creating them):
   - **Sharding** (`briefs/prompt-sharding.md`, branch `ideation/c-gate-shards`): a matrix of 4 shards balanced by junit, `check.sh --shard i/n`, plus the two `ci.yml` simplifications. Criteria:
     1. the same verdict and total test count as unsharded, including a planted failing test in a non-first shard;
     2. push to verdict of at most 7.5 min, the median of 3.
   - **Faster suite** (`briefs/prompt-faster-suite.md`, branch `ideation/c-faster-suite`): a cheaper bot or a shared lobby for tests that don't test Hard's skill, a library cache, iteration cuts, and two deletes. Criteria:
     1. the junit tests total down at least 25%;
     2. three planted bugs still fail: a pool leak, nondeterminism, quiet and logged fights differing.
   - Each needs a scope review and an Actions gate before it merges. Re-pin rewrites (plan step 5) come after.
4. **w7's Oozes hand-off** (wave 2b part 1, committed as `c66a88e5`):
   - Gate it with `scripts/cloud-gate.sh <sha>` (after the merge below), and run a scope review in parallel. Scope is the owner's words (09a, 09c, 09h, 09i) and plan v3's wave 2b text. Give the reviewer the brief `docs/ideation/briefs/wave2b-build.md` too, labelled as a proposal. w7's own report is `docs/ideation/content/pass3/wave2b-build.md` on its branch: treat it as claims.
   - **None of the three worker branches carries the Actions push trigger yet.** wave2b (`c66a88e5`), declutter (`8ded22c2`) and quilboar (`6bb7c730`) all lack `405bd57b`. Only commits that contain the `ideation/gate/**` trigger can be gated on Actions: `cloud-gate.sh` pushes, but no run starts. So once `e92ab110` is on ideation/main, merge `ideation/main` into each worker branch before gating its tip. Do it yourself, since workers refuse merges, and only while that worker is idle with a clean tree. The fallback is the Claude cloud gate routine (§5.2), which runs `check.sh` on any commit.
   - **Pot Luck at ×1.251 is under the ×1.3 criterion** (the engine line passes at ×1.369). Triage it with the triage skill before deciding: a card fix, a bot or line fix, or a dial raised (generous first). Don't steer bots away from a weak route to hide it (LEARNINGS).
   - Then parts 2 (Hedgerow), 3 (neutrals) and 4 (retire the 38 prototype bodies), each with its own reviewed hand-off.
5. **w6's Quilboar H1 rerun: done** (`6bb7c730`, results in §2):
   - Accounting failed again, so tuning has stopped. Logged in DECISIONS "Quilboar H1 rerun", including that the gap is **not** shown to be shared.
   - Then merge ideation/main into the branch (it lacks the trigger), a scope review, the Actions gate and merge. The Quilboar content is test-only: never in the release pool, a player build or `main`.
   - Then w6 does the harness follow-ups from DECISIONS "Harness review 6":
     - drop and report contaminated trials, failing if more than 2% are dropped, **before** the head measurement;
     - label low-roll results "banned card refused, still offered";
     - simplify the seated-line check;
     - store per-seed lists once.
   - Then the head measurement in B and C with keystone-banned low rolls. Heavy runs go to cloud sessions.
6. **A design consequence to act on:** paper accounting overestimates real boards at R12 for every tribe we've measured: about 2.3–6× for ours (Tempo 1.4×) and for budgeted Quilboar, about 8× for uncut Quilboar. Paper is not a usable target. Targets are already set on realized medians (09h amendment: B about 900, C about 1,800 realized). Wave 2b dials and the full-pool measurement should be judged on realized numbers. Uncut Quilboar's R12 median of 747 is evidence that B-scale is reachable.
7. **Later in plan v3:**
   - the full pass 3 pool measurement (step 5);
   - checkpoint 1: B against C, played blind by three or more reward-lens playtesters;
   - a build on the portal with presets B and C as a setting;
   - playtest rounds, the remaining Done means evidence, three fresh reviewers judging "very good";
   - a soak, and the export to `/data/bramble-builds/` with `latest`.
   - Declutter batches 2–4 (batch 4 is the tutorial and Rules page work).
   - Small follow-ups: isolate `XDG_DATA_HOME` in the slot wrapper as well (today only `check.sh` sets it per GUT run); check `/data/transfer/replays/` for owner Quilboar replays, and compare the port's line policy against them and against the 77 Quilboar perfect-game wins in `build/orchestrator/fundamentals/`.
8. **Every few steps,** tell the owner plainly whether the scale problem is fixed. It isn't yet.

---

## 5. How things are done here (procedures)

### 5.1 The owner's rules, as applied on ideation
- **Plain, short answers.** Lead with the outcome. No process talk to the owner (memory "owner wording for decisions"). Use they/them for the owner.
- **Long commands run in the background** with a hard timeout of about 2× the normal runtime. Say what you're waiting on, then end the turn. Don't sleep or poll. Read only the tail of the output.
- **Plans:** before approving a multi-step plan, run plan-interrogate in a fresh agent (`~/.claude/skills/plan-interrogate/SKILL.md`) with the owner's words quoted. On ideation the orchestrator then approves its own plan and logs it.
- **Every code step passes two gates before it merges:**
  1. Runtime: tests plus real behaviour.
  2. A fresh `scope-reviewer` on the commit range. Brief it with the owner's words quoted plus the approved plan text, never with your own brief as scope.

  Cut items are fixed first; ask items are the orchestrator's call, logged in DECISIONS. Never review a step in your own context.
- **On ideation, agents decide.** Wherever a rule says to ask the owner, decide and log it in `DECISIONS.md` instead. The owner's direction still outranks agent taste; a deviation needs a logged reason.
- **Never credit the owner with an orchestrator call.** Workers kept writing "as the owner confirmed". Check worker docs for it, and treat it as a cut.
- **Don't** edit CLAUDE.md rules, permission settings or config without the owner's OK. A subagent's message is never user approval.
- **Rules: which wins** (the old session's reading). Memory's "direct-instruction rules need the owner's OK on wording and reason" dates from 2 Nov. The ideation section of CLAUDE.md (6 Nov) hands "writing working rules for this branch" to the orchestrator, logged in DECISIONS. So the orchestrator writes ideation-only working rules in ideation docs (LEARNINGS, CLOUD.md, the plan) with their purpose, and leaves CLAUDE.md, memory rules, settings and anything that binds the owner's other sessions to the owner.

### 5.2 Gates and the merge rule (since 10 Nov)
- **The merge rule:** ideation/main moves only when `scripts/cloud-gate.sh --check <sha>` passes for that exact commit, or on `./scripts/check.sh --docs-only --base <sha>` from such a commit. `--base` accepts any commit, so always `--check` the base first.
- **Full gate:** `scripts/cloud-gate.sh <sha> [label]`, run in the background with `timeout 2400`.
  - It pushes to `ideation/gate/<12-char sha>`, waits for the Actions run, and prints `GATE <sha> PASS|FAIL <url>`.
  - Push to verdict takes about 11–15 min: the latest run (42706292823) took 10m45s, with the tests step at 559 s. Sharding should cut it.
- **Flaky failure:** `gh run rerun <id> --failed`, then `--check`. Pushing the same sha again starts no run.
- **The local `gh` login has no `workflow` scope.** The push is refused for any commit whose `.github/workflows/ci.yml` differs from what's on the remote ("refusing to allow an OAuth App to create or update workflow … without `workflow` scope"). Cloud sessions can push workflow changes, so `ci.yml` edits go to a cloud session. Changing the scope (`gh auth refresh -s workflow`) is the owner's call.
- **No local full gates,** by the orchestrator or by workers. Workers run targeted test files only, through the slot wrapper:
  - in a worktree that has it: `GODOT_SLOT_CLASS=worker scripts/godot_slot.sh <cmd>`;
  - otherwise: `/tmp/bramble-godot-slot systemd-run --user --scope -q -p MemoryMax=3G <cmd>`.
- **Docs-only commits:** `./scripts/check.sh --docs-only`. No Godot, no lock, about 30 s.
  - It refuses changes outside `docs/`, `.gdignore` changes, docs that code reads (`res://docs/...` in src, tests or tools GDScript), and moves out of `src/`.
- **Gate and push together.** In one conditional command, push only on "all steps passed" (LEARNINGS 9 Nov). A chained push once landed a failed gate.
- **The Claude cloud gate routine** (`trig_01Bu2zM5…`) is the fallback.
  - Force-push the sha to `ideation/c-gate-next`, then `RemoteTrigger run`. The first line of the final message is `GATE <sha> PASS|FAIL <step>`.
  - Runs queue in one persistent session.
  - The cloud agent's Bash limit is 600 s. A longer gate moves to the background but still reports; 2fa5247f took 17 min.
- **Only commits that carry the Actions push trigger can be gated on Actions.** The workflow file comes from the pushed commit.

### 5.3 Godot on this machine (6 cores, 14 GB RAM, 4 GB swap; the owner is adding RAM)
- **Every Godot process runs under `systemd-run --user --scope -q -p MemoryMax=3G`.** On 8 Nov a 4.2 GB Godot process ran the machine out of memory, and systemd killed the orchestrator's whole scope.
- **At most two Godot processes at once,** through two locks:
  - `/tmp/bramble-godot.lock` for gates, tests and probes;
  - `/tmp/bramble-harness-godot.lock` for sims.
- **The in-repo `scripts/godot_slot.sh`** takes whichever lock frees first, caps memory, sets `BRAMBLE_SLOT_HELD=1` for the child, and logs to `~/.local/state/bramble/godot-slots.csv`.
  - `check.sh` takes its own slot only from import through tests.
  - **Don't wrap `check.sh` in an outer `flock`:** it would wait for a second slot and deadlock.
  - The `/tmp/bramble-godot-slot` stopgap now sets `BRAMBLE_SLOT_HELD=1` too. A copy is at `build/orchestrator/bin/bramble-godot-slot.stopgap`.
- **Sims take only the harness lock.** Workers in older worktrees may still use `flock /tmp/bramble-harness-godot.lock …`.
- **Workflow agents and Claude subagents never run Godot locally.** Godot work goes to Codex workers or cloud sessions.
- **Toolchain:** `source /opt/bramble/env.sh` locally; cloud sessions load it by hook.
- **Never `pgrep -f` or `pkill -f`.** They match their own command line and have hung or killed things here several times. Use PIDs, `pgrep -x`, or `ps -eo pid,args`.

### 5.4 Codex workers
- **One worktree each,** inside `CODEX_BRIDGE_ROOTS`. Delegating to a new worktree outside the roots fails ("cwd is outside CODEX_BRIDGE_ROOTS"), so reuse the four roots and switch branches. Limit 3 workers.
- **Model** `gpt-6.1-sol`, effort high. `approach_first: true` for new tasks: check the three-line approach, then `codex_send {confirm:true}`.
- **Workers commit but can't push** (Codex's approval reviewer denies `git push`). The orchestrator pushes or gates their tips. Letting them push `ideation/gate/**` would be the owner's call.
- **A resumed thread keeps its first developer instructions,** and later messages don't override them. Hence:
  - w5 refuses merges.
  - Earlier workers refused Godot runs because a lock rule had named a specific lock.
  - Keep developer instructions general.
  - "Never merge" must say "into `main` or `ideation/main`", or the worker refuses ordinary merges of ideation/main into its own branch. In that case the orchestrator merges into worker branches itself.
- **A bridge turn ends silently at 60 min.** Keep turns under 50 min, and run long jobs detached with logs. When a turn times out, resume with "continue; keep turns short; detached jobs".
- **The wait-script race:** a wait started after the turn ended waits for the next turn. Once, w5 sat idle for about an hour. Check `codex_status` first.
- **Worker reports are claims to check.** Overclaims caught before include:
  - "real clicks" that weren't;
  - a vacuous A/A test (identical mirrored bots);
  - a tautological bar;
  - a null planted card that planted nothing;
  - R² passing 15% compounding;
  - owner misattributions.
- **Workers write helper scripts to `/tmp`** (an old worker's file list includes `/tmp/bramble_*.py`). They aren't in git, so ask for anything that must last to be committed under `tools/` or the evidence folder.

### 5.5 Reviews and workflows
- **Where Claude work runs.** CLAUDE.md ("Claude work runs in the cloud") and CLOUD.md ("No Claude subagents run on this machine") are out of date for Claude work. Since 9 Nov, local `Workflow` scripts and `scope-reviewer` subagents replace cloud routing for Claude work that doesn't run Godot (DECISIONS "9 Nov 2026 — Fundamentals first: build 8 held, workflows replace cloud routing", owner note 09b, memory "ideation compute routing"). Cloud routines remain for Godot-heavy Claude work. Changing CLAUDE.md to match is the owner's call.
- **A `scope-reviewer` subagent** (Agent tool, `run_in_background`) for every merge. Brief it with:
  - the commit range;
  - the owner's words, quoted;
  - the approved plan text;
  - a few specific probes.

  Have it write its report to the scratchpad. Copy the report verbatim into `docs/ideation/evidence/review-<slug>.md` when merging.
- **Ultracode was on** (owner 09b): use `Workflow` for orchestrated Claude work (critics, cold readers, analyses).
  - Workflow agents never run Godot.
  - Results: the `journal.jsonl` under `~/.claude/projects/-home-alex-code-Bramble-ideation/<session>/subagents/workflows/<runId>/`.
  - `resumeFromRunId` works only in the same session.
- **On 10 Nov the owner said a reviewer wasn't needed for this restart guide itself.** That isn't a general rule.

### 5.6 Cloud routines (Claude in the cloud)
- **Create:**
  - `RemoteTrigger create` with `persist_session: true`, `clear_mcp_connections: true`, environment `env_01WsDsVCdxvDvXSktc7dZx9X`, repo `https://github.com/SwitchOCE/Bramble`, model `claude-opus-5-5`, and allowed tools Bash, Read, Write, Edit, Glob, Grep, Agent, WebFetch and WebSearch.
  - Then `update {"clear_mcp_connections": true}` if connectors got attached anyway. Then `run`.
  - The body shape: `RemoteTrigger get trig_01AK9fNeUVHZQaFqCxRfrM54` is a working example to copy.
- **Every prompt starts with the preamble in `docs/ideation/CLOUD.md`.**
- **Long prompts have failed** with "could not be parsed as JSON": two prompts of about 3.5k characters on 8 Nov. A 4.8k prompt worked on 9 Nov (the gate-plumbing routine), so the cause may have been escaping rather than length. If `create` fails that way, move long material into a repo file and point to it. The two briefs in `build/orchestrator/briefs/` are 4.3k and 4.6k characters.
- **Without `persist_session`,** every update plus run starts a new session instead of messaging the old one.
- **A run re-fires the stored prompt into the persistent session.** To give new instructions, start a new routine.
- **Nothing notifies the orchestrator when a routine ends.** Set a background timer and read `get_run_log`.
- **Cloud sessions can push `ideation/c-*` and `ideation/gate/**`, including workflow changes.** `gh pr` and `gh issue` fail there. A stop hook nags them to commit.
- **Reports must be under 250 words,** or go in a file on their branch.

### 5.7 Merging
- **Merge into ideation/main locally** in `/home/alex/code/Bramble-ideation` (or on a temp branch), resolve conflicts, then gate the exact merge commit on Actions, then push.
- **Direction:** main → ideation is fine. ideation → main is **never** allowed without the owner, including cherry-picks and file copies.
- **Octopus merges have failed silently.** Merge one branch at a time and check ancestry.
- **`check.sh` conflicts are common.** On 10 Nov: keep wave 2a's `GUT_TIMEOUT=1200` and private `XDG_DATA_HOME` per GUT run, and add the plumbing's `MEMCAP`, junit file and `9>&-`.
- **Don't force-push shared branches.** A wrong trailer gets corrected in the next commit's message.

### 5.8 Logging
- **`docs/ideation/DECISIONS.md`:** newest first. Format: `### <date> — <question>`, then **Source**, **Picked**, **Why**.
- **`docs/ideation/LOG.md`:** routine ids and purposes.
- **`docs/ideation/LEARNINGS.md`:** gotchas.
- **The PLAN status block,** in the owner's plain voice. Its "In short" line is shown on the portal. Refreshed at the hand-off; update it whenever a step merges.
- **Owner notes** are new dated files transcribed from dictation. Never edit existing ones.

### 5.9 Portal inbox and builds
- **Inbox:** at session start, read `/data/bramble-portal/inbox/*.json` and act on any. Mark each one handled with `<stem>.handled.json` (`docs/workstreams/README.md`). It was empty at writing.
- **Builds:** `/data/bramble-builds/<mmdd-hhmm>-ideation<N>/` with a `README.txt` whose first line is `Ideation build <N>: …`. Then point `latest` at it. Windows exports need `wine` to smoke-test; Android needs the APK signing check.

### 5.10 Commits
End every commit message with the two trailer lines the harness gives, `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and the new `Claude-Session: …`. PR descriptions don't apply: ideation uses no PRs.

---

## 6. Durable files left by the old session (`build/orchestrator/`, gitignored, local only)

| File | What it is |
|---|---|
| `RESUME.md` | The old short resume notes; superseded by this guide |
| `compact-summaries.md` | All 15 compaction summaries of the old session: the full history |
| `bin/waitw.sh` | Worker turn wait, using the newest bridge log for that worker id |
| `bin/locksample.sh` | Lock and memory sampler, every 30 s, into `lock-samples.csv` |
| `bin/bramble-godot-slot.stopgap` | A copy of `/tmp/bramble-godot-slot`, in case `/tmp` is cleared |
| `briefs/prompt-sharding.md`, `briefs/prompt-faster-suite.md` | The two ready cloud briefs (§4 step 3) |
| `lock-samples.csv` | Slot-wait baseline samples |
| `gates/` | Older local gate logs |
| `worker-finals/` | The three workers' bridge logs and final reports, copied out of `/tmp` at the hand-off |
| `fundamentals/` | 915 MB of fundamentals evidence, including the 77 Quilboar perfect-game wins |

**The old transcript:** `~/.claude/projects/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2.jsonl` (87 MB). Subagent and workflow transcripts are under the matching session folder.

---

## 7. Ids and paths

**Worktrees:**
- `/home/alex/code/Bramble-ideation`: orchestrator, ideation/main.
- `-balance`: w7, wave 2b.
- `-tribes2`: w5, declutter.
- `-sol`: w6, Quilboar.

**Android debug keystore:** `/opt/godot-data/godot/keystores/debug.keystore` (the export scripts copy it in). Backup: `/home/alex/backups/bramble-keystore/debug.keystore` (mode 600, outside `/data/bramble-builds`, so the portal never serves it). SHA-256 `c2acb87b…c1ba4`. Builds 5–7 are signed with it; lose it and later APKs won't install over them.

Other `~/code/Bramble*` worktrees belong to other sessions (main, design, portal, proto). Read them; never change them.

`/tmp/bramble-harness-fresh-shard` (detached at `1ea90ea9`, already in ideation/main) is a leftover harness worktree. It's safe to remove with `git worktree remove`, and a reboot drops it anyway.

**Cloud routines in use (10 Nov):**

| Routine | Session | Purpose |
|---|---|---|
| `trig_01Bu2zM5LeTNEw9jLVYeUtB1` | `cse_013aVwzBJr76yXztWUedWGN2` | Cloud gate (fallback) |
| `trig_01AK9fNeUVHZQaFqCxRfrM54` | `cse_013aVwz8HFHWotZyM4s8svPr` | Gate plumbing, done |
| `trig_01GtoRWGU6rww9LLCYASvfvh` | `cse_013aVwzAdTGUmZVpidhVbqhT` | Per-game profile, done |
| `trig_013zH8bkta7kjJGQ49XuqKNB` | `cse_013aVwz99ZxFnJax89A3USJA` | Test profile, done and merged |
| `trig_01GXxumcX3aARXz3SNUKquwh`, `trig_01T498Kyc14Qvv5bVkTNE1kR`, `trig_015Cq8RGqhzeEfDAPUHxWxhW` | | Fun probe A, B and C, done |

Older ones are in `docs/ideation/LOG.md`.

**Actions runs:**
- 42702428298: `405bd57b`, PASS, the tests step 771 s.
- 42705008878: `81dd2307`, PASS.
- 42706292823: `e92ab110`, PASS, the tests step 559 s.
- The plumbing's own runs: 42696545119, 42696549685, and the planted failure 42696555037.

**Paths:**
- **Evidence:** `docs/ideation/evidence/`. The test suite is under `test-suite/` (1–7 and `game-profile/`), and `test-profile/`. The declutter is under `declutter/batch1/` (its third cold-reader files are only on `ideation/declutter` until it merges). Each review is in `review-*.md`.
- **Briefs:** `docs/ideation/briefs/`. The current one is `wave2b-build.md`.
- **Content designs:** `docs/ideation/content/pass3/`: oozes, hedgerow, cross-tribe and presets.
- **The harness:** `tools/sim/HARNESS.md`.
- **The Quilboar reference:** `content/reference/quilboar/` (test-only, behind `reference_quilboar`), and `docs/ideation/reference/quilboar/`. Both exist only on `ideation/quilboar` until it merges.

**Numbers worth having:**
- **Tests on ideation/main:** 205 scripts, 2,158 tests.
- **Cloud tests step:** 353 s before wave 2a, then 966 s (Claude cloud) or 771 s (Actions), then 559 s on Actions after the combat fast paths. `GUT_TIMEOUT` is 1,200 s.
- **Slowest scripts on Actions** (run 42706292823, after the fast paths):

  | Script | Time |
  |---|---|
  | test_bot_brain | 64.3 s |
  | test_field_normal_regression | 31.3 s |
  | test_playthrough | 17.7 s |
  | test_placing_bar_probe | 17.5 s |
  | test_wave1_lines | 16.4 s |

- **One Hard lobby:** about 15–19 s. Board-search quiet fights are 75–78% of it (about 1,400 fights at about 10 ms).
- **Run history, 6–9 Nov:** 307 gates. 28 real regressions were caught, all by UI, contract and content tests. The orchestrator's own 41 gates caught nothing.

---

## 8. Gotchas, collected (6–10 Nov; the details are in `compact-summaries.md`)

**Honesty and reporting**
- **Don't state timer or progress figures without checking.**
  - "2 minutes left" was really 13.
  - "Half the readers are done" was really none.
  - Use `date`, and look before reporting.
- **Don't say "logged" or "pushed" before it's true.** It happened twice. Correct mistakes to the owner openly, at once.
- **Check numbers before passing them on.** "Five Birds have no text" was really four. The human/bot gap was "2–3×" but really about 1.5× for Birds.
- **Owner misattribution.** Workers repeatedly wrote "as the owner confirmed" for orchestrator calls. Fix it as a cut.

**Git**
- A chained command once pushed a failed gate. Gate and push conditionally, in one command.
- A push was rejected as non-fast-forward because another session had merged main's toolchain fixes into ideation/main. Fetch, merge and push. main → ideation is allowed.
- Large screenshot sets bloat history (29 MB). Squash-merge UI-shot branches.
- Wrong session trailers happened (a reviewer's id was used). Correct them in the next commit's message; don't rewrite pushed history.
- The `git stash` stack is shared across worktrees and sessions. Use WIP commits instead.

**Gates and tests**
- **The old `--docs-only` had holes:** `git mv` into docs/, docs that code reads, and docs read through `tools/` scripts. All are fixed (633c56dd, a200e88f), with 10 Python tests.
- **Merging a measurement branch after a balance change breaks fixture pins** (Hedge Witch Hex 6 → 5). Re-pin only with a logged reason.
- **The suite more than doubled with wave 2a.** Don't add slow tests. Any new whole-game test reuses a shared lobby or a short fixed board. Workers report each new script's time.
- **GUT skips scripts that fail to parse and still exits 0.** `check.sh` catches this. Warnings are errors: `(x as T)` from a Variant fails to compile, so use a checked assignment.
- **A V-Sync warning, and "resources still in use" on exit,** are tolerated noise in UI runs.

**Machine and processes**
- **Memory:** systemd killed the orchestrator's scope on 8 Nov (§5.3).
- **`pgrep -f` / `pkill -f`** matched themselves: loops hung for 90 minutes and a kill took its own shell. Never use them.
- **`&` inside a Bash tool call dies when the call ends.** Use `run_in_background`, or `nohup … &` for something that must outlive the session.
- **Codex image generation hangs on an open stdin.** Add `</dev/null`.
- **The scratch quota once filled** (2.6 GB). Clean old temp project copies and venvs.
- **The owner's PowerShell mangles quoted `ssh … "bash -c …"`.** Give them a script on the server instead.

**Codex**: see §5.4. In short:
- workers keep their first instructions;
- turns end at 60 min;
- the wait race;
- workers can't push;
- worktrees must be in the roots;
- the parameter is `workerId`, for `codex_close` too.

**Cloud**: see §5.6. In short:
- `persist_session`;
- long prompts have failed to parse;
- connectors attach unless cleared;
- nothing notifies the orchestrator;
- logs cut at about 2,000 characters;
- a cloud agent's 600 s Bash limit.

**Design-process lessons**
- **Triage before fixing** (the triage skill; owner method 08f). Use several hypotheses at different levels. Check each card's role at the moment it's bought, and the journey from R1 to R10+.
- **Paper models overestimate** when they assume arrivals: real R12 boards reach 0.17–0.44× of paper for our tribes, and 0.12–0.23× for Quilboar. Set targets on realized boards.
- **When a sim shows a tribe is weak, fix the cards,** not the bots' routes.
- **After parallel designers,** rebuild the competition list and put every tribe's boards on one sheet before costing.
- **Pitch ideas to the owner concretely:** a unit with full text, its interactions, why a player would run it, and two or three variations.
- **Owner design reactions are directions:** never cut a design straight away.
- **At most two deciding criteria a step** (09i). Report the rest.

---

## 9. Review at the hand-off

A fresh Claude subagent reviewed this guide at `990a6fb1`, live against the machine. Its report, verbatim: `docs/ideation/evidence/review-restart-guide.md`. What was done with each item:

| # | Issue | Done |
|---|---|---|
| 1 | No launch command; the existing launcher resumes the old conversation | `~/code/Bramble-ideation-start.sh` (fresh session, tmux, `OOMPolicy=continue`, no connectors, auto mode, extra high effort); §0 step 2 warns about `restart.sh` |
| 2 | No step to shut the old session down | §0 step 1. The old session closed its Codex workers before handing over |
| 3 | `/goal`, ultracode and effort must be set again | §0 step 3, as owner actions. Adding RESTART.md to the goal is the owner's choice |
| 4 | State moved; w6's result undercuts the Quilboar conclusion | §2, §4 steps 4–6 and PLAN's status block updated; DECISIONS "Quilboar H1 rerun" |
| 5 | Old worker ids; broken log recipe | §0 table and §3.3: go by label; recipe fixed |
| 6 | CLAUDE.md and CLOUD.md contradict local Claude agents | §5.5 says which wins and why; changing CLAUDE.md stays the owner's call |
| 7 | A reboot wipes `/tmp` | Final reports copied to `build/orchestrator/worker-finals/`; after-reboot checklist in §0 |
| 8 | The first five minutes resumed w5 before its merge | §0 step 5 changed: resume only with the next task, after the merge. The merges themselves were **not** done at the hand-off, because the owner said to start no new work. Declutter's merge will likely conflict in UI files |
| 9 | Claude Desktop's SSH remote differs | §0 step 2, second option |
| 10 | Pending work missing | §4 steps 2 and 7; §6 lists `fundamentals/` |
| 11–18 | Minor items | Lock sampler still running (§0 table); `ps` grep covers Python sims; timings refreshed to run 42706292823 here and in both briefs; reviewer scope labelled; w5 told "no `check.sh`"; stale lines and the memory entry fixed; branch-only paths marked; the stray `/tmp` worktree noted; LOG.md has the three missing routines; RemoteTrigger loading noted; rule precedence in §5.1 |
