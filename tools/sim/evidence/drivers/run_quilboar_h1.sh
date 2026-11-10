#!/usr/bin/env bash
# Detached controller: systemd-run --user --collect --unit=bramble-quilboar-h1 \
#   -p WorkingDirectory="$PWD" bash tools/sim/evidence/drivers/run_quilboar_h1.sh smoke
# Sims acquire only /tmp/bramble-harness-godot.lock. Run mode resumes completed chunks.
set -uo pipefail
source /opt/bramble/env.sh
cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." || exit 2
mode="${1:-smoke}"
shift || true
mkdir -p build/quilboar-h1
python3 tools/sim/quilboar_h1.py "$mode" "$@" > "build/quilboar-h1/$mode.log" 2>&1
status=$?
echo "$status" > "build/quilboar-h1/$mode.exit"
exit "$status"
