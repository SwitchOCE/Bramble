#!/usr/bin/env bash
# Runs the full gate for one commit on GitHub Actions and prints the verdict. Needs an
# authenticated gh (the local orchestrator's).
#   scripts/cloud-gate.sh <commit> [label]   push <commit> to ideation/gate/<short-sha>, wait for
#                                            its CI run, print GATE <sha> PASS|FAIL <url>; on a
#                                            failure, also the last 40 lines of the failed log
#   scripts/cloud-gate.sh --check <commit>   print whether <commit> has a successful gate run
#                                            (GATE <sha> PASSED <url>, or GATE <sha> NONE)
# Exit: 0 pass, 1 fail or no passing run, 2 usage or setup error.
# Each gate appends a line to ${XDG_STATE_HOME:-$HOME/.local/state}/bramble/cloud-gates.csv:
#   start_utc,label,sha,verdict,push_to_verdict_s,url
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2
WORKFLOW=ci.yml
GATE_LOG="${XDG_STATE_HOME:-$HOME/.local/state}/bramble/cloud-gates.csv"

usage() {
  sed -n '2,/^set /{/^#/s/^# \{0,1\}//p}' "$0"
}

# full_sha <commit>: the full sha, from the local repo or the remote.
full_sha() {
  git rev-parse --verify -q "$1^{commit}" 2>/dev/null && return 0
  gh api "repos/{owner}/{repo}/commits/$1" --jq .sha 2>/dev/null
}

# passed_run <sha>: url of a successful gate run (a push to ideation/gate/**) for <sha>.
passed_run() {
  gh run list --workflow "$WORKFLOW" --commit "$1" --event push --status success \
    --json url,headBranch --jq '[.[] | select(.headBranch | startswith("ideation/gate/"))][0].url // empty'
}

case "${1:-}" in
  "" | -h | --help)
    usage
    [ -n "${1:-}" ] || exit 2
    exit 0
    ;;
  --check)
    [ -n "${2:-}" ] || { usage; exit 2; }
    sha="$(full_sha "$2")" || { echo "unknown commit: $2"; exit 2; }
    url="$(passed_run "$sha")" || { echo "gh run list failed"; exit 2; }
    if [ -n "$url" ]; then
      echo "GATE $sha PASSED $url"
      exit 0
    fi
    echo "GATE $sha NONE"
    exit 1
    ;;
esac

sha="$(git rev-parse --verify -q "$1^{commit}")" || { echo "unknown commit: $1"; exit 2; }
label="${2:-}"
branch="ideation/gate/${sha:0:12}"
start_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
t0=$SECONDS

# The branch name holds the sha, so a re-gate of the same commit is a no-op push that finds the
# earlier run below.
git push -q origin "$sha:refs/heads/$branch" || { echo "push to $branch failed"; exit 2; }

# The run shows up a few seconds after the push.
run_id=""
for _ in $(seq 1 30); do
  run_id="$(gh run list --workflow "$WORKFLOW" --branch "$branch" --commit "$sha" --event push \
    --limit 1 --json databaseId --jq '.[0].databaseId // empty')"
  [ -n "$run_id" ] && break
  sleep 4
done
[ -n "$run_id" ] || { echo "no CI run found for $branch after 2 min"; exit 2; }

gh run watch "$run_id" --exit-status --interval 15 >/dev/null 2>&1
url="$(gh run view "$run_id" --json url --jq .url)"
conclusion="$(gh run view "$run_id" --json conclusion --jq .conclusion)"
verdict=FAIL
[ "$conclusion" = success ] && verdict=PASS

mkdir -p "$(dirname "$GATE_LOG")"
[ -s "$GATE_LOG" ] || echo "start_utc,label,sha,verdict,push_to_verdict_s,url" >>"$GATE_LOG"
echo "$start_utc,\"${label//\"/\"\"}\",$sha,$verdict,$((SECONDS - t0)),$url" >>"$GATE_LOG"

echo "GATE $sha $verdict $url"
if [ "$verdict" = FAIL ]; then
  gh run view "$run_id" --log-failed 2>&1 | tail -n 40
  exit 1
fi
