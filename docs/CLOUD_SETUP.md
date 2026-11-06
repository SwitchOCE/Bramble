# Cloud environment and toolchain

How Bramble's Godot toolchain is set up: locally, in Claude Code cloud sessions and in GitHub Actions. Built from the Autobattler lessons in [research/autobattler/toolchain.md](research/autobattler/toolchain.md); section numbers like "2.7" below point there.

Every version and checksum lives in [`tools/versions.env`](../tools/versions.env). Nothing else spells them out, and `scripts/check.sh` fails when a copy drifts (2.6).

## The files

| File | What it does |
|---|---|
| `tools/versions.env` | The pins: Godot and its SHA-512s, export templates, GUT, gdtoolkit, ruff, JDK, Android SDK parts. |
| `scripts/cloud-setup.sh` | The cloud environment's setup script. **You paste it into the environment UI.** It carries a verbatim copy of `tools/versions.env`. |
| `scripts/session-start.sh` + `.claude/settings.json` | SessionStart hook in cloud sessions: exports the toolchain variables, warns when the environment differs from the pins, imports the project once. |
| `scripts/check.sh` | The quality gate: tools, versions, shell, python, format, lint, import, compile, tests. |
| `scripts/export_smoke.sh` | Exports Linux, Windows, Android APK and (with `--aab`) the Android App Bundle, checks each, and boots the Linux build. |
| `scripts/godot_log.sh` + `tools/checks/log_allowlist.txt` | What counts as a problem in a Godot log, and the short list of known engine noise that doesn't. |
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
- `uploads.github.com` is for screenshot uploads to release assets.
- Add others only when a session reports a blocked host it really needs, and add them here at the same time. Autobattler's copy of this list drifted (1).

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
  - the Android SDK command-line tools, platform and build-tools. The NDK is off (`INSTALL_ANDROID_NDK=0`): Gradle builds the AAB without it, and it is only needed once Bramble has native code.
- Each download is checked against its pinned checksum. Only a failed Godot install stops the session; anything else logs a `WARNING` and the startup hook reports what is missing.
- **By pasting it you accept the Android SDK licences.** The script runs `sdkmanager --licenses` and answers yes. Autobattler treated that acceptance as the owner's call (2.15).
- The environment is snapshotted only when the script finishes in about 5 minutes (2.5). The script logs each section's time and the total. In a local test on a home connection it took 379 s without the NDK, mostly the 1.3 GB export templates (214 s) and apt (93 s); the cloud's network should be faster, and the proof session measures it.
- The script writes `/opt/bramble/setup.env`. The startup hook compares it with `tools/versions.env` and warns when the pasted script is out of date. **Whenever `scripts/cloud-setup.sh` changes in the repo, paste it again.**

## 2. Prove the toolchain in one cloud session

**Already proved in a local container**, a fresh `ubuntu:24.04` running the real setup script (2 November 2026):
- the setup script installs everything and writes its stamp; the startup hook exports the variables, finds JDK 17 and imports;
- `godot -s` passes its exit code through (42 in, 42 out);
- xvfb renders the main scene to a real 1280×720 image;
- `check.sh` passes all steps;
- `export_smoke.sh --aab` passes: Linux (and its headless boot), Windows (with ProductName), the APK, and the AAB through Gradle. The first Gradle build downloads about 1.2 GB into `~/.gradle` and takes about 2 minutes;
- the AAB builds without the NDK.

What a container can't show is the cloud itself: its network proxy and allowlist (Autobattler's Gradle builds hit HTTP 429 from Maven Central there, 2.4), its setup time and snapshot, the hook running as a real SessionStart hook, and GitHub access from a session. The brief below covers all of it anyway, so the cloud has its own record.

Start one session on branch `build/toolchain` with the `Bramble Cloud` environment, and send it this brief. It changes only the toolchain files and adds a report.

> Prove the cloud toolchain for Bramble. Read docs/CLOUD_SETUP.md first. Change nothing except toolchain files (scripts/, tools/checks/, tools/versions.env, .github/, .claude/settings.json, docs/CLOUD_SETUP.md) and write your findings to docs/build.md. Report, for each item, the command, the result and the shortest decisive line of output:
> 1. Setup: the `[cloud-setup]` section times and total (from the setup log if you can see it, else `cat /opt/bramble/setup.env`), and whether the session started from a cached snapshot.
> 2. Startup hook: any WARNING lines it printed; `echo $XDG_DATA_HOME $JAVA_HOME $ANDROID_HOME`; `java -version`; `godot --version`.
> 3. `godot -s` exit codes: a SceneTree script that calls `quit(42)` must exit 42.
> 4. Rendering: `xvfb-run -a godot --rendering-driver opengl3 --audio-driver Dummy --write-movie /tmp/shot.png --quit-after 3` must write a PNG that is not one flat colour (check pixel variety with python3).
> 5. `./scripts/check.sh` passes. Then break things one at a time and show that each fails: a scene pointing at a missing script, an untyped `var x = 1`, a test with no asserts, a test with a parse error, a changed GODOT_VERSION in tools/versions.env.
> 6. `./scripts/export_smoke.sh --aab`: Linux, Windows and the APK must pass. For the AAB (Gradle), try in order and report each: (a) plain; (b) with a Gradle init script that points Maven Central at a mirror, for the HTTP 429s Autobattler hit (2.4); (c) with the Gradle cache warmed in the setup script, and how much setup time that adds. Stop at the first that works. (In a local container the plain build worked; the cloud's proxy is what is being tested.)
> 7. GitHub from the session: the `gh api` calls workers will need (read an issue, comment on it, add and remove a label, open a PR, read a PR's check runs). `gh pr` / `gh issue` are expected to fail (2.13).
> 8. Screenshot storage: create a pre-release named `screens` with `gh api`, upload the PNG from item 4 as an asset through uploads.github.com, show its URL rendering in a PR comment, then delete the asset.
> Fix what fails in the toolchain files, keep `./scripts/check.sh` green, push to the branch, and list anything you could not fix.

## 3. CI on GitHub

- **Every PR** that touches more than docs and the art/research tools runs `check.sh` on `ubuntu-24.04`.
- **Exports** run when a PR carries the `exports` label, or from **Actions → CI → Run workflow**. They build Linux, Windows, the APK and the AAB, and keep the builds as artifacts for 3 days.
- Actions minutes are free while the repo is public.

## 4. Locally

Godot work runs in WSL, never in a window on the desktop (2.16):

```bash
GODOT=~/godot472/godot ./scripts/check.sh
```

- Run it from a Linux-side copy of the repo, not `/mnt/c`, so line endings, exec bits and speed match CI.
- One heavy run at a time, at low priority (`nice -n 19`).
- WSL has Godot, the export templates, gdtoolkit and ruff. It has no JDK, Android SDK or shellcheck, so Android exports are proven in CI and the cloud only.

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

- `check.sh` and `export_smoke.sh` fail on any `ERROR`, `WARNING`, `SCRIPT ERROR`, `Parse Error` or `handle_crash` line in a Godot log (2.7).
- `tools/checks/log_allowlist.txt` lists the few lines that are known engine noise. Each has a comment saying why it is harmless.
- An entry hides that line in every log, so add one only with a reason, and never to get a real error past the gate.

## Upgrading the toolchain

1. Change the versions in `tools/versions.env`. Take the SHA-512s from the new release's `SHA512-SUMS.txt`.
2. On a Godot upgrade:
   - re-read the Android levels from `config.gradle` inside the new templates' `android_source.zip` (2.2);
   - update the GUT version to the release that supports the new Godot, and vendor it into `addons/gut/`;
   - update `config/features` in `project.godot`.
3. Paste the new `tools/versions.env` into the block in `scripts/cloud-setup.sh`, between its markers.
4. Run `./scripts/check.sh`. Its versions step names anything still out of step.
5. Re-paste `scripts/cloud-setup.sh` into the environment, and run an exports build in CI.

## Troubleshooting

- **The session won't start:** the setup script exited non-zero, which only happens when Godot fails to download, fails its checksum or won't run.
- **A `WARNING` from the startup hook:** it names the missing or mismatched part. The usual fix is to re-paste `scripts/cloud-setup.sh`.
- **A host is blocked:** add it under Custom → Allowed domains, and to the list in section 1.
- **Script errors on the first import after a merge:** a stale class cache (2.7). `check.sh` imports again and judges only the second pass.
- **`$'\r'` errors from a shell script:** a file was saved with CRLF. Run `git add --renormalize .` and commit.

## What stays out of the cloud

- **Release signing:** the Android release keystore and its passwords. The owner creates them and stores them as GitHub secrets; no agent handles them. The release path itself is not decided yet.
- Store accounts and uploads, code-signing certificates, and testing on real devices.
