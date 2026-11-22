#!/usr/bin/env bash
# Red's second stopping test, on red-c14 (commit 4b9d95cd), with its own reference field cut from
# red-c14 and blue-c13. Matches take turns with blue's test under the cores lock. Log in chain.log.
set -uo pipefail
lg=/data/third-run/referee-tree/tools/league
ref=/data/third-run/ref-2
log=/data/third-run/stopping/chain.log
echo "$(date +%F' '%T) red-2 chain start" >> "$log"
if [[ ! -s $ref/index.jsonl ]]; then
  flock /data/third-run/cores.lock "$lg/ref_field.sh" red-c14 blue-c13 "$ref" 1500 >> "$log" 2>&1 \
    || { echo "$(date +%T) ref_field (ref-2) FAILED" >> "$log"; exit 1; }
fi
echo "$(date +%F' '%T) red-2 test start" >> "$log"
FIELD=$ref BASE_KNOBS="" "$lg/stop_test.sh" red 4b9d95cd /data/third-run/stopping/red-2 >> "$log" 2>&1
echo "$(date +%F' '%T) red-2 test done" >> "$log"
