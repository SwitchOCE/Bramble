#!/usr/bin/env bash
# Cut the eight seats of one deterministic Godot game under the current card and heap rules.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
repo="$(cd "$here/../.." && pwd)"
store="$(realpath -m "${1:?usage: current_async_field.sh <empty store>}")"
bin="$(realpath "${CARGO_TARGET_DIR:-$here/target}")/release/bramble-ghosts"
match="$(mktemp -d "${TMPDIR:-/tmp}/async-proof-field-XXXXXX")"
trap 'rm -rf -- "$match"' EXIT
mkdir -p "$match/records"
cd "$repo"
# shellcheck source=scripts/godot_log.sh
. scripts/godot_log.sh
godot_log_init "$match"
log="$match/records.log"
if ! timeout -k 10 120 "${GODOT:-godot}" --headless --log-file "$log.engine" \
    -s res://tools/checks/records.gd -- games=1 first_seed=1001 "directory=$match/records" >"$log" 2>&1 \
    || godot_log_problems "$log" || ! grep -q '^records: PASS 1 games' "$log"; then
  echo "current_async_field: reference game failed, see $log" >&2
  exit 1
fi
mv -- "$match"/records/*.jsonl "$match/records/game-00000.jsonl"
# records.gd assigns FlowBot to even seats and RandomBot to odd seats.
python3 - <<'PY' > "$match/games.jsonl"
import json

seats = [{"seat": seat, "bot": ("flow", "random")[seat % 2]} for seat in range(8)]
print(json.dumps({"game": 0, "seed": "1001", "seats": seats}))
PY
"$bin" cut --match "$match" --store "$store" --made 2026-11-20T12:00:00Z
