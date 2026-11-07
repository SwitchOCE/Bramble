# Lessons from the Autobattler project

Written 2 November 2026 from the Autobattler repo (`C:\Users\keech\Documents\Autobattler`, GitHub `SwitchOCE/Autobattler`), its cloud worker logs, its local orchestrator transcripts and the owner's memory notes for it. Autobattler was a Godot 4.7 auto-battler built by cloud Claude Code workers from 10 to 18 October 2026: 389 commits, about 213 PRs, about 3,500 GUT tests.

The owner's ask: "anything from that project that we can leverage to our advantage to make sure this project runs better."

Detail files in this folder:
- [toolchain.md](toolchain.md): cloud environment, Godot, Android, exports, CI, tests. Symptom, cause, fix and the Bramble action for each problem.
- [cloud-logs.md](cloud-logs.md): what the worker run logs showed, and how to read them.
- [orchestration.md](orchestration.md): how dispatch, review and merging worked, what broke, and what the owner corrected.
- [reuse.md](reuse.md): which code, scripts and templates to copy, adapt, learn from or avoid.

**[V]** marks a fact checked in a file, commit, issue, log or memory note. **[I]** marks an inference.

## The short version

The engineering infrastructure mostly worked and much of it is worth copying. What failed was supervision, CI budget, and a few cloud tooling gaps that cost time again and again.

1. **The design drifted because agents made design calls early.** The owner's brief was one paragraph, and agents were told to "pick a reversible default… Don't stop for it". By the 15 October audit the economy, progression and content shape were agent choices, and "almost all existing content will be redesigned" [V]. Bramble's CLAUDE.md rules already address this. The new lesson is that delegation was widened again on 17 October under time and usage pressure ("3 hours left till usage limits. Fan out agressively"), and the orchestrator then ran ahead of the bottom-up model it had agreed to wait for [V].
2. **GitHub Actions ran out on day 2 and never came back.** The artifact storage quota was hit on the first CI run. From 10 October 23:22Z every job said "The job was not started because an Actions budget is preventing further use" [V]: 177 real runs, then 405 instant red runs over 8 days. From then on each worker's local `check.sh` was the merge gate, and a stale-head merge broke main for about 30 minutes.
3. **Cloud workers could not release.** The auto-mode classifier refused `export_release.sh` as "[Production Deploy]" three times, even with the owner's approval relayed. RemoteTrigger drops `auto_mode_allow`, and repo settings don't reach cloud auto mode; only Team/Enterprise server-managed settings do [V]. Releases v0.8.0 and v0.8.1 went out from a local WSL session, without an APK.
4. **Android AAB builds never worked in the cloud.** Gradle got HTTP 429 from Maven Central every time, so only plain APKs were built [V]. Issue #11 is still open. Android is a first target for Bramble, so this needs proving on day one.
5. **Cloud environment traps** each cost a worker turn or more [V]:
   - env vars in `.claude/settings.json` didn't reach the shell (fix: write them to `$CLAUDE_ENV_FILE` from the SessionStart hook);
   - the Android SDK versions were wrong (they must come from the pinned Godot's own `config.gradle`);
   - Godot needs a Java SDK path pre-written in editor settings;
   - `gh pr` and `gh issue` fail in cloud sessions ("GitHub GraphQL is not available"), so only `gh api` works;
   - `docs.godotengine.org` was blocked;
   - Actions job logs sit on blob storage the VM can't reach;
   - `shellcheck` and Python `PIL` are not installed.
6. **Godot headless traps** [V]:
   - `--import` doesn't compile scripts;
   - GUT exits 0 on unparseable scripts;
   - a broken scene passed the first gate;
   - a stale class cache after merges logged script errors;
   - one parse error showed up as dozens of "Nonexistent function 'new'" failures;
   - PNGs under `docs/` got imported until `.gdignore` was added.
   Autobattler's `check.sh` handles all of these, and Bramble can copy it.
7. **The test suite outgrew the timeout.** GUT reached 549–726 s on the 4-CPU cloud VM against a 600 s limit. Four parallel shards brought it to 133–194 s, but sharding exposed suites that shared `user://` paths [V].
8. **Worker messaging was fragile.** Idle workers missed PR review comments (18 issues re-dispatched, #234 four times), two sessions pushed to one PR four times, and mailbox messages arrived one turn late until `update` and `run` were sequenced [V]. The fixes are in `ORCHESTRATOR.md` and worth inheriting.
9. **Cost.** The 7-day usage warning came on night one. Orchestrator sessions averaged 270–350k tokens of context per call, with 11 compactions in one session. About 150 status commits went straight to main, and `STATUS.md` grew to 38 KB [V].
10. **The repo got heavy.** Native-size screenshots were committed: `docs/screens` is 577 MB and `.git` is 943 MB [V]. Every worker clones that.

## What worked and should be copied

- **Layer enforcement:** `tools/checks/layers.py`, about 400 lines of stdlib Python with fixture tests, changed only twice. Copy it and adapt the rule tables.
- **The strict quality gate:** `scripts/check.sh` up to the test step, `compile_all.gd`, the strict GUT hook, warnings as errors in `project.godot`, and the lint configs.
- **Determinism:** PCG32 and SplitMix64 with named seeded streams, and the atomic `FileKeyValueStore` save store.
- **Exports from Linux:** Windows (with version resources and no wine), macOS and Android APK all exported. `export_smoke.sh` caught missing runtime files. The version file has a consistency test.
- **Screenshots:** the screenshot tool (xvfb, opengl3, an error-counting logger) and its 720 base size with `expand`, which gives phone and desktop the same scale.
- **Process:**
  - the issue contract (Scope, Acceptance, Verification) and one-line dispatch;
  - non-overlapping file scope as the limit on parallel work;
  - a QA subagent before every PR (it caught real blockers every time);
  - checks on the merged, re-imported head;
  - the persistent-routine mailbox;
  - worker output treated as data;
  - owner decision pages built as artifacts with a database (the owner praised these).

Avoid: every core and effect primitive (they encode Autobattler's spire HP, cooldowns and fatigue), the bots and balance tools, and the game-designer and balance-analyst agents. Bramble's CLAUDE.md already rules out carrying over those design assumptions.

## Day-one checklist for Bramble's cloud setup [I]

1. **One versions file** for Godot (version and SHA-512s), export templates, GUT, gdtoolkit, ruff, Android SDK, build-tools, NDK and JDK. Every script reads it, and a test fails when a copy drifts. Autobattler copied the Godot pin into about 8 places.
2. **Setup script:**
   - SHA-checked downloads;
   - only a failed Godot install is fatal;
   - prints its version and duration;
   - finishes in under ~5 minutes, so the snapshot is cached;
   - pre-writes Godot editor settings (Java and Android SDK paths).
   It is pasted by hand into the environment UI, so print a hash that the hook compares with the repo copy.
3. **SessionStart hook** writes every env var to `$CLAUDE_ENV_FILE`, puts JDK 17 first on PATH, and imports when `.godot/imported` is missing.
4. **The full network allowlist from the start:**
   - `dl.google.com`, `maven.google.com`, `services.gradle.org`, `plugins.gradle.org`;
   - `docs.godotengine.org`, `uploads.github.com`;
   - every addon host.
   Keep the setup doc in sync; Autobattler's drifted.
5. **Toolchain issue #1**, proved in a fresh cloud session:
   - xvfb render to a non-blank PNG;
   - the exit code of `godot -s`;
   - an Android Gradle debug export;
   - a Windows export with version resources;
   - every `gh api` call workers will use.
6. **First commit:**
   - `.gitattributes` with LF line endings, and binary rules for images, fonts, audio, `.dll`/`.so`/`.dylib` and keystores;
   - `.gitignore` for keystores and `.env*`;
   - exec bits on scripts;
   - `.gdignore` in `docs/`, `tools/` output and `build/`;
   - in `project.godot`: gl_compatibility, `import_etc2_astc=true`, an app icon, and warnings as errors.
7. **Quality gate:**
   - re-import after merges;
   - a compile step;
   - the strict GUT hook and a parse-error grep;
   - shards with per-shard timeouts once tests pass ~5 minutes;
   - each suite owns its `user://` paths;
   - an allowlist for known engine noise;
   - perf warns by default, and strict mode uses the median of 3 runs.
8. **Decide the CI budget before CI exists**, then design lean triggers: PRs only, path filters, exports on a label, nightly run or tag.
9. **A release path outside cloud workers:** a tag-triggered Actions workflow, or a local session the owner starts, with allow rules set first.
10. **Keep screenshots out of the repo:** Actions artifacts, LFS or a separate repo.
11. **Choose the app ID before the first store upload.** It cannot change after that.

## Owner decisions, 2 November 2026

1. **CI: public repo, free Actions minutes, for now.** The owner accepts the small risk of the project being copied, and may take the repo private later. Before the switch:
   - scan the full history for secrets;
   - set interaction limits to collaborators only.
   Going private later doesn't recall clones or forks made while it was public.
2. **Android store builds (AAB): in GitHub Actions.** The first toolchain issue also proves a Gradle build in the cloud environment. Try a plain build, then a Maven Central mirror, then pre-warming the Gradle cache in the setup script, and report what worked and how long setup took. The owner wants Gradle in the cloud if it is possible.
3. **Releases: not decided yet.** The recommendation is a tag-triggered GitHub Actions workflow. The signing key stays in GitHub secrets, and only the owner's account can create release tags. GitHub's docs say required reviewers on deployment environments are free only on public repos (on Free, Pro and Team plans). The owner would create the Android release keystore and keep an offline backup. The owner asked about the downsides and hasn't chosen yet.
4. **Screenshots: a separate repo, under review.** Claude Code's docs say a cloud session with several repositories ignores each repo's hooks, env and permission settings. If workers can only push to a second repo by adding it to the session, that switches off the setup hook. An orphan branch in the game repo is the alternative. The first toolchain issue tests whether workers can push to either.
5. **Orientation: held for the UI/UX phase.** Landscape is the setup placeholder. The owner leans towards portrait on phones and landscape on desktop. The owner frames the real choice as your board at the bottom and the opponent's at the top, versus left and right. Top and bottom works in both orientations (Hearthstone Battlegrounds is landscape with your board at the bottom), so supporting both orientations would mean two sets of proportions, not two layouts. At the UI phase, check which auto-battlers run portrait on phones.
6. **Memory: only how agents work with the owner.** Project rules, decisions and state go in repo docs, where cloud workers can read them. Direct-instruction rules ("you can / you can't") are written nowhere agents follow them until the owner has approved the exact wording and the reason. Each rule carries its purpose. Notes about learnings don't need approval.

## How to read the cloud logs again

This needs nothing from the owner. A local session can read Autobattler's cloud workers with `RemoteTrigger` (`list`, `get`, `list_runs`, `get_run_log`). Limits found [V]:
- `list` returns only the 20 newest routines and ignores its cursor.
- Older worker session ids are in the orchestrator's "Dispatched: routine …, session …" comments on each GitHub issue.
- `get_run_log` returns the newest 200 events per page and still works on sessions from 10 October.
- Fresh subagents don't get `RemoteTrigger`; a fork of the main session does.
- Each log costs about 15k tokens of context, which is why only 9 were read in depth.
- Cloud sessions started by hand on claude.ai, rather than as routines, don't appear in the routine list.
