#!/usr/bin/env bash
# QA soak: runs tools/checks/soak.gd (bot-only full_game lobbies with rules invariants) and fails
# on any violation, a crash, or any problem line in the Godot log (scripts/godot_log.sh).
#   tools/checks/soak.sh [N=200] [--preset P] [--library L] [--synthetic K] [--first-seed S] [--log F]
# N real lobbies from seed S (default 1): 3 in 5 on preset P (default: rates.json's default), 1 in
# 5 on the other preset, 1 in 5 on P with field rivals from library L (skipped and counted without
# one). --synthetic K adds K games on SoakContent's synthetic cards, counted separately. The log
# goes to F (default build/check/soak.log). Locally, run it through scripts/godot_slot.sh; on
# Actions, through the sim job (kind soak, docs/CLOUD_SETUP.md).
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 1
games=200
args=()
log="$ROOT/build/check/soak.log"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --preset) args+=("preset=${2:?--preset needs a value}"); shift ;;
    --library) args+=("library=${2:?--library needs a path}"); shift ;;
    --synthetic) args+=("synthetic=${2:?--synthetic needs a count}"); shift ;;
    --first-seed) args+=("first_seed=${2:?--first-seed needs a seed}"); shift ;;
    --log) log="${2:?--log needs a path}"; shift ;;
    -h | --help) sed -n '2,/^set /{/^#/s/^# \{0,1\}//p}' "$0"; exit 0 ;;
    *)
      [[ "$1" =~ ^[0-9]+$ ]] || { echo "soak: unknown argument $1 (try --help)"; exit 2; }
      games="$1"
      ;;
  esac
  shift
done
LOG_DIR="$(dirname "$log")"
mkdir -p "$LOG_DIR"
# shellcheck source=scripts/godot_log.sh
. "$ROOT/scripts/godot_log.sh"
godot_log_init "$LOG_DIR"
timeout "${SOAK_TIMEOUT:-7200}" "${GODOT:-godot}" --headless -s res://tools/checks/soak.gd -- \
  "games=$games" "${args[@]}" >"$log" 2>&1
status=$?
grep '^soak:' "$log"
case "$status" in
  0 | 1) ;;
  *) echo "soak: CRASH: Godot exited $status" ;;
esac
grep -q '^soak: violations ' "$log" || { echo "soak: CRASH: the run ended before its report"; status=3; }
bad="$(godot_log_problems "$log")"
if [ -n "$bad" ]; then
  echo "soak: log problems:"
  echo "$bad" | head -20
  [ "$status" -ne 0 ] || status=1
fi
echo "soak: exit $status (full log: $log)"
exit "$status"
