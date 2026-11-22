#!/usr/bin/env bash
# The first stopping tests: reference field, then red's test, then blue's. Detached; log in chain.log.
set -uo pipefail
lg=/data/third-run/referee-tree/tools/league
ref=/data/third-run/ref-1
log=/data/third-run/stopping/chain.log
echo "$(date +%F' '%T) chain start" >> "$log"
if [[ ! -s $ref/index.jsonl ]]; then
  flock /data/third-run/cores.lock "$lg/ref_field.sh" red-c10 blue-c13 "$ref" 1500 >> "$log" 2>&1 \
    || { echo "$(date +%T) ref_field FAILED" >> "$log"; exit 1; }
fi
echo "$(date +%F' '%T) red test start" >> "$log"
FIELD=$ref BASE_KNOBS="sell_dead 0" "$lg/stop_test.sh" red red-c13 /data/third-run/stopping/red-1 >> "$log" 2>&1
echo "$(date +%F' '%T) blue test start" >> "$log"
FIELD=$ref BASE_KNOBS="" "$lg/stop_test.sh" blue d6d25427 /data/third-run/stopping/blue-1 >> "$log" 2>&1
echo "$(date +%F' '%T) chain done" >> "$log"
