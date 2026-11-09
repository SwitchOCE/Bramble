extends SceneTree
## Matching native screenshots from one saved production-UI state, before and after UI repairs.
## Usage: ... -s res://tests/ui/shots/wave1_ui_followup.gd -- <WxH> <before|after> <out>

const App := preload("res://src/ui/app.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")

var _window: Vector2i
var _phase: String
var _out: String
var _app: App
var _port: FixturePort
var _captures: Array[Dictionary] = []


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 3 or args[1] not in ["before", "after"]:
		printerr("usage: -- <WxH> <before|after> <out>")
		quit(2)
		return
	var dims: PackedStringArray = args[0].split("x")
	_window = Vector2i(int(dims[0]), int(dims[1]))
	_phase = args[1]
	_out = args[2]
	DirAccess.make_dir_recursive_absolute(_out)
	DisplayServer.window_set_size(_window)
	root.size = _window
	CardView.window_override = Vector2(_window)
	@warning_ignore("missing_await")
	_run()


func _run() -> void:
	await process_frame
	var prior: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(
			"res://docs/ideation/evidence/wave1/screenshots-1920x1080.json"
		)
	)
	_port = FixturePort.new()
	for capture: Dictionary in prior["captures"]:
		if str(capture["file"]) == "ring-carry-away-birds-1920x1080.png":
			var captured_state: Dictionary = capture["state"]
			_port._state = captured_state.duplicate(true)
	assert(not _port.get_state().is_empty())
	_app = App.new()
	root.add_child(_app)
	_app.setup(_port)
	_app.show_recruit()
	var screen: RecruitScreen = _app.current as RecruitScreen
	await _capture("overview")
	screen._on_tapped("board", 4)
	await _capture("ring-reader")
	screen._on_tapped("table", -1)
	await _capture("away-tray")
	var file := FileAccess.open(
		_out.path_join(_phase + "-" + _dimensions() + ".json"), FileAccess.WRITE
	)
	(
		file
		. store_string(
			(
				(
					JSON
					. stringify(
						{
							"phase": _phase,
							"pixels": [_window.x, _window.y],
							"setup":
							"FixturePort replays the previously captured controlled production state.",
							"state_source": "screenshots-1920x1080.json: ring-carry-away-birds",
							"state": _port.get_state(),
							"captures": _captures,
						},
						"\t"
					)
				)
				+ "\n"
			)
		)
	)
	root.remove_child(_app)
	_app.queue_free()
	await process_frame
	quit()


func _capture(scene: String) -> void:
	var screen: RecruitScreen = _app.current as RecruitScreen
	screen._clear_toast()
	for frame: int in 20:
		await process_frame
	var filename: String = "ui-" + _phase + "-" + scene + "-" + _dimensions() + ".png"
	var captured: Image = root.get_texture().get_image()
	assert(captured.get_size() == _window)
	assert(captured.save_png(_out.path_join(filename)) == OK)
	var detail: CardDetail = screen.get("_detail")
	var preview: Dictionary = {}
	if _phase == "after":
		var tray: Control = screen.get("_away_tray")
		var notes: RichTextLabel = tray.get("_notes")
		preview = {
			"visible": tray.is_visible_in_tree(),
			"rect": str(tray.get_global_rect()),
			"text": notes.text,
			"font_size": notes.get_theme_font_size("normal_font_size"),
		}
	var end_button: Control = screen.get("_end_button")
	var subtitle: Label = end_button.get("_sub")
	(
		_captures
		. append(
			{
				"file": filename,
				"detail_shown": detail.shown,
				"away_preview": preview,
				"end_button_rect": str(end_button.get_global_rect()),
				"end_subtitle_rect": str(subtitle.get_global_rect()),
				"layout_notes": Array(LayoutCheck.problems(screen, scene, false)),
			}
		)
	)
	print(filename)


func _dimensions() -> String:
	return "%dx%d" % [_window.x, _window.y]
