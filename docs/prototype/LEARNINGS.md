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

### 4 Nov 00:20 — UI: strict typing rejects every Variant passed on

**What happened:** with every warning an error, a value read from a `Dictionary` (`d["x"]`, `d.get("x")`) or returned by `Callable.call()` can't be passed straight to a typed parameter, to `int()`, or even to a GUT `assert_eq` ("requires the subtype Variant but the supertype Variant was provided"); `x as Dictionary` on a Variant is an "unsafe cast". Assigning it to a typed local first is allowed. The first compile of the UI had about 50 of these.
**Why:** `unsafe_call_argument` and `unsafe_cast` are errors (CLOUD_SETUP.md, project settings), and SPEC's state and events are plain Dictionaries.
**Next time:** read state through small typed helpers (`src/ui/view_data.gd`: `Data.i(d, "gold")`, `Data.a(...)`, `Data.entry(array, i)`), and in tests assign to a typed local before asserting. Godot reports only the first such error per function, so fix and recompile in rounds; `godot --headless -s res://tools/checks/compile_all.gd` is the fast loop.

### 4 Nov 00:21 — UI: setting a Control's size right after its minimum size doesn't take

**What happened:** cards drawn by hand at different sizes kept their old layout: `custom_minimum_size = s; size = s` left `size` at the old, larger minimum, so the card laid itself out at full size inside a smaller slot. Headless size dumps looked right a frame later, which hid it.
**Why:** `size` is clamped to the combined minimum size, and that cache updates deferred.
**Next time:** lay out from the size you asked for (a `card_size` field), not from `size`. Containers also stretch children to the row height unless the child's size flags say `SHRINK_CENTER`.

### 4 Nov 00:22 — UI: screenshots from a SceneTree script, native size

**What happened:** `tests/ui/shots/screenshot.gd` builds one screen from the fixtures, sets the window size in code, waits 20 frames and saves `root.get_texture().get_image()`; `tests/ui/render_screens.sh` runs it under `xvfb-run -s "-screen 0 2560x1440x24"` with `--rendering-driver opengl3` and converts to JPEG 85. Each shot takes about a second. Reading the shots caught three layout bugs no test would have (an off-screen inspector, cards overflowing their rows, floating numbers placed before layout).
**Why it went well:** a script entry point needs no scene list, and the default 1280×720 window override is bypassed by sizing the window in code.
**Next time:** look at every screen at both sizes before reporting. Don't compute positions from `get_global_rect()` in the frame a screen is built: wait a frame first.

### 4 Nov 00:23 — UI: the fixture port reads docs/ directly, which an export won't have

**What happened:** `docs/.gdignore` stops Godot importing `docs/`, but `FileAccess` still reads `res://docs/prototype/fixtures/*.json` in the editor and in tests, so the fixture port uses them in place (no copy to drift). Exports exclude `docs/*`, so the fixture port can't work in a build. Not checked: whether `content/units/*.json` is packed (Godot 4 treats `.json` as a resource, so it probably is).
**Next time:** at integration, list the pck's files (`tools/checks/pck_files.gd`) and add `include_filter="*.json"` to `export_presets.cfg` if the unit files are missing.
### 4 Nov 00:40 — UI: unit JSON is packed without an include filter (corrects the 00:23 entry)

**What happened:** listing the Linux debug pack with `tools/checks/pck_files.gd` showed all 41 `content/units/*.json` files even before `include_filter` was set, and no `docs/` or `tests/` files. The filter `content/units/*.json` is now in all four presets anyway, so the content doesn't depend on how Godot classes `.json`.
**Why:** Godot 4 imports `.json` as a resource, so the "all resources" export mode takes it.
**Next time:** keep the explicit filter for anything the core reads with `FileAccess`, and list the pack after any export-preset change.

### 4 Nov 00:40 — UI: after merging another worker's branch, import before compiling

**What happened:** the first compile after `git merge proto/core` failed on every core `class_name` (`UnitLibrary`, `GameSession`, …) as unknown types.
**Why:** global class names live in `.godot/global_script_class_cache.cfg`, which only an import rebuilds; a merge adds scripts without it.
**Next time:** run `godot --headless --import` straight after each merge.

### 4 Nov 00:40 — UI: a gdlint disable comment only works on line 1

**What happened:** `# gdlint:disable=max-public-methods` below `extends` was ignored, so the 20+ method ports still failed lint.
**Why:** gdlint reads file-wide disables only from the first line.
**Next time:** put the disable on line 1 and the reason on line 2.

### 4 Nov 00:40 — UI: a node kept out of the tree leaks at exit

**What happened:** the app keeps the sandbox screen alive (detached) while its fight plays, so the owner returns to the boards they built. Quitting during that fight logged leaked GL textures and an orphan node.
**Why:** nodes outside the tree aren't freed with it.
**Next time:** any node held outside the tree needs an owner that frees it in `_exit_tree` (here `App._exit_tree`).

### 4 Nov 00:40 — UI: touch input in tests needs window pixels

**What happened:** a test that sent `InputEventScreenTouch`/`ScreenDrag` through `Input.parse_input_event` at a card's canvas position missed: the mouse landed at about 30× the position.
**Why:** input events are in window pixels and the root viewport stretches 1920×1080 onto the (tiny, headless) window. Converting with `get_tree().root.get_final_transform() * position` fixed it; touch-to-mouse emulation then starts Godot's drag and drop as on a phone. Set `Input.use_accumulated_input = false` so each drag step arrives.
**Next time:** convert to window pixels in any input-driving test.

### 4 Nov 00:14 — Core: strict GDScript typing traps in Godot 4.7

**What happened:** the first compile of the rules core failed on warnings-as-errors that are easy to hit in data-heavy code: `int(x)` / `bool(x)` on a Variant (from a Dictionary or JSON) is an unsafe call argument; `null if a else b` with a typed `b` is "ternary values not mutually compatible"; a parameter named `seed` shadows the global `seed()`; gdlint's `max-returns: 6` trips on validation functions. In tests, every GUT assert that receives a Variant (a Dictionary value, even a local declared `: Variant`) is flagged as an unsafe argument, although GUT's parameters are untyped.
**Why:** the project turns every typing warning into an error (owner's decision of 2 Nov), and JSON numbers arrive as floats.
**Next time:** in `src/`, convert through a typed local (`var n: int = dict["k"]`) or a helper (`CoreUtil.to_int`), and build nullable fields with an `if`. In test files, put `@warning_ignore_start("unsafe_call_argument")` under the header comment; it passes gdformat and gdlint. Commit the `.gd.uid` files Godot writes next to new scripts.

### 4 Nov 00:14 — Core: what went well

**What happened:** with the spec's API, fixtures and rule numbers fixed up front, the walking skeleton (library, pool, recruit, plain combat, bots, game loop) compiled after one round of typing fixes, and 96 GUT tests (rule number in each test name) run in about a second, including nine bot-only full games (two of them a same-seed replay) with a pool-conservation check after every round. The whole gate takes under 15 s.
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
