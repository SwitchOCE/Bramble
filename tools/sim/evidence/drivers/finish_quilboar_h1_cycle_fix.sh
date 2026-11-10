#!/usr/bin/env bash
# Offline-only report watcher for the single B150/uncut100 rerun. Never starts Godot.
set -uo pipefail
source /opt/bramble/env.sh
cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." || exit 2
mkdir -p build/quilboar-h1-cycle-fix
for ((attempt=0; attempt<180; attempt++)); do
  state=$(python3 - <<'PY'
import json
from pathlib import Path
path = Path('build/quilboar-h1-cycle-fix/run/progress.json')
print(json.loads(path.read_text()).get('state', '') if path.exists() else '')
PY
)
  if [[ "$state" == complete ]]; then
    python3 tools/sim/quilboar_h1_rerun_report.py \
      --folder build/quilboar-h1-cycle-fix/run --out docs/ideation/reference/quilboar/h1 \
      > build/quilboar-h1-cycle-fix/report.log 2>&1
    status=$?
    echo "$status" > build/quilboar-h1-cycle-fix/report.exit
    exit "$status"
  fi
  if [[ "$state" == failed ]]; then
    echo simulation_failed > build/quilboar-h1-cycle-fix/report.exit
    exit 1
  fi
  sleep 20
done
echo timed_out > build/quilboar-h1-cycle-fix/report.exit
exit 124
