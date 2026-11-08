#!/usr/bin/env bash
set -euo pipefail
cd /home/alex/code/Bramble-ideation
# shellcheck source=/opt/bramble/env.sh
source /opt/bramble/env.sh
export XDG_DATA_HOME=/tmp/bramble7-data XDG_CONFIG_HOME=/tmp/bramble7-config LP_NUM_THREADS=6
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
rm -f build/ideation7-checks.exit build/ideation7-ui-validated.exit build/ideation7-export.exit
trap 'printf "%s\n" "$?" >build/ideation7-checks.exit' EXIT
timeout -k 5 600 godot --headless --import >/tmp/bramble7-import.log 2>&1
timeout -k 5 900 scripts/check.sh >/tmp/bramble7-gate.log 2>&1
timeout -k 5 2400 tests/ui/full_ui_run.sh 2 1000 >/tmp/bramble7-ui.log 2>&1
