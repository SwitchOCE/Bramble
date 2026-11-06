#!/usr/bin/env bash
# The bench: seeded, reproducible full games; CSVs plus a readable report.
#   tools/sim/bench.sh [--cores N] [--out dir] [--report file] [--seed N] [--timeout s] [suite=games ...]
# With no suites it runs the Done-means set below. --cores defaults to 2 and may not make a run
# differ: seats and fights depend only on suite and seed. Raw CSVs go to build/sim/bench/.
# Suites: spread, plant, hard_naive, hard_easy, hard_normal, hard_lobby_normal, hard_lobby_hard,
# normal_easy, easy_naive, place_search, place_rule, place_shuffled, place_big, blind_alone,
# blind_lobby, blind_shuffled (tools/sim/bench_suites.gd).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
CORES=2
OUT="$ROOT/build/sim/bench"
REPORT="$ROOT/docs/ideation/evidence/bench-latest.md"
FIRST=1
LIMIT=3600
GODOT="${GODOT:-godot}"
SUITES=()
while [ $# -gt 0 ]; do
  case "$1" in
    --cores) CORES="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --report) REPORT="$2"; shift 2 ;;
    --seed) FIRST="$2"; shift 2 ;;
    --timeout) LIMIT="$2"; shift 2 ;;
    *=*) SUITES+=("$1"); shift ;;
    *) echo "bad argument: $1"; exit 2 ;;
  esac
done
if [ ${#SUITES[@]} -eq 0 ]; then
  SUITES=(spread=2000 plant=300 hard_naive=500 hard_easy=300 hard_normal=500 hard_lobby_normal=500
    hard_lobby_hard=500 normal_easy=500 easy_naive=300 place_search=500 place_rule=500
    place_shuffled=500 place_big=100 blind_alone=500 blind_lobby=500 blind_shuffled=500)
fi
mkdir -p "$OUT"
uptime
# A killed bench takes its shards with it.
stop_shards() {
  local running
  running="$(jobs -p)"
  [ -z "$running" ] || kill $running 2>/dev/null || true
}
trap stop_shards EXIT
trap 'exit 143' TERM INT

for entry in "${SUITES[@]}"; do
  suite="${entry%%=*}"
  games="${entry#*=}"
  per=$((games / CORES))
  pids=()
  for ((shard = 0; shard < CORES; shard++)); do
    count=$per
    [ "$shard" -eq $((CORES - 1)) ] && count=$((games - per * (CORES - 1)))
    timeout "$LIMIT" "$GODOT" --headless --path "$ROOT" -s res://tools/sim/bench.gd -- \
      suite="$suite" games="$count" first_seed=$((FIRST + per * shard)) \
      out="$OUT/.$suite.$shard" >"$OUT/.$suite.$shard.log" 2>&1 &
    pids+=($!)
  done
  for pid in "${pids[@]}"; do wait "$pid"; done
  for part in players rounds cards turns; do
    head -n 1 "$OUT/.$suite.0.$part.csv" >"$OUT/$suite.$part.csv"
    for ((shard = 0; shard < CORES; shard++)); do
      tail -n +2 "$OUT/.$suite.$shard.$part.csv" >>"$OUT/$suite.$part.csv"
    done
    rm -f "$OUT/.$suite".*."$part".csv
  done
  grep -h "bench:" "$OUT/.$suite".*.log || true
  if grep -lE "SCRIPT ERROR|^ERROR" "$OUT/.$suite".*.log; then
    echo "errors in the logs above"
    exit 1
  fi
  rm -f "$OUT/.$suite".*.log
  # The report says what code each suite last ran on, as a partial rerun mixes commits.
  echo "$(git rev-parse --short HEAD) $games" >"$OUT/$suite.stamp"
done
python3 "$ROOT/tools/sim/summarize_bench.py" "$OUT" "$REPORT"
