#!/usr/bin/env bash
# Blue's second stopping test, on blue-c17, with its own reference field cut from red-c14 and
# blue-c17. Matches take turns with red's test under the cores lock. Log in chain.log.
set -uo pipefail
lg=/data/third-run/referee-tree/tools/league
ref=/data/third-run/ref-3
log=/data/third-run/stopping/chain.log
echo "$(date +%F' '%T) blue-2 chain start" >> "$log"
if [[ ! -s $ref/index.jsonl ]]; then
  flock /data/third-run/cores.lock "$lg/ref_field.sh" red-c14 blue-c17 "$ref" 1500 >> "$log" 2>&1 \
    || { echo "$(date +%T) ref_field (ref-3) FAILED" >> "$log"; exit 1; }
fi
echo "$(date +%F' '%T) blue-2 test start" >> "$log"
FIELD=$ref BASE_KNOBS="" "$lg/stop_test.sh" blue blue-c17 /data/third-run/stopping/blue-2 >> "$log" 2>&1
echo "$(date +%F' '%T) blue-2 test done" >> "$log"
