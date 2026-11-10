#!/usr/bin/env bash
# Fresh neutral recruit packet; older evidence remains read-only.
set -euo pipefail
source /opt/bramble/env.sh
capture_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$capture_root"
revision="$1"
packet="$capture_root/docs/ideation/evidence/declutter/batch2/cold-recruit"
raw="$capture_root/build/declutter-cold/frames"
mkdir -p "$packet/reader" "$packet/technical" build/declutter-cold
export LP_NUM_THREADS=1 GODOT_SLOT_CLASS=worker
export XDG_STATE_HOME=/tmp/declutter-cold-state
export XDG_CONFIG_HOME=/tmp/declutter-cold-config
export XDG_DATA_HOME=/tmp/declutter-cold-data
scripts/godot_slot.sh timeout 180 xvfb-run -a -s '-screen 0 2560x1440x24' \
  godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 \
  -s res://tests/ui/shots/declutter_cold_frames.gd -- "$packet" "$raw" "$revision" \
  >build/declutter-cold/frames.log 2>&1
if rg -q 'SCRIPT ERROR|ERROR:|Assertion failed' build/declutter-cold/frames.log; then exit 3; fi
python3 tests/ui/shots/declutter_cold_report.py assemble "$packet" "$revision" --raw "$raw"
scripts/godot_slot.sh timeout 60 xvfb-run -a -s '-screen 0 2560x1440x24' \
  godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 \
  -s res://tests/ui/shots/declutter_b2_faces.gd -- "$packet/technical" \
  >build/declutter-cold/faces.log 2>&1
if rg -q 'SCRIPT ERROR|ERROR:|Assertion failed' build/declutter-cold/faces.log; then exit 4; fi
python3 tests/ui/shots/declutter_cold_report.py faces "$packet" "$revision"
