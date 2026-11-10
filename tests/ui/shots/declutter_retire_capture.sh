#!/usr/bin/env bash
# Nine after-only sheets. Both isolated cleanup timing heads must already exist.
# Usage: bash tests/ui/shots/declutter_retire_capture.sh <source revision> [packet directory]
set -euo pipefail
source /opt/bramble/env.sh
runner_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$runner_root"
revision="$1"
packet="${2:-$runner_root/docs/ideation/evidence/declutter/batch1/strips/uniform-plus-peaks}"
mkdir -p "$packet"
for baseline in before-timings.json after-cleanup-timings.json; do
  if [ ! -f "$packet/$baseline" ]; then
    cp "$runner_root/docs/ideation/evidence/declutter/batch1/strips/cue-retirement/$baseline" "$packet/$baseline"
  fi
done
export LP_NUM_THREADS=1 GODOT_SLOT_CLASS=worker
export XDG_STATE_HOME=/tmp/declutter-retire-state
export XDG_CONFIG_HOME=/tmp/declutter-retire-config
export XDG_DATA_HOME=/tmp/declutter-retire-data
mkdir -p "$runner_root/build/declutter-retire"
capture_log="$runner_root/build/declutter-retire/uniform-capture.log"
scripts/godot_slot.sh timeout 90 xvfb-run -a -s '-screen 0 2560x1440x24' \
  godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 \
  -s res://tests/ui/shots/declutter_retire_frames.gd -- after "$packet" "$revision" >"$capture_log" 2>&1
cat "$capture_log"
if rg -q 'SCRIPT ERROR|ERROR:|Assertion failed' "$capture_log"; then exit 3; fi
python3 tests/ui/shots/declutter_retire_report.py "$packet" \
  "$runner_root/build/declutter-retire/after-frames" "$revision"
