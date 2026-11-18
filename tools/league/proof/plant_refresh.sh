#!/usr/bin/env bash
# Planted-bug check for the record checks (brief 5b step 2): builds a copy of the engine with
# refresh costing 1 more gold, then shows that both record checks catch it:
#   - GDScript records replayed in the planted Rust engine must all fail;
#   - records the planted Rust engine writes must all be rejected by GDScript.
# The working tree is never edited: the plant goes into a temporary copy.
# Usage: tools/league/proof/plant_refresh.sh [out-dir]   (LEAGUE_DATA as in recheck.sh)
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
repo="$(cd "$here/../.." && pwd)"
data="${LEAGUE_DATA:-/home/alex/league}"
jobs="${JOBS:-4}"
out="${1:-$data/proof/plant-refresh-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$out/gd"
export PATH="$HOME/.cargo/bin:$PATH"
# The copy sits beside tools/league, so the binaries still find the repository (src/content).
copy="$(mktemp -d "$repo/tools/.league-plant-XXXXXX")"
trap 'rm -rf "$copy"' EXIT
tar -C "$here" --exclude=./target -cf - . | tar -C "$copy" -xf -
rules="$copy/bramble-engine/src/core/rules/rules.rs"
grep -q 'let mut cost = config.refresh_base_cost;' "$rules" || { echo "plant site not found"; exit 2; }
sed -i 's/let mut cost = config.refresh_base_cost;/let mut cost = config.refresh_base_cost + 1;/' "$rules"
(cd "$copy" && CARGO_BUILD_JOBS=2 cargo build --offline --locked --release -p bramble-replay -p league) \
  > "$out/build.log" 2>&1 || { echo "FAIL build: $(tail -1 "$out/build.log")"; exit 1; }

# 1. GDScript to Rust: every reference record must now fail.
total=0; caught=0
while read -r f; do
  total=$((total + 1))
  "$copy/target/release/bramble-replay" replay --record "$f" > /dev/null 2>> "$out/replay.log" \
    || caught=$((caught + 1))
done < <(find "$data/records/gd/c0" "$data/records/gd/c1" "$data/records/gd/c2" -maxdepth 1 \
  -name '*.jsonl' ! -name '*.legal.jsonl' | sort)
echo "plant replay: records=$total caught=$caught"
head -1 "$out/replay.log"
# Every failure must be the plant (a refresh that now costs too much), not a build or path problem.
other=$(grep -c -v 'not enough gold' "$out/replay.log")
echo "plant replay: failures not about gold=$other"

# 2. Rust to GDScript: records the planted engine writes must be rejected.
head -2 "$data/proof/r2g-seeds.txt" > "$out/seeds.txt"
"$copy/target/release/league" match --red flow --blue random --games 4 --seeds "$out/seeds.txt" \
  --threads "$jobs" --out "$out/match" > "$out/match.log" 2>&1 \
  || { echo "FAIL planted match: $(tail -1 "$out/match.log")"; exit 1; }
gtotal=0; rejected=0
cd "$repo" || exit 2
shopt -s nullglob
for f in "$out"/match/records/*.jsonl; do
  gtotal=$((gtotal + 1)); n=$(basename "$f" .jsonl)
  RECORDS_LOG="$out/gd/$n.log" timeout 300 scripts/records.sh record="$f" > "$out/gd/$n.out" 2>&1
  # Rejected for the plant: GDScript ran and found a differing turn after the start.
  grep -q 'first differing turn [1-9]' "$out/gd/$n.out" && rejected=$((rejected + 1))
done
echo "plant r2g: records=$gtotal rejected=$rejected"
# A turn-0 rejection would mean the build or content differs, not the plant.
turn0=$(cat "$out"/gd/*.out | grep -c 'first differing turn 0')
echo "plant r2g: rejected at turn 0=$turn0"
head -1 "$out"/gd/*.out | grep -v '^==' | head -1
if [ "$total" -gt 0 ] && [ "$caught" -eq "$total" ] && [ "$other" -eq 0 ] && [ "$gtotal" -gt 0 ] && [ "$rejected" -eq "$gtotal" ] && [ "$turn0" -eq 0 ]; then
  echo "plant_refresh: PASS (logs in $out)"; else echo "plant_refresh: FAIL (logs in $out)"; exit 1; fi
