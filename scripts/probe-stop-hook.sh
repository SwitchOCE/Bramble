#!/usr/bin/env bash
# Throwaway steering test: tell issue 19 when a cloud worker's turn ends.
# Lives only on probe/steering. It never blocks the turn from ending.
[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0
input="$(cat)"
active="$(printf '%s' "$input" | sed -n 's/.*"stop_hook_active": *\(true\|false\).*/\1/p')"
gh api repos/SwitchOCE/Bramble/issues/19/comments \
  -f body="HOOK turn-ended $(date -u +%H:%M:%SZ) stop_hook_active=${active:-unknown} branch=$(git branch --show-current 2>/dev/null)" \
  >/dev/null 2>&1 || true
exit 0
