#!/usr/bin/env bash
# Rebuild local alpha sources, sixteen stills, tap-reader studies and the comparison sheet.
# This writes only build/. Publishing the requested gallery directory is a separate copy.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/tmp/bramble-layout-config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-/tmp/bramble-layout-data}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-/tmp/bramble-layout-state}"
export LP_NUM_THREADS=1
export GODOT_SLOT_CLASS=worker
godot_bin="${GODOT:-godot}"
mkdir -p build/layout-parts/recruit build/layout-parts/fight build/layouts
if [ "${1:-}" != --reuse-captures ]; then
scripts/godot_slot.sh "$godot_bin" --headless --editor --path . --import --quit >build/layouts/import.log 2>&1
for group in recruit fight; do
  state=recruit_late
  [ "$group" != fight ] || state=combat_mid
  scripts/godot_slot.sh timeout 120 xvfb-run -a "$godot_bin" --path . --rendering-driver opengl3 \
    --audio-driver Dummy -s res://tools/mockup/capture_parts.gd -- \
    "$state" 1920x1080 "build/layout-parts/$group" >"build/layouts/capture-$group.log" 2>&1
  if rg 'SCRIPT ERROR|^ERROR|Parse Error' "build/layouts/capture-$group.log" | rg -v 'resources still in use at exit'; then
    exit 1
  fi
done
fi
python3 tools/mockup/layouts.py
for size in 1920x1080 1688x780; do
  export LAYOUT_PLAN="$(realpath "build/layouts/woodland-table/recruit_$size.json")"
  export LAYOUT_ASSETS="$(realpath build/layout-parts)"
  scripts/godot_slot.sh timeout 120 xvfb-run -a "$godot_bin" --path . --rendering-driver opengl3 \
    --audio-driver Dummy -s res://tools/mockup/render_table.gd -- \
    recruit_late "$size" "build/layouts/woodland-table/recruit_$size.png" >"build/layouts/live-$size.log" 2>&1
  if rg 'SCRIPT ERROR|^ERROR|Parse Error' "build/layouts/live-$size.log"; then exit 1; fi
done
python3 tools/mockup/layouts.py --finalize
cp docs/ideation/ui/layouts.md build/layouts/notes.md
python3 tools/mockup/verify.py
