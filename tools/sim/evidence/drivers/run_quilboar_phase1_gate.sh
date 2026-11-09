#!/usr/bin/env bash
# Start detached (from repo root); append 'focused' to run just the reference tests:
# systemd-run --user --collect --unit=bramble-quilboar-phase1-check \
#   -p WorkingDirectory="$PWD" bash tools/sim/evidence/drivers/run_quilboar_phase1_gate.sh
# This driver is reference-only. Its Godot subprocesses share the gate lock and 3 GB scope.
set -uo pipefail
source /opt/bramble/env.sh
cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." || exit 2
mkdir -p build/quilboar
mode="${2:-${1:-gate}}"
if [[ "${1:-}" != "--locked" ]]; then
  echo waiting_for_shared_lock > "build/quilboar/$mode.status"
  flock /tmp/bramble-godot.lock systemd-run --user --scope -q -p MemoryMax=3G \
    timeout 1800 bash tools/sim/evidence/drivers/run_quilboar_phase1_gate.sh --locked "$mode"
  status=$?
  echo "$status" > "build/quilboar/$mode.exit"
  exit "$status"
fi
echo running > "build/quilboar/$mode.status"
if [[ "$mode" == focused ]]; then
  timeout 180 godot --headless -s addons/gut/gut_cmdln.gd -gdir= \
    -gtest=res://tests/core/test_quilboar.gd,res://tests/core/test_quilboar_bot.gd,res://tests/core/test_quilboar_combat.gd,res://tests/core/test_quilboar_content.gd,res://tests/core/test_quilboar_isolation.gd \
    -gexit > build/quilboar/focused.log 2>&1
  status=$?
else
  ./scripts/check.sh > build/quilboar/gate.log 2>&1
  status=$?
fi
echo "$status" > "build/quilboar/$mode.exit"
echo finished > "build/quilboar/$mode.status"
exit "$status"
