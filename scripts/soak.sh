#!/usr/bin/env bash
# The rules soak: bot-only games with rules invariants (tools/checks/soak.gd). Fails on any
# violation, a crash, a run that ended before its report, or any problem line in the Godot log.
#   scripts/soak.sh [GAMES=300] [key=value ...]   e.g. scripts/soak.sh 50 first_seed=1000
# Extra key=value arguments go to soak.gd (first_seed, plant, checks). One Godot process, one
# core. The log goes to build/check/soak.log (SOAK_LOG overrides it).
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2
games=300
args=()
for arg in "$@"; do
  case "$arg" in
    -h | --help) sed -n '2,/^set /{/^#/s/^# \{0,1\}//p}' "$0"; exit 0 ;;
    *=*) args+=("$arg") ;;
    *)
      [[ "$arg" =~ ^[0-9]+$ ]] || { echo "soak: unknown argument $arg (try --help)"; exit 2; }
      games="$arg"
      ;;
  esac
done
log="${SOAK_LOG:-$ROOT/build/check/soak.log}"
mkdir -p "$(dirname "$log")"
# shellcheck source=scripts/godot_log.sh
. "$ROOT/scripts/godot_log.sh"
godot_log_init "$(dirname "$log")"
timeout "${SOAK_TIMEOUT:-1800}" "${GODOT:-godot}" --headless -s res://tools/checks/soak.gd -- \
  "games=$games" "${args[@]}" >"$log" 2>&1
status=$?
grep '^soak:' "$log"
case "$status" in
  0 | 1) ;;
  *) echo "soak: CRASH: Godot exited $status"; status=3 ;;
esac
grep -q '^soak: violations ' "$log" || { echo "soak: CRASH: the run ended before its report"; status=3; }
bad="$(godot_log_problems "$log")"
if [ -n "$bad" ]; then
  echo "soak: log problems:"
  echo "$bad" | head -20
  [ "$status" -ne 0 ] || status=1
fi
echo "soak: exit $status (log: $log)"
exit "$status"
