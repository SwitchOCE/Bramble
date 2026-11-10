#!/usr/bin/env bash
# Starts and waits for runs of the Actions sim job (.github/workflows/sim.yml).
#   scripts/sim-run.sh <config.json> [--base <commit>]
#                       commit the config as sim/<id>.json on top of <commit> (default HEAD), without
#                       touching the working tree, and push it to ideation/sim/<id>. The id is the
#                       config's file name without .json; an id already on origin is refused.
#   scripts/sim-run.sh --wait <id>
#                       wait for the results commit, copy sim/<id>/ to build/sim/<id>/ and print the
#                       summary's path. Exits 1 if the run failed.
# Status comes from gh when it's logged in, otherwise from the public REST API.
# Exit: 0 done, 1 run failed, 2 usage or setup error.
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2
REPO="${SIM_REPO:-SwitchOCE/Bramble}"
POLL=30

usage() { sed -n '2,/^set /{/^#/s/^# \{0,1\}//p}' "$0"; }

# api <path>: a REST call, through gh when it's logged in.
api() {
  if gh auth status >/dev/null 2>&1; then
    gh api "$1"
  else
    curl -fsS "https://api.github.com/$1"
  fi
}

# run_state <branch>: "<status> <conclusion> <url>" of the branch's newest Sim run, or nothing.
run_state() {
  api "repos/$REPO/actions/workflows/sim.yml/runs?branch=$1&per_page=1" 2>/dev/null | python3 -c '
import json, sys
runs = json.load(sys.stdin).get("workflow_runs", [])
if runs:
    print(runs[0]["status"], runs[0]["conclusion"] or "-", runs[0]["html_url"])'
}

start() {
  local config="$1" base="${2:-HEAD}" id branch blob tree commit index
  [ -f "$config" ] || { echo "no such config: $config"; exit 2; }
  id="$(basename "$config" .json)"
  [[ "$id" =~ ^[a-z0-9][a-z0-9._-]*$ ]] || { echo "id '$id' must be lower-case letters, digits, . _ -"; exit 2; }
  branch="ideation/sim/$id"
  base="$(git rev-parse --verify -q "$base^{commit}")" || { echo "unknown commit: ${2:-HEAD}"; exit 2; }
  python3 tools/sim/sim_job.py matrix "$config" >/dev/null || exit 2
  if git ls-remote --exit-code origin "refs/heads/$branch" >/dev/null 2>&1; then
    echo "$branch is already on origin; pick a new id"
    exit 2
  fi
  index="$(mktemp)"
  GIT_INDEX_FILE="$index" git read-tree "$base"
  blob="$(git hash-object -w "$config")"
  GIT_INDEX_FILE="$index" git update-index --add --cacheinfo "100644,$blob,sim/$id.json"
  tree="$(GIT_INDEX_FILE="$index" git write-tree)"
  rm -f "$index"
  commit="$(git commit-tree "$tree" -p "$base" -m "sim $id: config")"
  git push -q origin "$commit:refs/heads/$branch" || { echo "push to $branch failed"; exit 2; }
  echo "SIM $id pushed $commit (base $base) to $branch"
  echo "wait with: scripts/sim-run.sh --wait $id"
}

wait_for() {
  local id="$1" branch="ideation/sim/$1" state out t0=$SECONDS seen_success=0
  out="build/sim/$id"
  while true; do
    if git fetch -q origin "refs/heads/$branch" 2>/dev/null \
      && git cat-file -e "FETCH_HEAD:sim/$id/summary.json" 2>/dev/null; then
      rm -rf "$out" && mkdir -p "$out"
      git archive FETCH_HEAD "sim/$id" | tar -x -C "$out" --strip-components=2
      echo "SIM $id DONE $(git rev-parse FETCH_HEAD) after $((SECONDS - t0)) s of waiting"
      echo "$out/summary.json"
      return 0
    fi
    state="$(run_state "$branch")"
    case "$state" in
      # The merge job pushes before the run completes, so one more fetch must find it.
      "completed success "*)
        [ "${seen_success:-0}" -eq 0 ] || { echo "SIM $id: run passed but no results on $branch"; return 1; }
        seen_success=1
        continue
        ;;
      completed*)
        echo "SIM $id FAILED: $state"
        return 1
        ;;
    esac
    sleep "$POLL"
  done
}

case "${1:-}" in
  "" | -h | --help)
    usage
    [ -n "${1:-}" ] || exit 2
    ;;
  --wait)
    [ -n "${2:-}" ] || { usage; exit 2; }
    wait_for "$2"
    ;;
  *)
    if [ "${2:-}" = "--base" ]; then
      [ -n "${3:-}" ] || { usage; exit 2; }
      start "$1" "$3"
    else
      [ "$#" -eq 1 ] || { usage; exit 2; }
      start "$1"
    fi
    ;;
esac
