extends SceneTree
## Batch phone renders of rewritten card text in the normal recruit reader, from current content.
## LP_NUM_THREADS=1 taskset -c 2 xvfb-run -a godot --rendering-driver opengl3 \
##   --audio-driver Dummy -s res://tests/ui/shots/commitment_cards.gd -- <out> [ids...]
## Add _golden to a unit id to inspect its golden text. Default: every changed card, both versions.

const App := preload("res://src/ui/app.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")

const SPELLS: PackedStringArray = [
	"stand_behind_me", "bread_from_the_back", "harvest_supper", "hiring_fair"
]
const UNITS: PackedStringArray = [
	"queen_of_elfland",
	"charcoal_burner",
	"seven_whistlers",
	"fairy_monarch",
	"elder_ooze",
	"moss_ooze",
	"laird_of_sett"
]
const PHONE: Vector2i = Vector2i(1688, 780)


func _initialize() -> void:
	DisplayServer.window_set_size(PHONE)
	root.size = PHONE
	@warning_ignore("missing_await")
	_run()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("usage: -- <out directory> [card ids...]")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(args[0])
	var ids: PackedStringArray = args.slice(1)
	if ids.is_empty():
		ids.append_array(SPELLS)
		for id: String in UNITS:
			ids.append(id)
			ids.append(id + "_golden")
	var library: UnitLibrary = TestLibraries.current()
	var port: FixturePort = FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	var state: Dictionary = port.get_state()
	state["lobby_tribes"] = ["Hedgerow folk", "Fairies", "Oozes", "Birds", "Hunters"]
	state["tribe_bonuses"] = {"Fairies": 3, "Oozes": 1, "Birds": 2}
	state["pending_choice"] = null
	state["away"] = []
	state["slot_effects"] = [[], [], [], [], [], [], []]
	state["bands"] = [false, false, false, false, false, false, false]
	state["hand"] = []
	state["board"] = [null, null, null, null, null, null, null]
	var app: App = App.new()
	root.add_child(app)
	app.setup(port)
	for id: String in ids:
		var unit_id: String = id.trim_suffix("_golden")
		var spell: bool = SPELLS.has(id)
		state["hand_items"] = []
		var board: Array = state["board"]
		board[0] = null
		if spell:
			state["hand_items"] = [HandItem.make(library.get_card(id), 1).view()]
		else:
			var unit: RecruitUnit = RecruitUnit.make(
				library.get_unit(unit_id), 1, id.ends_with("_golden")
			)
			unit.origin = RecruitUnit.ORIGIN_BOUGHT
			board[0] = unit.view()
		app.show_recruit()
		var screen: RecruitScreen = app.current as RecruitScreen
		screen.call("_on_tapped", "hand" if spell else "board", 0)
		screen.call("_clear_toast")
		for frame: int in 8:
			await process_frame
		var image: Image = root.get_texture().get_image()
		var detail: CardDetail = screen.get("_detail")
		var scale: float = float(image.get_height()) / root.get_visible_rect().size.y
		var bounds: Rect2 = detail.get_global_rect()
		var crop: Rect2i = Rect2i(bounds.position * scale, bounds.size * scale)
		image.get_region(crop).save_png(args[0].path_join(id + ".png"))
		var notes: RichTextLabel = detail.get("_notes")
		print(
			(
				"commit_phone: %s %s scroll=%s"
				% [id, crop.size, notes.get_content_height() > notes.size.y + 1]
			)
		)
	quit(0)
