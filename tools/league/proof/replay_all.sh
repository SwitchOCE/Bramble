#!/usr/bin/env bash
# Replays every GDScript record in the given folders in the Rust engine and checks every
# state hash, action result and fight payload. Usage: replay_all.sh <jobs> [--ghost-store <dir>] <folder>...
# Prints one line per failing record, then a PASS/FAIL summary. Run from tools/league after
# `cargo build --release --offline --locked`.
set -uo pipefail
jobs=$1; shift
bin="${CARGO_TARGET_DIR:-$(dirname "$0")/../target}/release/bramble-replay"
args=()
if [[ ${1:-} == --ghost-store ]]; then
  args=(--ghost-store "$2")
  shift 2
fi
list=$(mktemp)
find "$@" -maxdepth 1 -name '*.jsonl' ! -name '*.legal.jsonl' ! -name '*-changed-action.jsonl' | sort > "$list"
total=$(wc -l < "$list")
out=$(mktemp)
# shellcheck disable=SC2016
xargs -P "$jobs" -I{} sh -c 'f=$1; shift; r=$("$0" replay --record "$f" "$@" 2>&1); s=$?; if [ $s -ne 0 ]; then echo "FAIL $f: $(echo "$r" | head -2 | tr "\n" " ")"; else echo "OK $f $r"; fi' "$bin" {} "${args[@]}" < "$list" > "$out"
fails=$(grep -c '^FAIL' "$out")
grep '^FAIL' "$out" | head -20
complete=$(grep -c 'complete true' "$out")
checks=$(grep '^OK' "$out" | awk '{s+=$6} END {print s+0}')
echo "replay_all: records=$total ok=$((total-fails)) fail=$fails complete=$complete checkpoints=$checks"
rm -f "$list" "$out"
[ "$total" -gt 0 ] && [ "$fails" -eq 0 ] && [ "$complete" -eq "$total" ]
