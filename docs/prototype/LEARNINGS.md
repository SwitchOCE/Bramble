# Prototype learnings log

What went well, what went wrong, setup and permission problems, and engine gotchas, from the overnight prototype on 3–4 November 2026 and after. Newest at the bottom. Anyone working on the prototype adds entries here.

Format: `### date time — short title`, then **What happened**, **Why**, **Next time**.

### 3 Nov 23:40 — The design branch had never been pushed

**What happened:** `design/tribes-and-budget` held 30 commits (rulebook v0.4, archetypes, the mechanics library, owner notes 02 to 02k) that existed only on the desktop. The migration copied it with a git bundle, so nothing was lost, but GitHub had none of it.
**Why:** sessions committed but never pushed, waiting for a PR that didn't get opened.
**Next time:** push a branch as soon as it has work worth keeping, even before the PR.

### 3 Nov 23:40 — The Optiplex toolchain

**What happened:** the server had Python, Node, Docker, Codex and `claude`, but no Godot and no PowerShell. Passwordless `sudo` works. `scripts/cloud-setup.sh` from `build/toolchain` was run as root, unchanged, to install the pinned Godot, export templates, JDK and Android SDK the same way as a cloud environment.
**Why:** the toolchain branch was proved only in Docker and on GitHub CI; the server is a third environment.
**Next time:** `tools/art/run-codex-image.ps1` needs PowerShell; on Linux use a bash port or call `codex exec` directly.

### 3 Nov 23:40 — No GitHub MCP tools in this session

**What happened:** the GitHub MCP server wasn't available in this session, so pull requests couldn't be opened from here; `git push` works.
**Next time:** open PRs from the compare link, or check the MCP connection at session start.

### 3 Nov 23:50 — The cloud setup script works on the server as-is

**What happened:** `sudo bash scripts/cloud-setup.sh` installed Godot 4.7.2, the export templates, JDK 17, the Android SDK, gdtoolkit and ruff in 314 s with no warnings. `check.sh` then passed all 9 steps, and `export_smoke.sh --aab` built Linux, Windows, the APK and the AAB.
**Why it matters:** the same script now works in Docker, on GitHub CI and on this server.
**Next time:** commands outside a cloud session need the variables that `session-start.sh` exports. They are in `/opt/bramble/env.sh`: `source /opt/bramble/env.sh` first.

### 3 Nov 23:55 — Windows builds can be launch-tested under Wine

**What happened:** Wine 10 (apt `wine wine64 wine32:i386`) runs the exported `bramble.console.exe --headless --quit-after 60` under `xvfb-run`, and it reaches "boot: main scene ready". This is the first real launch check of the Windows build; before, it was only checked statically.
**Next time:** use a separate prefix (`WINEPREFIX=~/.wine-bramble`) and `WINEDEBUG=-all`; the first `wineboot` takes about a minute.

### 3 Nov 23:58 — Playwright doesn't know Ubuntu 26.04

**What happened:** the server runs Ubuntu 26.04. `npx playwright install chromium` fails with "Playwright does not support chromium on ubuntu26.04-x64". `PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=ubuntu24.04-x64` downloads the 24.04 build, which runs fine. Playwright isn't preinstalled here (that is true only of cloud containers); it lives in `~/.local/share/bramble-tools/`.
**Next time:** set the override whenever installing Playwright browsers on this machine.

### 3 Nov 23:59 — The server is shared and modest

**What happened:** 6 cores and about 15 GB of RAM, much less than the desktop. The Claude desktop app was using about 1 GB and was closed. This session runs as the `claude-remote-control-bramble` systemd user service, so closing the desktop app doesn't affect it.
**Next time:** run Godot and Gradle jobs one at a time, run Chromium renders in small waves, and check `uptime` and `free -m` before heavy steps.
### 3 Nov 23:58 — Spec: the library is thin where the prototype needed it most

**What happened:** of the library's 226 example units, Oozes have 3 (all Bud, whose split rule is still open) and most of the 15 Fairy units need systems the prototype doesn't have (Changeling, Bargain, Rainbow, Foundling, Gall). The chosen 16 library units also have none at tier 4. The spec filled the gaps with 24 plain stat-line units with placeholder names. A mid-task scope change (cut to 12–16 library units, hook points plus one script per mechanic instead of a data-driven effects engine, fixtures for the UI) arrived after the unit selection had started, which cost a re-pick.
**Why:** the shortlisted mechanics' example units sit mostly at tiers 1–3, and tribe depth was never a goal of the library rounds. The scope review ran in parallel with the spec instead of before it.
**Next time:** run the plan review before the spec agent starts. When the owner wants to try a tribe, check its library depth per tier first. Generating unit and fixture files from one script (as here, from the unit JSON) keeps fixtures and content in step.

### 4 Nov 00:14 — Core: strict GDScript typing traps in Godot 4.7

**What happened:** the first compile of the rules core failed on warnings-as-errors that are easy to hit in data-heavy code: `int(x)` / `bool(x)` on a Variant (from a Dictionary or JSON) is an unsafe call argument; `null if a else b` with a typed `b` is "ternary values not mutually compatible"; a parameter named `seed` shadows the global `seed()`; gdlint's `max-returns: 6` trips on validation functions. In tests, every GUT assert that receives a Variant (a Dictionary value, even a local declared `: Variant`) is flagged as an unsafe argument, although GUT's parameters are untyped.
**Why:** the project turns every typing warning into an error (owner's decision of 2 Nov), and JSON numbers arrive as floats.
**Next time:** in `src/`, convert through a typed local (`var n: int = dict["k"]`) or a helper (`CoreUtil.to_int`), and build nullable fields with an `if`. In test files, put `@warning_ignore_start("unsafe_call_argument")` under the header comment; it passes gdformat and gdlint. Commit the `.gd.uid` files Godot writes next to new scripts.

### 4 Nov 00:14 — Core: what went well

**What happened:** with the spec's API, fixtures and rule numbers fixed up front, the walking skeleton (library, pool, recruit, plain combat, bots, game loop) compiled after one round of typing fixes, and 98 GUT tests (rule number in each test name) run in about a second, including nine bot-only full games (two of them a same-seed replay) with a pool-conservation check after every round. The whole gate takes under 15 s.
**Why:** a pure `RefCounted` core with no Nodes runs headless, and checking the event and state keys against the fixtures catches contract drift with the UI cheaply.
**Next time:** keep the core free of Nodes; test against the fixture files rather than restating the format.

### 4 Nov 00:44 — Core: per-mechanic commits and shared files

**What happened:** every mechanic adds one line to the shared registry (`MechanicRegistry.BUILT`). Early in milestone B the registry was committed together with Bystander, so the Sett Warden, Garden Snail and Mudwallow Toad commits don't pass the tests on their own. From Weasel Second onwards each commit carries its own registry line, staged by writing the file without the later lines.
**Why:** the brief asks for each mechanic commit to be mergeable on its own, and the registry is the one file they all touch.
**Next time:** write one mechanic and its test, commit it with its registry line, then start the next. Don't write several and split them afterwards.

### 4 Nov 00:44 — Core: test boards need a deterministic first attacker

**What happened:** several mechanic tests failed only because the other side attacked first. When both sides have the same number of units, 9.2.1 decides at random. Tests that fill a board with copies of one unit (seven Field Voles) started forming triples once triples were built.
**Why:** with equal unit counts, the seed decides who opens. The triple check runs on every buy.
**Next time:** give the side that should attack first an extra 0-Attack unit in the back row, and fill boards and hands with goldens when the test isn't about triples.
