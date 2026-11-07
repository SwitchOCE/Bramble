#!/usr/bin/env bash
# Exact absolute hard deadline for an owned detached bench process group.
set -euo pipefail
OUT="$(realpath "$1")"
GROUP="$2"
[[ "$GROUP" =~ ^[0-9]+$ ]] || exit 2
started="$(date -u -d "$(cat "$OUT/started.utc")" +%s)"
remaining=$((started + 7200 - $(date -u +%s)))
if [ "$remaining" -gt 0 ]; then sleep "$remaining"; fi
# Verify ownership again before signaling: this is the timeout leader we launched.
command="$(ps -p "$GROUP" -o args= || true)"
if [[ "$command" == *"timeout --signal=TERM --kill-after=15s 7200 bash $OUT/job.sh $OUT"* ]]; then
  echo timeout:124 > "$OUT/status"
  date -u +%FT%TZ > "$OUT/finished.utc"
  kill -KILL -- "-$GROUP" 2>/dev/null || true
fi
