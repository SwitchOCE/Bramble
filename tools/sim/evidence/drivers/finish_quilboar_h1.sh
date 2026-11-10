#!/usr/bin/env bash
# Offline-only completion watcher. It never starts Godot or takes a Godot lock.
set -uo pipefail
source /opt/bramble/env.sh
cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." || exit 2
mkdir -p build/quilboar-h1
for ((attempt=0; attempt<240; attempt++)); do
  state=$(python3 - <<'PY'
import json
from pathlib import Path
path = Path('build/quilboar-h1/run/progress.json')
print(json.loads(path.read_text()).get('state', '') if path.exists() else '')
PY
)
  if [[ "$state" == complete ]]; then
    python3 tools/sim/quilboar_h1.py report --folder build/quilboar-h1/run \
      --out docs/ideation/reference/quilboar/h1 > build/quilboar-h1/report.log 2>&1
    status=$?
    echo "$status" > build/quilboar-h1/report.exit
    exit "$status"
  fi
  if [[ "$state" == failed ]]; then
    echo simulation_failed > build/quilboar-h1/report.exit
    exit 1
  fi
  sleep 30
done
echo timed_out > build/quilboar-h1/report.exit
exit 124
