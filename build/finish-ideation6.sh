#!/usr/bin/env bash
set -euo pipefail
cd /home/alex/code/Bramble-ideation
out="$(cat build/ideation6-path.txt)"
commit="$(git rev-parse HEAD)"
source_commit="$(cat build/ideation6-source.txt)"
[ "$(cat build/ideation6-checks.exit)" = 0 ]
[ "$(cat build/ideation6-ui-validated.exit)" = 0 ]
[ "$(cat build/ideation6-export.exit)" = 0 ]
grep -qx 'boot: main scene ready' "$out/linux-boot.log"
tr -d '\r' <"$out/windows-boot.log" | grep -qx 'boot: main scene ready'
cmp "$out/build5-certificate.txt" "$out/build6-certificate.txt"
git diff --quiet "$source_commit" -- src tests content assets project.godot export_presets.cfg
cat >"$out/README.txt" <<README
Ideation build 6: Harvest Supper from tier 3; the Last Four lifts the damage cap; Last Stand saves each hero once on 1 Health in the last four; Last Blow awards a mutual wipe to the side that struck last.
Source: ideation/main at $source_commit (requested baseline c8693ae); delivery commit $commit. Game and tests unchanged from the checked source.
Fix commits during this delivery: none.

Windows: unzip Bramble-windows.zip, run windows/bramble.exe (keep bramble.pck next to it).
Android: install Bramble.apk (debug-signed with build 5's signing key; allow installing from unknown sources).
Linux: linux/bramble.x86_64

Rules: Last Stand only saves a lethal hero loss from 2+ Health with four or fewer heroes left; ghosts never spend it. Last Blow credits the finishing effect's owner; Start of Combat mutual wipes remain ties.
Checked: Godot headless import; all ten gate steps, 1,279/1,279 tests; short UI run (tests/ui/full_ui_run.sh 2 1000), four games at 1920x1080 and 1688x780 plus two forced late-game checks, all passed. Normal engine clock, core 2 only, hard 40-minute UI timeout; original UI minimums retained. Required Android export (REQUIRE_ANDROID=1), pack contents, archive and APK checks passed. APK signing certificate matches build 5. Linux and Windows (Wine) reached 'boot: main scene ready'. Measured UI results and logs accompany this build. Report's legacy Naive slot labels do not describe the actual bots: the harness uses the game's sole bot strength.
Not checked: depth-bar UI run, full bench on this source, real device, sounds by ear. Nobody has heard the sounds.
Known: Burner remains provisional and bot-tuned. Bot strength is unchanged from build 5. Small-Bird flights (Old Tern and One Swallow) beside larger buffed Birds remain human-play watch items. These checks do not establish balance or strategic depth.
How to play and what changed: docs/ideation/PLAYTEST.md on ideation/main, or How to play in the game's menu.
README
[ -s "$out/Bramble-windows.zip" ]
[ -s "$out/Bramble.apk" ]
grep -q '^Ideation build 6: ' "$out/README.txt"
ln -sfn "$out" /data/bramble-builds/latest
readlink /data/bramble-builds/latest
[ "$(readlink /data/bramble-builds/latest)" = "$out" ]
