#!/usr/bin/env bash
# The bench: seeded, reproducible full games; CSVs plus a readable report.
#   tools/sim/bench.sh [--cores N] [--out dir] [--report file] [--seed N] [--timeout s] [suite=games ...]
# With no suites it runs the Done-means set below. --cores defaults to 2 and may not make a run
# differ: seats and fights depend only on suite and seed. Raw CSVs go to build/sim/bench/.
# Head-to-head: --candidate hard --incumbent hard head_to_head=200 means 200 pairs / 400 games.
# Suites: head_to_head, spread, plant, hard_naive, hard_lobby_hard, place_search, place_rule,
# place_shuffled, place_big, blind_alone,
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
CANDIDATE=hard
INCUMBENT=hard
SUITES=()
while [ $# -gt 0 ]; do
  case "$1" in
    --candidate) CANDIDATE="$2"; shift 2 ;;
    --incumbent) INCUMBENT="$2"; shift 2 ;;
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
  SUITES=(head_to_head=200 spread=2000 plant=300 hard_naive=500 hard_lobby_hard=500 place_search=500 place_rule=500
    place_shuffled=500 place_big=100 blind_alone=500 blind_lobby=500 blind_shuffled=500)
fi
mkdir -p "$OUT"
uptime
# A killed bench takes its shards with it.
stop_shards() {
  local -a running
  mapfile -t running < <(jobs -p)
  [ "${#running[@]}" -eq 0 ] || kill "${running[@]}" 2>/dev/null || true
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
      candidate="$CANDIDATE" incumbent="$INCUMBENT" out="$OUT/.$suite.$shard" >"$OUT/.$suite.$shard.log" 2>&1 &
    pids+=($!)
  done
  for pid in "${pids[@]}"; do wait "$pid"; done
  for part in players rounds cards turns profile; do
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
  played=$games
  [ "$suite" != head_to_head ] || played=$((games * 2))
  revision="$(git rev-parse --short HEAD)"
  if ! git diff --quiet HEAD -- src content tools/sim; then revision+="+dirty"; fi
  echo "$revision $played" >"$OUT/$suite.stamp"
done
python3 "$ROOT/tools/sim/summarize_bench.py" "$OUT" "$REPORT"
