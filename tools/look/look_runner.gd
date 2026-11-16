extends SceneTree
## Started by tools/look/look.py, not by hand. Opens one scene as the running game would (it
## becomes current_scene), then writes the ready file once a few frames have been drawn.
## A scene that does not exist or does not load exits with LOAD_FAILED.
## Usage: godot --path . -s res://tools/look/look_runner.gd -- <res:// scene or ""> <ready file>

const LOAD_FAILED: int = 3
const SETTLE_FRAMES: int = 10


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 2:
		printerr("ERROR: look: expected -- <scene> <ready file>")
		quit(2)
		return
	var scene_path: String = args[0]
	if scene_path.is_empty():
		scene_path = str(ProjectSettings.get_setting("application/run/main_scene", ""))
	if not ResourceLoader.exists(scene_path, "PackedScene"):
		printerr("ERROR: look: no scene at '%s'" % scene_path)
		quit(LOAD_FAILED)
		return
	var packed: PackedScene = ResourceLoader.load(scene_path, "PackedScene") as PackedScene
	if packed == null or change_scene_to_packed(packed) != OK:
		printerr("ERROR: look: scene '%s' failed to load" % scene_path)
		quit(LOAD_FAILED)
		return
	for i: int in SETTLE_FRAMES:
		await process_frame
	var ready: FileAccess = FileAccess.open(args[1], FileAccess.WRITE)
	ready.store_string(scene_path)
	ready.close()
	print("look: ready %s" % scene_path)
