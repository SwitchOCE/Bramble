#!/usr/bin/env bash
# Run this entire job inside the shared flock/systemd wrapper. Never invokes Godot in parallel.
set -euo pipefail
BASELINE="$1"
OUT="$2"
SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
mkdir -p "$BASELINE" "$OUT/before" "$SOURCE/build/declutter/baseline-logs"
git -C "$SOURCE" archive 1ecbce6 | tar -x -C "$BASELINE"
cp "$SOURCE/tests/ui/shots/declutter_capture.gd" "$BASELINE/tests/ui/shots/declutter_capture.gd"
cp "$SOURCE/tests/ui/shots/declutter_rival.gd" "$BASELINE/tests/ui/shots/declutter_rival.gd"
python3 - "$BASELINE" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
hook = 'preload("res://tests/ui/shots/declutter_capture.gd").baseline(root, %s)'
for name, old, path in [
    ("screenshot.gd", "\timage.save_png(out_path)", "out_path"),
    ("wave1_evidence.gd", '\t_require(image.save_png(_out.path_join(filename)) == OK, "save screenshot " + filename)', '_out.path_join(filename)'),
    ("strong_field.gd", "\tassert(picture.save_png(path) == OK)", "path"),
]:
    file = root / "tests/ui/shots" / name
    text = file.read_text()
    assert old in text, name
    file.write_text(text.replace(old, "\t" + hook % path + "\n" + old))
file = root / "src/ui/adapter/core_port.gd"
text = file.read_text()
old = 'func end_turn() -> String:\n\treturn _after(session.end_turn()) if session != null else NOT_AVAILABLE'
new = '''func end_turn() -> String:
\tif session == null:
\t\treturn NOT_AVAILABLE
\tvar previous: Callable = session.fight_capture_observer
\tsession.fight_capture_observer = func(input: Dictionary, result: Dictionary, fight: Combat) -> void:
\t\tvar ids: Array = input["player_ids"]
\t\tif ids.has(0):
\t\t\t_declutter_input = input.duplicate(true)
\t\tif previous.is_valid():
\t\t\tprevious.call(input, result, fight)
\tvar reason: String = session.end_turn()
\tsession.fight_capture_observer = previous
\treturn _after(reason)'''
assert old in text
text = text.replace(old, new)
text = text.replace('\nfunc ', '\nvar _declutter_input: Dictionary = {}\n\n\nfunc ', 1)
file.write_text(text)
PY
cd "$BASELINE"
export LP_NUM_THREADS=1
godot --headless --import >"$SOURCE/build/declutter/baseline-logs/import.log" 2>&1
timeout 180 godot --headless -s res://tools/checks/compile_all.gd \
  >"$SOURCE/build/declutter/baseline-logs/compile.log" 2>&1
render() {
  local name="$1"
  shift
  timeout 300 xvfb-run -a -s '-screen 0 2560x1440x24' godot --rendering-driver opengl3 \
    --audio-driver Dummy --fixed-fps 120 "$@" \
    >"$SOURCE/build/declutter/baseline-logs/$name.log" 2>&1
}
for size in 1688x780 1920x1080; do
  render "combat-mid-$size" -s res://tests/ui/shots/screenshot.gd -- combat_mid "$size" "$OUT/before/combat_mid_$size.png"
  render "combat-reminder-$size" -s res://tests/ui/shots/screenshot.gd -- combat_reminder "$size" "$OUT/before/combat_reminder_$size.png"
  mkdir -p "$OUT/before/wave1-$size"
  render "homecoming-$size" -s res://tests/ui/shots/wave1_evidence.gd -- "$size" "$OUT/before/wave1-$size"
  cp "$OUT/before/wave1-$size/homecoming-following-combat-$size.png" "$OUT/before/homecoming-following-combat_$size.png"
  cp "$OUT/before/wave1-$size/homecoming-following-combat-$size.json" "$OUT/before/homecoming-following-combat_$size.json"
  rm -rf "$OUT/before/wave1-$size"
  render "rival-$size" -s res://tests/ui/shots/declutter_rival.gd -- "$size" "$OUT/before/rival-fight_$size.png"
done
echo 'declutter: baseline captures complete'
