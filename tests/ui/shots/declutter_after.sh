#!/usr/bin/env bash
# Run inside the Godot-slot/systemd scope; each Godot process finishes before the next starts.
set -euo pipefail
SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$SOURCE"
OUT="${1:-$SOURCE/docs/ideation/evidence/declutter/batch1}"
export LP_NUM_THREADS=1
mkdir -p build/declutter "$OUT/after" "$OUT/strips"
timeout 180 godot --headless -s res://tools/checks/compile_all.gd \
  >build/declutter/evidence-compile.log 2>&1
timeout 180 xvfb-run -a -s '-screen 0 2560x1440x24' godot --rendering-driver opengl3 \
  --audio-driver Dummy --fixed-fps 120 -s res://tests/ui/shots/declutter_stills.gd \
  -- "$OUT/before" "$OUT/after" >build/declutter/after.log 2>&1
timeout 600 xvfb-run -a -s '-screen 0 2560x1440x24' godot --rendering-driver opengl3 \
  --audio-driver Dummy --fixed-fps 120 -s res://tests/ui/shots/declutter_frames.gd \
  -- "$OUT/before" res://build/declutter/frames >build/declutter/frames.log 2>&1
/usr/bin/python3 tests/ui/shots/declutter_strips.py build/declutter/frames "$OUT/strips" \
  >build/declutter/strips.log 2>&1
echo 'declutter: after pairs and strips complete'
