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

### 3 Nov 23:58 — Spec: the library is thin where the prototype needed it most

**What happened:** of the library's 226 example units, Oozes have 3 (all Bud, whose split rule is still open) and most of the 15 Fairy units need systems the prototype doesn't have (Changeling, Bargain, Rainbow, Foundling, Gall). The chosen 16 library units also have none at tier 4. The spec filled the gaps with 24 plain stat-line units with placeholder names. A mid-task scope change (cut to 12–16 library units, hook points plus one script per mechanic instead of a data-driven effects engine, fixtures for the UI) arrived after the unit selection had started, which cost a re-pick.
**Why:** the shortlisted mechanics' example units sit mostly at tiers 1–3, and tribe depth was never a goal of the library rounds. The scope review ran in parallel with the spec instead of before it.
**Next time:** run the plan review before the spec agent starts. When the owner wants to try a tribe, check its library depth per tier first. Generating unit and fixture files from one script (as here, from the unit JSON) keeps fixtures and content in step.
