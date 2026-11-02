# Autobattler: what the cloud worker logs showed

Read on 2 November 2026 with `RemoteTrigger` (read-only actions only). **[V]** = seen in a log, **[I]** = inference.

## Coverage

- **Routine index:** 190 routines. 165 worker session ids were recovered from the orchestrator's "Dispatched: routine …, session …" issue comments.
- **Logs read in depth:** 9, newest 200 events each, so some early-turn errors may be missing:

| Issue | Date | Session | Topic |
|---|---|---|---|
| #1 | 10-10 | `session_01LS9djkSU4NZpngYiM9Rx6B` | toolchain check |
| #3 | 10-10 | `session_01VZK1QwsR7Yd3tekdVgmrX6` | skeleton and `check.sh` |
| #4 | 10-10 | `session_01TqEqF7Wc7Fj22xajRDXn5r` | screenshot tool and CI |
| #36 | 10-10 | `session_01HNxxrDszk5DYK1UY18RvbN` | export presets and smoke test |
| #61 | 10-11 | `session_019hyu1fqrsytHRmTaUxrZEe` | vendoring GodotSteam |
| #134 | 10-11 | `session_012Y5dSHHT4t2f5EgKtPPHmr` | tutorial and touch follow-ups |
| #292 | 10-17 | `cse_017FwrrwDhqnBuU2UqrnNT7U` | menu idle perf |
| #405 | 10-18 | `cse_01X8wbP32cQUrgNcXfU1Vuts` | GUT timeout |
| #414 | 10-18 | `cse_013NFeZ58xuUNsnYVYopc39E` | v0.8.1 build |

- **Not read:** the content-batch runs.
- **More can be read:** sessions back to 10 October are still available.

## Patterns, ranked by cost

1. **Actions budget gone from day 2** [V].
   - 10 October: "Artifact storage quota has been hit."
   - From 11 October 01:28 to 18 October: "The job was not started because an Actions budget is preventing further use."
   - Every worker spent turns diagnosing red checks, and merges relied on the local `check.sh`.
2. **The classifier blocked releases** [V].
   - #414: `export_release.sh` was denied 3 times as "[Production Deploy]", so there was no tag and no release.
   - Also: "[Exfil Scouting]" on a proxy probe (#1), and `rm` safety checks (#1, #4).
3. **Gate runtime** [V].
   - GUT took 480–730 s against a 600 s timeout, until sharding (#405).
   - The full gate took about 10 minutes in #292, so it ran in the background.
   - Perf was noisy: "budget miss menu_idle process_p99 2.73 > 2.00".
4. **Cloud tool gaps** [V].
   - `gh` porcelain: "HTTP 403: GitHub GraphQL is not available from Claude Code sessions; use the REST API" (#36).
   - Job logs on unreachable blob storage (#4, #292).
   - `docs.godotengine.org` blocked (#1).
   - No `shellcheck` (#61) and no `PIL` (#134).
   - `sleep 240` blocked (#61).
   - `--doctool` hung for more than 300 s (#4).
5. **Android** [V].
   - Build-tools 36.1.0 were missing (#1).
   - Gradle got HTTP 429 from Maven Central (#1).
   - With fresh XDG config: "A valid Java SDK path is required in Editor Settings" (#36).
   - Preset keys were missing, and there was no icon (#1).
6. **Godot headless** [V].
   - A fresh clone with no import cache hung at exit 124 (#4).
   - Import doesn't compile scripts, and "[brokenscene] EXIT 0" passed the first gate (#3).
   - One parse error turned into many "Nonexistent function 'new'" failures (#292).
   - PNGs under `docs/` were imported until `.gdignore` was added (#3).
   - Exit leaks of 5–6k ObjectDB instances (#61, #405).
7. **Exports from Linux** [V].
   - Linux, Windows, macOS and APK work; iOS gives an Xcode project only (#36).
   - The smoke test caught missing runtime files (#36).
   - The app ID is immutable after the first store upload (#36).
   - Native `.dll`/`.so` files were committed under `text=auto` (#61).
8. **Protocol** [V].
   - Workers unsubscribed from PR activity after reporting, so the orchestrator's review went unseen: "Original session went idle without seeing the review" (#134; also #91, #94, #138). 18 issues were re-dispatched, #234 four times.
   - Parallel workers fixing the same break caused merge conflicts (#292 against #302).
   - One "Mode B" session (#103) is still active and idle.
   - **What worked:** a QA subagent before each PR caught real blockers every time (#3: four layer-checker bypasses; #36: a CI exports job that would have failed every run; #405: a CI-timeout problem). The persistent-session mailbox ran #414's two phases.

## Notes per run

### #1 toolchain check (504 s, 30 turns, 2 permission denials)
- Setup script first run: about 24 s. Later wake: "Setup script cached from previous run".
- **Verified:**
  - Godot 4.7.2, gdlint/gdformat 4.5.0, JDK 17.0.20.1, Python 3.11, export templates, SDK 36;
  - `xvfb-run -a godot --rendering-driver opengl3 --resolution 1080x2400` renders a real PNG;
  - `godot --headless -s` passes the exit code through.
- **Android export:**
  - a minimal preset failed for lack of `include_filter`;
  - it needs the full preset keys, `import_etc2_astc=true` and an icon.
- **Versions:** the Gradle template pins build-tools 36.1.0, NDK 29.0.14206865 and JDK 17; setup had only 36.0.0. A plain (non-Gradle) export signs and verifies.
- **Gradle failed:** Maven Central returned HTTP 429, and the retry failed too.
- **Network:** `docs.godotengine.org` was blocked.
- **Denials:** "[Exfil Scouting]" on `curl $HTTPS_PROXY/__agentproxy/status`, and "Dangerous rm operation on statically-unresolvable target" for `cd X && rm -f build/*`.
- **Environment:** it injects `JAVA_TOOL_OPTIONS` with the agent proxy.

### #3 skeleton and `check.sh` (first turn 942 s, 54 turns)
- The cloud Stop hook nagged about untracked `docs/screens/*.png.import` files. Fix: `docs/.gdignore`.
- Import doesn't compile scripts, so a `compile_all.gd` step was added.
- The QA deliberate-break test: "[brokenscene] EXIT 0" passed every step until the gate failed on ERROR lines.
- The QA subagent found 4 layer-checker bypasses.
- Workers scheduled their own "Re-check PR" check-ins, which is where the many "Re-check PR #N" routines came from.

### #4 screenshot tool and CI (805 s, 27 turns)
- **Fresh clone without an import cache:** it hung at exit 124. The tool now uses preloads instead of `class_name`.
- **Window size:** `window_*_override` beats `--resolution`, so the size is set in code.
- **False success:** the tool reported success when the scene's script failed. A Logger subclass now counts errors.
- **Hang:** `--doctool` hung for more than 300 s and was killed (exit 144).
- **CI:**
  - job logs on blob storage were unreachable;
  - the first CI run hit the artifact quota;
  - a Node 20 deprecation warning came from `actions/cache`.
- **Rendering:** Mesa llvmpipe. "Could not set V-Sync mode" is harmless; use `--audio-driver Dummy`.

### #36 export presets, smoke test and CI exports job (first turn 1,252 s, 47 turns)
- **`gh`:** `gh run list` and `gh pr list` failed with HTTP 403 (GraphQL not available).
- **Android:** "A valid Java SDK path is required in Editor Settings". Godot reads `java_sdk_path`, `android_sdk_path` and the debug keystore from `editor_settings-4.7.tres`.
- **Exports:** Linux, Windows (with resources, no wine), macOS universal and APK all OK; iOS gives an Xcode project only.
- **Templates:** the archive is 1.3 GB; CI caches only the needed 290 MB.
- **The smoke test caught:** excluded `content/schemas`, and the `en_XA` pseudo-locale breaking the exported build's startup.
- **Signing:** through `GODOT_ANDROID_KEYSTORE_RELEASE_*`, `GODOT_MACOS_CODESIGN_*` and `GODOT_WINDOWS_CODESIGN_*`.
- **App ID:** flagged as needing the owner.
- **QA:** caught a `JAVA_HOME` override that would have failed the CI exports job on every run.

### #61 vendoring GodotSteam (1,145 s, 46 turns)
- **Missing tool:** `shellcheck: command not found`.
- **Blocked:** "Blocked: sleep 240 followed by … use Monitor with an until-loop … or run_in_background".
- **Exit leaks:** "WARNING: 5067 ObjectDB instances were leaked at exit".
- **Line endings:** `git check-attr` showed "steam_api64.dll: text: auto / eol: lf".
- **Checksums:** upstream publishes none, so the worker recorded SHA-256s.
- **Mobile:** desktop GDExtensions must not ship in the APK.

### #134 tutorial and touch follow-ups (first turn 1,559 s, 74 turns)
- The Actions budget was already exhausted by 11 October 01:28.
- The worker unsubscribed from PR activity after its report, so it never saw the review, and the issue was re-dispatched in Mode B.
- `PIL` was not installed.

### #292 menu idle perf (17 October)
- **Gate time:** tests took 411–422 s and the whole gate about 10 minutes.
- **Perf:** the median of 3 runs; single runs exceeded the limit.
- **Parse error:** `lerpf()` on a Variant was "Parse Error … (Warning treated as error.)", and the whole script failed.
- **Conflict:** a merge conflict with parallel worker #302, which fixed the same break.
- **CI and logs:** CI was blocked by the budget, and job logs were unreachable.

### #405 GUT timeout (18 October)
- GUT took 549 s for 385 scripts against the 600 s limit. Four shards brought it to 133–194 s.
- Sharding exposed shared `user://` paths.
- The leaks were a lambda capturing `self`, an unreleased state and an unfreed popover.
- CI after the merge: blocked by the budget.

### #414 v0.8.1 build (18 October)
- **Phase 1:** export smoke OK (Linux, Windows, Android debug), and a 60-run soak with `--verify-resume --verify-replay` had 0 mismatches.
- **Phase 2:** "[Production Deploy]" denials 3 times. The worker refused to add its own allow rule on a relayed "owner authorised" message. The issue went to `status:blocked`.
- **Mailbox:** "Orchestrator:" messages into the persistent session worked.

## How to read these logs again

- **`RemoteTrigger list`** returns only the 20 newest routines and ignores `cursor`. Older session ids are in the issue comments ("Dispatched: routine …, session …").
- **`get_run_log <session_id>`** returns the newest 200 events. Pass `next_cursor` for older ones. Logs from 10 October still load.
- **Fresh subagents** don't get `RemoteTrigger`; a fork of the main session does.
- **Cost:** each in-depth log costs about 15k tokens.
- **Missing:** cloud sessions started by hand on claude.ai, rather than as routines, are not in the routine list.
