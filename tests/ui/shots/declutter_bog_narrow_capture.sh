#!/usr/bin/env bash
# Only the requested rival Pounce and combat Mire-wait repair moments.
set -euo pipefail
source /opt/bramble/env.sh
export LP_NUM_THREADS=1 GODOT_SLOT_CLASS=worker
export XDG_STATE_HOME=/tmp/declutter-bog-state
export XDG_CONFIG_HOME=/tmp/declutter-bog-config
export XDG_DATA_HOME=/tmp/declutter-bog-data
frames="$1"
packet="$2"
for selected in rival-fight:25,33 combat_mid:45; do
  scenario="${selected%:*}"
  attack="${selected#*:}"
  scripts/godot_slot.sh timeout 240 xvfb-run -a -s '-screen 0 2560x1440x24' \
    godot --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 120 \
    -s res://tests/ui/shots/declutter_bog_narrow_frames.gd -- \
    res://docs/ideation/evidence/declutter/batch1/before "$frames" "$scenario" "$attack"
done
python3 tests/ui/shots/declutter_strips.py "$frames" "$packet"
revision="$(git rev-parse HEAD)"
python3 - "$packet" "$revision" <<'PY'
import hashlib
import json
import sys
from pathlib import Path
packet = Path(sys.argv[1])
revision = sys.argv[2]
summary = []
for path in sorted(packet.glob('*/manifest.json')):
    manifest = json.loads(path.read_text())
    fixture = Path('docs/ideation/evidence/declutter/batch1/before') / (manifest['scenario'] + '_1688x780.json')
    source = json.loads(fixture.read_text())
    assert manifest['events'] == source['combat']['events']
    assert manifest['timing_passes_equal']
    required = 25 if manifest['scenario'] == 'rival-fight' else 45
    for interval in manifest['attacks']:
        interval['requested_repair_moment'] = interval['event_index'] == required
        interval['adjacent_context'] = interval['event_index'] == 33
        if interval['event_index'] == 33:
            interval['context_reason'] = 'Pounce declaration event32 in required attack025 is followed by the actual Pounce attack033; this adjacent sheet makes its lunge visible.'
    manifest.update(production_revision=revision, original_fixture=str(fixture), original_fixture_sha256=hashlib.sha256(fixture.read_bytes()).hexdigest(), same_original_event_stream=True)
    path.write_text(json.dumps(manifest, indent=2) + '\n')
    summary.append(dict(run=path.parent.name, production_revision=revision, requested_attack=required, included_attacks=[i['event_index'] for i in manifest['attacks']], same_original_event_stream=True, timing_passes_equal=True))
assert len(summary) == 4
(packet / 'provenance.json').write_text(json.dumps(summary, indent=2) + '\n')
print('All four requested narrow runs preserve exact original events and within-head fixed-tick replay')
PY
