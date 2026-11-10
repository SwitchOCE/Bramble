#!/usr/bin/env bash
# Detached targeted check: systemd-run --user --collect --unit=bramble-quilboar-h1-checks \
#   -p WorkingDirectory="$PWD" bash tools/sim/evidence/drivers/run_quilboar_h1_checks.sh
set -uo pipefail
source /opt/bramble/env.sh
cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." || exit 2
mkdir -p build/quilboar-h1/checks
if [[ "${1:-}" != --locked ]]; then
  /tmp/bramble-godot-slot systemd-run --user --scope -q -p MemoryMax=3G \
    timeout 300 bash tools/sim/evidence/drivers/run_quilboar_h1_checks.sh --locked
  status=$?
  echo "$status" > build/quilboar-h1/checks/exit
  exit "$status"
fi
source scripts/godot_log.sh
godot_log_init build/quilboar-h1/checks
timeout 90 godot --headless --import > build/quilboar-h1/checks/import.log 2>&1
status=$?
problems="$(godot_log_problems build/quilboar-h1/checks/import.log)"
if [[ "$status" != 0 || -n "$problems" ]]; then
  echo "$problems"
  exit 1
fi
timeout 180 godot --headless -s addons/gut/gut_cmdln.gd -gdir= \
  -gtest=res://tests/core/test_quilboar.gd,res://tests/core/test_quilboar_bot.gd,res://tests/core/test_quilboar_combat.gd,res://tests/core/test_quilboar_content.gd,res://tests/core/test_quilboar_isolation.gd,res://tests/core/test_quilboar_h1_switches.gd,res://tests/core/test_quilboar_h1_suite.gd \
  -gexit > build/quilboar-h1/checks/gut.log 2>&1
status=$?
problems="$(godot_log_problems build/quilboar-h1/checks/gut.log)"
if [[ "$status" != 0 || -n "$problems" ]] || ! grep -q 'gut_strict: ok' build/quilboar-h1/checks/gut.log; then
  echo "$problems"
  exit 1
fi
exit 0
