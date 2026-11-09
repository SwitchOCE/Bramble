#!/usr/bin/env bash
# Runs a command in one of the two local Godot slots, waiting until one is free.
#   GODOT_SLOT_CLASS=gate scripts/godot_slot.sh ./scripts/check.sh
#   GODOT_SLOT_CLASS=worker scripts/godot_slot.sh godot --headless -s addons/gut/gut_cmdln.gd ...
# A slot is a flock on /tmp/bramble-godot.lock or /tmp/bramble-harness-godot.lock. Sims keep
# taking only the harness lock themselves; this wrapper is for gates, tests and probes.
# GODOT_SLOT_CLASS is gate, review, worker or probe (default: other).
# The child sees BRAMBLE_SLOT_HELD=1, so a nested check.sh doesn't lock again.
# Each run appends one CSV line to ${XDG_STATE_HOME:-$HOME/.local/state}/bramble/godot-slots.csv:
#   start_utc,class,slot,wait_s,hold_s,exit,command
# check.sh takes a slot itself, only from import through tests, so this wrapper runs it without
# a slot (it still passes the class on). Sourced, this file only defines the functions.

GODOT_SLOT_LOCKS=(/tmp/bramble-godot.lock /tmp/bramble-harness-godot.lock)
GODOT_SLOT_LOG="${XDG_STATE_HOME:-$HOME/.local/state}/bramble/godot-slots.csv"

# godot_slot_acquire: blocks until a slot's lock is held on fd 9.
# Sets GODOT_SLOT_NAME, GODOT_SLOT_WAIT_S, and the start times used by godot_slot_release.
godot_slot_acquire() {
  local lock said=0
  _slot_t0=$EPOCHREALTIME
  _slot_start_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  while :; do
    for lock in "${GODOT_SLOT_LOCKS[@]}"; do
      exec 9>>"$lock"
      if flock -n 9; then
        _slot_t1=$EPOCHREALTIME
        GODOT_SLOT_NAME="$(basename "$lock" .lock)"
        GODOT_SLOT_WAIT_S="$(_slot_secs "$_slot_t0" "$_slot_t1")"
        return 0
      fi
      exec 9>&-
    done
    if [ "$said" -eq 0 ]; then
      echo "godot_slot: both Godot slots are busy; waiting" >&2
      said=1
    fi
    sleep 5
  done
}

# godot_slot_release <exit-code> <command...>: frees the slot and appends the CSV line.
godot_slot_release() {
  local code="$1" t2=$EPOCHREALTIME cmd
  shift
  exec 9>&-
  cmd="$*"
  cmd="\"${cmd//\"/\"\"}\""
  mkdir -p "$(dirname "$GODOT_SLOT_LOG")"
  [ -s "$GODOT_SLOT_LOG" ] || echo "start_utc,class,slot,wait_s,hold_s,exit,command" >>"$GODOT_SLOT_LOG"
  printf '%s,%s,%s,%s,%s,%s,%s\n' "$_slot_start_utc" "${GODOT_SLOT_CLASS:-other}" \
    "$GODOT_SLOT_NAME" "$GODOT_SLOT_WAIT_S" "$(_slot_secs "$_slot_t1" "$t2")" "$code" "$cmd" \
    >>"$GODOT_SLOT_LOG"
}

# _slot_secs <from> <to>: seconds between two EPOCHREALTIME stamps, one decimal.
_slot_secs() {
  awk -v a="$1" -v b="$2" 'BEGIN { printf "%.1f", b - a }'
}

# Run as a command (not sourced).
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -uo pipefail
  if [ "$#" -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    sed -n '2,/^[^#]/{/^#/s/^# \{0,1\}//p}' "$0"
    [ "$#" -eq 0 ] && exit 2
    exit 0
  fi

  case "$(basename "$1")" in
    check.sh) exec "$@" ;;
  esac

  godot_slot_acquire
  BRAMBLE_SLOT_HELD=1 "$@" 9>&-
  status=$?
  godot_slot_release "$status" "$@"
  exit "$status"
fi
