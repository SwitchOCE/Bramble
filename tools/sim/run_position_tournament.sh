#!/usr/bin/env bash
# Runs tools/sim/position_tournament.gd in parallel shards and merges the CSVs.
#   run_position_tournament.sh <out dir> <shards> <games> key=value ...
# The key=value options go to the script (pool=, arm=, budget=, rules=, probe=, first_seed=). Output:
# <out dir>/<pool>_<arm>[_<rules>].{games,fights,probes}.csv. The seeds are first_seed onwards
# whatever the shard count, so a run's result doesn't depend on it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$1"
SHARDS="$2"
GAMES="$3"
shift 3
mkdir -p "$OUT"

pool=a arm=heuristic rules="" probe="" first=1
pass=()
for option in "$@"; do
  case "$option" in
    pool=*) pool="${option#pool=}" ;;
    arm=*) arm="${option#arm=}" ;;
    rules=*) rules="${option#rules=}" ;;
    probe=*) probe="${option#probe=}" ;;
    first_seed=*) first="${option#first_seed=}"; continue ;;
    tag=*) tag="${option#tag=}"; continue ;;
  esac
  pass+=("$option")
done
name="${pool}_${arm}${rules:+_${rules//,/+}}${tag:+_$tag}"
[ -n "$probe" ] && name="${name}_probe"

pids=()
per=$((GAMES / SHARDS))
for ((shard = 0; shard < SHARDS; shard++)); do
  count=$per
  [ "$shard" -eq $((SHARDS - 1)) ] && count=$((GAMES - per * (SHARDS - 1)))
  godot --headless --path "$ROOT" -s res://tools/sim/position_tournament.gd -- \
    "${pass[@]}" games="$count" first_seed=$((first + per * shard)) \
    out="$OUT/.${name}.$shard" >"$OUT/.${name}.$shard.log" 2>&1 &
  pids+=($!)
done
for pid in "${pids[@]}"; do wait "$pid"; done

for part in games fights probes; do
  [ -f "$OUT/.${name}.0.$part.csv" ] || continue
  head -n 1 "$OUT/.${name}.0.$part.csv" >"$OUT/$name.$part.csv"
  for ((shard = 0; shard < SHARDS; shard++)); do
    tail -n +2 "$OUT/.${name}.$shard.$part.csv" >>"$OUT/$name.$part.csv"
  done
  rm -f "$OUT/.${name}".*."$part".csv
done
grep -h position_tournament: "$OUT/.${name}".*.log
if grep -lE "SCRIPT ERROR|^ERROR" "$OUT/.${name}".*.log; then
  echo "errors in the logs above"
  exit 1
fi
rm -f "$OUT/.${name}".*.log
