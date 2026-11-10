extends SceneTree
## Replays a tools/play save through the real CorePort and draws the real UI's screens at one size:
## the recruit screen at each turn's start and end, a frame strip of that turn's fight, and the
## game-over screen. Run through tools/play/render.sh, which loops the sizes and writes index.md:
##   xvfb-run -a godot --rendering-driver opengl3 --audio-driver Dummy \
##     -s res://tools/play/render.gd -- <save> <WxH> <out dir> [--turn N | --all]

const CorePort := preload("res://src/ui/adapter/core_port.gd")
const App := preload("res://src/ui/app.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const Records := preload("res://src/ui/records.gd")

## Frames in a fight strip, the last one after the fight's final event.
const STRIP: int = 6
const SETTLE_FRAMES: int = 24

var _size: Vector2i
var _out: String
var _files: Array = []
var _moments: Array = []


func _initialize() -> void:
	# The game-over screen records a result; keep it away from a player's real records.
	Records.path = "user://render_records.cfg"
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 3:
		printerr("usage: -- <save> <WxH> <out dir> [--turn N | --all]")
		quit(2)
		return
	var dims: PackedStringArray = args[1].split("x")
	_size = Vector2i(int(dims[0]), int(dims[1]))
	_out = args[2]
	DisplayServer.window_set_size(_size)
	root.size = _size
	var only: int = -1
	var index: int = args.find("--turn")
	if index >= 0 and index + 1 < args.size():
		only = args[index + 1].to_int()
	@warning_ignore("missing_await")
	_run(args[0], only)


func _run(save_path: String, only: int) -> void:
	await process_frame
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary:
		printerr("render: no save at %s" % save_path)
		quit(1)
		return
	var save: Dictionary = data
	var turns := PlayTurns.open(save)
	if turns.error != "":
		printerr("render: %s" % turns.error)
		quit(2)
		return
	var app := App.new()
	root.add_child(app)
	var port := CorePort.new()
	port.setup(GameConfig.full_game())
	port.session = turns.game.session
	app.setup(port)
	while true:
		var moment: Dictionary = turns.next()
		if moment.is_empty():
			break
		var wanted: bool = only < 0 or CoreUtil.to_int(moment["round"]) == only
		if moment["kind"] == PlayTurns.OVER:
			wanted = only < 0
		if wanted:
			await _draw(app, moment)
	if turns.error != "":
		printerr("render: %s" % turns.error)
		quit(2)
		return
	_write_manifest(save_path)
	quit(0)


func _draw(app: App, moment: Dictionary) -> void:
	var stem: String = "r%02d-%s" % [CoreUtil.to_int(moment["round"]), moment["kind"]]
	var entry: Dictionary = moment.duplicate(true)
	var files: Array = []
	match str(moment["kind"]):
		PlayTurns.START, PlayTurns.END:
			app.show_recruit()
			files.append(await _shoot(stem))
		PlayTurns.FIGHT:
			app.show_game_combat()
			var fight: CombatScreen = app.current as CombatScreen
			if fight != null:
				entry["shown"] = _shown(fight)
				files.append_array(await _strip(fight, stem))
		PlayTurns.OVER:
			app.show_recruit()
			files.append(await _shoot("over"))
	entry["files"] = files
	_moments.append(entry)


## STRIP frames spread over the fight's events: the first after the opening, the last at the end.
func _strip(fight: CombatScreen, stem: String) -> Array:
	fight.playing = false
	for i: int in 3:
		await process_frame
	var files: Array = []
	var count: int = fight.events.size()
	for frame: int in STRIP:
		if frame == STRIP - 1:
			fight.skip_to_end()
		else:
			var target: int = 1 + roundi(float(frame) * float(maxi(0, count - 2)) / (STRIP - 1))
			while fight.next_index < mini(target, count):
				fight.step_once()
		files.append(await _shoot("%s-%d" % [stem, frame + 1]))
	return files


## What the fight screen was given: the opponent on its plaque and the events it plays.
static func _shown(fight: CombatScreen) -> Dictionary:
	var plaque: Label = fight.get("_fight_name")
	return {"opponent": plaque.text if plaque != null else "", "events": fight.events.size()}


func _shoot(stem: String) -> String:
	for i: int in SETTLE_FRAMES:
		await process_frame
	var image: Image = root.get_texture().get_image()
	var name: String = "%s_%dx%d.png" % [stem, _size.x, _size.y]
	if image.get_size() != _size:
		printerr("render: got %s, wanted %s" % [image.get_size(), _size])
	image.save_png(_out.path_join(name))
	_files.append(name)
	return name


func _write_manifest(save_path: String) -> void:
	var manifest: Dictionary = {
		"save": save_path,
		"size": "%dx%d" % [_size.x, _size.y],
		"moments": _moments,
		"files": _files,
	}
	var path: String = _out.path_join("manifest_%dx%d.json" % [_size.x, _size.y])
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	print("render: %d files at %s" % [_files.size(), _size])
