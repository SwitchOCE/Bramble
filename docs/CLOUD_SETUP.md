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
| `scripts/export_smoke.sh` | Exports Linux, Windows, Android APK and (with `--aab`) the Android App Bundle; requires the field library in every pack, boots Linux, and checks feature-off Bots defaults. |
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

A push to `ideation/gate/**` runs the gate on that exact commit, with no exports and no paths-ignore, as five parallel jobs. The run's conclusion is the verdict. The workflow comes from the pushed commit, so only commits that carry this trigger can be gated.

- `gate-static` runs `./scripts/check.sh --keep-going --no-tests --base "$DOCS_BASE_SHA"`: every step but tests, once.
- `gate-tests` is a matrix of 4 shards. Each runs `./scripts/check.sh --shard i/4 --base "$DOCS_BASE_SHA"`: the tools step (Godot and Python only), import, then the tests step on shard i's scripts. Each shard uploads its `build/check/gut.xml` (GUT's JUnit output) as `gut-junit-<i>`. The Run Summary is in each shard's step log.
- In the tests step, the strict hook, the parse-error check and the zero-tests backstop apply to each shard. A shard also fails if the number of scripts GUT ran isn't the number the shard lists.
- `tools/checks/test_shards.py` makes the shards. It balances by the per-script seconds in `tools/checks/test_times.json`, slowest first onto the lightest shard. A script with no time (a new test) goes on the lightest shard at the median time, after the known ones, so it never moves them. `test_shards.py show 4` prints the split. To refresh the times, run `python3 tools/checks/test_shards.py times <gut.xml>...` on an unsharded `build/check/gut.xml` or on all four `gut-junit-<i>` files of one gate run. The python step prints a `test_times: WARNING` line when more than a quarter of the scripts have no time; it never fails the gate, since a stale file only skews shard sizes.
- Gate jobs don't use the Godot cache: a gate branch can't read a cache saved on another ref, and the download takes seconds. PR runs restore and save it.
- PR and manual runs are unchanged: one unsharded `check` job, plus exports when asked. Without `--shard` or `--no-tests`, `check.sh` is the full unsharded gate, locally and anywhere else.

- `scripts/cloud-gate.sh <commit> [label]` pushes the commit to `ideation/gate/<12-char sha>`, waits with `gh run watch`, and prints `GATE <sha> PASS|FAIL <url>`, plus, on a failure, the failed jobs' `check.sh` lines: `FAIL` and `failed:` lines, each failing script and test with its message, and the GUT totals (`scripts/gate_failures.sh`, which also reads a plain job log on stdin). If none match, because a setup step failed before `check.sh`, it prints the log's last 40 lines. It needs an authenticated `gh`, and logs each gate to `~/.local/state/bramble/cloud-gates.csv`.
- `scripts/cloud-gate.sh --check <commit>` says whether the commit has a successful gate run: the merge rule's test.
- Every `check.sh` mode requires an explicit `--base <sha>`. The docs size guard checks every introduced blob in the full range, including versions later shrunk or deleted, plus staged and local changes. It permits 2 MB per blob and 30 MB of distinct introduced content, excluding exact allowlisted paths and blobs already reachable from the base. It never infers a base from the upstream or `HEAD^`.
- CI checks out full history. PR runs pass the PR base SHA; manual runs require the `docs_base` input. Gate pushes explicitly fetch `origin/ideation/main` and use its merge-base with HEAD. Missing bases and a base equal to HEAD fail setup instead of checking an empty or shortened range.
- `./scripts/check.sh --docs-only --base <sha>` is the docs-only path against a gated commit. It doesn't check that `<sha>` was gated: run `scripts/cloud-gate.sh --check <sha>` first.
- A failure that looks flaky: `gh run rerun <run id> --failed`, then `scripts/cloud-gate.sh --check <commit>`. Pushing the same commit again starts no new run.

### The sim job on Actions

Build 9 sims and soaks run locally through three shared Godot slots; Actions sims are reserved for a single run estimated above two hours. `.github/workflows/sim.yml` runs when `ideation/sim/<id>` is pushed with a config at `sim/<id>.json` in its tree, and commits compact results back to `sim/<id>/` on that branch.

```json
{"kind": "lines", "suite": "quilboar_h1", "preset": "B", "first_seed": 2911001, "lobbies": 32,
 "rates": {"bog_soak_keep": 3}, "shards": 8}
```

- **Config:** `kind` is `lines`, `field`, `designed` or `soak`. Line `preset` is the harness arm (`B`, `C`, `uncut`, `uncut_frozen`); other kinds use an authored rates preset (`A`, `B` or `C`). For B and C it also sets `pass3_preset`. Seeds are `seeds: [...]` or `first_seed` plus `lobbies`. `rates` (optional) overrides `content/pass3/rates.json` dials as GameConfig values, for A3.5's t-paths. `shards` is 1 to 8. Orchestration lives in `tools/checks/sim_job.py`, with a small compatibility entry point at `tools/sim/sim_job.py`; `python3 tools/sim/sim_job.py matrix <config>` validates a config without running Godot.
- **Kind `lines`:** the committed-line lobbies of `tools/sim/quilboar_h1.py`. One of each engine line plus a Hard anchor, through the same `bench.gd` entry point, compacted by that harness's `compact_chunk` and summarized by `quilboar_h1_report.summarize`. There is no second analysis path.
- **Kinds `field` and `designed`:** add `"input": "path/to/frozen-input.json"` (JSON.gz and verified harness archive pointers also work). `field` consumes the sampled `rounds/boards/line_weights` format from `field.py sample`; `designed` consumes complete `boards/line_weights` from `designed_setups.py` or `export_real_designed.gd`. Every configured seed is an actual signed 64-bit combat RNG seed, and fights every within-round board pair in both orientations. Shards pass explicit seed strings to the existing `field_fights.gd` entry point, preserving all hidden combat state. `field.field_report` produces the weighted report; factorial designed inputs also use `designed_report.summarize` for carry/even comparisons. Incomplete or duplicate pair/seed outputs fail. The job applies the selected preset and optional rate overrides to the frozen input configs; it does not infer achievable boards from bot play.
- **Kind `soak`:** `{"kind": "soak", "preset": "B", "first_seed": 1, "lobbies": 200, "shards": 8, "library": "", "synthetic": 0}`. Each shard runs `tools/checks/soak.sh` on one contiguous block of seeds. The merge writes `summary.json` with games, the mix, field games skipped, violations (each distinct line with its count; a directed check repeats once per shard), crashes and Godot log problems, and a README with the verdict. A soak with violations or crashes still commits its results, then fails the run. Synthetic-card games (`synthetic`, on shard 1) are reported apart and don't decide the verdict.
- **The soak itself:** `tools/checks/soak.sh [N] --preset P [--library L] [--synthetic K] [--first-seed S]` plays N real `full_game` lobbies, half the seats on random legal play and the rest on the real bots. By seed % 5, 3 in 5 play preset P, 1 in 5 the other preset (C for B; B for A and C), and 1 in 5 play P with field rivals from library L, skipped and counted without one. Every lobby gets the existing rules checks, plus a check that every unit appearing anywhere in the lobby, including combat summons, has the game's card set. `tools/checks/soak_plant.sh` plants one fault per check and wants each run red.
- **Jobs:** `plan` reads the config, then up to 8 `shard` jobs run at once (`max-parallel: 8`, since GitHub Free runs 20 jobs at once across the repo and a gate takes 5), then `merge`. Line and fight seeds are dealt round-robin; soak seeds use balanced nonempty contiguous blocks. A failed line chunk is retried seed by seed. A seed that still fails is recorded with its reason and makes the overall run fail; nothing is resampled.
- **Results** in `sim/<id>/`: `summary.json` (the harness summary plus a `sim_job` block with the config, seeds, dropped seeds and shard seconds), `<preset>.lobbies.json.gz` (compact lobby records, or one record per seed containing paired-fight counts for field/designed runs), and `README.md` (commit, config, timing, dropped trials and the relevant summary). The results commit carries `[skip ci]`. Raw fight captures and logs are the run's `sim-raw-<i>` artifacts, kept 7 days and never in git.
- **`scripts/sim-run.sh <config.json> [--base <commit>]`** commits the config as `sim/<id>.json` on top of the commit (default `HEAD`) without touching the working tree, and pushes `ideation/sim/<id>`. The id is the file name without `.json`; an id already on origin is refused. **`scripts/sim-run.sh --wait <id>`** waits, copies `sim/<id>/` to `build/sim/<id>/` and prints the summary's path, or exits 1 if the run failed. It uses `gh` when logged in, otherwise the public REST API.
- **Locally:** `python3 tools/sim/sim_job.py local <config> <dir> --jobs 2` runs the same shards and merge on this machine. The runner accepts `--jobs 1` through `--jobs 3` and acquires one shared slot per job; do not wrap parallel local runs in `godot_slot.sh`. Build 9 measurement may use three jobs; other workers use two. Compare the harness's per-line R12 medians and R8–R14 growth on the same commit, config and seeds to verify local/Actions parity. Timing and receipt metadata naturally differ.

For example, freeze two constructed boards, commit that input with the job code, and use a config such as:

```json
{"kind": "designed", "preset": "B", "input": "sim/fixtures/carry-even.json",
 "seeds": [1001, 1007, 1013, 1019], "lobbies": 4, "shards": 2}
```

`python3 tools/sim/designed_setups.py screen --out sim/fixtures/carry-even.json` generates the existing factorial setup input. For current-card authored recipes, run `designed_setups.py real`, then materialize them through `GODOT_SLOT_CLASS=worker scripts/godot_slot.sh godot --headless -s res://tools/sim/export_real_designed.gd -- recipes.json sim/fixtures/real.json`. Config validation requires the complete exported combat state. Native field runs keep their original four-argument seed families; the job's optional fifth argument supplies exact configured seeds.

### Godot slots

The local machine has three Godot slots, flocks on `/tmp/bramble-godot.lock`, `/tmp/bramble-harness-godot.lock` and `/tmp/bramble-godot-third.lock`. Local sim-job shards use the same queue. Historical sim drivers that acquire the harness lock directly still share that one slot. Gates, tests and probes go through `GODOT_SLOT_CLASS=<gate|review|worker|probe> scripts/godot_slot.sh <command...>`, which logs start, class, slot, wait, hold, exit code and command to `~/.local/state/bramble/godot-slots.csv` and sets `BRAMBLE_SLOT_HELD=1` for the child. `check.sh` takes a slot itself, only from import through tests, so the wrapper runs it without one; with `BRAMBLE_SLOT_HELD=1` it doesn't lock again. Don't wrap `check.sh` in an outer `flock` on any slot lock: it would wait for a second slot. Where `systemd-run --user` works, the wrapper's command and each of `check.sh`'s Godot steps run under `MemoryMax=3G`. The tests step also prints the 20 slowest test scripts from `gut.xml`.

## 4. Locally

In Autobattler, Godot running in WSL windows stole focus, and two parallel check runs froze the PC on 11 October (2.16). Headless runs in WSL avoid the windows:

```bash
GODOT=~/godot472/godot ./scripts/check.sh --base <base-sha>
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
