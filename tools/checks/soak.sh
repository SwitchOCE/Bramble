#!/usr/bin/env bash
# QA soak: runs tools/checks/soak.gd (bot-only full games with rules invariants) and fails on
# any violation or any problem line in the Godot log (scripts/godot_log.sh).
# Usage: tools/checks/soak.sh [games=200] [first_seed=1]   (source /opt/bramble/env.sh first)
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="$ROOT/build/check"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/soak.log"
# shellcheck source=scripts/godot_log.sh
. "$ROOT/scripts/godot_log.sh"
godot_log_init "$LOG_DIR"
cd "$ROOT" || exit 1
"${GODOT:-godot}" --headless -s res://tools/checks/soak.gd -- "${1:-200}" "${2:-1}" >"$LOG" 2>&1
status=$?
grep '^soak:' "$LOG"
bad="$(godot_log_problems "$LOG")"
if [ -n "$bad" ]; then
  echo "soak: log problems:"
  echo "$bad" | head -20
  status=1
fi
echo "soak: exit $status (full log: $LOG)"
exit "$status"
