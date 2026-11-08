#!/usr/bin/env bash
# Run preregistered paired arms. Caller may background this script; logs and data persist.
# Usage: source /opt/bramble/env.sh; tools/sim/damage_v05.sh [empty-output-directory]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
if [ "${1:-}" = --batch ]; then
  arm="$2"
  out="$3"
  pids=()
  # shellcheck disable=SC2329 # Called by EXIT trap.
  stop_shards() {
    kill "${pids[@]}" 2>/dev/null || true
  }
  trap stop_shards EXIT
  trap 'exit 143' TERM INT
  for shard in 0 1 2 3; do
    XDG_CONFIG_HOME="$ROOT/build/damage-config/$arm.$shard" \
      XDG_DATA_HOME="$ROOT/build/damage-data/$arm.$shard" \
      taskset -c "$((shard + 1))" "${GODOT:-godot}" --headless --path "$ROOT" \
      -s res://tools/sim/damage_v05.gd -- "$arm" "$((860001 + shard * 50))" 50 \
      "$out/$arm.$shard.jsonl" >"$out/$arm.$shard.log" 2>&1 &
    pids+=("$!")
  done
  status=0
  for pid in "${pids[@]}"; do
    wait "$pid" || status=1
  done
  if rg -n 'SCRIPT ERROR|^ERROR|damage: unfinished' "$out/$arm."*.log; then
    status=1
  fi
  exit "$status"
fi
OUT="${1:-$ROOT/docs/ideation/evidence/damage-v05}"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
# Refuse archived or partial shards before opening files or launching expensive simulations.
if compgen -G "$OUT/*.jsonl*" >/dev/null; then
  echo "damage: output already contains raw shards; pass an empty output directory" >&2
  exit 2
fi
for arm in baseline A B C D E; do
  echo "damage: starting $arm $(date -Iseconds)"
  timeout --kill-after=10s 3000s bash "$0" --batch "$arm" "$OUT" >"$OUT/$arm.batch.log" 2>&1
  echo "damage: finished $arm $(date -Iseconds)"
done
python3 tools/sim/summarize_damage_v05.py "$OUT"
