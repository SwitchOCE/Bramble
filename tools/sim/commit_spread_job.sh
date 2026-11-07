#!/usr/bin/env bash
# Detached job body. Run under: timeout --kill-after=15s 7200 bash this-file OUT
# OUT/snapshot is a git archive of b872a6b with measurement-only commit_spread.gd added.
set -euo pipefail
OUT="$(realpath "$1")"
ROOT="$OUT/snapshot"
export XDG_DATA_HOME="$OUT/user-data" XDG_CONFIG_HOME="$OUT/user-config"
export LP_NUM_THREADS=1 OMP_NUM_THREADS=1
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
date -u +%FT%TZ > "$OUT/started.utc"
echo running > "$OUT/status"
pids=()
cleanup() {
  local status=$?
  trap - EXIT
  for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null || true; done
  if [ "$status" -ne 0 ]; then echo "failed:$status" > "$OUT/status"; fi
  date -u +%FT%TZ > "$OUT/finished.utc"
  exit "$status"
}
trap cleanup EXIT
trap 'exit 124' TERM INT
for shard in 0 1; do
  taskset -c "$shard" godot --headless --path "$ROOT" -s res://tools/sim/commit_spread.gd -- \
    suite=spread games=500 first_seed=$((61000 + shard * 500)) out="$OUT/shard-$shard" \
    > "$OUT/shard-$shard.log" 2>&1 &
  pids+=("$!")
done
printf '%s\n' "${pids[@]}" > "$OUT/shards.pid"
for pid in "${pids[@]}"; do wait "$pid"; done
if rg -n 'SCRIPT ERROR|^ERROR:|Assertion failed' "$OUT"/shard-*.log; then exit 1; fi
for part in players rounds cards turns; do
  head -n 1 "$OUT/shard-0.$part.csv" > "$OUT/spread.$part.csv"
  for shard in 0 1; do tail -n +2 "$OUT/shard-$shard.$part.csv" >> "$OUT/spread.$part.csv"; done
done
python3 "$ROOT/tools/sim/summarize_bench.py" "$OUT" "$OUT/stock-report.md"
python3 "$ROOT/tools/sim/summarize_commit_spread.py" "$OUT"
echo complete > "$OUT/status"
