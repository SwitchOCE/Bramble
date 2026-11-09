#!/usr/bin/env bash
# Start detached (from repo root):
# systemd-run --user --collect --unit=bramble-quilboar-phase1-check \
#   -p WorkingDirectory="$PWD" bash tools/sim/evidence/drivers/run_quilboar_phase1_gate.sh
# This driver is reference-only. Its Godot subprocesses all share the gate lock and 3 GB scope.
set -uo pipefail
source /opt/bramble/env.sh
cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." || exit 2
mkdir -p build/quilboar
if [[ "${1:-}" != "--locked" ]]; then
  echo waiting_for_shared_lock > build/quilboar/gate.status
  flock /tmp/bramble-godot.lock systemd-run --user --scope -q -p MemoryMax=3G \
    timeout 1800 bash tools/sim/evidence/drivers/run_quilboar_phase1_gate.sh --locked
  status=$?
  echo "$status" > build/quilboar/gate.exit
  exit "$status"
fi
echo running > build/quilboar/gate.status
./scripts/check.sh --keep-going > build/quilboar/gate.log 2>&1
status=$?
echo "$status" > build/quilboar/gate.exit
echo finished > build/quilboar/gate.status
exit "$status"
