extends SceneTree
## Matched recruit evidence. Before serializes the exact inputs replayed by after.
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const Settings := preload("res://src/ui/settings.gd")
const Capture := preload("res://tests/ui/shots/declutter_capture.gd")

var _out: String
var _phase: String
var _window: Vector2i
var _states: Dictionary
var _manifest: Array[Dictionary] = []
var _selected: PackedStringArray = []


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	assert(args.size() in [3, 4], "usage: -- <WxH> <before|after> <batch2 output> [scenarios]")
	if args.size() == 4:
		_selected = args[3].split(",", false)
	var dims: PackedStringArray = args[0].split("x")
	_window = Vector2i(int(dims[0]), int(dims[1]))
	_phase = args[1]
	_out = args[2]
	root.size = _window
	DisplayServer.window_set_size(_window)
	CardView.window_override = Vector2(_window)
	Settings.path = "user://declutter_b2_evidence.cfg"
	Settings.reset()
	DirAccess.make_dir_recursive_absolute(_out.path_join(_phase))
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var state_path: String = _out.path_join("states.json")
	if _phase == "before" and not FileAccess.file_exists(state_path):
		_states = _make_states()
		_write(state_path, _states)
	else:
		_states = FixturePort.load_json(state_path)
	for scenario: String in [
		"overview", "reader-reel_mistress-golden", "natural-birds", "lobby", "scout"
	]:
		if _states.has(scenario) and (_selected.is_empty() or _selected.has(scenario)):
			await _capture(scenario)
	var manifest_path: String = _out.path_join(_phase).path_join(
		"manifest-%dx%d.json" % [_window.x, _window.y]
	)
	if not _selected.is_empty() and FileAccess.file_exists(manifest_path):
		var existing: Dictionary = FixturePort.load_json(manifest_path)
		for capture: Dictionary in existing.get("captures", []):
			if not _selected.has(str(capture["scenario"])):
				_manifest.append(capture)
	_write(
		_out.path_join(_phase).path_join("manifest-%dx%d.json" % [_window.x, _window.y]),
		{
			"phase": _phase,
			"pixels": [_window.x, _window.y],
			"captures": _manifest,
			"before_revision": "d400831e",
			"method":
			(
				"Same serialized production states; native viewport pixels; all visible nonempty "
				+ "text nodes count, including stats and fallback names."
			)
		}
	)
	quit()


func _make_states() -> Dictionary:
	var prior: Dictionary = FixturePort.load_json(
		"res://docs/ideation/evidence/wave1/screenshots-1920x1080.json"
	)
	var out: Dictionary = {}
	for capture: Dictionary in prior["captures"]:
		var file: String = str(capture["file"])
		if file == "ring-carry-away-birds-1920x1080.png":
			out["overview"] = {
				"state": capture["state"],
				"source":
				(
					"wave1/redbreast-label/ui-after-overview; "
					+ "wave1/screenshots-1920x1080.json: ring-carry-away-birds"
				),
				"seed": prior["seed"]
			}
		elif file == "reader-reel_mistress-golden-1920x1080.png":
			out["reader-reel_mistress-golden"] = {
				"state": capture["state"],
				"source": "wave1/screenshots-1920x1080.json: reader-reel_mistress-golden",
				"seed": prior["seed"]
			}
		elif file == "natural-birds-ring-and-away-1920x1080.png":
			out["natural-birds"] = {
				"state": capture["state"],
				"source": "wave1/screenshots-1920x1080.json: natural-birds-ring-and-away",
				"seed": capture["seed"]
			}
	return out


func _capture(scenario: String) -> void:
	var fixture: FixturePort = FixturePort.new()
	var captured: Dictionary = _states[scenario]["state"]
	fixture._state = captured.duplicate(true)
	var screen: RecruitScreen = RecruitScreen.new()
	root.add_child(screen)
	screen.setup(fixture)
	if scenario == "scout":
		screen.toggle_scout()
	elif scenario == "reader-reel_mistress-golden":
		var hand: Array = fixture.get_state()["hand"]
		for index: int in hand.size():
			var card: Dictionary = hand[index]
			if str(card.get("def_id", "")) == "reel_mistress":
				screen._on_tapped("hand", index)
	screen._clear_toast()
	for frame: int in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	var filename: String = "%s-%dx%d.png" % [scenario, _window.x, _window.y]
	var picture: Image = root.get_texture().get_image()
	assert(picture.get_size() == _window)
	assert(picture.save_png(_out.path_join(_phase).path_join(filename)) == OK)
	var nodes: Array[Dictionary] = Capture.text_nodes(screen)
	var board: Control = screen.get("_board")
	_manifest.append(
		{
			"file": filename,
			"scenario": scenario,
			"source": _states[scenario]["source"],
			"seed": _states[scenario]["seed"],
			"visible_text_count": nodes.size(),
			"visible_text_nodes": nodes,
			"pocket_canvas": [board.get("pocket").x, board.get("pocket").y],
			"board_rect": str(board.get_global_rect()),
			"state_sha256": JSON.stringify(captured, "", true, true).sha256_text(),
			"calm_mask_regions": _mask_regions(screen)
		}
	)
	print("declutter-b2: ", _phase, " ", filename, " labels=", nodes.size())
	root.remove_child(screen)
	screen.free()
	await process_frame


func _write(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null, path)
	file.store_string(JSON.stringify(value, "\t", true, true) + "\n")


## Auditable free-surface mask: text/control/art bounds occupy space; plain trays do not.
func _mask_regions(node: Node) -> Array[Dictionary]:
	var regions: Array[Dictionary] = []
	if node is CanvasItem:
		var item: CanvasItem = node as CanvasItem
		if not item.is_visible_in_tree() or item.modulate.a < 0.05:
			return regions
	if node is Control:
		var control: Control = node as Control
		var script_value: Variant = node.get_script()
		var path: String = ""
		if script_value is Script:
			var script: Script = script_value
			path = script.resource_path
		var occupied: bool = node is BaseButton or node is CardView
		occupied = occupied or path.ends_with("/art_frame.gd")
		occupied = occupied or path.ends_with("/shape_badge.gd")
		occupied = occupied or path.ends_with("/gold_plaque.gd")
		if node is Label:
			occupied = not (node as Label).text.strip_edges().is_empty()
		elif node is RichTextLabel:
			occupied = not (node as RichTextLabel).get_parsed_text().strip_edges().is_empty()
		if occupied and control.self_modulate.a >= 0.05:
			var rect: Rect2 = control.get_global_rect()
			regions.append(
				{
					"path": str(node.get_path()),
					"kind": path.get_file(),
					"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
				}
			)
	for child: Node in node.get_children():
		regions.append_array(_mask_regions(child))
	return regions
