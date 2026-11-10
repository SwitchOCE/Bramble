#!/usr/bin/env bash
# Runs a command in one of the three local Godot slots, waiting until one is free.
#   GODOT_SLOT_CLASS=gate scripts/godot_slot.sh ./scripts/check.sh
#   GODOT_SLOT_CLASS=worker scripts/godot_slot.sh godot --headless -s addons/gut/gut_cmdln.gd ...
# The command runs under MemoryMax=3G via systemd-run --user; fail closed if unavailable.
# Slots are flocks on /tmp/bramble-godot.lock, /tmp/bramble-harness-godot.lock and
# /tmp/bramble-godot-third.lock. Local sim jobs, gates, tests and probes share this queue.
# Slot3 requires MemAvailable >=4 GiB at acquisition; otherwise wait for slot1/2.
# Slot acquisition and memory decisions are logged to stderr; CSV columns stay unchanged.
# GODOT_SLOT_CLASS is gate, review, worker or probe (default: other).
# The child sees BRAMBLE_SLOT_HELD=1, so a nested check.sh doesn't lock again.
# Each run appends one CSV line to ${XDG_STATE_HOME:-$HOME/.local/state}/bramble/godot-slots.csv:
#   start_utc,class,slot,wait_s,hold_s,exit,command
# check.sh takes a slot itself, only from import through tests, so this wrapper runs it without
# a slot (it still passes the class on). Sourced, this file only defines the functions.

GODOT_SLOT_LOCKS=(/tmp/bramble-godot.lock /tmp/bramble-harness-godot.lock /tmp/bramble-godot-third.lock)
GODOT_SLOT_LOG="${XDG_STATE_HOME:-$HOME/.local/state}/bramble/godot-slots.csv"

# godot_slot_acquire: blocks until a slot's lock is held on fd 9.
# Sets GODOT_SLOT_NAME, GODOT_SLOT_WAIT_S, and the start times used by godot_slot_release.
godot_slot_acquire() {
  local lock index available memory_said='' said=0
  _slot_t0=$EPOCHREALTIME
  _slot_start_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  while :; do
    for index in "${!GODOT_SLOT_LOCKS[@]}"; do
      lock="${GODOT_SLOT_LOCKS[$index]}"
      exec 9>>"$lock"
      if flock -n 9; then
        if [ "$index" -eq 2 ]; then
          # Check while holding slot3's lock, immediately before granting it.
          # Missing/unreadable meminfo fails closed for slot3 only.
          available="$(_slot_mem_available_kib)" || available=''
          if ! [[ "$available" =~ ^[0-9]+$ ]] || [ "$available" -lt 4194304 ]; then
            exec 9>&-
            if [ "$memory_said" != low ]; then
              echo "godot_slot: slot3 withheld: MemAvailable=${available:-unknown} KiB requires >=4194304 KiB (4 GiB); waiting for slot1/2" >&2
              memory_said=low
            fi
            continue
          fi
          echo "godot_slot: slot3 allowed: MemAvailable=$available KiB >=4194304 KiB (4 GiB)" >&2
        fi
        _slot_t1=$EPOCHREALTIME
        GODOT_SLOT_NAME="$(basename "$lock" .lock)"
        GODOT_SLOT_WAIT_S="$(_slot_secs "$_slot_t0" "$_slot_t1")"
        echo "godot_slot: acquired $GODOT_SLOT_NAME" >&2
        return 0
      fi
      exec 9>&-
    done
    if [ "$said" -eq 0 ]; then
      if [ "$memory_said" != low ]; then
        echo "godot_slot: all ${#GODOT_SLOT_LOCKS[@]} Godot slots are busy; waiting" >&2
      fi
      said=1
    fi
    sleep 5
  done
}

# No environment override: production always reads the kernel's current memory report.
_slot_mem_available_kib() {
  awk '$1 == "MemAvailable:" && $2 ~ /^[0-9]+$/ && $3 == "kB" { print $2; found=1; exit }
       END { if (!found) exit 1 }' /proc/meminfo
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

  if ! systemd-run --user --scope -q -p MemoryMax=3G true >/dev/null 2>&1; then
    echo "godot_slot: cannot establish MemoryMax=3G with systemd-run --user; refusing to run uncapped" >&2
    exit 1
  fi
  cap=(systemd-run --user --scope -q -p MemoryMax=3G)
  godot_slot_acquire
  BRAMBLE_SLOT_HELD=1 "${cap[@]}" "$@" 9>&-
  status=$?
  godot_slot_release "$status" "$@"
  exit "$status"
fi
