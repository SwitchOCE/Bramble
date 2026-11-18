#!/usr/bin/env bash
# The referee's analysis of one played match: exact events from the records, the section 9
# reports, the deep analytics, and (for an official match) each team's own view.
# usage: analyse_match.sh <match-dir> [<naive-match-dir>] [--teams]
# Runs on the referee's cores (4,5). Reports land in the match folder.
set -u
m=$(cd "$1" && pwd); naive=""; teams=0
shift
for a in "$@"; do [ "$a" = --teams ] && teams=1 || naive=$(cd "$a" && pwd); done
export PATH="$HOME/.cargo/bin:$PATH"
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
A=$here/analysis
run() { echo "== $*"; taskset -c 4,5 "$@" || { echo "FAILED: $*"; fail=1; }; }
fail=0
(cd "$here" && taskset -c 4,5 env CARGO_BUILD_JOBS=2 cargo build --offline --locked --release -p bramble-events 2>&1 | tail -1)
# Not piped through `run`: a pipe would put `run` in a subshell and lose its failure.
echo "== bramble-events $m"
if ev=$(taskset -c 4,5 "$here/target/release/bramble-events" "$m" 2>&1); then echo "$ev" | tail -3
else echo "$ev" | tail -5; echo "FAILED: bramble-events (events.py below would read an old archive, so stopping)"; exit 1; fi
for s in cards tribes behaviours agree events; do run python3 "$A/$s.py" "$m" >/dev/null; done
run python3 "$A/winscore.py" "$m"
[ -n "$naive" ] && run python3 "$A/findings.py" "$m" "$naive" >/dev/null
run python3 "$A/deep/run.py" "$m" >/dev/null
if [ $teams -eq 1 ]; then
  for c in red blue; do run python3 "$A/split_team.py" "$m" "$c" "$m/teams/$c" >/dev/null; done
fi
ls "$m" "$m/deep" | tr '\n' ' '; echo; exit $fail
