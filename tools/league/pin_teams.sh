#!/usr/bin/env bash
# Keeps each team's processes on that team's cores (brief section 6, T3 amendment).
#
# T3's server starts every agent, so a team's thread can't be started inside a
# CPU-limited group. Instead this loop finds every process whose working folder is
# under one of a team's folders and sets its allowed cores. Children started later
# inherit them. A process that changes its own cores is put back on the next pass,
# and the change is logged.
#
# usage: pin_teams.sh [--once] [--log FILE] DIR=CPULIST [DIR=CPULIST ...]
#   e.g. pin_teams.sh /home/alex/league/red=0,1 /home/alex/league/blue=2,3
# Change a team's cores by stopping this and starting it with the new lists.
# For a whole league, run it as a user service so it outlives the referee's shell:
#   systemd-run --user --unit league-pin --collect tools/league/pin_teams.sh --log FILE DIR=CPUS ...
#   systemctl --user is-active league-pin
set -u
once=0
log=/dev/stderr
rules=()
while [ $# -gt 0 ]; do
  case "$1" in
    --once) once=1 ;;
    --log) shift; log="$1" ;;
    *=*) rules+=("$1") ;;
    *) echo "usage: pin_teams.sh [--once] [--log FILE] DIR=CPULIST ..." >&2; exit 2 ;;
  esac
  shift
done
[ ${#rules[@]} -gt 0 ] || { echo "no DIR=CPULIST given" >&2; exit 2; }

# The hex mask taskset prints for a core list such as "0,1" or "2-3".
mask() {
  local m=0 part lo hi i
  for part in ${1//,/ }; do
    lo=${part%-*}; hi=${part#*-}
    for ((i = lo; i <= hi; i++)); do m=$((m | (1 << i))); done
  done
  printf '%x' "$m"
}

pass() {
  local p pid cwd rule dir cpus cur
  for p in /proc/[0-9]*; do
    pid=${p#/proc/}
    cwd=$(readlink "$p/cwd" 2>/dev/null) || continue
    for rule in "${rules[@]}"; do
      dir=${rule%%=*}; cpus=${rule#*=}
      case "$cwd/" in
        "$dir"/*)
          cur=$(taskset -p "$pid" 2>/dev/null | sed 's/.*: //') || break
          if [ "$cur" != "$(mask "$cpus")" ]; then
            if taskset -a -cp "$cpus" "$pid" >/dev/null 2>&1; then
              echo "$(date +%FT%T) pinned $pid ($(cat "$p/comm" 2>/dev/null)) mask $cur -> cores $cpus [$dir]" >>"$log"
            fi
          fi
          break ;;
      esac
    done
  done
}

if [ $once -eq 1 ]; then pass; exit 0; fi
while :; do pass; sleep 5; done
