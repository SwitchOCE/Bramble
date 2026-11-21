#!/usr/bin/env bash
# Compares every fight event, not only the state, between the engines on a sample of the
# reference fight cases (step E of docs/workstreams/third-run/ghost-plan.md).
# Usage: tools/league/proof/fight_logs.sh <cases.jsonl> <out-dir> [count] [jobs]
# Draws <count> cases (default 10,000) with a fixed seed, asks both runners for every event
# ("trace": ["*"]), runs GDScript in <jobs> shards (default 3) and Rust once, and compares
# results, state bytes and the event arrays. Needs bramble-fight built in CARGO_TARGET_DIR.
set -euo pipefail
cases=$1 out=$2 count=${3:-10000} jobs=${4:-3}
here="$(cd "$(dirname "$0")/.." && pwd)"
repo="$(cd "$here/../.." && pwd)"
bin="$(realpath -m "${CARGO_TARGET_DIR:-$here/target}")/release"
mkdir -p "$out"
sample="$out/fight-logs-cases.jsonl"
python3 - "$cases" "$sample" "$count" <<'EOF'
import json, random, sys
source, target, count = sys.argv[1], sys.argv[2], int(sys.argv[3])
with open(source, encoding="utf-8") as f:
    total = sum(1 for _ in f)
pick = set(random.Random(20261121).sample(range(total), count))
with open(source, encoding="utf-8") as f, open(target, "w", encoding="utf-8") as o:
    for number, line in enumerate(f):
        if number in pick:
            case = json.loads(line)
            case["trace"] = ["*"]
            o.write(json.dumps(case, separators=(",", ":"), ensure_ascii=False) + "\n")
EOF
size=$(( (count + jobs - 1) / jobs ))
pids=()
cd "$repo"
for (( shard = 0; shard < jobs; shard++ )); do
  timeout -k 10 3600 "${GODOT:-godot}" --headless --log-file "$out/fight-logs-gd-$shard.godot.log" \
    -s res://tools/league/gd/fight_run.gd -- "cases=$sample" "out=$out/fight-logs-gd-$shard.jsonl" \
    "first=$(( shard * size ))" "count=$size" > "$out/fight-logs-gd-$shard.log" 2>&1 &
  pids+=($!)
done
timeout -k 10 3600 "$bin/bramble-fight" "cases=$sample" "out=$out/fight-logs-rust.jsonl" \
  > "$out/fight-logs-rust.log" 2>&1 &
pids+=($!)
status=0
for pid in "${pids[@]}"; do wait "$pid" || status=1; done
(( status == 0 )) || { echo "a fight runner failed; logs in $out"; exit 1; }
cat "$out"/fight-logs-gd-*.jsonl > "$out/fight-logs-gd.jsonl"
python3 "$here/bramble-fight/compare.py" --require-trace --trace-values \
  "$out/fight-logs-gd.jsonl" "$out/fight-logs-rust.jsonl"
rm -f -- "$sample" "$out"/fight-logs-*.jsonl
