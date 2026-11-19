#!/usr/bin/env bash
# Verify a local game record, or generate and replay seeded bot games (no network).
#   scripts/records.sh record=/path/game.jsonl
#   scripts/records.sh games=50 first_seed=1 plant=1 [directory=/local/folder]
#   scripts/records.sh games=25 ghost_store=/local/ghost-store [directory=/local/folder]
# plant=1 also changes one recorded action and requires a first-difference report at turn 2.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2
log="${RECORDS_LOG:-build/check/records.log}"
mkdir -p "$(dirname "$log")"
# shellcheck source=scripts/godot_log.sh
. scripts/godot_log.sh
godot_log_init "$(dirname "$log")"
timeout "${RECORDS_TIMEOUT:-1800}" "${GODOT:-godot}" --headless -s res://tools/checks/records.gd -- "$@" >"$log" 2>&1
status=$?
grep '^records:' "$log"
bad="$(godot_log_problems "$log")"
if [ -n "$bad" ]; then
  echo "$bad" | head -20
  status=1
fi
if ! grep -q '^records:' "$log"; then
  echo "records: run ended without a report"
  status=1
fi
echo "records: exit $status (log: $log)"
exit "$status"
