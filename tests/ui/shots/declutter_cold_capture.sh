#!/usr/bin/env bash
# Fresh neutral recruit packet; older evidence remains read-only.
# Run detached by the caller; logs and slot history remain in this packet's build directory.
set -euo pipefail
source /opt/bramble/env.sh
capture_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$capture_root"
revision="${1:?usage: declutter_cold_capture.sh REVISION [packet-name]}"
packet_name="${2:-cold-recruit-followup}"
[[ "$packet_name" =~ ^[a-zA-Z0-9_-]+$ ]] || exit 2
packet="$capture_root/docs/ideation/evidence/declutter/batch2/$packet_name"
build_root="$capture_root/build/$packet_name"
raw="$build_root/frames"
mkdir -p "$packet/reader" "$packet/technical" "$build_root"
export LP_NUM_THREADS=1 GODOT_SLOT_CLASS=worker
export XDG_STATE_HOME="/tmp/$packet_name-state"
export XDG_CONFIG_HOME="/tmp/$packet_name-config"
export XDG_DATA_HOME="/tmp/$packet_name-data"
scripts/godot_slot.sh timeout 360 xvfb-run -a -s '-screen 0 2560x1440x24' \
  godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 \
  -s res://tests/ui/shots/declutter_cold_frames.gd -- "$packet" "$raw" "$revision" \
  >"$build_root/frames.log" 2>&1
if rg -q 'SCRIPT ERROR|ERROR:|Assertion failed' "$build_root/frames.log"; then exit 3; fi
python3 tests/ui/shots/declutter_cold_report.py assemble "$packet" "$revision" --raw "$raw"
scripts/godot_slot.sh timeout 90 xvfb-run -a -s '-screen 0 2560x1440x24' \
  godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 \
  -s res://tests/ui/shots/declutter_b2_faces.gd -- "$packet/technical" \
  >"$build_root/faces.log" 2>&1
if rg -q 'SCRIPT ERROR|ERROR:|Assertion failed' "$build_root/faces.log"; then exit 4; fi
python3 tests/ui/shots/declutter_cold_report.py faces "$packet" "$revision"
python3 tests/ui/shots/declutter_cold_report.py history "$packet" "$revision" \
  --slot-log "$XDG_STATE_HOME/bramble/godot-slots.csv"
