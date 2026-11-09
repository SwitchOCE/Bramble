extends SceneTree
## Current-rules replay of the committed seed-72, round-8 strong-field fight input.

const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const Capture := preload("res://tests/ui/shots/declutter_capture.gd")
const Settings := preload("res://src/ui/settings.gd")
const Replay := preload("res://tools/sim/fight_capture.gd")

var _size: Vector2i
var _out: String


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var dims: PackedStringArray = args[0].split("x")
	_size = Vector2i(dims[0].to_int(), dims[1].to_int())
	_out = args[1]
	DisplayServer.window_set_size(_size)
	root.size = _size
	Settings.path = "user://declutter_rival_settings.cfg"
	Settings.reset()
	Settings.field_mode_enabled = true
	Settings.opponents = "field"
	@warning_ignore("missing_await")
	_run()


func _run() -> void:
	await process_frame
	var source: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://docs/ideation/evidence/strong-field/ui-1688x780.json")
	)
	var inputs: Array = source["human_fight_inputs"]
	var input: Dictionary = inputs[7]
	assert(CoreUtil.to_int(input["round"]) == 8)
	var fight: Dictionary = Replay.replay(input, UnitLibrary.load_dir())
	fight["floor_marks"] = Capture.floor_marks(input)
	var screen := CombatScreen.new()
	root.add_child(screen)
	screen.setup(fight, PackedStringArray(["You", "Rival 4 · Brother Bracken"]), 0, "Round 8", 40)
	screen.playing = false
	for event: Dictionary in screen.events:
		screen._play_event(event, false)
		screen.next_index += 1
		if str(event.get("type", "")) == "attack":
			break
	for frame: int in 2:
		await process_frame
	await RenderingServer.frame_post_draw
	Capture.baseline(root, _out, CoreUtil.to_int(source["seed"]))
	var report_path: String = _out.get_basename() + ".json"
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(report_path))
	var heroes: Array[Dictionary] = [{}, {}]
	for hero: Dictionary in UnitLibrary.load_dir().all_heroes():
		if str(hero.get("id", "")) == "dame_farthing":
			heroes[0] = hero
		if str(hero.get("id", "")) == "brother_bracken":
			heroes[1] = hero
	report["hero_views"] = heroes
	report["hero_health"] = [-1, 40]
	report["combat"] = fight
	report["fight_input"] = input
	var report_file := FileAccess.open(report_path, FileAccess.WRITE)
	report_file.store_string(JSON.stringify(report, "\t", true, true))
	report_file.close()
	assert(root.get_texture().get_image().save_png(_out) == OK)
	print(
		(
			"declutter: rival replay source seed=%d round=8 flag=field size=%s"
			% [CoreUtil.to_int(source["seed"]), _size]
		)
	)
	quit(0)
