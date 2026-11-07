#!/usr/bin/env bash
# Sourced by scripts/export_smoke.sh, not run: stops the Gradle daemons one run started, and no
# others. A daemon inherits the environment of the build that launched it, so a variable
# exported with a value unique to this run marks the daemons it starts.
#   gradle_daemons_mark_run      once, before any Gradle build
#   gradle_daemons_stop_marked   stops the marked daemons (TERM, then KILL after 10 s)

gradle_daemons_mark_run() {
  BRAMBLE_GRADLE_RUN="$$-$(date +%s%N)"
  export BRAMBLE_GRADLE_RUN
}

gradle_daemons_stop_marked() {
  local mark pid others=0
  [ -n "${BRAMBLE_GRADLE_RUN:-}" ] || return 0
  mark="BRAMBLE_GRADLE_RUN=$BRAMBLE_GRADLE_RUN"
  for pid in $(pgrep -f GradleDaemon); do
    if ! tr '\0' '\n' <"/proc/$pid/environ" 2>/dev/null | grep -qxF "$mark"; then
      others=$((others + 1))
      continue
    fi
    kill "$pid" 2>/dev/null || continue
    for _ in $(seq 20); do
      # Gone, or a zombie waiting for its parent to reap it.
      case "$(ps -o stat= -p "$pid" 2>/dev/null)" in "" | Z*) break ;; esac
      sleep 0.5
    done
    kill -9 "$pid" 2>/dev/null
    echo "stopped the Gradle daemon this run started (pid $pid)"
  done
  [ "$others" -eq 0 ] || echo "note: left $others Gradle daemon(s) this run did not start"
  return 0
}
