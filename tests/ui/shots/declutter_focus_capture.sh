#!/usr/bin/env bash
# New isolated follow-up packet. Existing parent evidence is read-only.
# Usage: bash tests/ui/shots/declutter_focus_capture.sh <revision> [stills|motion|faces|all]
set -euo pipefail
source /opt/bramble/env.sh
runner_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$runner_root"
revision="$1"
stage="${2:-all}"
case "$stage" in stills|motion|faces|all) ;; *) exit 2 ;; esac
packet="$runner_root/docs/ideation/evidence/declutter/batch2/focus-followup"
frames="$runner_root/build/declutter-focus/frames"
mkdir -p "$runner_root/build/declutter-focus"
export LP_NUM_THREADS=1 GODOT_SLOT_CLASS=worker
export XDG_STATE_HOME=/tmp/declutter-focus-state
export XDG_CONFIG_HOME=/tmp/declutter-focus-config
export XDG_DATA_HOME=/tmp/declutter-focus-data
python3 tests/ui/shots/declutter_focus_report.py prepare "$packet"
if [ "$stage" = stills ] || [ "$stage" = all ]; then
  for dimensions in 1688x780 1920x1080; do
    scripts/godot_slot.sh timeout 90 xvfb-run -a -s '-screen 0 2560x1440x24' \
      godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 \
      -s res://tests/ui/shots/declutter_b2_stills.gd -- "$dimensions" after "$packet" \
      >"build/declutter-focus/stills-$dimensions.log" 2>&1
    if rg -q 'SCRIPT ERROR|ERROR:|Assertion failed' "build/declutter-focus/stills-$dimensions.log"; then exit 3; fi
  done
  python3 tests/ui/shots/declutter_focus_report.py stills "$packet" "$revision"
fi
if [ "$stage" = motion ] || [ "$stage" = all ]; then
  scripts/godot_slot.sh timeout 90 xvfb-run -a -s '-screen 0 2560x1440x24' \
    godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 \
    -s res://tests/ui/shots/declutter_focus_frames.gd -- "$packet" "$frames" \
    >build/declutter-focus/motion.log 2>&1
  if rg -q 'SCRIPT ERROR|ERROR:|Assertion failed' build/declutter-focus/motion.log; then exit 4; fi
  python3 tests/ui/shots/declutter_b2_strips.py "$frames" "$packet/strips"
fi
if [ "$stage" = faces ] || [ "$stage" = all ]; then
  scripts/godot_slot.sh timeout 45 xvfb-run -a -s '-screen 0 2560x1440x24' \
    godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 \
    -s res://tests/ui/shots/declutter_b2_faces.gd -- "$packet" >build/declutter-focus/faces.log 2>&1
  if rg -q 'SCRIPT ERROR|ERROR:|Assertion failed' build/declutter-focus/faces.log; then exit 5; fi
fi
python3 tests/ui/shots/declutter_focus_report.py verify "$packet"
