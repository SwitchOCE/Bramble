#!/usr/bin/env bash
# Replays every GDScript record in the given folders in the Rust engine and checks every
# state hash, action result and fight payload. Usage: replay_all.sh <jobs> <folder>...
# Prints one line per failing record, then a PASS/FAIL summary. Run from tools/league after
# `cargo build --release --offline --locked`.
set -uo pipefail
jobs=$1; shift
bin="$(dirname "$0")/../target/release/bramble-replay"
list=$(mktemp)
find "$@" -maxdepth 1 -name '*.jsonl' ! -name '*.legal.jsonl' ! -name '*-changed-action.jsonl' | sort > "$list"
total=$(wc -l < "$list")
out=$(mktemp)
xargs -P "$jobs" -I{} sh -c 'r=$("$0" replay --record "$1" 2>&1); s=$?; if [ $s -ne 0 ]; then echo "FAIL $1: $(echo "$r" | head -2 | tr "\n" " ")"; else echo "OK $1 $r"; fi' "$bin" {} < "$list" > "$out"
fails=$(grep -c '^FAIL' "$out")
grep '^FAIL' "$out" | head -20
complete=$(grep -c 'complete true' "$out")
checks=$(grep '^OK' "$out" | awk '{s+=$6} END {print s+0}')
echo "replay_all: records=$total ok=$((total-fails)) fail=$fails complete=$complete checkpoints=$checks"
rm -f "$list" "$out"
[ "$fails" -eq 0 ]
