# Leftover processes and temp files, 17–18 Nov 2026

On 18 Nov, before a restart, the owner asked whether everything was stopped. Two processes were still running from work that had finished hours earlier. The same day, temp files filled `/tmp` and failed a gate. The owner's words: "Those processes represent problems. You need to document those, and we need to find guardrails to stop that kind of stuff and find those early."

This page records what happened and why. The owner approved the guardrails at the end on 18 Nov: "Yeah, so I'm happy with the guardrail plan."

Evidence (outside Git, survives a restart): `~/.claude/handoff/leftover-processes-2026-11-18/`. It holds the slots worker's Codex logs and the full process list taken at 11:30 on 18 Nov.

## What was found

### 1. A Godot capture running for 2.5 hours at 142% CPU

- **What:** `godot --path . --rendering-driver opengl3 … res://tests/screens/slots_capture.tscn` under `xvfb-run`. It started at 09:02 on 18 Nov and was killed at 11:36. It used more than one core the whole time, alongside four gate runs and two scope reviews.
- **Who started it:** Codex worker w16 (the slots brief), in `n18-slots`.
- **Why it never ended:**
  - The worker's first capture command had **no timeout**. Its later reruns had `timeout 100`, so the worker knew the rule but missed it once.
  - The capture scene never quit on that first run. The worker fixed the scene a few seconds later and moved on. Codex appears to stop waiting for a long command without killing it. That command never finished, so it is missing from the worker's own log, which records commands only when they end. This is inferred from the log and the process tree, not confirmed in Codex's code.
  - The worker tried to clean up. A later command began with `pkill -f '^godot --path . .*slots_capture.tscn'`, which matches the leftover, yet the leftover survived. A likely reason, not verified, is that the Codex sandbox can't see other commands' processes.
  - `codex_close` on w16 and w22 **didn't kill the worker's leftover commands**. On Linux, the bridge's `stopTree()` (`codex-bridge.mjs:160-163`) only sends SIGTERM to the Codex app-server. Only its Windows branch kills the whole tree. At 11:30 the app-server was gone, but its sandbox process and Godot were orphaned and still running.
  - Removing the `n18-slots` worktree didn't stop it either. It kept running in a deleted folder.
- **Why nobody saw it:** nothing looks for leftover processes. I didn't check the machine's load before starting gates, which the compute rule in `CLAUDE.md` asks for.

### 2. A Wine setup process left over from a Windows build

- **What:** `rundll32.exe setupapi,InstallHinfSection PreInstall … wine.inf` and a defunct `wineboot.exe`. They started about 11:35 on 17 Nov and ran for a day.
- **Why:** `scripts/build_windows.sh` boots the exe under Wine in a fresh prefix: `timeout 120 xvfb-run -a wine bramble.exe …`. A fresh prefix makes Wine run its first-time setup in the background. When the game quits, `wine` returns, but that setup and the Wine server can live on. The script's exit trap then deletes the prefix folder. It never runs `wineserver -k`, so nothing stops what was running inside it.

### 3. `/tmp` filled up and failed a gate

- **What:** `/tmp` is held in memory (7.5 GB). Claude Code's temp folder hit its quota at about 10:15 on 18 Nov. PR 134's gate failed in its feel stage. Every shell command failed until space was freed.
- **Why:** full copies of the repo (about 220 MB each) piled up and were never removed:
  - workers' `git archive` copies to compare with `dev` (`/tmp/bramble-slots-dev`, `/tmp/bramble-slots-baseline`, `/tmp/tipfix-before`, `/tmp/tipfix-parent`);
  - reviewers' probe copies;
  - my own scratch checkouts from the night run (`copy`, `copy2`, `tree`, `amb`).

  Each is reasonable alone. Nobody owns removing them, and nothing reports free space before a gate starts.

### 4. A cleanup command that killed itself (orchestrator error)

- To stop stale gates I ran `pkill -f "n18-(tipfix|slots).*check.sh"` in the same command that started the new gate. That command line matched the pattern, so `pkill` killed its own shell, with exit code 144. It cost one gate run.
- Lesson: kill by PID, or by a pattern that can't appear in your own command.

## The common causes

1. **A command with no time limit.** The leftover Godot run had no `timeout`. On this machine, `timeout` (uutils 0.10.0) signals the whole process group when time runs out. A test with `sleep` showed it reaching a grandchild started the way `xvfb-run` starts its command. So a `timeout` would have stopped Godot and Xvfb. The project's own scripts already put a `timeout` on every Godot run. The leak came from a one-off worker command.
2. **What a command starts can outlive a normal exit.** Wine's server starts its own session, so neither `timeout` nor the game quitting stops it. Only `wineserver -k` does.
3. **Nobody owns cleanup when work ends.** Closing a worker, removing a worktree or finishing a build doesn't stop its processes or delete its temp copies.
4. **Nothing looks.** No step lists leftover processes, temp copies or free `/tmp` space, so leftovers are found by accident, as here before a restart.

## Guardrails (approved by the owner, 18 Nov)

An independent agent interrogated a first draft. It found that draft's first cause wrong (it said `timeout` reaches only its direct child). It also cut a wrapper script and a lint that would not have caught either incident. This is the revised plan, in order.

1. **The Windows build stops Wine.** In `build_windows.sh`'s exit trap, `WINEPREFIX="$WORK/wine" wineserver -k || true` runs before the prefix is deleted. This fixes incident 2.
2. **A leftovers sweep, `scripts/leftovers.sh`, that finds problems early.** It lists:
   - processes whose working folder has been deleted, for example a removed worktree, whoever started them: Codex, Claude background shells or subagents;
   - Godot, Xvfb and Wine processes older than about 30 minutes, with each one's parent chain and PID;
   - free space in `/tmp`, and the size of each Claude session's temp folder and any repo copies in `/tmp`.

   It only reports, and anything is killed by PID, never by pattern (incident 4). `check.sh` runs it first. It warns about processes and fails only when `/tmp` is nearly full. That automates the load check `CLAUDE.md` already asks for, which was skipped. The orchestrator also runs it before telling the owner the machine is ready, and after closing a Codex worker until guardrail 3 lands. Inside a Codex worker's sandbox it may see nothing, so the orchestrator's run is the one that counts.
3. **Closing a Codex worker stops its commands.** In `codex-bridge`, `stopTree()` on Linux collects every descendant of the app-server from `/proc` before signalling. Orphans lose their parent link, so they must be collected first. It sends TERM, then KILL after a grace period. This is about 15 lines in a separate repository that other projects share. Check: close a test worker with a `sleep` running and confirm it dies.
4. **Worker habits, one line each in `WORKER.md`:**
   - Godot, `xvfb-run` and `wine` commands get `timeout -k 10 <seconds>`.
   - Comparison copies of the repo go in a gitignored folder inside the worker's own worktree, not in `/tmp`. That is on disk rather than memory, and it goes away with the worktree, so nobody has to remember to remove it.
5. **Orchestrator habit:** stop your own background tasks and delete your own scratch copies when their work ends.

### Built

- Item 1: `scripts/build_windows.sh` stops the build's Wine prefix in its EXIT cleanup before deleting it.
- Item 2: `scripts/leftovers.sh` reports processes and temp usage; `scripts/check.sh` runs it first and logs it in `build/check/leftovers.log`. It skips the agents' standing display (`xvfb@*.service`, started at boot) unless its folder was deleted.
- Item 4: `docs/orchestration/WORKER.md` (cloud Claude workers) and `AGENTS.md` (local Codex workers, added on the owner's "Yes, add AGENTS.md") give the timeout and comparison-copy habits; `.gitignore` excludes `.copies/`.
- Item 5: `docs/orchestration/ORCHESTRATOR.md` gives the sweep and cleanup habit.

Deferred: a wrapper script for every Godot run, and a lint for missing timeouts. Revisit them only if a script, rather than a one-off command, leaks a process that a plain `timeout` didn't stop.

Settled with the plan, as the orchestrator's defaults the owner didn't change: the codex-bridge change goes ahead; `check.sh` warns about leftover processes and fails only when `/tmp` is nearly full; the sweep lists other sessions' old Claude temp folders but doesn't delete them.
