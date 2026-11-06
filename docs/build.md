# Cloud toolchain proof

The first proof session. Its brief is in the history of [CLOUD_SETUP.md](CLOUD_SETUP.md) at `8cde7ad`, section 2; item numbers follow that brief. It ran on 6 November 2026 in the `Bramble Cloud` environment, on branch `claude/inspiring-faraday-x45a8n`, which was cut from `build/toolchain` at `8cde7ad`.

**In short:** the tools work in the cloud when the hook is run by hand. Four toolchain problems turned up and are fixed: a false JDK warning, an unpinned ruff shadowing the pinned one, the AAB's HTTP 429s from Maven Central (fixed with a mirror), and setup times that were lost.

**Not shown by this session:** the hook firing as a real SessionStart hook, snapshot reuse, and the changed setup script. Screenshot storage through releases is refused by the session's GitHub gateway. The short proof in [CLOUD_SETUP.md](CLOUD_SETUP.md), section 2, covers what's left.

**Limits of these results:** Windows and Android builds were built and inspected, not launched, and all are debug builds. No single AAB run combined the mirror, an empty Gradle cache and a fresh template, and each variant ran once. The gate timings are for 2 tests.

## Results

| # | Item | Result |
|---|---|---|
| 1 | Setup | 133 s; ran live, no cached snapshot. Section times were not visible (fixed for next time). |
| 2 | Startup hook | Works when run by hand; not yet fired as a real hook. One false WARNING (JDK), fixed. |
| 3 | `godot -s` exit codes | Pass: 42 in, 42 out. |
| 4 | Rendering | Pass: 1280×720 PNG, 226 distinct colours. |
| 5 | `check.sh` + 5 breakages | Failed at first (ruff 0.16.9 shadowed the pin), fixed; passes in about 11 s. All 5 breakages fail it. |
| 6 | `export_smoke.sh --aab` | Linux, Windows and APK pass. AAB: (a) plain fails with HTTP 429; (b) the Maven mirror passes. (c) was not needed. |
| 7 | GitHub `gh api` | Every call works. `gh pr` and `gh issue` fail with 403 as expected. |
| 8 | Screenshot storage | **Blocked**: creating a release gives HTTP 403 from the session gateway. Not fixable in the repo. |

Commands below assume the toolchain variables are loaded. The hook writes them to `$CLAUDE_ENV_FILE`; see item 2 for why this session loaded them by hand.

## 1. Setup

- **Section times:** not visible. The cloud does not show the setup script's output to the session: `/tmp/env-manager.log` only records `Successfully executed init script`, and nothing else on disk has the `[cloud-setup]` lines.
- **Total:** `cat /opt/bramble/setup.env` → `SETUP_SECONDS=133`. The environment manager's log agrees: init started at 05:00:30 and ended at 05:02:45 UTC (`Environment initialization completed (parallel) {"duration_ms": 135528}`, which includes a 2.6 s clone).
- **Cached snapshot: no.** The VM booted at 04:58:36 (`uptime -s`), and `setup.env` was written at 05:02:45, after boot, at the moment the init script finished. So the script ran in full this session. At 133 s it is well under the roughly 300 s limit, so later sessions should start from a snapshot. This session can't confirm that.
- The local container estimate was 379 s; the cloud's network makes it about 2.8 times faster.
- `setup.env` has `SETUP_SCRIPT_SHA256=42cf8ce6…`, which is not the hash of the repo's `scripts/cloud-setup.sh` (`41de8190…`). The cause: the environment UI drops the file's final newline. With that newline removed, the repo file hashes to `42cf8ce6…` exactly, so the pasted script was current.

**Fixed:**
- `cloud-setup.sh` now tees its output to `/opt/bramble/setup.log`, so the next session can read the section times.
- The startup hook now compares `SETUP_SCRIPT_SHA256` with the repo copy, ignoring the final newline. When they differ it prints `WARNING: the environment's setup script differs from scripts/cloud-setup.sh: re-paste it …`. This session tested it both ways: silent for the pasted version, warning for the edited one.

## 2. Startup hook

- **The hook did not run on its own this session.** The session cloned `main`, which has no `.claude/settings.json` (the toolchain is only on `build/toolchain`). So I ran it by hand: `CLAUDE_ENV_FILE=<file> bash scripts/session-start.sh` took about 10 s, including the first import. Its first run as a real SessionStart hook is still unproved. Start the next session on a branch that has the toolchain.
- **WARNING lines** before the fix:
  `WARNING: JDK 17 not found at /usr/lib/jvm/java-17-openjdk-amd64 (got: Picked up JAVA_TOOL_OPTIONS: -Djavax.net.ssl.trustStore=… -Dhttps.proxyHost=127.0.0.1 …)`
  - This was a false alarm. The cloud sets `JAVA_TOOL_OPTIONS` for its proxy, and Java prints a "Picked up" line before the version line, so the hook's `head -n1` read the wrong line.
  - **Fixed:** the hook now matches the line that contains ` version `.
- **Second problem:** the hook didn't warn about ruff, but `check.sh` caught it (item 5).
- After the fixes, the hook prints only `Godot: 4.7.2.stable.official.ed1daf0bf`. The re-paste warning now appears too, because `cloud-setup.sh` changed.
- `echo $XDG_DATA_HOME $JAVA_HOME $ANDROID_HOME` → `/opt/godot-data /usr/lib/jvm/java-17-openjdk-amd64 /opt/android-sdk`
  - Before the hook's variables load, the cloud's own `JAVA_HOME` is JDK 21: `/usr/lib/jvm/java-21-openjdk-amd64`.
- `java -version` → `openjdk version "17.0.20.1" 2026-08-18`, after the "Picked up JAVA_TOOL_OPTIONS" line.
- `godot --version` → `4.7.2.stable.official.ed1daf0bf`

## 3. `godot -s` exit codes

Ran `godot --headless -s quit42.gd`, where the script is `extends SceneTree` with `func _initialize() -> void: quit(42)`.
- **Result:** pass. `quit42 exit=42`.

## 4. Rendering

Ran `xvfb-run -a godot --rendering-driver opengl3 --audio-driver Dummy --write-movie /tmp/shot.png --quit-after 3`.
- **Result:** pass. Exit 0 after 3.6 s.
- **The output name differs from the brief:** `--write-movie` numbers its frames, so it wrote `/tmp/shot00000000.png` to `/tmp/shot00000002.png`, not `/tmp/shot.png`.
- **Renderer:** `OpenGL API 4.5 (Core Profile) Mesa 25.2.8 … llvmpipe`.
- **Pixel check:** decoded with python3's `zlib` and `struct` (no PIL needed). Result: `(1280, 720, 226)` distinct colours. That's the green background plus the anti-aliased "Bramble" title.
- **One log line:** `WARNING: Could not set V-Sync mode …`. It is harmless under xvfb, and this command isn't gated.

## 5. `./scripts/check.sh`

**First run** → `'ruff 0.16.9', pinned ruff 0.16.8` / `FAIL tools`.
- The cloud base image ships its own Python tools through uv in `/root/.local/bin`: ruff 0.16.9, black, mypy, pytest and others. That directory comes before `/usr/local/bin` on PATH, where the setup script's pinned pip install lives.
- **Fixed in the hook:** it now puts pip's script directory (`sysconfig` "scripts", here `/usr/local/bin`) first on PATH; `check.sh` still fails on a version mismatch. No re-paste was needed for this fix.

**After the fix** → `check.sh: all steps passed` in 10.7 s (import 6 s, tests 2 s).

**Breakages:** each one was applied alone, then `./scripts/check.sh --keep-going` was run and the change reverted. 49 s for all five.

| Breakage | Result | Failing steps | Decisive line |
|---|---|---|---|
| `main.tscn` points at `res://src/main/missing.gd` | exit 1 | import, compile, tests | `ERROR: Attempt to open script 'res://src/main/missing.gd' resulted in error 'File not found'.` |
| `var x = 1` in a new `src/break/untyped.gd` | exit 1 | compile | `SCRIPT ERROR: Parse Error: Variable "x" has no static type. (Warning treated as error.)` |
| Test with no asserts (`func test_nothing() -> void: pass`) | exit 1 | tests | `gut_strict: no asserts: res://tests/break/test_no_asserts.gd.test_nothing` |
| Test with a parse error (unclosed `assert_true(true`) | exit 1 | format, lint, compile, tests | `SCRIPT ERROR: Parse Error: Expected closing ")" after call arguments.` |
| `GODOT_VERSION=4.7.3` in `tools/versions.env` | exit 1 | tools, versions | `godot is '4.7.2.stable.official.ed1daf0bf', pinned 4.7.3` and `versions: scripts/cloud-setup.sh: the block between its markers differs from tools/versions.env …` |

## 6. `./scripts/export_smoke.sh --aab`

**Linux, Windows and APK pass in every run:**
- `boot ok: linux reached the main scene and exited 0`
- `resources ok: build/export-smoke/windows/bramble.exe has ProductName 'Bramble'`
- `contents ok: android-apk (12 files)`, 56 MB

**AAB through Gradle:**

**(a) Plain: fails.** `export exit 1 in 173s`, with `~/.gradle` at 734 MB when it stopped.
- Both Gradle passes (the template install and the export) died on Maven Central rate limits. The template pass hit 2 × 429 and the export hit more:
  `Could not GET 'https://repo.maven.apache.org/maven2/org/glassfish/jaxb/jaxb-runtime/2.3.2/jaxb-runtime-2.3.2.jar'. Received status code 429 from server: Too Many Requests`
  `Could not GET 'https://repo.maven.apache.org/maven2/org/jetbrains/kotlin/kotlin-stdlib/2.1.21/kotlin-stdlib-2.1.21.pom'. Received status code 429 from server: Too Many Requests`
- This matches Autobattler 2.4.
- A single `curl` of the same jar returns 200, so this is a burst rate limit on the proxy's shared egress, not a block.
- `plugins.gradle.org/m2` answers 303, redirecting to `repo.maven.apache.org`, so the redirect also ends at Maven Central.
- `central.sonatype.com` (snapshots) answers 403. It only serves snapshot versions, which this build doesn't use.

**(b) Gradle init script with a Maven Central mirror: passes.**
- **Setup:** an empty `GRADLE_USER_HOME` whose `init.d/` held only `scripts/gradle/maven-mirror.init.gradle`, so (a)'s partial cache couldn't help.
- **Result:** `exported 'Android AAB' -> build/export-smoke/android-aab/bramble.aab`, 56 MB, and `export_smoke: all checks passed`. Exit 0 in 138 s, a 1.2 GB Gradle cache, 0 × 429.
- **Mirror choice:** Google's mirror of Maven Central on Cloud Storage, `https://maven-central.storage-download.googleapis.com/maven2/`. It is reachable through the proxy with no allowlist change (0.14 s for the 1 MB test jar). `repo1.maven.org` and the EU/Asia Google mirrors also answered 200.
- **How the init script works:** it points any repository at `repo.maven.apache.org` or `repo1.maven.org` at the mirror, and puts the mirror first in every repository list (settings, buildscript, project). Rewriting URLs alone wouldn't catch the plugin portal's redirects.
- **Confidence: moderate to high.** Each variant ran once, and a rate limit can vary over time. But (b) fetched more (1.2 GB) than (a) reached (734 MB) with no 429 at all.
- In (b), (a) had already installed the build template, so only the strict export ran Gradle. The end-to-end run below covers the fresh template.

**(c) Warmed Gradle cache in setup: not attempted.** (b) worked, and the brief says to stop at the first that works. The owner chose the mirror alone on 6 November. For the record: the cache is 1.2 GB and takes about 2 minutes to fill, so warming it in setup would take the script from about 133 s to roughly 250–300 s, close to the snapshot limit. That's an estimate.

**Now in the toolchain:**
- `scripts/gradle/maven-mirror.init.gradle`, which the startup hook copies to `~/.gradle/init.d/` in cloud sessions only. Local and CI builds are unchanged.
- `export_smoke.sh` used to report a Gradle failure in the template-install pass as `FAIL could not install the Android build template`, though the template had installed. It now notes that and lets the strict export report the real error. It also prints Gradle's own `Could not GET … Received status code …` lines, which carry no `ERROR` prefix.

**End to end, the way a session will run it, passes:**
- **Setup:** the hook installed the mirror into `~/.gradle/init.d/bramble-maven-mirror.gradle`, and `android/` was moved aside so the template install pass ran again.
- **Result:** `./scripts/export_smoke.sh --aab` → `export_smoke: all checks passed`, exit 0 in 149 s, 0 × 429 in both Gradle logs.
- **Caveat:** this `~/.gradle` still held (a)'s partial 734 MB cache.

## 7. GitHub from the session

All through `gh api` (REST). The test used this session's PR, [SwitchOCE/Bramble#7](https://github.com/SwitchOCE/Bramble/pull/7), through the issues endpoints, which serve PRs too. That avoided a throwaway issue.

| Call | Command | Result |
|---|---|---|
| Read an issue | `gh api repos/SwitchOCE/Bramble/issues/7` | `#7 open Cloud toolchain proof: findings and fixes labels=[]` |
| Comment | `gh api -X POST repos/SwitchOCE/Bramble/issues/7/comments -f body=…` | `comment 6677465406 …/pull/7#issuecomment-6677465406` |
| Add a label | `gh api -X POST repos/SwitchOCE/Bramble/issues/7/labels -f 'labels[]=documentation'` | `["documentation"]` |
| Remove a label | `gh api -X DELETE repos/SwitchOCE/Bramble/issues/7/labels/documentation` | `[]` |
| Open a PR | `gh api -X POST repos/SwitchOCE/Bramble/pulls --input pr.json` (title, head, base `build/toolchain`, `draft: true`) | `PR #7 https://github.com/SwitchOCE/Bramble/pull/7 draft=true` |
| Read check runs | `gh api repos/SwitchOCE/Bramble/commits/<sha>/check-runs` | `total=2 exports:completed/skipped, check:in_progress/null`, later `check:completed/success` |
| `gh pr list`, `gh issue view 6` | — | `HTTP 403: GitHub GraphQL is not available from Claude Code sessions; use the REST API …`, as expected (2.13) |

Also:
- `gh auth status` reports `The token in GH_TOKEN is invalid`, but every `gh api` call works, because the proxy supplies the credentials.
- The repository reports `admin`, `push` and `triage` permissions for the session.

## 8. Screenshot storage

- **Lookup:** `gh api repos/SwitchOCE/Bramble/releases/tags/screens` → 404. There are no releases yet.
- **Create:** `gh api -X POST repos/SwitchOCE/Bramble/releases -f tag_name=screens -f target_commitish=main -f name=screens -F prerelease=true …` → **`Creating, editing, or deleting releases is not permitted for this session type.` (HTTP 403)**
- That refusal comes from the session's GitHub gateway, not from GitHub or from the repository's permissions. Nothing in the toolchain files can change it.
- `uploads.github.com` itself is reachable: `curl https://uploads.github.com/` reached GitHub with HTTP 400. But with no release to attach to, the asset upload, the rendering in a PR comment and the deletion are all **untested**.
- **Open question:** whether the gateway also refuses asset uploads to a release that someone else created. Its wording ("creating, editing, or deleting releases") suggests it might.

**Options considered.** The owner chose an orphan `screens` branch on 6 November ([CLOUD_SETUP.md](CLOUD_SETUP.md), Screenshots).
1. **The owner creates the `screens` pre-release once by hand** (GitHub → Releases → Draft a new release, tag `screens`, tick "Set as a pre-release"). A later session then tests only the upload and delete. It may still be refused.
2. **CI uploads screenshots.** A workflow job with `contents: write` renders the scene under xvfb, uploads to the release, and comments on the PR with the URL. This moves the release write out of the session. It needs a workflow change and its own proof.
3. **Commit screenshots to a dedicated branch** (say `screens`) and link `raw.githubusercontent.com` URLs. It needs no release permissions, but pushing it from a session wasn't tried here, and every screenshot stays in the repository's history until the branch is reset.

## Not fixed

- **Screenshot storage through releases** (item 8). Session policy; see the options above.
- **The hook as a real SessionStart hook.** It isn't proved, because this session started on `main`, which has no hook. Proved by hand only.
- **Snapshot reuse.** Can't be seen from the session that ran the setup. The next session on this environment should check that `/opt/bramble/setup.env` is older than its boot time (`uptime -s`).
- **Re-paste needed:** `scripts/cloud-setup.sh` changed (the setup log). Until it is pasted again, the hook warns that the setup script differs, and `/opt/bramble/setup.log` won't exist.

## Short proof: session A

The brief is in [CLOUD_SETUP.md](CLOUD_SETUP.md), section 2, "Short proof, once the toolchain is on `main`"; item numbers follow it. It ran on 6 November 2026 in the `Bramble Cloud` environment, on branch `claude/ecstatic-bell-122yef`, cut from `main` at `6d87af5`, before the owner re-pasted the current setup script. `scripts/session-start.sh` was not run by hand.

**In short:** the hook fires as a real SessionStart hook and its warning reaches the agent. Its variables load, `check.sh` passes and its `tests` step fails on an empty test folder. Pushing a new `screens` branch, opening and merging a PR, and reading CI job logs all work through the session. **Deleting a branch does not:** both `git push --delete` and the REST ref delete are refused with HTTP 403, so the three throwaway branches are still on GitHub for the owner to delete.

| # | Item | Result |
|---|---|---|
| 1 | Hook | Pass. Fired on its own; `Godot:` line and the expected re-paste `WARNING` both visible. |
| 2 | Variables | Pass. Pinned paths, ruff 0.16.8, JDK 17, Maven mirror installed. |
| 3 | `check.sh` + empty test folder | Pass in 10 s; the empty folder fails `tests` with `[GUT ERROR]:  Nothing was run.` |
| 4 | Screenshot push | Push and raw URL work. **Deleting `screens` is refused** (HTTP 403). |
| 5 | Merging through `gh api` | Open and merge work. **Deleting both branches is refused** (HTTP 403). |
| 6 | CI logs | Pass. Job steps and the full job log both read. |

### 1. Hook

What the session context shows from the SessionStart hook, verbatim:

```
SessionStart:startup hook success: WARNING: the environment's setup script differs from scripts/cloud-setup.sh: re-paste it into the environment (docs/CLOUD_SETUP.md)
Godot: 4.7.2.stable.official.ed1daf0bf
Importing the project (first run in this VM)...
```

- **Result:** pass. This is the first time the hook has fired as a real SessionStart hook, and its output reached the agent.
- The re-paste warning is the expected one: the environment still runs the setup script from before `setup.log` was added.
- No other `WARNING` line.

### 2. Variables

| Command | Result |
|---|---|
| `echo $XDG_DATA_HOME $JAVA_HOME $ANDROID_HOME` | `/opt/godot-data /usr/lib/jvm/java-17-openjdk-amd64 /opt/android-sdk` |
| `command -v ruff` | `/usr/local/bin/ruff` (the pinned pip install, not the image's `~/.local/bin`) |
| `ruff --version` | `ruff 0.16.8` |
| `java -version` | `openjdk version "17.0.20.1" 2026-08-18`, after the usual `Picked up JAVA_TOOL_OPTIONS` line |
| `ls ~/.gradle/init.d` | `bramble-maven-mirror.gradle` |

- **Result:** pass. Every value comes from the hook's `$CLAUDE_ENV_FILE`, so the hook's variables load into the agent's shell without a manual step.

### 3. `./scripts/check.sh`

- `./scripts/check.sh` → exit 0 in 10.3 s: `check.sh: all steps passed`.
- **Break:** `dirs` in `.gutconfig.json` set to `["res://empty_tests"]`, an empty folder, then `./scripts/check.sh --keep-going` → exit 1, `failed: tests`.
  - Decisive line: `[GUT ERROR]:  Nothing was run.`
  - Every other step still passed: `passed: tools versions shell python format lint import compile`.
- **Restored:** `.gutconfig.json` copied back and `empty_tests/` removed; `git status` was clean.

### 4. Screenshot push

- **Render:** `xvfb-run -a godot --rendering-driver opengl3 --audio-driver Dummy --write-movie /tmp/shot.png --quit-after 3` → exit 0, wrote `/tmp/shot00000000.png` to `/tmp/shot00000002.png` (10,225 bytes each). The only log noise was the known `WARNING: Could not set V-Sync mode …`.
- **Push:** an orphan commit holding only `shot00000002.png`, built with `git hash-object`, `git mktree` and `git commit-tree`, then `git push origin <sha>:refs/heads/screens` → `* [new branch] c73c2f9… -> screens`.
  - Git also printed `warning: push negotiation failed; proceeding anyway with push`. That is harmless noise from the session's git gateway; every push in this session printed it.
- **Raw URL:** `curl https://raw.githubusercontent.com/SwitchOCE/Bramble/screens/shot00000002.png` → `200 image/png 10225`, byte-identical to the local file.
- **PR comment:** see below.
- **Delete:** see below.

### 5. Merging through `gh api`

- **Branches:** `git push origin <main sha>:refs/heads/claude/merge-test-base <head sha>:refs/heads/claude/merge-test-head` → both `* [new branch]`. The head is `859c55a`, one empty commit on `main` at `6d87af5`.
- **Open:** `gh api -X POST repos/SwitchOCE/Bramble/pulls -f head=claude/merge-test-head -f base=claude/merge-test-base …` → `PR #8 https://github.com/SwitchOCE/Bramble/pull/8 base=claude/merge-test-base`.
- **Merge:** `gh api -X PUT repos/SwitchOCE/Bramble/pulls/8/merge -f merge_method=merge` → `{"sha":"46edbab…","merged":true,"message":"Pull Request successfully merged"}`.
- `main` was unchanged before and after: `6d87af5`.
- **Delete: refused.**
  - `git push origin --delete claude/merge-test-base claude/merge-test-head` → `error: RPC failed; HTTP 403 curl 22 The requested URL returned error: 403`. Git's trace shows the 403 comes on the `git-receive-pack` POST, after the ref advertisement succeeded.
  - `gh api -X DELETE repos/SwitchOCE/Bramble/git/refs/heads/claude/merge-test-head` → `Write access to this GitHub API path is not permitted through this proxy. (HTTP 403)`.
  - Both refusals come from the session's GitHub gateway, not from GitHub: the session has `admin` permission on the repository (item 7 above). I stopped after one try of each route.
  - **Both branches are still on GitHub.** The owner deletes them by hand.

### 6. CI logs

- **Job steps:** `gh api repos/SwitchOCE/Bramble/actions/runs/42210500968/jobs` (the latest CI run, on `build/toolchain`) → two jobs, `check 127867673429 completed/success` and `exports 127867673247 completed/success`, with every step and its conclusion (for example `10 check.sh: success`).
- **Job log:** `gh api repos/SwitchOCE/Bramble/actions/jobs/127867673429/logs` → exit 0, 396 lines, including `check.sh: all steps passed`.
- **Result:** pass.

### What this means

- **The `screens` design needs a change.** A session can create and push the branch but cannot delete it or any other branch. A session can probably still update `screens` with a normal fast-forward push; that was not tested here. The planned scheduled Action that resets the branch runs with its own token, so it is unaffected.
- **Merging from a session works.** The gateway refuses neither the PR nor the merge, so a session could merge into `main` too. Nothing in the gateway stops that; only the working rule in `CLAUDE.md` does.
- **Throwaway branches pile up.** Any brief that has a session create and then delete a branch needs the owner to delete it instead.
- **Not shown by this session:** snapshot reuse and the current setup script (sessions B and C).
