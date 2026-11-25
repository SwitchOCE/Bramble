---
name: share-build
description: Put the latest Bramble build at the owner's fixed public download links, the ones they give to friends. Use when the owner asks for an installer deploy, to deploy, share or publish the latest build or version, to update the friend link, or asks what the download link is. Not for making a build the owner plays themselves (scripts/build_windows.sh and Play-Bramble.cmd).
---

# Sharing the latest build

The owner asked for "some way that I can share it with a friend repeatedly", and for a skill "to update this when I request for a installer deploy for the latest version" (23 Nov 2026).

There is one link per system. It never changes. Each deploy replaces the build behind it:

- Windows: https://pub-7c7d20a539e24b1087bb867c332fd080.r2.dev/Bramble-windows.zip
- Mac: https://pub-7c7d20a539e24b1087bb867c332fd080.r2.dev/Bramble-macos.zip
- Linux: https://pub-7c7d20a539e24b1087bb867c332fd080.r2.dev/Bramble-linux.zip
- Android: https://pub-7c7d20a539e24b1087bb867c332fd080.r2.dev/Bramble-android.apk

The Linux and Android links are reserved for later (owner, 23 Nov: "when I will want them later on, may as well do them now"). Nothing has been built for them, so they answer "not found" until a first build is uploaded.

The download arrives under the build's own name (`Bramble-windows-<commit>-<date>-<time>[-label].zip`), so anyone can tell which build they have. To see what a link holds now: `curl -sI <link>` and read `content-disposition`.

**The links are public.** Anyone who has one can download the game, with no password. Put there only a build made by the build script from committed `dev`. A build from another branch goes up only when the owner asks for that branch by name.

## A deploy

1. **Find the latest version.** `git fetch`, then the head of `origin/dev`.
2. **Find the newest build zip** and the commit in its name. Builds are made on the Optiplex, in `build/windows/` of whichever checkout or worktree ran the build script; sessions often delete them once sent. `find ~/code ~/.t3/worktrees /data -name 'Bramble-windows-*.zip'` lists what is left. On the owner's PC a zip is in Downloads only until `Play-Bramble.cmd` unpacks it, which deletes it; `%USERPROFILE%\Bramble\installed.txt` names the one unpacked last.
3. **Is that build the latest version?** It is if nothing that goes into the game changed between its commit and the head of `dev`. List the changes with `git diff --name-only <commit> origin/dev`. Docs don't go into the game, and neither does anything the export leaves out (`exclude_filter` in `export_presets.cfg`: `tests/`, `tools/`, `scripts/`, `docs/`, `build/`, `addons/gut/`). If every changed path is one of those, or nothing changed, the build is the latest. Check on the machine that has the commit; a build commit is sometimes only on the Optiplex.
4. **If it isn't, make one.** On the Optiplex, in a clean checkout of `origin/dev`: `scripts/build_windows.sh <label>`. It is a long command. It exits 0 only when the build passed its own checks; don't share a build that didn't.
5. **Upload it:** `scripts/share_build.sh <zip>`, on a machine with a Cloudflare login. The owner's PC has one. The Optiplex has none (23 Nov), so send the zip to the PC first (`tailscale file cp <zip> <pc name>:` lands it in Downloads) and upload it straight away, before `Play-Bramble.cmd` unpacks and deletes it. Or ask the owner for a Cloudflare token for the Optiplex; agents don't create keys. The script exits 0 only when the public link serves the new file.
6. **Tell the owner** the link, the build it now holds (commit, date, label), and what nobody checked. A person has not played a build just because the script passed.

The first time a friend runs it, Windows shows a "Windows protected your PC" warning, because the game isn't signed: More info, then Run anyway. A Mac shows its own warning for the same reason; the README inside the Mac zip says how to open it.

## Mac, Linux and Android

A deploy means Windows unless the owner names another system.

**Linux and Android** have export presets (`export_presets.cfg`) and the export smoke test builds them as debug builds, but no script makes a build for a player yet. When the owner asks for one, that script comes first: say so, and don't upload a smoke-test build. Name its output `Bramble-linux-<commit>-<date>-<time>[-label].zip` or `Bramble-android-<commit>-<date>-<time>[-label].apk` and `scripts/share_build.sh` puts it at the right link.

**Mac.** Deploy the Mac build only when the owner asks for Mac. `scripts/build_macos.sh` makes it, and its own rule is the same. The owner: "it's to be triggered only when I request it, explicitly only".

The Mac link can hold an older build than the Windows link. When it does, say so with both dates.

## Where it lives

The bucket is `bramble-builds` in the owner's Cloudflare account, apart from `bramble-assets` so that `tools/assets/assets.py prune` never touches it. It holds one file per system and no history: a deploy overwrites. Each is about 200 MB of the account's free 10 GB (`tools/assets/README.md` has the limits).
