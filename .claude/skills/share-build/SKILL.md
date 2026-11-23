---
name: share-build
description: Put the latest Bramble build at the owner's fixed public download links, the ones they give to friends. Use when the owner asks for an installer deploy, to deploy, share or publish the latest build or version, to update the friend link, or asks what the download link is. Not for making a build the owner plays themselves (scripts/build_windows.sh and Play-Bramble.cmd).
---

# Sharing the latest build

The owner asked for "some way that I can share it with a friend repeatedly", and for a skill "to update this when I request for a installer deploy for the latest version" (23 Nov 2026).

There is one link per system. It never changes. Each deploy replaces the build behind it:

- Windows: https://pub-7c7d20a539e24b1087bb867c332fd080.r2.dev/Bramble-windows.zip
- Mac: https://pub-7c7d20a539e24b1087bb867c332fd080.r2.dev/Bramble-macos.zip

The download arrives under the build's own name (`Bramble-windows-<commit>-<date>-<time>[-label].zip`), so anyone can tell which build they have. To see what a link holds now: `curl -sI <link>` and read `content-disposition`.

**The links are public.** Anyone who has one can download the game, with no password. Put there only a build made by the build script from committed `dev`. A build from another branch goes up only when the owner asks for that branch by name.

## A deploy

1. **Find the latest version.** `git fetch`, then the head of `origin/dev`.
2. **Find the newest build zip** and the commit in its name. Builds are made on the Optiplex and sit in `build/windows/` of the checkout that made them. On the owner's PC a zip is in Downloads only until `Play-Bramble.cmd` unpacks it, which deletes it; `%USERPROFILE%\Bramble\installed.txt` names the one unpacked last.
3. **Is that build the latest version?** It is if nothing the game is built from changed between its commit and the head of `dev`: `git diff --name-only <commit> origin/dev | scripts/docs_only.sh` says "docs only", or there is no difference. Check on the machine that has the commit; a build commit is sometimes only on the Optiplex.
4. **If it isn't, make one.** On the Optiplex, in a clean checkout of `origin/dev`: `scripts/build_windows.sh <label>`. It is a long command. It exits 0 only when the build passed its own checks; don't share a build that didn't.
5. **Upload it:** `scripts/share_build.sh <zip>`, on a machine with a Cloudflare login. The owner's PC has one. The Optiplex has none (23 Nov), so send the zip to the PC first (`tailscale file cp <zip> <pc name>:` lands it in Downloads), or ask the owner for a Cloudflare token for the Optiplex; agents don't create keys. The script exits 0 only when the public link serves the new file.
6. **Tell the owner** the link, the build it now holds (commit, date, label), and what nobody checked. A person has not played a build just because the script passed.

## Mac

Deploy the Mac build only when the owner asks for Mac. It is made separately, so the Mac link can hold an older build than the Windows link. When it does, say so with both dates.

## Where it lives

The bucket is `bramble-builds` in the owner's Cloudflare account, apart from `bramble-assets` so that `tools/assets/assets.py prune` never touches it. It holds two files and no history: a deploy overwrites. Each is about 200 MB of the account's free 10 GB (`tools/assets/README.md` has the limits).
