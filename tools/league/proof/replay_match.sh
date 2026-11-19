#!/usr/bin/env bash
# Verify every official match record against the GDScript engine.
# Usage: replay_match.sh <match-dir> [jobs]
set -uo pipefail

jobs=${2-4}
if [[ $# -lt 1 || $# -gt 2 || ! $jobs =~ ^[1-9][0-9]*$ ]]; then
  echo "Usage: replay_match.sh <match-dir> [positive jobs, default 4]" >&2
  exit 2
fi

SECONDS=0
matched=0
total=0
summary() {
  printf 'replay_match: %d of %d records matched in %ds\n' "$matched" "$total" "$SECONDS"
}

match_dir=$(CDPATH='' cd -- "$1" && pwd -P) || { summary; exit 1; }
shopt -s nullglob
records=("$match_dir"/records/game-*.jsonl)
total=${#records[@]}
if (( total == 0 )); then
  summary
  exit 1
fi
if (( jobs > total )); then
  jobs=$total
fi
# A match that lost a record must not pass: the count has to equal the match's own.
if [[ -f "$match_dir/summary.json" ]]; then
  expected=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["games"])' "$match_dir/summary.json") || { summary; exit 1; }
  if (( expected != total )); then
    printf 'FAIL %s: %d records found, but summary.json says %d games\n' "$match_dir" "$total" "$expected"
    summary
    exit 1
  fi
fi

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." || exit 2
mkdir -p .copies || exit 2

work=
interrupted=0
declare -A active=()

# Each background timeout gets its own process group. Forward interruption to
# those groups and reap the supervisors before removing their log directories.
set -m
cleanup() {
  local pid
  trap '' HUP INT TERM
  for pid in "${!active[@]}"; do
    kill -TERM -- "-$pid" 2>/dev/null || true
  done
  for pid in "${!active[@]}"; do
    wait -f "$pid" 2>/dev/null || true
    kill -KILL -- "-$pid" 2>/dev/null || true
  done
  if [[ -n $work ]]; then
    rm -rf -- "$work"
  fi
}
trap cleanup EXIT
# Wait until the newly launched PID has been registered before acting on a signal.
trap 'interrupted=129' HUP
trap 'interrupted=130' INT
trap 'interrupted=143' TERM

work=$(mktemp -d "$PWD/.copies/replay-match.XXXXXXXX") || exit 2
# shellcheck source=scripts/godot_log.sh
. scripts/godot_log.sh
godot_log_init "$work"
complete_report='^records: matched [0-9]+ turns, [0-9]+ checkpoints; complete$'

reap_one() {
  local pid status index record log problem report
  status=0
  wait -n -f -p pid "${!active[@]}" 2>/dev/null || status=$?
  (( interrupted == 0 )) || exit "$interrupted"
  if [[ ! -v pid ]]; then
    # wait -n can miss jobs that finished before it started.
    for pid in "${!active[@]}"; do break; done
    status=0
    wait -f "$pid" 2>/dev/null || status=$?
    (( interrupted == 0 )) || exit "$interrupted"
  fi

  kill -KILL -- "-$pid" 2>/dev/null || true
  index=${active[$pid]}
  unset 'active[$pid]'
  record=${records[$index]}
  log="$work/$index.log"

  problem=$(godot_log_problems "$log" | head -n 1)
  report=$(grep -m 1 '^records: ' "$log")
  if [[ -n $problem ]]; then
    printf 'FAIL %s: %s\n' "$record" "$problem"
  elif (( status == 0 )) && [[ $report =~ $complete_report ]]; then
    (( matched += 1 ))
  elif [[ -n $report && $report != *'; complete' ]]; then
    printf 'FAIL %s: %s\n' "$record" "${report#records: }"
  elif (( status == 124 || status == 137 )); then
    printf 'FAIL %s: Godot timed out or was killed (exit %d)\n' "$record" "$status"
  else
    problem=$(grep -m 1 -Ev '^(Godot Engine |[[:space:]]*$)' "$log")
    printf 'FAIL %s: Godot exited %d without a successful replay%s\n' "$record" "$status" "${problem:+: $problem}"
  fi
  rm -rf -- "${work:?}/$index" "$log"
}

for index in "${!records[@]}"; do
  (( interrupted == 0 )) || exit "$interrupted"
  record=${records[$index]}
  if [[ ! -f $record || ! -r $record ]]; then
    printf 'FAIL %s: record is not a readable file\n' "$record"
    continue
  fi
  sandbox="$work/$index"
  XDG_DATA_HOME="$sandbox/data" XDG_CONFIG_HOME="$sandbox/config" XDG_CACHE_HOME="$sandbox/cache" \
    timeout -k 10 "${RECORDS_TIMEOUT:-1800}" "${GODOT:-godot}" --headless \
      -s res://tools/checks/records.gd -- "record=$record" </dev/null >"$work/$index.log" 2>&1 &
  active[$!]=$index
  if (( ${#active[@]} >= jobs )); then
    (( interrupted == 0 )) || exit "$interrupted"
    reap_one
  fi
done
while (( ${#active[@]} > 0 )); do
  (( interrupted == 0 )) || exit "$interrupted"
  reap_one
done

(( interrupted == 0 )) || exit "$interrupted"
summary
(( matched == total ))
