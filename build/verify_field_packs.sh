#!/usr/bin/env bash
# Negative controls against the actual dry-run Windows PCK and APK asset pack.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$(realpath "${1:?usage: build/verify_field_packs.sh <dry-run-folder>}")"
source /opt/bramble/env.sh
export XDG_DATA_HOME="$out/data" XDG_CONFIG_HOME="$out/config" XDG_CACHE_HOME="$out/cache" LP_NUM_THREADS=6
mkdir -p "$out/negative"
slot() { GODOT_SLOT_CLASS=worker "$ROOT/scripts/godot_slot.sh" "$@"; }
for listing in windows.files android_apk.files; do
  grep -qxF content/fields/baseline.json.gz "$out/$listing"
done
python3 - "$out" <<'PY'
import sys, zipfile
from pathlib import Path
out = Path(sys.argv[1])
with zipfile.ZipFile(out / 'android-assets.zip') as source, zipfile.ZipFile(out / 'negative/android-without-field.zip', 'w') as target:
    for entry in source.infolist():
        if entry.filename != 'content/fields/baseline.json.gz':
            target.writestr(entry, source.read(entry))
    assert 'content/fields/baseline.json.gz' not in target.namelist()
PY
slot timeout 120 godot --headless --main-pack "$out/windows/bramble.pck" \
  -s "$ROOT/tools/sim/strip_field_pack.gd" -- "$out/windows.files" "$out/negative/windows-without-field.pck" \
  >"$out/negative/strip-windows.log" 2>&1
for pack in android-without-field.zip windows-without-field.pck; do
  set +e
  slot timeout 120 godot --headless --main-pack "$out/negative/$pack" \
    -s "$out/project/tools/sim/export_field_probe.gd" >"$out/negative/$pack.log" 2>&1
  status=$?
  set -e
  [ "$status" = 1 ]
  grep -qxF 'export-field: Field library does not exist: res://content/fields/baseline.json.gz' "$out/negative/$pack.log"
  if grep -q 'export-field: loaded' "$out/negative/$pack.log"; then exit 1; fi
  printf '%s: missing library rejected with exit 1\n' "$pack"
done
