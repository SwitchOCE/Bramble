#!/usr/bin/env bash
# Throwaway steering test (issue 19). Runs in the worker's VM for up to 3 hours.
# Every 15 s it reads the issue for the owner's `Orchestrator:` comments. Every
# 30 s it rewrites one STATUS comment with what the VM is really doing.
state=/tmp/probe19
here="$(cd "$(dirname "$0")" && pwd)"
api=repos/SwitchOCE/Bramble/issues
exec 9>"$state/lock"
flock -n 9 || exit 0
touch "$state/seen"

# Messages from before this VM started don't count.
gh api "$api/19/comments?per_page=100" --jq '.[].id' >"$state/seen" 2>/dev/null
status_id="$(gh api "$api/19/comments" -f body="STATUS starting $(date -u +%H:%M:%SZ)" --jq .id 2>/dev/null)"

tick=0
while [ "$SECONDS" -lt 10800 ]; do
  gh api "$api/19/comments?per_page=100" \
    --jq '.[] | select(.user.login=="SwitchOCE" and (.body|startswith("Orchestrator:"))) | "\(.id)\t\(.body)"' \
    >"$state/comments" 2>/dev/null
  while IFS=$'\t' read -r id body; do
    grep -qx "$id" "$state/seen" && continue
    printf '%s\n' "$id" >>"$state/seen"
    printf '%s\n' "$body" >>"$state/inbox"
    if [ "$body" = "Orchestrator: STOP" ]; then
      touch "$state/stopped"
      date -u +%H:%M:%SZ >"$state/stop-seen"
      pkill -f export_smoke.sh
      pkill -f gradle
      pkill -f godot
    fi
    [ "$body" = "Orchestrator: RESUME" ] && rm -f "$state/stopped"
  done <"$state/comments"

  if [ $((tick % 2)) -eq 0 ] && [ -n "$status_id" ]; then
    transcript="$(cat "$state/transcript" 2>/dev/null)"
    age=unknown
    [ -f "$transcript" ] && age="$(($(date +%s) - $(stat -c %Y "$transcript")))s"
    gh api -X PATCH "$api/comments/$status_id" -f body="STATUS $(date -u +%H:%M:%SZ)
last transcript write: $age ago
build processes: $(pgrep -fc 'export_smoke|gradle|godot')
marker jobs: $(pgrep -fc 'probe-background')
$(python3 "$here/probe-transcript.py" "$transcript" tokens 2>&1 | head -c 300)
inbox delivered: $(tr '\n' ' ' <"$state/delivered" 2>/dev/null)
guard refused: $(tr '\n' ' ' <"$state/guard-refused" 2>/dev/null)
stop seen: $(cat "$state/stop-seen" 2>/dev/null)" >/dev/null 2>&1
  fi
  tick=$((tick + 1))
  sleep 15
done
