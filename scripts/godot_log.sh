#!/usr/bin/env bash
# Shared by scripts/check.sh and scripts/export_smoke.sh (sourced, not run): what counts as a
# problem in a Godot log. Any ERROR / WARNING / SCRIPT ERROR / Parse Error / handle_crash line,
# except lines matching tools/checks/log_allowlist.txt.
#   godot_log_init <work dir>   once, before godot_log_problems
#   godot_log_problems <log>    prints the problem lines; prints nothing when the log is clean

GODOT_PROBLEM_RE='(^|[^A-Za-z_])(ERROR|WARNING|SCRIPT ERROR|Parse Error)[: ]|handle_crash'
GODOT_LOG_ALLOWLIST=""

godot_log_init() {
  local root
  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  GODOT_LOG_ALLOWLIST="$1/log_allowlist.re"
  grep -vE '^[[:space:]]*(#|$)' "$root/tools/checks/log_allowlist.txt" >"$GODOT_LOG_ALLOWLIST" || true
}

godot_log_problems() {
  if [ -s "$GODOT_LOG_ALLOWLIST" ]; then
    grep -E "$GODOT_PROBLEM_RE" "$1" | grep -vEf "$GODOT_LOG_ALLOWLIST"
  else
    grep -E "$GODOT_PROBLEM_RE" "$1"
  fi
}
