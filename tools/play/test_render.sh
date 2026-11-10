#!/usr/bin/env bash
# The render tool's test (needs xvfb and Mesa, so it isn't in the GUT suite):
# plays a short game, renders it twice, and checks both renders agree on state hashes and files,
# and that each fight strip shows the fight `play.sh <save> log` reports for its round.
#   tools/play/test_render.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLAY="$ROOT/tools/play/play.sh"
work="$ROOT/build/render-test"
rm -rf "$work"
mkdir -p "$work"
save="$work/render-test.json"
"$PLAY" new --seed 11 --save "$save" >/dev/null
for action in "choose 1" "buy 2" "play @3 F1" "end" "buy 0" "end"; do
  # shellcheck disable=SC2086
  "$PLAY" "$save" $action >/dev/null
done
"$PLAY" "$save" log >"$work/log.txt"
"$ROOT/tools/play/render.sh" "$save" --all
mv "$ROOT/build/render/render-test" "$work/first"
"$ROOT/tools/play/render.sh" "$save" --all
mv "$ROOT/build/render/render-test" "$work/second"
python3 "$ROOT/tools/play/render_check.py" "$work/first" "$work/second" "$work/log.txt"
