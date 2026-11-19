#!/usr/bin/env bash
# Reruns every port check of brief 5b step 2 on the current code, for a port fix (brief 6).
# Usage: tools/league/proof/recheck.sh [out-dir]   (default /home/alex/league/proof/recheck-<time>)
# Needs the reference data made in phase 0, under LEAGUE_DATA (default /home/alex/league):
#   records/gd/c0..c2     1,000 GDScript records (scripts/records.sh)
#   fights/cases.jsonl    100,000 fight cases, fights/gd.jsonl their GDScript results
#   proof/r2g-seeds.txt   25 seeds for the Rust-to-GDScript games
#   records/tribe-gd      200 TribeBot records (tools/league/gd/tribe_records.gd)
# Prints one PASS/FAIL line per check and exits non-zero if any fails.
# Run with a hard time limit and set JOBS to the desired parallelism (default 8).
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
repo="$(cd "$here/../.." && pwd)"
data="$(realpath -m "${LEAGUE_DATA:-/home/alex/engine-data/dev-level}")"
jobs="${JOBS:-8}"
out="$(realpath -m "${1:-$data/proof/recheck-$(date +%Y%m%d-%H%M%S)}")"
mkdir -p "$out"
export TMPDIR="$out"
export PATH="$HOME/.cargo/bin:$PATH"
cd "$here" || exit 2
fail=0
step() { # name, then the command; the log goes to $out/<name>.log
  local name=$1; shift
  if "$@" > "$out/$name.log" 2>&1; then echo "PASS $name: $(tail -1 "$out/$name.log")"
  else echo "FAIL $name: $(tail -2 "$out/$name.log" | tr '\n' ' ')"; fail=1; fi
}

step build env CARGO_BUILD_JOBS="$jobs" cargo build --offline --locked --release --workspace
step test env LEAGUE_DATA="$data" CARGO_BUILD_JOBS="$jobs" cargo test --offline --locked --release --workspace
step replay proof/replay_all.sh "$jobs" "$data/records/gd/c0" "$data/records/gd/c1" "$data/records/gd/c2"
fights_run() {
  local cases="$data/fights/cases.jsonl" total size job first count shard
  local -a pids=()
  total=$(wc -l < "$cases") || return
  [[ "$total" -eq 100000 ]] || { echo "expected 100,000 fight cases, got $total"; return 1; }
  size=$(((total + jobs - 1) / jobs))
  for ((job=0; job<jobs; job++)); do
    first=$((job * size))
    if (( first >= total )); then break; fi
    count=$((total - first < size ? total - first : size))
    printf -v shard '%04d' "$job"
    target/release/bramble-fight "cases=$cases" "out=$out/fights-rust-$shard.jsonl" \
      "first=$first" "count=$count" > "$out/fights-rust-$shard.log" 2>&1 &
    pids+=("$!")
  done
  local failed=0 pid
  for pid in "${pids[@]}"; do wait "$pid" || failed=1; done
  tail -q -n 1 "$out"/fights-rust-*.log
  (( failed == 0 )) || return 1
  echo "bramble-fight cases=$total shards=${#pids[@]}"
}
step fights-run fights_run
step fights-compare python3 bramble-fight/compare.py "$data/fights/gd.jsonl" "$out"/fights-rust-*.jsonl
step selfcheck target/release/league selfcheck --records "$data/records/gd/c0" \
  --records "$data/records/gd/c1" --records "$data/records/gd/c2" --threads "$jobs"
step selfcheck-tribe target/release/league selfcheck --records "$data/records/tribe-gd" \
  --bots tribe --threads "$jobs"
rm -rf "$out/r2g"
step r2g-play target/release/league match --red flow --blue random --games 50 \
  --seeds "$data/proof/r2g-seeds.txt" --threads "$jobs" --out "$out/r2g"
r2g_one() {
  local f=$1 n log
  n=$(basename "$f" .jsonl)
  log="$out/r2g-gd/$n.log"
  if ! timeout -k 10 600 "${GODOT:-godot}" --headless --log-file "$log.engine" \
      -s res://tools/checks/records.gd -- "record=$f" > "$log" 2>&1 \
      || godot_log_problems "$log" >&2 || ! grep -q '^records: .*complete$' "$log"; then
    echo "failed: $f (see $log)"
    return 1
  fi
  echo complete
}
r2g() { # every Rust record must replay in GDScript, complete, with no Godot errors
  cd "$repo" || return 2
  # shellcheck source=scripts/godot_log.sh
  . scripts/godot_log.sh
  godot_log_init "$out/r2g-gd"
  local -a records=("$out"/r2g/records/*.jsonl)
  [[ -f "${records[0]}" ]] || { echo "no Rust records to replay"; return 1; }
  export out GODOT_PROBLEM_RE GODOT_LOG_ALLOWLIST
  export -f r2g_one godot_log_problems
  local total="${#records[@]}" complete
  # shellcheck disable=SC2016
  printf '%s\0' "${records[@]}" | xargs -0 -n 1 -P "$jobs" bash -c 'r2g_one "$1"' _ > "$out/r2g-gd/results.log"
  grep '^failed:' "$out/r2g-gd/results.log"
  complete=$(grep -c '^complete$' "$out/r2g-gd/results.log")
  echo "r2g: records=$total failed=$((total - complete))"
  [[ "$total" -eq 50 && "$complete" -eq "$total" ]]
}
mkdir -p "$out/r2g-gd"
step r2g-replay r2g
rm -f "$out"/fights-rust-*.jsonl
echo "recheck: logs in $out"
if [ "$fail" -eq 0 ]; then echo "recheck: PASS"; else echo "recheck: FAIL"; exit 1; fi
