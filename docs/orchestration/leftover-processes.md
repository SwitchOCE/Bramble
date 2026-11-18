# Leftover processes and temp files, 17–18 Nov 2026

On 18 Nov, before a restart, the owner asked whether everything was stopped. Two processes were still running from work that had finished hours earlier. The same day, temp files filled `/tmp` and failed a gate. The owner's words: "Those processes represent problems. You need to document those, and we need to find guardrails to stop that kind of stuff and find those early."

This page records what happened and why. The guardrails at the end are **proposals**, not decided.

Evidence (outside Git, survives a restart): `~/.claude/handoff/leftover-processes-2026-11-18/`. It holds the slots worker's Codex logs and the full process list taken at 11:30 on 18 Nov.

## What was found

### 1. A Godot capture running for 2.5 hours at 142% CPU

- **What:** `godot --path . --rendering-driver opengl3 … res://tests/screens/slots_capture.tscn` under `xvfb-run`. It started at 09:02 on 18 Nov and was killed at 11:36. It used more than one core the whole time, alongside four gate runs and two scope reviews.
- **Who started it:** Codex worker w16 (the slots brief), in `n18-slots`.
- **Why it never ended:**
  - The worker's first capture command had **no timeout**. Its later reruns had `timeout 100`, so the worker knew the rule but missed it once.
  - The capture scene never quit on that first run. The worker fixed the scene a few seconds later and moved on. Codex appears to stop waiting for a long command without killing it. That command never finished, so it is missing from the worker's own log, which records commands only when they end. This is inferred from the log and the process tree, not confirmed in Codex's code.
  - `codex_close` on w16 and w22 **didn't kill the worker's leftover commands**.
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

1. **Timeouts that don't reach the real process.** `timeout` signals only its direct child. With `xvfb-run` or `wine` in between, Godot or Wine's helpers survive. Some commands had no timeout at all.
2. **Nobody owns cleanup when work ends.** Closing a worker, removing a worktree or finishing a build doesn't stop its processes or delete its temp copies.
3. **Nothing looks.** No step lists leftover processes, temp copies or free `/tmp` space, so leftovers are found by accident, as here before a restart.

## Proposed guardrails (proposals, for the owner's go)

1. **One way to run Godot, Xvfb and Wine.**
   - Add a small wrapper, for example `scripts/run_bounded.sh <seconds> <command…>`. It starts the command in its own process group, and on timeout or exit it kills the whole group.
   - `check.sh`, `build_windows.sh`, `tools/look` and `tools/feel` use it.
   - `AGENTS.md` and `WORKER.md` tell workers to run Godot only through it.
   - Optionally, a lint step in `check.sh` flags new scripts that call `godot` or `xvfb-run` without it.
2. **The Windows build cleans up Wine.** `build_windows.sh` runs `wineserver -k` with the build's own prefix before its trap deletes that prefix.
3. **A leftovers sweep, run early and often.** `scripts/leftovers.sh` lists:
   - Godot, Xvfb, `xvfb-run` and Wine processes older than about 30 minutes;
   - any process whose working folder has been deleted or is a removed worktree;
   - repo copies in `/tmp`, and free space in `/tmp`.

   `check.sh` runs it first and warns, or fails when `/tmp` is nearly full. The orchestrator runs it after each worker closes, after each merge and cleanup, and before saying the machine is ready.
4. **Closing a Codex worker kills its commands.** In `codex-bridge`, `codex_close` kills every process the worker started, using its process group or the sandbox's process tree. This is a change in the bridge's own repository.
5. **Throwaway copies go in one place with an owner.** Workers and reviewers make comparison copies under one named folder per task, for example `/tmp/bramble-copies/<task>/`, rather than loose `/tmp` names. Whoever closes the task removes that folder, and the sweep reports anything left there.
