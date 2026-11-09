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
cp "$SOURCE/tests/ui/shots/declutter_seed_input.gd" "$BASELINE/tests/ui/shots/declutter_seed_input.gd"
cp "$SOURCE/tests/ui/shots/declutter_baseline_replay.gd" "$BASELINE/tests/ui/shots/declutter_baseline_replay.gd"
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
\t\t\tvar healths: Array[int] = []
\t\t\tvar snapshot: Dictionary = session.get_state()
\t\t\tvar standings: Array = snapshot["standings"]
\t\t\tfor id: Variant in ids:
\t\t\t\tvar health: int = -1
\t\t\t\tfor standing: Dictionary in standings:
\t\t\t\t\tif CoreUtil.to_int(standing.get("player_id", -2)) == CoreUtil.to_int(id):
\t\t\t\t\t\thealth = CoreUtil.to_int(standing.get("health", -1))
\t\t\t\thealths.append(health)
\t\t\t_declutter_input["hero_health_before"] = healths
\t\tif previous.is_valid():
\t\t\tprevious.call(input, result, fight)
\tvar reason: String = session.end_turn()
\tsession.fight_capture_observer = previous
\treturn _after(reason)'''
assert old in text
text = text.replace(old, new)
text = text.replace('\nfunc ', '\nvar _declutter_input: Dictionary = {}\n\n\nfunc ', 1)
file.write_text(text)
file = root / "tests/ui/shots/screenshot.gd"
text = file.read_text()
start = text.index("func _play_until(")
end = text.index("\n\nfunc _run(", start)
text = text[:start] + '''func _play_until(combat: CombatScreen, index: int) -> void:
\tcombat.playing = false
\twhile combat.next_index < index:
\t\tvar event: Dictionary = combat.events[combat.next_index]
\t\tcombat._play_event(event, false)
\t\tcombat.next_index += 1
\tfor frame: int in 2:
\t\tawait process_frame
''' + text[end:]
text = text.replace('for i: int in 20:', 'for i: int in 2:')
file.write_text(text)
file = root / "tests/ui/shots/wave1_evidence.gd"
text = file.read_text()
text = text.replace('_port.session._players[0].ring_size == 1.25', '_port.session._players[0].ring_size > 1.0')
text = text.replace('var returned: Dictionary = _find_hand("one_swallow")', 'var returned: Dictionary = _find_hand("one_swallow")\n\tvar flight_spec: Dictionary = _before_flight["one_swallow"]')
text = text.replace('CoreUtil.to_int(returned.get("attack")) == 14', 'CoreUtil.to_int(returned.get("attack")) == CoreUtil.to_int(flight_spec["attack"]) * 2')
text = text.replace('CoreUtil.to_int(returned.get("health")) == 16', 'CoreUtil.to_int(returned.get("health")) == CoreUtil.to_int(flight_spec["health"]) * 2')
start = text.index('\n\tawait _readers()')
end = text.index('\n\nfunc _find_shop()', start)
text = text[:start] + '\n\tprint("declutter: real homecoming checkpoint saved")\n\tquit(0)\n' + text[end:]
text = text.replace('func _capture(name: String, details: Dictionary) -> void:\n', 'func _capture(name: String, details: Dictionary) -> void:\n\tif name != "homecoming-following-combat":\n\t\treturn\n')
text = text.replace('for _frame: int in 20:', 'for _frame: int in 2:')
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
if [ ! -f "$OUT/before/combat_mid_1688x780.json" ]; then
  render combat-mid-1688x780 -s res://tests/ui/shots/screenshot.gd -- combat_mid 1688x780 "$OUT/before/combat_mid_1688x780.png"
fi
timeout 180 godot --headless -s res://tests/ui/shots/declutter_seed_input.gd -- "$OUT/before" \
  >"$SOURCE/build/declutter/baseline-logs/seed-input.log" 2>&1
mkdir -p "$OUT/before/wave1-1688x780"
render homecoming-1688x780 -s res://tests/ui/shots/wave1_evidence.gd -- 1688x780 "$OUT/before/wave1-1688x780"
cp "$OUT/before/wave1-1688x780/homecoming-following-combat-1688x780.png" "$OUT/before/homecoming-following-combat_1688x780.png"
cp "$OUT/before/wave1-1688x780/homecoming-following-combat-1688x780.json" "$OUT/before/homecoming-following-combat_1688x780.json"
rm -rf "$OUT/before/wave1-1688x780"
render rival-1688x780 -s res://tests/ui/shots/declutter_rival.gd -- 1688x780 "$OUT/before/rival-fight_1688x780.png"
render replays -s res://tests/ui/shots/declutter_baseline_replay.gd -- "$OUT/before"
echo 'declutter: baseline captures complete'
