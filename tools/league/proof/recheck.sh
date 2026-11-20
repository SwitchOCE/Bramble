#!/usr/bin/env bash
# Reruns every port check of brief 5b step 2 on the current code, for a port fix (brief 6).
# Usage: tools/league/proof/recheck.sh [out-dir]   (default /home/alex/league/proof/recheck-<time>)
# Needs the reference data made in phase 0, under LEAGUE_DATA (default /home/alex/league):
#   records/gd/c0..c2     1,000 GDScript records (scripts/records.sh)
#   fights/cases.jsonl    100,000 fight cases, fights/gd.jsonl their GDScript results
#   proof/r2g-seeds.txt   25 seeds for the Rust-to-GDScript games
#   records/tribe-gd      200 TribeBot records (tools/league/gd/tribe_records.gd)
#   proof/async-store     populated from the committed proof fixture if absent
# Prints one PASS/FAIL line per check and exits non-zero if any fails.
# Run with a hard time limit and set JOBS to the desired parallelism (default 8).
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
repo="$(cd "$here/../.." && pwd)"
data="$(realpath -m "${LEAGUE_DATA:-/home/alex/engine-data/dev-level}")"
jobs="${JOBS:-8}"
out="$(realpath -m "${1:-$data/proof/recheck-$(date +%Y%m%d-%H%M%S)}")"
mkdir -p "$out"
export TMPDIR="${TMPDIR:-$out}"
CARGO_TARGET_DIR="$(realpath -m "${CARGO_TARGET_DIR:-$here/target}")" || exit 2
export CARGO_TARGET_DIR
bin="$CARGO_TARGET_DIR/release"
export PATH="$HOME/.cargo/bin:$PATH"
cd "$here" || exit 2
fail=0
step() { # name, then the command; the log goes to $out/<name>.log
  local name=$1; shift
  if "$@" > "$out/$name.log" 2>&1; then echo "PASS $name: $(tail -1 "$out/$name.log")"
  else echo "FAIL $name: $(tail -2 "$out/$name.log" | tr '\n' ' ')"; fail=1; fi
}

step build env CARGO_BUILD_JOBS="$jobs" cargo build --offline --locked --release --workspace
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
    "$bin/bramble-fight" "cases=$cases" "out=$out/fights-rust-$shard.jsonl" \
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
step fights-compare python3 bramble-fight/compare.py --require-trace "$data/fights/gd.jsonl" "$out"/fights-rust-*.jsonl
# The workspace tests include bot games. Require the record and fight comparisons first.
if (( !fail )); then
  step test env LEAGUE_DATA="$data" CARGO_BUILD_JOBS="$jobs" cargo test --offline --locked --release --workspace
fi
if (( fail )); then
  echo "recheck: logs in $out"
  echo "recheck: FAIL"
  exit 1
fi
step selfcheck "$bin/league" selfcheck --records "$data/records/gd/c0" \
  --records "$data/records/gd/c1" --records "$data/records/gd/c2" --threads "$jobs"
step selfcheck-tribe "$bin/league" selfcheck --records "$data/records/tribe-gd" \
  --bots tribe --threads "$jobs"
rm -rf "$out/r2g"
step r2g-play "$bin/league" match --red flow --blue random --games 50 \
  --seeds "$data/proof/r2g-seeds.txt" --threads "$jobs" --out "$out/r2g"
r2g_one() {
  local f=$1 log_dir=$2 store=$3 n log matched
  local -a args
  n=$(basename "$f" .jsonl)
  log="$log_dir/$n.log"
  if [[ -n "$store" ]]; then
    args=(-- --replay-record "$f" --ghost-store "$store")
    matched='^records: matched [0-9]+ turns \(complete\)$'
  else
    args=(-s res://tools/checks/records.gd -- "record=$f")
    matched='^records: matched .* complete$'
  fi
  if ! timeout -k 10 600 "${GODOT:-godot}" --headless --log-file "$log.engine" \
      "${args[@]}" > "$log" 2>&1 \
      || godot_log_problems "$log" >&2 || ! grep -Eq "$matched" "$log"; then
    echo "failed: $f (see $log)"
    return 1
  fi
  awk '/"op":"(start|fight_boards|finish)"/ && /"hash":/ { n++ } END { print "complete", n+0 }' "$f"
}
r2g() { # every Rust record must replay in GDScript, complete, with no Godot errors
  local source=$1 log_dir=$2 store=${3:-}
  local -a records=("$source"/*.jsonl)
  [[ -f "${records[0]}" ]] || { echo "no Rust records to replay"; return 1; }
  (
    cd "$repo" || exit 2
    # shellcheck source=scripts/godot_log.sh
    . scripts/godot_log.sh
    mkdir -p "$log_dir"
    godot_log_init "$log_dir"
    export GODOT_PROBLEM_RE GODOT_LOG_ALLOWLIST
    export -f r2g_one godot_log_problems
    local total="${#records[@]}" complete checks
    # shellcheck disable=SC2016
    printf '%s\0' "${records[@]}" | xargs -0 -n 1 -P "$jobs" bash -c \
      'r2g_one "$3" "$1" "$2"' _ "$log_dir" "$store" > "$log_dir/results.log"
    grep '^failed:' "$log_dir/results.log"
    read -r complete checks < <(awk '/^complete / { n++; s+=$2 } END { print n+0, s+0 }' "$log_dir/results.log")
    echo "r2g: records=$total failed=$((total - complete)) checkpoints=$checks"
    [[ "$total" -eq 50 && "$complete" -eq "$total" ]]
  )
}
step r2g-replay r2g "$out/r2g/records" "$out/r2g-gd"

store="$data/proof/async-store"
async_r2g() {
  # Always the committed runs: a store left in the data folder could differ.
  rm -rf -- "$store"
  cp -a -- "$here/proof/fixtures/async-store" "$store" || return
  rm -rf -- "$out/async-rust"
  CARGO_BUILD_JOBS="$jobs" cargo build --offline --locked --release -p bramble-engine --example async_records || return
  "$bin/examples/async_records" "$store" "$data/proof/r2g-seeds.txt" "$out/async-rust" || return
  r2g "$out/async-rust" "$out/async-r2g-gd" "$store"
}
async_g2r() {
  rm -rf -- "$out/async-godot"
  mkdir -p "$out/async-godot"
  local log="$out/async-godot/records.log"
  (
    cd "$repo" || exit 2
    # shellcheck source=scripts/godot_log.sh
    . scripts/godot_log.sh
    godot_log_init "$out/async-godot"
    timeout -k 10 900 "${GODOT:-godot}" --headless --log-file "$log.engine" \
      -s res://tools/checks/records.gd -- games=25 first_seed=9001 \
      "directory=$out/async-godot" "ghost_store=$store" > "$log" 2>&1 \
      && ! godot_log_problems "$log" && grep '^records: PASS 25 async games' "$log"
  ) || return
  proof/replay_all.sh "$jobs" --ghost-store "$store" "$out/async-godot"
}
ghost_match() {
  # A field cut from r2g's 50 live games (cut twice: one record seat is one run), a ghost-match
  # pair on it, and that pair's records cut back with the field as their ghost store.
  local field="$out/ghost-field" again="$out/ghost-again" n
  rm -rf -- "$field" "$again" "$out/ghost-match"
  "$bin/bramble-ghosts" cut --match "$out/r2g" --store "$field" --made 2026-01-01T00:00:00Z || return
  "$bin/bramble-ghosts" cut --match "$out/r2g" --store "$field" --made 2026-01-02T00:00:00Z || return
  n=$(find "$field/runs" -name '*.json' | wc -l)
  [[ "$n" -eq 400 ]] || { echo "ghost field: $n runs, expected 400"; return 1; }
  "$bin/league" ghost-match --red flow --blue random --field "$field" --games 2 \
    --seeds "$data/proof/r2g-seeds.txt" --threads "$jobs" --out "$out/ghost-match" > /dev/null || return
  python3 proof/check_ghost_match.py "$out/ghost-match" 2 || return
  "$bin/bramble-ghosts" cut --match "$out/ghost-match" --store "$again" --ghost-store "$field" \
    --made 2026-01-01T00:00:00Z || return
  n=$(find "$again/runs" -name '*.json' | wc -l)
  [[ "$n" -eq 2 ]] || { echo "async cut: $n runs, expected 2 (seat 0 of each game)"; return 1; }
}
step async-r2g async_r2g
step async-g2r async_g2r
step ghost-match ghost_match
step async-planted python3 proof/plant_async.py "$bin/bramble-replay" "$store" "$out"
rm -f "$out"/fights-rust-*.jsonl
echo "recheck: logs in $out"
if [ "$fail" -eq 0 ]; then echo "recheck: PASS"; else echo "recheck: FAIL"; exit 1; fi
