#!/usr/bin/env bash
# Nine after-only sheets. Both isolated cleanup timing heads must already exist.
# Usage: bash tests/ui/shots/declutter_retire_capture.sh <source revision> [packet directory]
set -euo pipefail
source /opt/bramble/env.sh
runner_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$runner_root"
revision="$1"
packet="${2:-$runner_root/docs/ideation/evidence/declutter/batch1/strips/cue-retirement}"
test -f "$packet/before-timings.json"
test -f "$packet/after-cleanup-timings.json"
export LP_NUM_THREADS=1 GODOT_SLOT_CLASS=worker
export XDG_STATE_HOME=/tmp/declutter-retire-state
export XDG_CONFIG_HOME=/tmp/declutter-retire-config
export XDG_DATA_HOME=/tmp/declutter-retire-data
scripts/godot_slot.sh timeout 90 xvfb-run -a -s '-screen 0 2560x1440x24' \
  godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 \
  -s res://tests/ui/shots/declutter_retire_frames.gd -- after "$packet" "$revision"
python3 tests/ui/shots/declutter_retire_report.py "$packet" \
  "$runner_root/build/declutter-retire/after-frames" "$revision"
