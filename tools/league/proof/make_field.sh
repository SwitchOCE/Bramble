#!/usr/bin/env bash
# Play the final red and blue bots live, then cut their finished games into a field.
# Usage: make_field.sh <out-dir> [games=1000] [threads=8]
set -euo pipefail

if [[ $# -lt 1 || $# -gt 3 || ! ${2:-1000} =~ ^[1-9][0-9]*$ || ! ${3:-8} =~ ^[1-9][0-9]*$ ]]; then
  echo "usage: make_field.sh <out-dir> [games] [threads]" >&2
  exit 2
fi
field="$(realpath -m -- "$1")"
games="${2:-1000}"
threads="${3:-8}"
league="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo="$(cd "$league/../.." && pwd)"
CARGO_TARGET_DIR="$(realpath -m "${CARGO_TARGET_DIR:-$league/target}")"
export CARGO_TARGET_DIR
# The match goes beside the field, never in /tmp (RAM on the Optiplex), and is removed once the field
# verifies. A failed run keeps it, for its logs.
mkdir -p "$(dirname "$field")"
work="$(mktemp -d "$(dirname "$field")/.bramble-field-match.XXXXXXXX")"
echo "make_field: $games games on $threads threads; match and logs in $work"

# Use a new folder so pre-existing runs can never be mistaken for this match's output.
mkdir -p "$(dirname "$field")"
mkdir "$field"
cd "$league"
CARGO_BUILD_JOBS="$threads" timeout -k 10 600 cargo build --offline --locked --release -p league -p bramble-ghosts
rules_hash="$(python3 -c 'import json; print(json.load(open("league/build.json"))["rules_hash"])')"
seq 1 "$(((games + 1) / 2))" > "$work/seeds.txt"

start=$SECONDS
timeout -k 10 3600 "$CARGO_TARGET_DIR/release/league" match --red red --blue blue \
  --games "$games" --seeds "$work/seeds.txt" --clock-ms 1000 --threads "$threads" --out "$work/match"
echo "make_field: live match took $((SECONDS - start))s"
timeout -k 10 1200 "$CARGO_TARGET_DIR/release/bramble-ghosts" cut --match "$work/match" \
  --store "$field" --repo-root "$repo" --made "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
timeout -k 10 120 "$CARGO_TARGET_DIR/release/bramble-ghosts" verify --store "$field" --rules-hash "$rules_hash"
echo "make_field: $field; match, cut and verification took $((SECONDS - start))s"
rm -rf "${work:?}"
