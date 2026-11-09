#!/usr/bin/env bash
# Fixed budget: first 320 eligible seeds from the original 640, reused for both caps settings.
set -euo pipefail
source /opt/bramble/env.sh
BASELINE_SOURCE_COMMIT="f9c924b9"
BASELINE_ROOT="$(git rev-parse --show-toplevel)"
BASELINE_OUTPUT="$BASELINE_ROOT/build/sim/wave1-shipped-baseline"
for baseline_preset in shipped checkpoint; do
  python3 tools/sim/wave1_baseline.py prepare --source-tree "$BASELINE_ROOT" \
    --commit "$BASELINE_SOURCE_COMMIT" --preset "$baseline_preset" \
    --output "$BASELINE_OUTPUT/$baseline_preset" --max-lobbies 320
 done
python3 - <<'PY'
import json
from pathlib import Path
root = Path('build/sim/wave1-shipped-baseline')
a = json.loads((root/'shipped/plan.json').read_text())
b = json.loads((root/'checkpoint/plan.json').read_text())
assert a['seeds'] == b['seeds'], 'cap settings must use identical eligible seeds'
assert a['rates'] == b['rates'], 'Bird and Fairy dials must remain unchanged'
assert len(a['seeds']) == 320
(root/'paired-plan-summary.json').write_text(json.dumps({'lobbies_per_setting':320, 'source_commit':a['source_commit'], 'eligible_candidates':len(a['seeds'])+len(a['unused_eligible_seeds']), 'selected_seeds':a['seeds'], 'settings':['shipped','checkpoint'], 'budget':'Historical 2.65s/lobby projects 14.1min per setting, below the 30min per-setting ceiling; fixed before outcomes, reserving shared-lock/gate time.'},indent=2)+'\n')
PY
for baseline_preset in shipped checkpoint; do
  python3 tools/sim/wave1_baseline.py run --plan "$BASELINE_OUTPUT/$baseline_preset/plan.json"
  python3 tools/sim/wave1_baseline.py report --plan "$BASELINE_OUTPUT/$baseline_preset/plan.json" \
    --out "tools/sim/evidence/wave1-baseline-$baseline_preset.json" \
    --markdown "docs/ideation/evidence/wave1-baseline-$baseline_preset.md"
done
printf 'complete\n' > "$BASELINE_OUTPUT/job.complete"
python3 tools/sim/wave1_baseline_compare.py
printf 'complete\n' > "$BASELINE_OUTPUT/comparison.complete"
