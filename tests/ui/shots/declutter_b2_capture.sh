#!/usr/bin/env bash
# Replay the serialized batch2 states through the current UI and capture native evidence.
# Usage: bash tests/ui/shots/declutter_b2_capture.sh [packet directory]
set -euo pipefail
source /opt/bramble/env.sh
runner_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$runner_root"
packet="${1:-$runner_root/docs/ideation/evidence/declutter/batch2}"
frames="$runner_root/build/declutter-b2/final-frames"
export LP_NUM_THREADS=1 GODOT_SLOT_CLASS=worker
export XDG_STATE_HOME=/tmp/declutter-b2-state
export XDG_CONFIG_HOME=/tmp/declutter-b2-config
export XDG_DATA_HOME=/tmp/declutter-b2-data
scripts/godot_slot.sh timeout 45 godot --headless --editor --import --quit
for dims in 1688x780 1920x1080; do
  scripts/godot_slot.sh timeout 90 xvfb-run -a -s '-screen 0 2560x1440x24' \
    godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 \
    -s res://tests/ui/shots/declutter_b2_stills.gd -- "$dims" after "$packet"
done
python3 tests/ui/shots/declutter_b2_report.py "$packet" --measure
scripts/godot_slot.sh timeout 90 xvfb-run -a -s '-screen 0 2560x1440x24' \
  godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 \
  -s res://tests/ui/shots/declutter_b2_frames.gd -- "$packet" "$frames"
python3 tests/ui/shots/declutter_b2_strips.py "$frames" "$packet/strips"
scripts/godot_slot.sh timeout 30 xvfb-run -a -s '-screen 0 2560x1440x24' \
  godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 \
  -s res://tests/ui/shots/declutter_b2_faces.gd -- "$packet"
revision="$(git rev-parse HEAD)"
python3 - "$packet" "$revision" <<'PY'
import json
import sys
from pathlib import Path
packet=Path(sys.argv[1])
for path in [*packet.joinpath('after').glob('manifest-*.json'),*packet.joinpath('strips').glob('*/manifest.json'),packet/'all-unit-board-faces.json',packet/'pairs.json']:
    document=json.loads(path.read_text())
    document['production_revision']=sys.argv[2]
    path.write_text(json.dumps(document,indent=2)+'\n')
PY
