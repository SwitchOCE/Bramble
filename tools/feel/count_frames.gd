extends SceneTree
## How many frames Godot draws in ten seconds of wall time on a scene, with a box moving across it
## (so every frame has something to draw). For the README's table: run it as the look tool runs a
## game, with the same flags, and divide by ten.
## Usage: xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
##   --audio-driver Dummy --windowed --resolution 1920x1080 --max-fps 30 \
##   -s res://tools/feel/count_frames.gd -- res://tools/feel/demo/feel_demo.tscn

const SECONDS: int = 10
## Frames to let the scene start before counting.
const WARM_UP: int = 20

var _began: int = 0
var _first: int = 0
var _box: ColorRect


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var packed: PackedScene = load(args[0]) as PackedScene
	change_scene_to_packed(packed)
	_box = ColorRect.new()
	_box.size = Vector2(200, 200)
	_box.color = Color.RED
	var layer: CanvasLayer = CanvasLayer.new()
	root.add_child(layer)
	layer.add_child(_box)


func _process(_delta: float) -> bool:
	_box.position.x = fmod(Time.get_ticks_msec() * 0.5, 1700.0)
	if _began == 0 and Engine.get_frames_drawn() > WARM_UP:
		_began = Time.get_ticks_msec()
		_first = Engine.get_frames_drawn()
	elif _began > 0 and Time.get_ticks_msec() - _began >= SECONDS * 1000:
		var secs: float = (Time.get_ticks_msec() - _began) / 1000.0
		print("count_frames: %d frames in %.2f s" % [Engine.get_frames_drawn() - _first, secs])
		quit(0)
	return false
