#!/usr/bin/env bash
# Throwaway steering test (issue 19). Lives only on probe/steering.
# start:    start the VM daemon.
# stop:     post the turn's end, token totals and the full last message.
# guard:    refuse merges and pushes to main; refuse every tool after STOP.
# inbox:    hand any waiting orchestrator message to the worker.
[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0
event="$1"
input="$(cat)"
here="$CLAUDE_PROJECT_DIR/scripts"
state=/tmp/probe19
mkdir -p "$state"
field() { printf '%s' "$input" | python3 -c "import json,sys; print(json.load(sys.stdin).get('$1') or '')" 2>/dev/null; }
deny() {
  python3 -c 'import json,sys; print(json.dumps({"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":sys.argv[1]}}))' "$1"
  exit 0
}

case "$event" in
start)
  field transcript_path >"$state/transcript"
  setsid nohup bash "$here/probe-daemon.sh" </dev/null >/dev/null 2>&1 &
  ;;
stop)
  transcript="$(field transcript_path)"
  [ -n "$transcript" ] && printf '%s\n' "$transcript" >"$state/transcript"
  summary="$(python3 "$here/probe-transcript.py" "$transcript" full 2>&1 | head -c 60000)"
  gh api repos/SwitchOCE/Bramble/issues/19/comments \
    -f body="HOOK turn-ended $(date -u +%H:%M:%SZ) branch=$(git branch --show-current 2>/dev/null)
$summary" >/dev/null 2>&1 || true
  ;;
guard)
  [ -e "$state/stopped" ] && deny "Orchestrator: STOP was sent. Don't use any more tools. End your turn and say so."
  command="$(printf '%s' "$input" | python3 -c "import json,sys; print((json.load(sys.stdin).get('tool_input') or {}).get('command') or '')" 2>/dev/null)"
  if printf '%s' "$command" | grep -Eq 'pulls/[0-9]+/merge|gh pr merge|git push.*[ :](refs/heads/)?main( |$)'; then
    date -u +%H:%M:%SZ >>"$state/guard-refused"
    deny "This worker may not merge or push to main (rule W2)."
  fi
  ;;
inbox)
  [ -s "$state/inbox" ] || exit 0
  mv "$state/inbox" "$state/inbox.$$" 2>/dev/null || exit 0
  date -u +%H:%M:%SZ >>"$state/delivered"
  python3 -c 'import json,sys; print(json.dumps({"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"New message on your issue, from the orchestrator:\n"+open(sys.argv[1]).read()}}))' "$state/inbox.$$"
  rm -f "$state/inbox.$$"
  ;;
esac
exit 0
