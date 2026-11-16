extends SceneTree
## Started by tools/feel/film, not by hand. Opens a scenario's scene as the running game would
## (it becomes current_scene), then plays the scenario's pointer: synthetic mouse events through
## Input.parse_input_event along timed, eased paths, with an arrow drawn on top so a viewer can
## see it. Under --write-movie with --fixed-fps 60 every frame is rendered and written, however
## slow the machine is. Each press and release is logged to the events file, for frame strips
## (tools/feel/strips): "<frame> press|release <x> <y> <note>", x and y in window (film) pixels,
## the frame being the first one drawn after it.
## Usage: godot --path . -s res://tools/feel/feel_runner.gd -- <scenario.json> <events file>
##
## A scenario: {"scene": "res://...", "steps": [...]}. A step is one of
##   {"move": target, "time": s}   the pointer to target in s seconds, eased, in a slight arc
##   {"press": true, "note": ".."} the left button down where the pointer is
##   {"release": true, "note": ".."}
##   {"wait": s}
## A target is "x,y" in the scene's own pixels (the viewport's canvas, before the window's stretch),
## or a name the scene resolves: when the scene has
## feel_point(name: String) -> Vector2, that is asked first. Either may end in "+dx,dy".
## The scene may also have feel_setup(scenario: Dictionary), called once before the first step.

const FeelPointer := preload("res://tools/feel/feel_pointer.gd")
const LOAD_FAILED: int = 3
## Frames to let the scene draw before the first step.
const SETTLE_FRAMES: int = 5
## How long the film runs on after the last step, in seconds.
const TAIL: float = 0.5
## A path's sideways bow, as a share of its length (a hand moves in a slight arc).
const BOW: float = 0.06
## Where the pointer starts, as a share of the window.
const START: Vector2 = Vector2(0.5, 0.85)

var _steps: Array = []
var _step: int = -1
## The step being played: {kind, from, to, time, age}
var _now: Dictionary = {}
var _pointer: Vector2 = Vector2.ZERO
var _down: bool = false
var _arrow: FeelPointer
var _events: FileAccess
var _tail: float = -1.0
var _settle: int = SETTLE_FRAMES
var _scenario: Dictionary = {}


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 2:
		printerr("ERROR: feel: expected -- <scenario.json> <events file>")
		quit(2)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	if not parsed is Dictionary:
		printerr("ERROR: feel: %s is not a scenario (a JSON object)" % args[0])
		quit(2)
		return
	_scenario = parsed
	_steps = _scenario.get("steps", [])
	var scene_path: String = str(_scenario.get("scene", ""))
	if scene_path.is_empty():
		scene_path = str(ProjectSettings.get_setting("application/run/main_scene", ""))
	if not ResourceLoader.exists(scene_path, "PackedScene"):
		printerr("ERROR: feel: no scene at '%s'" % scene_path)
		quit(LOAD_FAILED)
		return
	var packed: PackedScene = ResourceLoader.load(scene_path, "PackedScene") as PackedScene
	if packed == null or change_scene_to_packed(packed) != OK:
		printerr("ERROR: feel: scene '%s' failed to load" % scene_path)
		quit(LOAD_FAILED)
		return
	_events = FileAccess.open(args[1], FileAccess.WRITE)
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 128
	root.add_child(layer)
	_arrow = FeelPointer.new()
	layer.add_child(_arrow)
	_pointer = root.get_visible_rect().size * START
	_arrow.position = _pointer


func _process(delta: float) -> bool:
	if _settle > 0:
		_settle -= 1
		if _settle == 0:
			if current_scene != null and current_scene.has_method("feel_setup"):
				current_scene.call("feel_setup", _scenario)
			_send_motion(_pointer)
			_next()
		return false
	if _tail >= 0.0:
		_tail -= delta
		if _tail <= 0.0:
			_events.close()
			quit(0)
		return false
	if _now.is_empty():
		return false
	_now["age"] = _num(_now["age"]) + delta
	var time: float = _now["time"]
	var t: float = 1.0 if time <= 0.0 else clampf(_num(_now["age"]) / time, 0.0, 1.0)
	if _now["kind"] == "move":
		var from: Vector2 = _now["from"]
		var to: Vector2 = _now["to"]
		var eased: float = t * t * (3.0 - 2.0 * t)
		var side: Vector2 = (to - from).orthogonal() * BOW * sin(PI * eased)
		_send_motion(from.lerp(to, eased) + side)
	if t >= 1.0:
		_next()
	return false


func _next() -> void:
	while true:
		_step += 1
		if _step >= _steps.size():
			_now = {}
			_tail = TAIL
			return
		var step: Dictionary = _steps[_step]
		if step.has("move"):
			var to: Vector2 = _resolve(str(step["move"]))
			_now = {"kind": "move", "from": _pointer, "to": to, "time": _num(step.get("time", 0.4))}
			_now["age"] = 0.0
			return
		if step.has("press") or step.has("release"):
			_send_button(step.has("press"), str(step.get("note", "")))
			continue
		_now = {"kind": "wait", "time": _num(step.get("wait", 0.0)), "age": 0.0}
		return


func _resolve(target: String) -> Vector2:
	var offset: Vector2 = Vector2.ZERO
	var plus: int = target.find("+")
	if plus >= 0:
		offset = _xy(target.substr(plus + 1))
		target = target.substr(0, plus)
	if target.contains(","):
		return _xy(target) + offset
	if current_scene == null or not current_scene.has_method("feel_point"):
		printerr("ERROR: feel: the scene has no feel_point() for target '%s'" % target)
		return _pointer
	var at: Vector2 = current_scene.call("feel_point", target)
	return at + offset


static func _num(v: Variant) -> float:
	return str(v).to_float()


static func _xy(words: String) -> Vector2:
	var parts: PackedStringArray = words.split(",")
	return Vector2(float(parts[0]), float(parts[1]))


## A point of the scene's canvas in window pixels, where input events are given (the window may
## stretch the canvas).
func _window(at: Vector2) -> Vector2:
	return root.get_final_transform() * at


func _send_motion(at: Vector2) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = _window(at)
	motion.global_position = motion.position
	motion.relative = motion.position - _window(_pointer)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT if _down else 0
	_pointer = at
	Input.parse_input_event(motion)
	_arrow.show_at(at, _down)


func _send_button(pressed: bool, note: String) -> void:
	_down = pressed
	var button: InputEventMouseButton = InputEventMouseButton.new()
	button.button_index = MOUSE_BUTTON_LEFT
	button.pressed = pressed
	button.position = _window(_pointer)
	button.global_position = button.position
	button.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(button)
	_arrow.show_at(_pointer, pressed)
	var line: String = (
		"%d %s %d %d %s"
		% [
			Engine.get_frames_drawn(),
			"press" if pressed else "release",
			roundi(button.position.x),
			roundi(button.position.y),
			note
		]
	)
	_events.store_line(line)
	print("feel: " + line)
