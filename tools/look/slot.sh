#!/usr/bin/env bash
# Reuse the slot wrapper's locking, accounting and memory cap with independent look locks.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/godot_slot.sh
. "$ROOT/scripts/godot_slot.sh"
GODOT_SLOT_LOCKS=(/tmp/bramble-look-1.lock /tmp/bramble-look-2.lock)
export GODOT_SLOT_CLASS=look
if [ -n "${BRAMBLE_LOOK_DIR:-}" ]; then
  GODOT_SLOT_LOG="$BRAMBLE_LOOK_DIR/godot-slots.csv"
fi
cap=()
if systemd-run --user --scope -q -p MemoryMax=3G true >/dev/null 2>&1; then
  cap=(systemd-run --user --scope -q -p MemoryMax=3G)
fi
godot_slot_acquire
"${cap[@]}" "$@" 9>&-
status=$?
godot_slot_release "$status" "$@"
exit "$status"
