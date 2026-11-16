#!/usr/bin/env bash
# Proves tools/look end to end on tests/look/look_demo.tscn, in about five seconds:
# start, shot, click the button, shot, read the click in the log, press E and read the error,
# press Q and see the quit reported, and see a missing scene fail fast. Exits 1 on any miss.
# Prints the two screenshot paths; open them to see "Not pressed", then "Pressed 1 time".
#   tools/look/demo.sh
set -uo pipefail
LOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/look"
SCENE=res://tests/look/look_demo.tscn
failed=0
fail() {
  echo "look demo: FAIL $*" >&2
  failed=1
}

session="$("$LOOK" start --scene "$SCENE")" || {
  echo "look demo: FAIL could not start $SCENE" >&2
  exit 1
}
trap '"$LOOK" --session "$session" stop >/dev/null 2>&1' EXIT
export BRAMBLE_LOOK_SESSION="$session"
before="$("$LOOK" shot before)" || fail "shot before"
# The button's centre: (640, 420) in the 1280x720 design, scaled 1.5x to the 1920x1080 window.
"$LOOK" click 960 630 || fail "click"
after="$("$LOOK" shot after)" || fail "shot after"
"$LOOK" log -n 200 | grep -q "look demo: pressed 1" || fail "the click did not press the button"
"$LOOK" key e || fail "key e"
"$LOOK" errors 2>/dev/null | grep -q "^ERROR: look demo: E was pressed" || fail "errors did not show the pushed error"
# Godot takes a moment to quit, so the key itself may still succeed; the next command must not.
if out="$("$LOOK" key q 2>&1 && "$LOOK" shot --wait 2 after_quit 2>&1)"; then
  fail "quitting the game was not reported"
else
  grep -q "exited with code 3" <<<"$out" || fail "quit reported as: $out"
fi
"$LOOK" errors 2>/dev/null | grep -q "E was pressed" || fail "errors unreadable after the game ended"
unset BRAMBLE_LOOK_SESSION
if out="$("$LOOK" start --scene res://tests/look/no_such_scene.tscn 2>&1)"; then
  fail "a missing scene started"
  "$LOOK" --session "$(tail -n 1 <<<"$out")" stop >/dev/null
else
  grep -q "no scene at" <<<"$out" || fail "missing scene reported as: $out"
fi

echo "before: $before"
echo "after:  $after"
[ "$failed" -eq 0 ] && echo "look demo: all checks passed"
exit "$failed"
