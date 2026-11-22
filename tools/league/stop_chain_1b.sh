#!/usr/bin/env bash
# Blue's first stopping test, after red-c10's was stopped (red-c14 kept). Detached; log in chain.log.
set -uo pipefail
lg=/data/third-run/referee-tree/tools/league
log=/data/third-run/stopping/chain.log
echo "$(date +%F' '%T) blue test start" >> "$log"
FIELD=/data/third-run/ref-1 BASE_KNOBS="" "$lg/stop_test.sh" blue d6d25427 /data/third-run/stopping/blue-1 >> "$log" 2>&1
echo "$(date +%F' '%T) blue test done" >> "$log"
