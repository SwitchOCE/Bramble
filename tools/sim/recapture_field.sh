#!/usr/bin/env bash
# Recapture the strong-field library when the full pass 3 pool is ready (v3 step 5).
#   tools/sim/recapture_field.sh [--games 120] [--first-seed 20262000]
#     [--per-line 64] [--sample-seed 91407] [--config overrides.json]
#     [--out content/fields/baseline.json.gz] [--capture-dir build/strong-field/recapture]
#     [--source-commit HEAD] [--strength top4] [--timeout 1500]
# Future shipped libraries contain source top-four finishers by default.
# Runs one Godot process at a time, under the shared lock and 3 GiB memory cap.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
# shellcheck source=/dev/null
. /opt/bramble/env.sh
GODOT_BIN="${GODOT:-godot}"
GAMES=120
FIRST_SEED=20262000
PER_LINE=64
SAMPLE_SEED=91407
STRENGTH=top4
OUTPUT=content/fields/baseline.json.gz
CAPTURE_DIR=build/strong-field/recapture
SOURCE_COMMIT=HEAD
LIMIT=1500
CONFIG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --games) GAMES="$2"; shift 2 ;;
    --first-seed) FIRST_SEED="$2"; shift 2 ;;
    --per-line) PER_LINE="$2"; shift 2 ;;
    --sample-seed) SAMPLE_SEED="$2"; shift 2 ;;
    --strength) STRENGTH="$2"; shift 2 ;;
    --out) OUTPUT="$2"; shift 2 ;;
    --capture-dir) CAPTURE_DIR="$2"; shift 2 ;;
    --source-commit) SOURCE_COMMIT="$2"; shift 2 ;;
    --timeout) LIMIT="$2"; shift 2 ;;
    --config) CONFIG="$2"; shift 2 ;;
    -h|--help) sed -n '2,9s/^# \{0,1\}//p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
if [ "$STRENGTH" != top4 ] && [ "$STRENGTH" != all ]; then
  echo "--strength must be top4 or all" >&2
  exit 2
fi
REVISION="$(git rev-parse --verify "${SOURCE_COMMIT}^{commit}")"
if [ "$REVISION" != "$(git rev-parse HEAD)" ]; then
  echo "recapture must run on the named source commit (current HEAD differs)" >&2
  exit 2
fi
# Existing generated fields do not affect all-line captures, so they may be replaced in place.
if ! git diff --quiet HEAD -- src tools/sim content/units content/spells content/heroes \
  content/levers content/schema content/bots; then
  echo "commit source/gameplay changes before recapturing; refusing misleading source provenance" >&2
  exit 2
fi
mkdir -p "$CAPTURE_DIR" "$(dirname "$OUTPUT")"
flock /tmp/bramble-godot.lock systemd-run --user --scope -p MemoryMax=3G \
  timeout 180 "$GODOT_BIN" --headless --path "$ROOT" --import \
  >"$CAPTURE_DIR/import.log" 2>&1
options=(suite=lines "games=$GAMES" "first_seed=$FIRST_SEED" capture=on "out=$CAPTURE_DIR/lines")
if [ -n "$CONFIG" ]; then options+=("config=$CONFIG"); fi
flock /tmp/bramble-godot.lock systemd-run --user --scope -p MemoryMax=3G \
  timeout "$LIMIT" "$GODOT_BIN" --headless --path "$ROOT" -s res://tools/sim/bench.gd \
  -- "${options[@]}" >"$CAPTURE_DIR/capture.log" 2>&1
if grep -E 'SCRIPT ERROR|^ERROR:|Parse Error' "$CAPTURE_DIR/import.log" "$CAPTURE_DIR/capture.log"; then
  echo "capture logged errors; library was not replaced" >&2
  exit 1
fi
python3 tools/sim/field_library.py "$CAPTURE_DIR/lines.fights.jsonl" \
  --source-commit "$REVISION" --per-line "$PER_LINE" --seed "$SAMPLE_SEED" \
  --strength "$STRENGTH" --out "$OUTPUT"
echo "recaptured $OUTPUT from $REVISION; source logs: $CAPTURE_DIR/"
