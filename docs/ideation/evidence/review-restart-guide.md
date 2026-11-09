*Independent review of docs/ideation/RESTART.md at 990a6fb1 by a fresh Claude subagent, 10 Nov 2026, copied verbatim. The fixes made in response are listed at the end of RESTART.md, under "Review at the hand-off".*

# Independent review: docs/ideation/RESTART.md (990a6fb1)

Checked live on 10 Nov 2026, 09:00–09:17 local (22:00–22:17 UTC 9 Nov).

## Verdict

Not yet. The procedures, ids and gotchas are thorough, and most concrete claims check out. The branch shas, Actions runs, thread ids, bridge config, memory location and most paths are right, and so is the claim that a resumed thread keeps its first instructions. But a fresh session would not resume cleanly as written, for three reasons:

- **No launch command.** The guide never says how to start the new session, and the only launcher on the machine, `~/code/Bramble-ideation-restart.sh`, resumes the old conversation instead of starting a clean one. The guide also leaves out that launcher's protections: tmux, `OOMPolicy=continue` and no claude.ai connectors.
- **No shutdown step.** The guide assumes the old session is dead. It is still running, with `/goal` active and its Codex bridge holding all three worker threads.
- **Optional owner steps.** The guide treats `/goal`, ultracode and the higher effort level as optional. The orchestrator loop depends on all three.

The state has also moved since writing. All three workers have committed and are idle with clean trees. w6's final Quilboar result contradicts the guide's main design conclusion ("the gap belongs to the method"). Fix these and the guide is good to resume from.

**Right now is a safe moment to close the old session:** no worker turn is running, no Godot process is running, and every worker tree is clean (checked 22:16 UTC).

---

## Issues, most serious first

### 1. BLOCKING: no launch command, and the existing launcher resumes the old conversation
- **Section:** §0 "Where to start".
- **What's wrong:** §0 says where to start but not how.
  - The old session was started by `~/code/Bramble-ideation-restart.sh` (the owner's command: `ssh -t alex@100.92.26.47 code/Bramble-ideation-restart.sh`).
  - That script runs Claude in tmux session `bramble-ideation`, wrapped in `systemd-run --user --scope -q -p OOMPolicy=continue`.
  - It also sets `ENABLE_CLAUDEAI_MCP_SERVERS=false` (drops the claude.ai connectors, agreed 9 Nov) and passes `--permission-mode auto --remote-control 'Bramble ideation'`.
  - The script also has `--resume 5369878e-…`. If the owner reuses it, they get the old 87 MB conversation back, not a clean restart.
  - A plain `claude` over SSH without tmux dies when the SSH connection drops. The Codex bridge and every worker turn die with it.
  - Without `OOMPolicy=continue`, an out-of-memory kill can take the orchestrator down (the 8 Nov incident).
- **Evidence:**
  - `cat ~/code/Bramble-ideation-restart.sh`.
  - Old process: `ps -o args -p 3342837` shows `claude --resume 5369878e… --remote-control Bramble ideation --permission-mode auto`.
  - `/proc/3342837/cgroup` shows `run-p3342837-…scope`, and `systemctl --user show` on it gives `OOMPolicy=continue`. Its environment has `ENABLE_CLAUDEAI_MCP_SERVERS=false`, and its parent is the tmux server.
  - None of `OOMPolicy`, `restart.sh` or `ENABLE_CLAUDEAI` appears in the guide or in `docs/`.
- **Fix:** add the exact start command to §0. For example, a copy of the script without `--resume`:

  ```
  tmux new-session -d -s bramble-ideation -c /home/alex/code/Bramble-ideation "ENABLE_CLAUDEAI_MCP_SERVERS=false systemd-run --user --scope -q -p OOMPolicy=continue claude --permission-mode auto --remote-control 'Bramble ideation'"
  ```

  Then `tmux attach -t bramble-ideation`. Say plainly that the existing restart script resumes the old session.

### 2. BLOCKING: no step to shut down the old session, which is still running
- **Section:** §0 "What died with the old session" and "The first five minutes".
- **What's wrong:**
  - The table is written as if the old process has exited, but it hasn't:
    - the old Claude, pid 3342837, in tmux session `bramble-ideation`;
    - its bridge, pid 3342936;
    - three `codex app-server` processes: 329635, 809982 and 961917.
  - Its `/goal` check-ins keep it working. Closing the Remote Control view on a phone doesn't stop the process.
  - If the new session resumes threads `01a1bf42…`, `01a1c0c7…` and `01a1be5b…` while the old bridge is alive, two app-servers and two orchestrators act on the same threads and worktrees.
- **Evidence:** `ps -eo pid,ppid,etime,args`, `tmux ls` (shows `bramble-ideation`) and `codex_status` (w5 idle, w6 and w7 live in the old bridge).
- **Fix:** add a "Before starting the new session" step:
  1. In the old session, `codex_close` w5, w6 and w7. All are idle now.
  2. `/exit`, or `tmux kill-session -t bramble-ideation`. Don't kill the tmux server: the `webatrice` session lives in it too.
  3. Confirm `ps -o pid,args -p 3342837,3342936,329635,809982,961917` shows nothing.

### 3. BLOCKING (owner action): `/goal`, ultracode and effort must be set again by the owner
- **Section:** §0 "The goal" and §5.5.
- **What's wrong:**
  - **`/goal`.** It is per session, and only the owner can type it. Without it, the new session stops after each turn instead of running the loop. The guide says "the owner *may* re-issue it".
  - **Ultracode.** It is also per session. The Workflow tool's opt-in depends on it, and §4 step 2 (the cold reader) and §5.5 both rely on Workflows. The guide only says ultracode "was on".
  - **Effort.** The owner ran the old session at "extra" (high) effort and checked it after the last restart: "verifying that you're still got extra high effort and ultra code". The guide doesn't mention effort.
  - **The goal text.** It doesn't mention RESTART.md. The memory index does point to it, which helps.
- **Evidence:**
  - The transcript has `ultra_effort_enter` and `ultra_effort_exit` attachments ("Ultracode is off — the Workflow tool's standard opt-in rule applies again", 9 Nov 02:42 UTC).
  - The opt-in rule reads: "Ultracode is on for the session (a system-reminder confirms it)".
  - compact-summaries.md, lines 1575–1583.
- **Fix:** in §0, tell the owner to do three things in the new session's first minute:
  1. set the effort to the same "extra" level;
  2. turn ultracode on;
  3. issue `/goal` with the verbatim text, adding "and docs/ideation/RESTART.md" to the reading list.

### 4. IMPORTANT: the state has moved, and w6's final result contradicts the guide's design conclusion
- **Section:** §2 (workers table, "The Quilboar reference", "Branches") and §4 steps 4–6.
- **What's wrong.** As of 22:16 UTC:
  - **w7 (wave 2b)** committed `c66a88e5` and its tree is clean. Engine line ×1.369 (passes). Pot Luck ×1.251 (fails). R12 medians: engine 262, Pot Luck 200, pooled 250. Paper accounting 0.27× and 0.20×. The six new test scripts add about 38 s, not 28 s. The old session sent it a wrap-up at 22:07 UTC that isn't in the guide.
  - **w6 (Quilboar)** committed `6bb7c730` and is idle; its detached H1 driver has finished. Uncut R12 median **747**, not 825. Uncut is **2.38× Birds [1.50, 3.28]**, not 3.05×. Uncut real/paper is **0.121×**, below our tribes' 0.17–0.44×. w6's words: "A matching shared gap is not established."
  - That undercuts §2 ("shows the gap belongs to the method, not one tribe") and §4 step 6 ("paper accounting overestimates … for every tribe, the reference included. Uncut Quilboar's about 825 is evidence that B-scale is reachable").
  - The PLAN status block's "In short" line (shown on the portal) still says "about 825".
  - **w5** is unchanged, at `8ded22c2`, idle and clean.
- **Evidence:**
  - `git -C <worktree> rev-parse HEAD` and `status --short` give c66a88e5, 8ded22c2 and 6bb7c730, all clean.
  - `codex_status w6` final message.
  - The w7 final message in `/tmp/codex-bridge/2026-11-09-3342936-w7.jsonl`.
  - `progress.json` reads "complete".
- **Fix:**
  - Refresh §2 with the three tips and numbers.
  - Reword the §2 Quilboar bullet and §4 step 6. The method-gap claim is not established, and B-scale reachability rests on uncut 747 at R12.
  - Correct "825" in PLAN's In short line in the same docs commit.

### 5. IMPORTANT: old worker ids and the broken log recipe make old results hard to read
- **Section:** §3.3, §4 and §6 (`waitw.sh`).
- **What's wrong:**
  - **Old ids.** The new bridge restarts ids at w1, and its `codex_status` won't list old workers. But §4 keeps saying w5, w6 and w7. `waitw.sh w7` picks the newest `*-w7.jsonl`, which is the dead old log, so it waits its full 9,000 s.
  - **The log recipe.** §3.3's final-message one-liner fails as written: `python3 -c "…open(L)…"` gives `NameError: name 'L' is not defined`. That makes the old logs, the only record of the workers' last reports, awkward to read.
- **Evidence:**
  - I ran the recipe with `L=/tmp/codex-bridge/…-w5.jsonl` and got the NameError.
  - `waitw.sh`'s `log_for()` uses `ls -t … | head -1`.
- **Fix:**
  - Say "use the ids `codex_delegate` returns; keep the labels wave2b, declutter and quilboar; never pass old ids to `waitw.sh`".
  - Change the recipe to `python3 -c "import json,sys;[print(d['text']) for d in map(json.loads,open(sys.argv[1])) if d.get('final')]" "$L" | tail -40`.

### 6. IMPORTANT: CLAUDE.md and CLOUD.md contradict the guide on local Claude agents
- **Section:** §5.5, and the §1 reading order.
- **What's wrong:**
  - CLAUDE.md, which loads as instructions, says "Claude work runs in the cloud, local work on Sol through Codex", pointing to CLOUD.md.
  - CLOUD.md says "No Claude subagents run on this machine" and "That reviewer is a cloud Claude session".
  - The guide says to run `scope-reviewer` as a local Agent subagent and use local Workflows.
  - The change is recorded in DECISIONS "9 Nov 2026 — Fundamentals first: build 8 held, workflows replace cloud routing" and owner note 09b. The guide cites neither for this point.
  - A new session that reads CLAUDE.md first may send every review to the cloud, or refuse local agents.
- **Evidence:** CLAUDE.md ("Who runs where"), CLOUD.md lines 11–15 and 63, DECISIONS.md line 892.
- **Fix:** add one line to §5.5. CLOUD.md's "Who runs where" is superseded for Claude work by owner note 09b and that DECISIONS entry: reviewers and critics run locally (Agent or Workflow), cloud routines stay for heavy runs and gates, and nothing local runs Godot.

### 7. IMPORTANT: the coming RAM-upgrade reboot is not planned for
- **Section:** §0 table, §5.2, §5.3 and §6.
- **What's wrong.** The owner is adding RAM, which means a power-off.
  - **`/tmp` is wiped on reboot.** It is tmpfs (RAM-backed, 5.8 of 7.5 GB in use), and it holds:
    - `/tmp/codex-bridge/*` (the only record of the old workers' final reports);
    - `/tmp/bramble-godot-slot` (the stopgap §5.2 tells workers to use);
    - the old scratchpad;
    - workers' `/tmp` helper scripts.
  - **Every worker depends on the stopgap.** All three worker worktrees lack `scripts/godot_slot.sh`.
  - **`gh` may stop working.** Its token is in the GNOME keyring, and git's credential helper is `gh auth git-credential`. After a reboot with no desktop login, the keyring may stay locked over SSH. Then `cloud-gate.sh`, `gh run list` and `git push` all fail.
- **Evidence:**
  - `findmnt /tmp` shows tmpfs.
  - `ls …/scripts/godot_slot.sh` is missing in -balance, -tribes2 and -sol.
  - `gh auth status` shows "(keyring)", and `~/.config/gh/hosts.yml` holds no token.
  - `git config` shows `credential.https://github.com.helper !/usr/bin/gh auth git-credential`.
- **Fix:**
  - **Now:** copy the three old workers' final messages into `build/orchestrator/`.
  - **Add an after-reboot checklist:**
    1. Restore `/tmp/bramble-godot-slot` from `build/orchestrator/bin/bramble-godot-slot.stopgap` (`chmod +x`).
    2. Run `gh auth status` and `git push --dry-run origin ideation/main`. If the keyring is locked, the owner logs in to the desktop once.
    3. Expect the old bridge logs to be gone.

### 8. IMPORTANT: the first five minutes resumes w5 before its merge
- **Section:** §0 step 5, against §4 steps 2 and 4.
- **What's wrong:**
  - Step 5 says to resume all three threads for a status report.
  - §4 step 2 says to merge ideation/main into `ideation/declutter` first, on a clean tree, then resume w5.
  - A resumed `implement` thread without `approach_first` "starts editing at once", so it can race the merge.
  - Now that all three trees are clean and idle, this is the moment to merge `ideation/main` into all three branches. None of the tips carries the Actions trigger, and the guide says merges must wait for an idle, clean tree.
- **Evidence:**
  - `git show <tip>:.github/workflows/ci.yml | grep -c ideation/gate` gives 0 for c66a88e5, 8ded22c2 and 6bb7c730, and 2 for ideation/main.
  - The trees are clean (issue 4).
- **Fix:** reorder step 5:
  1. Merge `origin/ideation/main` into wave2b, quilboar and declutter, one at a time, while they're idle.
  2. Then resume each thread with its next task. Don't send an edit-capable status ping first.

### 9. IMPORTANT: if "SSH" means Claude Desktop's SSH remote, several things change
- **Section:** §0.
- **What's wrong.** A Claude Desktop SSH session from the owner's machine is running now: pid 1022308, `~/.claude/remote/ccd-cli/2.1.321`, with `CLAUDE_CODE_ENTRYPOINT=claude-desktop`, started in `/home/alex/Documents`. If the new orchestrator runs that way:
  - It must be opened in `/home/alex/code/Bramble-ideation`. In `~/Documents` it gets no memory, no project CLAUDE.md and no codex MCP server, because the bridge config is keyed to `/home/alex/code/Bramble`.
  - It runs in the SSH login scope, without tmux or `OOMPolicy=continue`, and with the claude.ai connectors loaded.
  - Permission prompts go to the desktop UI.
  - `/goal`, ultracode and Remote Control in that client are unverified.
- **Evidence:** `ps`, `/proc/1022308/cwd`, `/proc/1022308/environ` (entrypoint and the `CLAUDE_SSH_*` variables), and `/proc/1022308/cgroup` (`session-391.scope`).
- **Fix:**
  - Say which client to use. The tmux command in issue 1 is the proven path.
  - If the owner uses Desktop, add a check before resuming any worker: `/mcp` shows codex connected, `/goal` is accepted, and ultracode is on.

### 10. IMPORTANT: pending work missing from §4
- **Section:** §4.
- **What's wrong:** these items from the history and DECISIONS are not in the next-actions list:
  - **After the declutter merge:** w5 ports Bog's kiss count, the pending-gain tag and Bog's Toll into the wordless face (DECISIONS line 309). The same goes for the Oozes' ladle, meal and wake marks (the wave2b brief, line 41).
  - **Declutter batches 2–4** (`ui-declutter-spec.md`). Pounce timing and Pack and Mire go to Batch 4 (DECISIONS, "Declutter batch 1, third cold reader").
  - **The owner's replays.** The owner was told to drop Quilboar replay files in `/data/transfer/replays/` (compact-summaries.md line 1900). The folder doesn't exist yet, and nothing tells the new session to check it.
  - **XDG_DATA_HOME.** Consider isolating it in the slot wrapper (summary 15, Pending Tasks).
  - **Unlisted durable data.** §6 doesn't list `build/orchestrator/fundamentals/` (915 MB, including the 77 Quilboar perfect-game wins used to check the port's line policy) or `pass3/`.
- **Fix:** add these as §4 step 2b, a §4 step 7 item and a §6 row.

### 11. MINOR: some old helpers survive, and the ps check misses drivers
- **Section:** §0 table, "lock sampler" and "Background wait scripts".
- **What's wrong:**
  - **The lock sampler.** `locksample.sh`, pid 817667, has been reparented to init and is still writing `build/orchestrator/lock-samples.csv` (last row 22:04 UTC). It runs the scratchpad copy. Following "Restart it" starts a second writer.
  - **Wait scripts.** Three `waitw.sh` processes (968843, 970065, 998197) may be orphaned when the old session exits.
  - **The ps check.** The first-five-minutes check greps only `godot|flock`, so it misses a detached Python sim driver between chunks (the H1 driver was `python3 tools/sim/quilboar_h1.py` under `timeout 5400`).
- **Fix:**
  - Check `ps -o pid,args -p 817667` before restarting the sampler.
  - Kill leftover `waitw.sh` processes by pid.
  - Grep for `godot|flock|tools/sim/|quilboar_h1`.

### 12. MINOR: stale timing figures in the guide and both cloud briefs
- **Section:** §5.2, §7 ("Slowest scripts"), and `build/orchestrator/briefs/*.md`.
- **What's wrong:**
  - §5.2 says a gate "takes about 15 min (771 s)". Since the fast paths it is 10m45s, with a 559 s tests step (run 42706292823).
  - The §7 table and the faster-suite brief list `test_bot_brain` at 94.9 s. It is now 64.3 s, with `test_field_normal_regression` at 31.3 s.
  - Both briefs give the old 771 s and 15 min as their "Why now". The faster-suite brief says game-profile is "on branch ideation/c-gameprofile if it isn't on ideation/main yet", but it is on ideation/main.
  - Sharding is still justified: 10m45s is over 7.5 min.
- **Evidence:** `gh run view 42706292823 --log | sed -n '/slowest 20/,/PASS tests/p'` and `gh run list` (10m45s).
- **Fix:** update the numbers to run 42706292823 before `RemoteTrigger create`.

### 13. MINOR: §4 step 4 gives the reviewer the orchestrator's own brief as scope
- **Section:** §4 step 4.
- **What's wrong:**
  - It says to brief the scope reviewer with `docs/ideation/briefs/wave2b-build.md`, which is the orchestrator's brief to the worker.
  - §5.1 and `~/.claude/CLAUDE.md` say scope is the owner's words plus the approved plan; briefs go in "only as labelled proposals".
- **Fix:** scope is owner notes 09a, 09c and 09h plus plan v3's text. Pass wave2b-build.md labelled "proposal".

### 14. MINOR: w5's standing rule plus check.sh after the merge can deadlock
- **Section:** §4 step 2.
- **What's wrong:**
  - w5's first developer instructions, which survive a resume, say "Godot only under flock /tmp/bramble-godot.lock systemd-run …".
  - After ideation/main is merged in, `check.sh` takes its own slot. Any `check.sh` that w5 runs inside that flock hits the outer-flock deadlock §5.3 warns about.
- **Evidence:** rollout `~/.codex/sessions/2026/11/10/rollout-…-01a1c0c7….jsonl`, the first developer message.
- **Fix:** the resume prompt says "don't run check.sh; targeted UI test files only".

### 15. MINOR: stale or contradictory lines
- **Section:** memory, §5.8 and §2.
- **What's wrong:**
  - **Memory.** `memory/ideation-restart-guide.md` says the guide "may still be only on the local temp branch ideation/merge-gate-plumbing". That branch is deleted, and the guide is on ideation/main at 990a6fb1. This memory file loads automatically.
  - **§5.8.** It says the PLAN status block "is stale at writing: it still says wave 2a is in progress". 990a6fb1 refreshed it, as §4 step 1 says.
  - **§2.** It says gate plumbing and the per-game profile were merged "(on the temp branch)". They are on ideation/main.
- **Fix:** correct these three lines. The memory edit needs the owner's OK under the guide's own §5.1 rule, or can be left to the new session with a note.

### 16. MINOR: paths that exist only on worker branches
- **Section:** §7 "Paths".
- **What's wrong:**
  - `content/reference/quilboar/` exists only on ideation/quilboar (-sol).
  - `docs/ideation/evidence/declutter/batch1/` exists only on ideation/declutter (-tribes2).
  - Neither exists on ideation/main.
- **Fix:** name the branch for each.

### 17. MINOR: a stray worktree in /tmp
- **Section:** §7 "Worktrees".
- **What's wrong:** `git worktree list` shows `/tmp/bramble-harness-fresh-shard`, a detached HEAD at `1ea90ea9`, which is already in ideation/main. It isn't mentioned, and the reboot will leave a stale worktree entry.
- **Fix:** note it, and run `git worktree prune` after the reboot.

### 18. MINOR: routine ids, reading load, tool loading and two rule conflicts
- **Section:** §7, §1, §0 and §5.1.
- **What's wrong:**
  - **Routine ids.** LOG.md doesn't have the gate-plumbing, game-profile or cloud-gate routine ids (`trig_01AK9f…`, `trig_01GtoRW…`, `trig_01Bu2zM5…`). They are only in RESTART.md and DECISIONS, though the guide says "Older ones are in LOG.md".
  - **Reading load.** The §1 list is about 390 KB, roughly 100k tokens, including 96 KB of 9–10 Nov DECISIONS entries. Read 10 Nov first and the rest on demand.
  - **Tool loading.** §0 explains loading `mcp__codex` but not `RemoteTrigger`, which is also a deferred tool (`ToolSearch select:RemoteTrigger`).
  - **Rule conflict.** Memory `owner-intent-rules-and-pushback` keeps rule-writing in briefs and docs for the owner, while CLAUDE.md's ideation section hands "writing working rules for this branch" to the orchestrator. Add one line on which wins on ideation: working rules go in DECISIONS, and CLAUDE.md, memory and permissions stay with the owner.

---

## Checked and correct

- **Git:** origin/ideation/main is at 990a6fb1, one docs commit after e92ab110, and contains 2fa5247f, 405bd57b, 81dd2307 and 66289bc5. The worktrees and branches match §7, apart from the stray `/tmp` worktree (issue 17).
- **Actions runs:** 42702428298, 42705008878 and 42706292823 all passed, and the plumbing runs including the planted failure are there. The local `gh` login lacks the `workflow` scope.
- **Bridge config:** it is in `~/.claude.json` under `/home/alex/code/Bramble`, with the four roots and `CODEX_BRIDGE_MAX=3`. The `resume_thread` and `workerId` parameter names match `codex-bridge.mjs`.
- **Threads:** all three thread ids exist under `~/.codex/sessions`.
- **Resumed threads keep their first instructions:** confirmed. The 19:45 UTC resume of w6 passed new `instructions`, but the rollout has no new developer message.
- **Memory and transcripts:** memory is under `-home-alex-code-Bramble/memory`, and the transcript and workflow journals are under `-home-alex-code-Bramble-ideation/5369878e…/`. The cold-reader script path exists.
- **Durable files:** `build/orchestrator/{RESUME.md, compact-summaries.md, bin/*, briefs/*}` exist and `build/` is gitignored.
- **Builds and inbox:** `/data/bramble-builds/latest` points to `1108-2016-ideation7`. The inbox is empty.
- **Local paths:** `/opt/bramble/env.sh`, both lock files and `~/.local/state/bramble/cloud-gates.csv` all exist.
- **Docs:** the owner notes 09a–09i and 10a, both plans, the test-suite evidence 1–7 plus game-profile, and the docs `HARNESS.md`, `wave2b-build.md` and `CLOUD_SETUP.md` all exist where the guide says.
- **Settings:** user settings have `defaultMode: auto` and `enableWorkflows: true`.
