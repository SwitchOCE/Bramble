# Autobattler: cloud environment, toolchain, build and CI

Sources: Autobattler `docs/CLOUD_SETUP.md`, `docs/build.md`, `scripts/` (`cloud-setup.sh`, `session-start.sh`, `check.sh`, `export_smoke.sh`), `.claude/settings.json`, `.github/workflows/ci.yml`, `export_presets.cfg`, `docs/decisions/` (1, 3, 4, 13, 36, 50, 193, 247, 333, 405), their git history, GitHub issues and PRs, the Actions API, the owner's memory notes for that project, and worker run logs (see [cloud-logs.md](cloud-logs.md)). **[V]** = verified, **[I]** = inference.

## 1. The final working cloud setup

**What it is made of [V]:**
- `scripts/cloud-setup.sh`, pasted by hand into the claude.ai cloud environment UI. It runs as root on Ubuntu 24.04 before Claude starts.
  - The result is snapshotted when the script finishes in about 5 minutes. Autobattler's first run took about 24 s.
  - Later sessions log "Setup script cached from previous run".
- `scripts/session-start.sh`, the SessionStart hook in `.claude/settings.json` (`matcher: startup|resume`, `timeout: 600`).
- Environment variables set in the UI: `BASH_DEFAULT_TIMEOUT_MS=300000` and `BASH_MAX_TIMEOUT_MS=600000`. No secrets go there; anyone using the environment can read them.

**What the setup script installs [V]:**
- **apt packages:**
  - `xvfb xauth libgl1 libgl1-mesa-dri libegl1 libglu1-mesa`, the virtual display and Mesa for rendered screenshots;
  - X11 libs `libxcursor1 libxinerama1 libxrandr2 libxi6 libxkbcommon0 libxkbcommon-x11-0`;
  - `libasound2t64 libpulse0 libfontconfig1 libfreetype6 libudev1`;
  - `fonts-dejavu-core fonts-noto-core`;
  - `openjdk-17-jdk-headless`, `imagemagick`, `unzip zip curl`.
- **Godot 4.7.2** from the GitHub release to `/opt/godot`, linked from `/usr/local/bin/godot`. This is the only fatal step; every other failure logs a warning.
- **Export templates** (about 1 GB) to `/opt/godot-data/godot/export_templates/4.7.2.stable`, with a symlink from `/root/.local/share/godot`.
- **gdtoolkit 4.5.0 and ruff 0.16.8**, installed with `pip --break-system-packages` and pinned to match CI (c704310b).
- **Android SDK:**
  - cmdline-tools 11076708, then `yes | sdkmanager --licenses`;
  - `platform-tools`, `build-tools;36.0.0`, `build-tools;36.1.0`, `platforms;android-36`.
- `chmod -R a+rwX /opt`.
- Godot editor settings (`editor_settings-4.7.tres`) with the Java and Android SDK paths.

**What the hook does [V]:**
- Exits unless `CLAUDE_CODE_REMOTE=true`.
- Writes `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, `JAVA_HOME` and `PATH` to `$CLAUDE_ENV_FILE`.
- Warns if `godot` is missing.
- Runs `timeout 500 godot --headless --import` when `.godot/imported` is absent.

**Network allowlist [V]:**
- Mode: Custom, with "Also include default list of common package managers" ticked.
- Domains at the start: `dl.google.com`, `maven.google.com`, `services.gradle.org`, `plugins.gradle.org`.
- Added later:
  - `docs.godotengine.org` on 10 October (b2af3302);
  - `codeberg.org` on 11 October, for GodotSteam (#61);
  - `uploads.github.com` on 18 October, for release assets.
- `github.com` and PyPI work through the agent proxy. `repo.maven.apache.org` returns HTTP 429.
- **Drift:** `CLOUD_SETUP.md` still lists only the first four domains.

**Other quirks of the cloud environment [V]:**
- It injects `JAVA_TOOL_OPTIONS` with the agent proxy (`https.proxyHost=127.0.0.1`), so Gradle goes through the proxy.
- A cloud Stop hook nags about untracked files and unpushed commits. Godot's `.import` files for PNGs under `docs/` set it off until `docs/.gdignore` was added.

## 2. Problems: symptom, cause, fix, and the Bramble action

### 2.1 Env vars from `.claude/settings.json` didn't reach the shell
- **Symptom [V]:** the `XDG_*` vars were unset in Bash and `java` was version 21 (#1, 10 October).
- **Fix [V]:** export everything through `$CLAUDE_ENV_FILE` in the SessionStart hook, with JDK 17 first on PATH (75ca523f).
- **Bramble:** do the same from day one, and check `java -version` and the XDG vars in the first session.

### 2.2 Android SDK versions
- **Symptom [V]:** the bootstrap installed build-tools 35.0.1 and platform 35.
- **Fix [V]:** platform 36 and build-tools 36.0.0 (75ca523f), plus 36.1.0 (b23b46df).
- **How the versions were found [V]:** the worker read them from `config.gradle` inside the templates' `android_source.zip`, because docs.godotengine.org was blocked. Godot 4.7.2 pins:
  - compileSdk and targetSdk 36, minSdk 24;
  - buildTools 36.1.0, NDK 29.0.14206865;
  - Java 17, Kotlin 2.1.21.
- **Bramble:** always derive these from the pinned Godot's own `config.gradle`.

### 2.3 Android export settings
- **Symptoms [V]:**
  - With a fresh XDG config, export failed: "A valid Java SDK path is required in Editor Settings."
  - A minimal preset failed: "Couldn't find the given section "preset.0" and key "include_filter"".
  - With no project icon, export logged an ERROR, which the strict log gates count as a failure.
- **Fix [V]:**
  - the setup script pre-writes editor settings;
  - presets carry their full key set;
  - `textures/vram_compression/import_etc2_astc=true` (required for Android);
  - an app icon is set.
- **Keystores [V]:** the bootstrap's custom debug keystore was dropped. Godot creates its own at `$XDG_DATA_HOME/godot/keystores/debug.keystore`. Release signing goes only through `GODOT_ANDROID_KEYSTORE_RELEASE_*` env vars.

### 2.4 Gradle and AAB never worked in the cloud
- **Symptom [V]:** the build got past configuration, then failed downloading from Maven Central: "Could not download jopt-simple-4.9.jar", HTTP 429. It failed twice (#1, #36), and #11 is still open.
- **Workaround [V]:** an `Android APK` preset with `use_gradle_build=false` works in cloud and CI. The `Android AAB` preset is "workstation only".
- NDK 29 was never installed: it is over 1 GB and would slow the snapshot.
- Gradle builds are needed only for Android plugins and AABs. The Play Store requires AABs.
- **Bramble [I]:** prove a Gradle debug export in a fresh session as toolchain issue #1. Options:
  - pre-warm `~/.gradle` in the setup snapshot, within the time budget;
  - use a Maven mirror;
  - build AABs in GitHub Actions, whose runner image ships the SDK and JDK 17 [V].

### 2.5 Setup-script caching
- **[V]** The snapshot is reused only when the script finishes in about 5 minutes. Changing the script invalidates the cache, and every change needs a manual re-paste into the UI.
- **[V]** The documented fallback for an overrun: move the Android SDK install to a background step in the hook.
- **Bramble [I]:**
  - keep the pasted script thin, or have it print a version or hash that the hook compares with the repo copy;
  - log its duration.

### 2.6 Version pinning
- **[V]** Godot stayed on 4.7.2 for the whole project, so there is no upgrade experience to learn from.
- **[V]** The pin is copied in about 8 places:
  - `cloud-setup.sh` and its pasted copy;
  - `GODOT_VERSION` in `settings.json`;
  - `config/features` in `project.godot`;
  - `ci.yml` (the version plus 3 SHA-512s) and `balance-nightly.yml`;
  - decision 1 and `build.md`;
  - the WSL path `~/godot472`.
- **[V]** GUT 9.7.1 matches Godot 4.7.x.
- **[V]** CI checks the Godot and template SHA-512s, but `cloud-setup.sh` checks nothing.
- **Bramble:** one versions-and-hashes file that every script reads, a test that every copy agrees (the way Autobattler's `tests/tools/test_build_version.gd` checks app versions), and an upgrade runbook.

### 2.7 Import and the class cache
- **Fresh clones [V]:**
  - `.godot/` is gitignored, so the hook imports.
  - `--import` does not compile scripts, so `check.sh` has a separate compile step (`tools/checks/compile_all.gd`).
  - The screenshot tool uses preloads instead of `class_name`, so it works before the cache exists. Without the cache it used to hang and time out (exit 124).
- **Stale cache after merges [V]:** after a merge the first import logged SCRIPT ERRORs (151 in #324, 6 in #360); a second import was clean. The fix is in WORKER.md step 5 (0cb8dde4): merge `origin/main`, re-import, then run `check.sh` on that merged head.
- **Exit leaks [V]:**
  - The first export after a fresh import logged "25 ObjectDB instances were leaked / 16 resources still in use at exit", which failed `export_smoke`. It was fixed with dependency injection (decision 50).
  - GUT runs ended with 5–6k leaked instances until #405. The causes were a lambda capturing `self`, an unreleased state and an unfreed popover.
- **Bramble [I]:** import in the hook, re-import after merges, keep a compile step, and keep the strict log gates with a documented allowlist of known engine noise.

### 2.8 Headless rendering and screenshots
- **The command that works [V]:** `xvfb-run -a godot --rendering-driver opengl3 --resolution WxH`, with the gl_compatibility renderer on Mesa llvmpipe (OpenGL 4.5 Compatibility).
- **Noise [V]:** `--audio-driver Dummy` removes the ALSA noise. "Could not set V-Sync mode" is harmless and allowlisted.
- **Window size [V]:** `--resolution` is ignored while `window_*_override` is set, so the screenshot tool sets the window size in code.
- **Screenshot tool rules [V]:**
  - It refuses `--headless`.
  - A Logger subclass counts errors, and any error fails the capture. At first it reported success even when the scene's script failed.
  - `screenshots.sh` asserts exact exit codes, so a hang (124) can't pass.
- **Hangs [V]:** `godot --headless --doctool` hung for more than 300 s. Query ClassDB from a script instead.
- **Frame timing [V]:**
  - headless runs measure CPU only;
  - Godot sleeps 6.9 ms per headless frame, and removing that broke frame-counting tests;
  - the first particle shader compile caused a hitch.
- **Repo size [V]:** screenshots were committed at native size, because downscaled ones had cost review rounds. `docs/screens` is 577 MB and `.git` is 943 MB.
- **Bramble [I]:** store screenshots outside git.

### 2.9 GUT: hangs, silent passes, timeouts
- **Silent passes and hangs [V]** (decision 13):
  - GUT hangs if `post_run_script` is missing, so `check.sh` checks for the hook file first.
  - GUT skips scripts that fail to parse and still exits 0, so `check.sh` greps for `SCRIPT ERROR|Parse Error|handle_crash`.
  - A strict hook fails on risky, pending and zero-assert tests, backed by a `[Risky]` grep.
- **One parse error, many failures [V]:** a warning treated as an error (`lerpf()` on a Variant from `Dictionary.get`) broke a whole script, and every test in it reported "Nonexistent function 'new' in base 'GDScript'". Check the one file with `godot --headless --check-only -s <file>`.
- **Timeout [V]** (#405, 18 October):
  - One GUT process took 480–730 s on the 4-CPU VM (549 s for 385 scripts and 3,489 tests), against the 600 s `GODOT_TIMEOUT`. Workers had been passing `GODOT_TIMEOUT=1500` by hand.
  - The whole gate took about 10 minutes, past the 600 s Bash maximum, so workers ran it in the background and waited.
- **Fix [V]** (PR #424):
  - `tools/checks/gut_shards.py` splits the scripts over up to 4 parallel processes, balanced on the last run's JUnit times;
  - each shard has its own `GUT_TIMEOUT` of 600 s (1500 s as a single shard), so a hang fails inside CI's 30-minute job;
  - the test step went to 133–194 s, and the whole gate to 4–6.5 minutes.
- **What sharding exposed [V]:** suites that shared `user://` paths. New rules: each suite owns its paths, and no test checks mid-tween state after a wall-clock wait.
- **Bramble:** shard early, isolate suites, and keep the strict hook.

### 2.10 Perf gates
- **[V]** One run on the shared VM can swing about 2×: "budget miss menu_idle process_p99 2.73 > 2.00".
- **Fix [V]:** warn by default; strict mode takes the median of 3 runs (decisions 193 and 247). No wall-clock gates under xvfb. Always use `--fixed-fps 60` for frame timing.

### 2.11 Exports from a Linux host
- **[V]** Linux, Windows, macOS (universal `.zip`) and Android APK all export. iOS produces only an Xcode project ("Xcode Build: .ipa can only be built on macOS") and needs a Team ID.
- **Windows [V]:**
  - `application/modify_resources=true` writes ProductName and FileVersion with no rcedit or wine, and the version was verified.
  - `product_name` must repeat the project name.
  - Code signing was off. Godot has no command-line override for preset options, so signing means a `sed` on the preset plus `GODOT_WINDOWS_CODESIGN_*` and `osslsigncode`. Without signing, SmartScreen warns players.
  - The exe is about 104 MiB; #223 (custom 2D template) is open.
- **macOS [V]:** ad-hoc signed, so Gatekeeper blocks it on other Macs.
- **The smoke test caught [V]:**
  - export filters that excluded `content/schemas`, which the game needs at runtime;
  - the `en_XA` pseudo-locale, which made exported builds log an error at startup.
  It now checks pack contents and boots the Linux build headless to the main scene.
- **App ID [V]:** it is immutable after the first store upload. The placeholder `com.switchoce.curiospire` was flagged as needing the owner.
- **Desktop GDExtensions [V]** (GodotSteam) must be excluded from mobile presets. The smoke test checks `extension_list.cfg`.

### 2.12 GitHub Actions minutes and storage
- **Artifact quota [V]:** the first run failed with "Failed to CreateArtifact: Artifact storage quota has been hit." After that every upload was `continue-on-error`, with 2–7 day retention.
- **Minutes [V]:**
  - 177 real runs from 10 October 10:24Z to 23:08Z: 99 on PRs and 78 on pushes to main, about 637 wall-minutes over 2 parallel jobs;
  - from 23:22Z every job said "The job was not started because an Actions budget is preventing further use";
  - 405 instantly-failed runs followed through 18 October, and the budget was never raised.
- **Mitigations [V]:**
  - `paths-ignore` for docs and `*.md` (90301a6f);
  - PR concurrency cancel;
  - the nightly balance job (about 50 minutes) taken off its schedule;
  - the merge gate became the worker's `check.sh` on a head that includes main.
- **Fallout [V]:**
  - workers spent turns diagnosing red checks;
  - a stale-head merge broke main for about 30 minutes on 17 October;
  - the macOS runner never ran: the iOS job was gated on unset `IOS_ENABLED` and `APPLE_TEAM_ID`.
- **Bramble [I]:**
  - settle the budget, or make the repo public, before turning CI on;
  - one job, PR-triggered, with path filters;
  - exports only on a label, nightly or on a tag;
  - disable the workflow when the budget is out, rather than leaving permanent red Xs.

### 2.13 GitHub from cloud workers
- **[V]** `gh pr`, `gh issue` and `gh run` fail: "HTTP 403: GitHub GraphQL is not available from Claude Code sessions; use the REST API". Use `gh api` and leave `GH_TOKEN` alone.
- **[V]** A label DELETE returns 404 when the label is absent; that is harmless.
- **[V]** Actions job logs live on `*.blob.core.windows.net`, which the VM can't reach. Read the job steps and check-run annotations through the API instead.
- **[V]** The cloud orchestrator merged through the GitHub MCP tool, because the classifier refused the `gh api` merge call.
- **[V]** `unsubscribe_pr_activity` wants the repo name alone: "SwitchOCE/Autobattler" became "switchoce/switchoce/autobattler".

### 2.14 The auto-mode classifier and permission checks
- **Release export [V]:** `export_release.sh` was refused as "[Production Deploy]" three times (#414), even after the owner's approval was relayed. The worker rightly refused to add its own allow rule on a relayed message.
- **Why it can't be fixed per repo [V]:** RemoteTrigger silently drops `auto_mode_allow`, and the repo's `.claude/settings.json` is ignored for `autoMode`. Allow rules reach cloud sessions only through server-managed settings, which need a Team or Enterprise owner.
- **Locally [V]:** `gh pr merge` and `gh pr review` were blocked ("Merge Without Review", "Self-Approval") until the owner added allow rules to `.claude/settings.local.json`.
- **Other blocks [V]:**
  - "[Exfil Scouting]" on a `curl` to the agent proxy's status page;
  - `rm` safety checks on `cd X && rm -f build/*` (use absolute paths) and on `/root.png`;
  - `sleep 240` (use Monitor with an until-loop, or `run_in_background`).
- **Bramble:** run releases from a tag- or dispatch-triggered Actions workflow, or from a local session the owner starts, and set the local allow rules first.

### 2.15 Releases shipped without an APK
- **[V]** v0.8.0 and v0.8.1 had no APK. The local WSL had no SDK or JDK, accepting the SDK licence was the owner's call, and the cloud could not run the release step.

### 2.16 Local Windows and WSL
- **Setup [V]:** no Godot on Windows. In WSL: `~/godot472/godot` (SHA verified), gdtoolkit and ruff in `~/.local`, run with `GODOT=~/godot472/godot`.
- **Incident [V]:** two parallel WSL check runs stole focus and froze the PC on 11 October.
- **Rules after that [V]:**
  - give the owner notice first;
  - one run at a time;
  - `--headless` for tests and `xvfb-run` for screenshots, never WSLg windows;
  - `flock /tmp/curio-heavy.lock nice -n 19` for heavy steps;
  - work in a scratch clone.
  The owner later paused all local execution.
- **Local screenshots [V]:** taken with `override.cfg` plus Movie Maker `--write-movie`, because the agent had no window access.

### 2.17 Line endings, file modes, binaries
- **[V]** `.gitattributes`:
  - `* text=auto eol=lf` and `*.sh eol=lf`;
  - images, audio, fonts, `.tpz` and `.keystore` are binary;
  - `.so`, `.dll` and `.dylib` were added after GodotSteam had already been committed under `text=auto` (109ba6b5).
- **[V]** The exec bit had to be fixed after bootstrapping from Windows (9409292f). No CRLF incident was recorded.
- **Bramble:** add these in the first commit and set exec bits with `git update-index --chmod=+x`.

### 2.18 Missing tools in the cloud image
- **[V]** `shellcheck` and Python `PIL` were not installed. Workers read PNG headers with `struct` instead.
- **[I]** Add `shellcheck`, and `pillow` if any tool needs images, to the setup script.

### 2.19 Addons
- **[V]** GodotSteam came from codeberg.org, which was blocked and then allowlisted. Version 4.23.1 is vendored with per-file SHA-256s, because upstream publishes no checksums.
- **[V]** Tests that assumed the addon was absent broke once it was vendored.

## 3. Final CI design [V] (`ci.yml`)

- **Triggers:** PRs and pushes to main (both with `paths-ignore`), plus manual dispatch. PR runs cancel on a new push.
- **Job `check`:**
  - Python 3.11, pinned gdtoolkit and ruff, apt Xvfb and Mesa;
  - Godot SHA-512 checked and cached with split `cache/restore` and `cache/save`, so a failed run still caches it;
  - runs `check.sh`, then `screenshots.sh`.
- **Job `exports`:**
  - installs only the 4 debug templates it uses (about 290 MB, not 1.3 GB), SHA-checked by `install_export_templates.sh`;
  - uses the runner's Android SDK and `JAVA_HOME_17_X64`;
  - runs `export_smoke.sh`.
- **Job `ios`:** gated; it never ran.
- **`check.sh` steps:** tools, import, format, lint, python, layers, rules, compile, tests, bots, balance, perf. Any `ERROR|WARNING|SCRIPT ERROR|Parse Error|handle_crash` line in a step's log fails that step.
- Actions are pinned by major tag. A Node 20 deprecation warning was noted in #4.
