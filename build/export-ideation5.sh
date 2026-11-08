#!/usr/bin/env bash
set -euo pipefail
cd /home/alex/code/Bramble-ideation
source /opt/bramble/env.sh
export XDG_DATA_HOME=/tmp/bramble5-data XDG_CONFIG_HOME=/tmp/bramble5-config LP_NUM_THREADS=1
mkdir -p "$XDG_DATA_HOME/godot/export_templates" "$XDG_DATA_HOME/godot/keystores"
cp /opt/godot-data/godot/keystores/debug.keystore "$XDG_DATA_HOME/godot/keystores/debug.keystore"
if [ ! -e "$XDG_DATA_HOME/godot/export_templates/4.7.2.stable" ]; then
  ln -s /opt/godot-data/godot/export_templates/4.7.2.stable "$XDG_DATA_HOME/godot/export_templates/4.7.2.stable"
fi
[ "$(cat build/ideation5-checks.exit)" = 1 ]
[ "$(cat build/ideation5-ui-retry.exit)" = 0 ]
[ "$(cat build/ideation5-ui-validated.exit)" = 0 ]
grep -q 'check.sh: all steps passed' /tmp/bramble5-gate.log
source_commit="$(cat build/ideation5-source.txt)"
git diff --quiet "$source_commit" -- src tests content assets project.godot export_presets.cfg
rm -f build/ideation5-export.exit
out="/data/bramble-builds/$(date +%m%d-%H%M)-ideation5"
printf '%s\n' "$out" >build/ideation5-path.txt
REQUIRE_ANDROID=1 taskset -c 3 scripts/export_smoke.sh "$out"
cp /tmp/bramble5-import.log "$out/import.log"
cp /tmp/bramble5-gate.log "$out/gate.log"
cp /tmp/bramble5-ui.log "$out/ui.log"
cp build/ui-retry5/1688x780_1101.log "$out/ui-phone-retry.log"
cp docs/ideation/evidence/ui-run.md "$out/ui-report.md"
cp build/check/export_boot_linux.log "$out/linux-boot.log"
WINEPREFIX="$HOME/.wine-bramble" WINEDEBUG=-all taskset -c 3 timeout -k 5 150 xvfb-run -a wine "$out/windows/bramble.console.exe" --headless --quit-after 60 >"$out/windows-boot.log" 2>&1
grep -q '^boot: main scene ready' "$out/windows-boot.log"
grep -q '^boot: main scene ready' "$out/linux-boot.log"
(cd "$out" && zip -q Bramble-windows.zip windows/bramble.exe windows/bramble.pck)
cp "$out/android/bramble.apk" "$out/Bramble.apk"
python3 - "$out" <<'PY'
import sys, zipfile
from pathlib import Path
out=Path(sys.argv[1])
with zipfile.ZipFile(out/'Bramble-windows.zip') as z:
    assert set(z.namelist())=={'windows/bramble.exe','windows/bramble.pck'}
assert (out/'Bramble.apk').stat().st_size > 10_000_000
assert len(list(out.glob('*.files'))) == 3
PY
printf '0\n' >build/ideation5-export.exit
printf 'EXPORT5 PASSED %s\n' "$out"
