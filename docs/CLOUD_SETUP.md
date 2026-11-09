# Cloud environment and toolchain

How Bramble's Godot toolchain is set up: locally, in Claude Code cloud sessions and in GitHub Actions. Built from the Autobattler lessons in [research/autobattler/toolchain.md](research/autobattler/toolchain.md); section numbers like "2.7" below point there.

Every version and checksum lives in [`tools/versions.env`](../tools/versions.env). Nothing else spells them out, and `scripts/check.sh` fails when a copy drifts (2.6).

## The files

| File | What it does |
|---|---|
| `tools/versions.env` | The pins: Godot and its SHA-512s, export templates, GUT, gdtoolkit, ruff, JDK, Android SDK parts. |
| `scripts/cloud-setup.sh` | The cloud environment's setup script. **You paste it into the environment UI.** It carries a verbatim copy of `tools/versions.env`. |
| `scripts/session-start.sh` + `.claude/settings.json` | SessionStart hook in cloud sessions: exports the toolchain variables (pinned tools first on PATH), warns when the pasted setup script differs from the repo or a tool is missing, installs the Gradle Maven mirror, imports the project once. |
| `scripts/gradle/maven-mirror.init.gradle` | Cloud only: sends Gradle's Maven Central downloads to a mirror, because Maven Central answers the cloud's proxy with HTTP 429 ([build.md](build.md), item 6). |
| `scripts/check.sh` | The quality gate: tools, versions, shell, python, format, lint, import, compile, tests. |
| `scripts/export_smoke.sh` | Exports Linux, Windows, Android APK and (with `--aab`) the Android App Bundle, checks each, and boots the Linux build. |
| `scripts/godot_log.sh` + `tools/checks/log_allowlist.txt` | What counts as a problem in a Godot log, and the known engine noise that doesn't (none so far). |
| `tools/checks/` | `versions.py` (drift check), `compile_all.gd`, `gut_strict_hook.gd`, `pck_files.gd`, and their tests. |
| `.github/workflows/ci.yml` | `check.sh` on pull requests; exports on PRs labelled `exports` and on manual runs. |
| `project.godot`, `export_presets.cfg`, `src/main/`, `tests/`, `addons/gut/` | The minimal Godot project: one placeholder scene, one test suite, GUT vendored. |

## 1. Create the cloud environment (owner)

claude.ai/code → the cloud icon above the message box → **Cloud** → **Add cloud environment**.

**Name:** `Bramble Cloud`

**Network access:** **Custom**, with **"Also include default list of common package managers"** ticked (GitHub release downloads, PyPI, Ubuntu apt). **Allowed domains**, one per line:

```
dl.google.com
maven.google.com
services.gradle.org
plugins.gradle.org
docs.godotengine.org
uploads.github.com
```

- The first four are for the Android SDK and Gradle.
- `docs.godotengine.org` was blocked in Autobattler and workers needed it (1).
- `uploads.github.com` was for screenshot uploads to releases. Nothing uses it now that sessions can't create releases; the owner left it in place on 6 November 2026, as harmless.
- Gradle's Maven Central downloads go to Google's mirror (`maven-central.storage-download.googleapis.com`), which the default list already allows. The owner chose the mirror alone on 6 November 2026, rather than also warming the Gradle cache in setup, so a fresh session's first AAB downloads about 1.2 GB (about 2 minutes).
- This list is the record of what the environment allows. Autobattler's copy drifted from its environment (1).

**Environment variables:**

```
BASH_DEFAULT_TIMEOUT_MS=300000
BASH_MAX_TIMEOUT_MS=600000
```

Imports, test runs and exports need the longer command timeouts. Put **no secrets** here: anyone using the environment can read them.

**Setup script:** paste the whole of [`scripts/cloud-setup.sh`](../scripts/cloud-setup.sh).

- It runs as root on Ubuntu 24.04 before Claude starts. It installs:
  - apt libraries, xvfb and Mesa (rendered screenshots), JDK 17, shellcheck;
  - Godot to `/usr/local/bin/godot` and the export templates (about 1.3 GB);
  - gdtoolkit and ruff;
  - the Android SDK command-line tools, platform and build-tools. Not the NDK: Gradle builds the AAB without it, and it is only needed once Bramble has native code.
- Each download is checked against its pinned checksum. Only a failed Godot install stops the session; anything else logs a `WARNING` and the startup hook reports what is missing.
- **By pasting it you accept the Android SDK licences.** The script runs `sdkmanager --licenses` and answers yes. `ci.yml` does the same on every exports run. The owner accepted both on 6 November 2026; Autobattler treated this as the owner's call (2.15).
- The environment is snapshotted only when the script finishes in about 5 minutes (2.5). The script logs each section's time and the total to `/opt/bramble/setup.log`, the only place a session can read the setup output or see why a part of it failed. In a local test on a home connection it took 379 s without the NDK, mostly the 1.3 GB export templates (214 s) and apt (93 s). In the cloud it took 133 s ([build.md](build.md), item 1).
- The script writes `/opt/bramble/setup.env`, including its own SHA-256. The startup hook compares that hash with `scripts/cloud-setup.sh` (ignoring the final newline, which the environment UI drops) and warns when the pasted script is out of date. **Whenever `scripts/cloud-setup.sh` changes in the repo, paste it again.**

## 2. What has been proved

**In a local container**, a fresh `ubuntu:24.04` running the setup script of 2 November 2026: setup, the hook run by hand, `godot -s` exit codes, an xvfb render, `check.sh`, and `export_smoke.sh --aab`.

**In the cloud**, 6 November 2026 ([build.md](build.md)): setup in 133 s, the hook run by hand, `godot -s` exit codes, an xvfb render, `check.sh` with its deliberate breaks, the Linux, Windows and APK exports, the AAB through the Maven mirror, and the `gh api` calls workers need.

**In the cloud from `main`**, 6 November 2026 (the short proof below, and [build.md](build.md)): the hook firing as a real SessionStart hook and its warning reaching the agent, the current setup script (130 s and 150 s), snapshot reuse, pushing a `screens` branch, merging through `gh api`, and reading CI logs from a session.

**Never launched:** the Windows and Android builds are built and inspected, not run. All exports are debug builds.

### Short proof

These briefs can run again after a toolchain change, once `screens` and both `claude/merge-test-*` branches are deleted from outside a session. Sessions start from `main`, so the change has to be merged first. Session A goes before pasting the changed setup script, so the hook has a real mismatch to warn about:

> Verify the toolchain from main. Change nothing except docs/build.md, on your own branch and PR. Do not run scripts/session-start.sh by hand. Report for each item the command, the result and the shortest decisive line:
> 1. Hook: quote what you can see in your session context from the SessionStart hook: the `Godot:` line and any `WARNING` line. A warning that the setup script differs is expected in this session.
> 2. Variables: `echo $XDG_DATA_HOME $JAVA_HOME $ANDROID_HOME`; `command -v ruff`; `ruff --version`; `java -version`; `ls ~/.gradle/init.d`.
> 3. `./scripts/check.sh` passes. Then point `dirs` in .gutconfig.json at an empty folder and show the `tests` step fails, then restore the file.
> 4. Screenshot push: render with `xvfb-run -a godot --rendering-driver opengl3 --audio-driver Dummy --write-movie /tmp/shot.png --quit-after 3`. Push `/tmp/shot00000002.png` to a new orphan branch `screens`, show its raw.githubusercontent.com URL rendering in a comment on your PR, and leave the branch: sessions can't delete branches, so the owner's side does. If the push is refused, quote the refusal.
> 5. Merging: push throwaway branches `claude/merge-test-base` (from main) and `claude/merge-test-head` (one empty commit more), open a PR from head to base with `gh api`, merge it with `gh api -X PUT repos/SwitchOCE/Bramble/pulls/<n>/merge`, and leave both branches. Quote any refusal. Never merge into main.
> 6. CI logs: read the job steps of a recent CI run with `gh api`, then try its job log with `gh api repos/SwitchOCE/Bramble/actions/jobs/<id>/logs`. Quote any refusal.

Between A and B, the owner pastes the current script. Session B runs after that, and session C is one more new session after B. Both get this:

> Report only, and change nothing: `cat /opt/bramble/setup.log`; `cat /opt/bramble/setup.env`; `ls -l --time-style=full-iso /opt/bramble/setup.env`; `uptime -s`; and any `WARNING` line you can see from the SessionStart hook. Say whether setup.env is older than the boot time. Finish with `./scripts/check.sh | tail -1`. Post the report as a comment on the PR that holds the toolchain change.

Session B should show no warning and a full `setup.log`. Session C should show `setup.env` older than its boot time, which means it started from the snapshot. Cloud sessions don't report back to the session that started them, so a report has to land somewhere readable, such as a PR comment.

## 3. CI on GitHub

- **Every PR** that touches more than docs and the art/research tools runs `check.sh` on `ubuntu-24.04`.
- **Exports** run when a PR carries the `exports` label, or from **Actions → CI → Run workflow**. They build Linux, Windows, the APK and the AAB, and keep the builds as artifacts for 3 days.
- Actions minutes are free while the repo is public.

### The ideation gate on Actions

A push to `ideation/gate/**` runs only the `check` job, on that exact commit, with no exports and no paths-ignore. It uploads `build/check/gut.xml` (GUT's JUnit output) as the `gut-junit` artifact and writes the GUT totals to the job summary. The workflow comes from the pushed commit, so only commits that carry this trigger can be gated.

- `scripts/cloud-gate.sh <commit> [label]` pushes the commit to `ideation/gate/<12-char sha>`, waits with `gh run watch`, and prints `GATE <sha> PASS|FAIL <url>`, plus the last 40 lines of the failed log on a failure. It needs an authenticated `gh`, and logs each gate to `~/.local/state/bramble/cloud-gates.csv`.
- `scripts/cloud-gate.sh --check <commit>` says whether the commit has a successful gate run: the merge rule's test.
- `./scripts/check.sh --docs-only --base <sha>` is the docs-only path against a gated commit instead of the upstream. It doesn't check that `<sha>` was gated: run `scripts/cloud-gate.sh --check <sha>` first.
- A failure that looks flaky: `gh run rerun <run id> --failed`, then `scripts/cloud-gate.sh --check <commit>`. Pushing the same commit again starts no new run.

### Godot slots

The local machine has two Godot slots, flocks on `/tmp/bramble-godot.lock` and `/tmp/bramble-harness-godot.lock`. Sims take the harness lock themselves. Gates, tests and probes go through `GODOT_SLOT_CLASS=<gate|review|worker|probe> scripts/godot_slot.sh <command...>`, which logs start, class, slot, wait, hold, exit code and command to `~/.local/state/bramble/godot-slots.csv` and sets `BRAMBLE_SLOT_HELD=1` for the child. `check.sh` takes a slot itself, only from import through tests, so the wrapper runs it without one; with `BRAMBLE_SLOT_HELD=1` it doesn't lock again. Don't wrap `check.sh` in an outer `flock` on either lock: it would wait for a second slot. Where `systemd-run --user` works, the wrapper's command and each of `check.sh`'s Godot steps run under `MemoryMax=3G`. The tests step also prints the 20 slowest test scripts from `gut.xml`.

## 4. Locally

In Autobattler, Godot running in WSL windows stole focus, and two parallel check runs froze the PC on 11 October (2.16). Headless runs in WSL avoid the windows:

```bash
GODOT=~/godot472/godot ./scripts/check.sh
```

- A Linux-side copy of the repo, rather than `/mnt/c`, matches CI on line endings, exec bits and speed.
- `nice -n 19` keeps a run from competing with other work on the machine.
- WSL has Godot, the export templates, gdtoolkit and ruff. It has no JDK or Android SDK, so Android exports are proven in CI and the cloud only. It has no shellcheck either, so `check.sh` stops at its `tools` step until one is on PATH.

## Project settings and why

`project.godot` loses its comments whenever the editor saves it, so the reasons live here.

- **Every GDScript warning is an error**, including all the typing ones (`untyped_declaration`, `unsafe_*`). That matches the owner's decision of 2 November 2026: GDScript "as typed as possible, as thorough as possible".
- **Two warnings are left off on purpose:**
  - `inferred_declaration` would forbid `var x := 1`, which is still statically typed;
  - `return_value_discarded` fires on almost every engine call that returns a value nobody needs.
- **`integer_division` is an error.** `5 / 2` is `2`; when that is intended, mark the line with `@warning_ignore("integer_division")`.
- `addons/` is exempt from warnings: that is Godot's own default, and it keeps GUT loading.
- **Renderer:** `gl_compatibility`, for the widest Android support and because it renders under xvfb and Mesa (2.8).
- **`textures/vram_compression/import_etc2_astc=true`:** Android export requires it (2.3).
- **Window:** a 1280×720 landscape placeholder. Orientation is held for the UI and UX phase; the owner leans to portrait on phones.
- **Icon:** `icon.svg`, a placeholder. A missing icon logs an ERROR during Android export, which the gate would count (2.3).
- **App ID:** `com.switchoce.bramble` is a placeholder. It can't change after the first store upload, so the owner picks it before then (2.11).

## The log allowlist

- `check.sh` and `export_smoke.sh` fail on any `ERROR`, `WARNING`, `SCRIPT ERROR`, `Parse Error`, `[GUT ERROR]`, `[GUT WARNING]` or `handle_crash` line in a Godot log (2.7).
- `tools/checks/log_allowlist.txt` is where known engine noise goes, each entry with a comment saying why it is harmless. It is empty so far.
- An entry hides that line in every log. V-Sync noise under xvfb is the first likely entry, once a gated command runs under xvfb.

## Upgrading the toolchain

1. Change the versions in `tools/versions.env`. Take the SHA-512s from the new release's `SHA512-SUMS.txt`.
2. On a Godot upgrade:
   - re-read the Android levels from `config.gradle` inside the new templates' `android_source.zip` (2.2);
   - update the GUT version to the release that supports the new Godot, and vendor it into `addons/gut/`;
   - update `config/features` in `project.godot`.
3. Paste the new `tools/versions.env` into the block in `scripts/cloud-setup.sh`, between its markers.
4. Run `./scripts/check.sh`. Its versions step names anything still out of step.
5. Re-paste `scripts/cloud-setup.sh` into the environment, and run an exports build in CI.

The NDK isn't pinned or installed. Once Bramble has native code, it comes from the same `config.gradle`, with its own pin and an `sdkmanager` line in `scripts/cloud-setup.sh` and `ci.yml`.

## Troubleshooting

- **The session won't start:** the setup script exited non-zero, which only happens when Godot fails to download, fails its checksum or won't run.
- **A `WARNING` from the startup hook:** it names the missing or mismatched part. The usual fix is to re-paste `scripts/cloud-setup.sh`.
- **A host is blocked:** add it under Custom → Allowed domains, and to the list in section 1.
- **HTTP 429 from `repo.maven.apache.org` in a Gradle log:** the Maven mirror isn't installed. Check for `~/.gradle/init.d/bramble-maven-mirror.gradle`; the startup hook copies it there.
- **`check.sh` says ruff is 0.16.9 (or another unpinned version):** the cloud image's own ruff in `~/.local/bin` is first on PATH, which means the hook's variables didn't load. Run `bash scripts/session-start.sh` with `CLAUDE_ENV_FILE` set, or source what it writes.
- **Script errors on the first import after a merge:** a stale class cache (2.7). `check.sh` imports again and judges only the second pass.
- **`$'\r'` errors from a shell script:** a file was saved with CRLF. Run `git add --renormalize .` and commit.

## Screenshots

Sessions can't create GitHub releases (HTTP 403 from the session's gateway, [build.md](build.md) item 8). The owner chose on 6 November 2026: an orphan `screens` branch, reset by a scheduled Action, with PRs linking its `raw.githubusercontent.com` URLs. The screenshot tool and the Action come when something needs them. A session can create and push the branch, and the image renders in a PR comment, but it can't delete a branch (HTTP 403); the Action uses its own token, so it can reset it. Updating an existing `screens` branch from a session wasn't tried. The lifecycle wording comes to the owner when the Action is built.

## What stays out of the cloud

- **Release signing:** the Android release keystore and its passwords. The owner creates them and stores them as GitHub secrets; no agent handles them. The release path itself is not decided yet.
- Store accounts and uploads, code-signing certificates, and testing on real devices.
