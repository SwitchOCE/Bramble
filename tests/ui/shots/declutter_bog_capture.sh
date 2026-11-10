#!/usr/bin/env bash
# One process at a time. Caller supplies either an isolated d400831e project or the after tree.
# Usage: bash tests/ui/shots/declutter_bog_capture.sh before|after <project> <packet> <frames> <revision>
set -euo pipefail
phase="$1"
project="$2"
packet="$3"
frames="$4"
revision="$5"
case "$phase" in before|after) ;; *) exit 2 ;; esac
runner_root="$(cd "$(dirname "$0")/../../.." && pwd)"
source /opt/bramble/env.sh
export LP_NUM_THREADS=1 GODOT_SLOT_CLASS=worker
export XDG_STATE_HOME=/tmp/declutter-bog-state
export XDG_CONFIG_HOME=/tmp/declutter-bog-config
export XDG_DATA_HOME=/tmp/declutter-bog-data
cd "$project"
if [ "$phase" = before ] && [ ! -f "$packet/fixture/bog_1688x780.json" ]; then
  scripts/godot_slot.sh timeout 60 godot --headless \
    -s res://tests/ui/shots/declutter_bog_fixture.gd -- "$packet/fixture"
fi
scripts/godot_slot.sh timeout 240 xvfb-run -a -s '-screen 0 2560x1440x24' \
  godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 \
  -s res://tests/ui/shots/declutter_bog_frames.gd -- "$packet/fixture" "$frames"
cd "$runner_root"
compare=()
if [ "$phase" = after ]; then compare=(--compare); fi
python3 tests/ui/shots/declutter_bog_strips.py "$frames" "$packet/$phase" \
  "$packet/fixture/bog_1688x780.json" --revision "$revision" "${compare[@]}"
