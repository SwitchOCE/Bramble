#!/usr/bin/env bash
# Run through scripts/godot_slot.sh; captures both physical window shapes from live core state.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../../.."
export LP_NUM_THREADS="${LP_NUM_THREADS:-2}"
out=build/loop1/arena
mkdir -p "$out"
for dimensions in 1920x1080 1688x780; do
  for state in recruit_empty recruit_full recruit_max reader scouting fight; do
    timeout 90 xvfb-run -a -s '-screen 0 2560x1440x24' godot \
      --rendering-driver opengl3 --audio-driver Dummy \
      -s res://tests/ui/shots/arena_capture.gd -- "$state" "$dimensions" \
      "$out/$state-$dimensions.png" >"$out/$state-$dimensions.log" 2>&1
    if rg -q 'SCRIPT ERROR|^ERROR:' "$out/$state-$dimensions.log"; then
      cat "$out/$state-$dimensions.log"
      exit 1
    fi
    echo "rendered $state $dimensions"
  done
done
