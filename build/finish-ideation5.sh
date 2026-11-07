#!/usr/bin/env bash
set -euo pipefail
cd /home/alex/code/Bramble-ideation
out="$(cat build/ideation5-path.txt)"
commit="$(git rev-parse HEAD)"
source_commit="$(cat build/ideation5-source.txt)"
[ "$(cat build/ideation5-checks.exit)" = 1 ]
[ "$(cat build/ideation5-ui-retry.exit)" = 0 ]
[ "$(cat build/ideation5-ui-validated.exit)" = 0 ]
[ "$(cat build/ideation5-export.exit)" = 0 ]
grep -qx 'boot: main scene ready' "$out/linux-boot.log"
grep -qx 'boot: main scene ready' "$out/windows-boot.log"
cat >"$out/README.txt" <<README
Ideation build 5: tribe commitment pays with Stand Behind Me, Bread from the Back, Harvest Supper, Hiring Fair and a visible tribe bonus; five tribes per lobby, one bot strength, Bird Eggs, the round toll and a picture guide.
Source: ideation/main at $source_commit (8c78def plus opening-name and waiting-hit-panel fixes and the guide-checker scope correction); delivery commit $commit. Game and tests unchanged from the checked source.

Windows: unzip Bramble-windows.zip, run windows/bramble.exe (keep bramble.pck next to it).
Android: install Bramble.apk (debug-signed; allow installing from unknown sources).
Linux: linux/bramble.x86_64

Checked: Godot headless import; all ten gate steps, 1,255/1,255 tests; short UI run (tests/ui/full_ui_run.sh 2 1000), 4 games at 1920x1080 and 1688x780 plus 2 forced late-game checks. Three games and both late checks passed; phone seed 1101 flagged three Ooze references in the whole-game guide when Oozes were absent from its lobby. Its full retry (hard 15-minute timeout) passed every original layout/action check after correcting guide vocabulary scope; original failed report retained. The harness uses the game's sole bot strength; legacy Naive slot labels in its report are not the actual lobby configuration. This is not a bot-strength benchmark. Normal engine clock, core 3 only, hard 40-minute UI timeout; original UI minimums retained. Required Android export, pack contents, archive and APK checks passed. Linux and Windows (Wine) booted to 'boot: main scene ready'.
Not checked: depth-bar UI run, full bench on this source, real device, sounds by ear. Nobody has heard the sounds.
Known: Burner is provisional and bot-tuned; judge its bank-versus-buy choice in human play. Watch small-Bird flights (Old Tern and One Swallow) beside larger buffed Birds. Easy and Normal were removed at the owner's request; there is one bot strength. These checks do not establish balance or strategic depth.
How to play and what changed: docs/ideation/PLAYTEST.md on ideation/main, or How to play in the game's menu.
README
ln -sfn "$out" /data/bramble-builds/latest
readlink /data/bramble-builds/latest
[ "$(readlink /data/bramble-builds/latest)" = "$out" ]
