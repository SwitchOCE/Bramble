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
