#!/usr/bin/env bash
# Reruns every port check of brief 5b step 2 on the current code, for a port fix (brief 6).
# Usage: tools/league/proof/recheck.sh [out-dir]   (default /home/alex/league/proof/recheck-<time>)
# Needs the reference data made in phase 0, under LEAGUE_DATA (default /home/alex/league):
#   records/gd/c0..c2     1,000 GDScript records (scripts/records.sh)
#   fights/cases.jsonl    100,000 fight cases, fights/gd.jsonl their GDScript results
#   proof/r2g-seeds.txt   25 seeds for the Rust-to-GDScript games
# Prints one PASS/FAIL line per check and exits non-zero if any fails. About 10 minutes on
# 4 jobs. Long: run it in the background with a time limit.
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
repo="$(cd "$here/../.." && pwd)"
data="${LEAGUE_DATA:-/home/alex/league}"
jobs="${JOBS:-4}"
out="${1:-$data/proof/recheck-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$out"
export PATH="$HOME/.cargo/bin:$PATH"
cd "$here" || exit 2
fail=0
step() { # name, then the command; the log goes to $out/<name>.log
  local name=$1; shift
  if "$@" > "$out/$name.log" 2>&1; then echo "PASS $name: $(tail -1 "$out/$name.log")"
  else echo "FAIL $name: $(tail -2 "$out/$name.log" | tr '\n' ' ')"; fail=1; fi
}

step build env CARGO_BUILD_JOBS=2 cargo build --offline --locked --release --workspace
step test env CARGO_BUILD_JOBS=2 cargo test --offline --locked --release --workspace
step replay proof/replay_all.sh "$jobs" "$data/records/gd/c0" "$data/records/gd/c1" "$data/records/gd/c2"
step fights-run target/release/bramble-fight cases="$data/fights/cases.jsonl" out="$out/fights-rust.jsonl"
step fights-compare python3 bramble-fight/compare.py "$data/fights/gd.jsonl" "$out/fights-rust.jsonl"
step selfcheck target/release/league selfcheck --records "$data/records/gd/c0" \
  --records "$data/records/gd/c1" --records "$data/records/gd/c2" --threads "$jobs"
rm -rf "$out/r2g"
step r2g-play target/release/league match --red flow --blue random --games 50 \
  --seeds "$data/proof/r2g-seeds.txt" --threads "$jobs" --out "$out/r2g"
r2g() { # every Rust record must replay in GDScript, complete, with no Godot errors
  local f n bad=0 total=0
  cd "$repo" || return 2
  for f in "$out"/r2g/records/*.jsonl; do
    total=$((total + 1)); n=$(basename "$f" .jsonl)
    if ! RECORDS_LOG="$out/r2g-gd/$n.log" timeout 600 scripts/records.sh record="$f" \
        > "$out/r2g-gd/$n.out" 2>&1 || ! grep -q 'complete$' "$out/r2g-gd/$n.out"; then
      bad=$((bad + 1)); echo "failed: $f"
    fi
  done
  echo "r2g: records=$total failed=$bad"
  [ "$total" -gt 0 ] && [ "$bad" -eq 0 ]
}
mkdir -p "$out/r2g-gd"
step r2g-replay r2g
rm -f "$out/fights-rust.jsonl"
echo "recheck: logs in $out"
if [ "$fail" -eq 0 ]; then echo "recheck: PASS"; else echo "recheck: FAIL"; exit 1; fi
