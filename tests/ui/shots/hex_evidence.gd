extends SceneTree
## A4 evidence: real screen widgets with full 7/4/7 state, and every shipped portrait.

const Card := preload("res://src/ui/widgets/card_view.gd")
const Recruit := preload("res://src/ui/screens/recruit_screen.gd")
const Fight := preload("res://src/ui/screens/combat_screen.gd")
const Fixture := preload("res://src/ui/adapter/fixture_port.gd")
const Views := preload("res://src/ui/unit_views.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Settings := preload("res://src/ui/settings.gd")
const IDS: PackedStringArray = [
	"little_nip", "mrs_jay", "wick", "field_vole", "old_brock", "prima_donna", "mother_goose"
]
const OUT: String = "res://build/loop1/hex/"

var _size: Vector2i
var _library: UnitLibrary


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var dims: PackedStringArray = args[1].split("x")
	_size = Vector2i(int(dims[0]), int(dims[1]))
	root.size = _size
	DisplayServer.window_set_size(_size)
	Settings.reset()
	_library = UnitLibrary.load_dir()
	@warning_ignore("missing_await")
	_run(args[0])


func _unit(id: String, uid: int, golden: bool = false) -> Dictionary:
	var view: Dictionary = Views.from_def(_library.get_unit(id), golden, uid)
	view["iid"] = uid
	return view


func _boards() -> Array:
	var boards: Array = [[], []]
	for side: int in 2:
		for slot: int in 7:
			var view: Dictionary = _unit(IDS[slot], side * 100 + slot + 1, slot == 4)
			if slot == 4:
				view["attack"] = 999
				view["health"] = 888
				view["max_health"] = 888
			var row: Array = boards[side]
			row.append(view)
	return boards


func _run(kind: String) -> void:
	await process_frame
	if kind == "portraits":
		await _portraits()
	elif kind == "states":
		await _states()
	elif kind == "recruit":
		var port := Fixture.new()
		port.use_state_file("res://tests/ui/data/recruit_slice.json")
		var state: Dictionary = port.get_state()
		state["board"] = _boards()[0]
		state["hand"] = []
		state["hand_items"] = []
		state["hand_limit"] = 4
		state["shop"] = []
		state["shop_size"] = 7
		state["tier"] = 6
		for slot: int in 7:
			var shop: Array = state["shop"]
			shop.append(_unit(IDS[slot], 300 + slot))
		for slot: int in 4:
			var hand: Array = state["hand"]
			hand.append(_unit(IDS[slot], 400 + slot))
		var screen := Recruit.new()
		root.add_child(screen)
		screen.setup(port)
		await _save("recruit-full")
	else:
		var screen := Fight.new()
		screen.manual_playback = true
		screen.auto_return = false
		root.add_child(screen)
		var rng := RandomNumberGenerator.new()
		rng.seed = 20261112
		var engine: Combat = Combat.create(_library, GameConfig.full_game(), rng)
		var fight: Dictionary = engine.run(_boards(), [6, 6], [0, 1], 0)
		screen.setup(fight, ["You", "Them"], 0, "Round 12", 30)
		if kind == "movie":
			for frame: int in 180:
				screen.advance_playback(1.0 / 30.0)
				await process_frame
		else:
			screen.playing = false
			for event: Dictionary in screen.events:
				screen._play_event(event, str(event["type"]) == "attack")
				if str(event["type"]) == "attack":
					break
			screen.playing = true
			screen.advance_playback(0.08)
			screen.playing = false
			await _save("fight-mid-attack")

	quit(0)


func _save(label: String) -> void:
	for frame: int in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var path: String = OUT + "%s-%dx%d.png" % [label, _size.x, _size.y]
	assert(root.get_texture().get_image().save_png(path) == OK)
	print("hex evidence: ", path)


func _portraits() -> void:
	var files: PackedStringArray = DirAccess.get_files_at("res://assets/portraits")
	var ids: PackedStringArray = []
	for file: String in files:
		if file.ends_with(".jpg"):
			ids.append(file.get_basename())
	var page: int = 0
	for first: int in range(0, ids.size(), 32):
		var sheet := Control.new()
		sheet.theme = UiTheme.get_theme()
		root.add_child(sheet)
		var background := ColorRect.new()
		background.color = Color("3d4540")
		background.size = Vector2(_size)
		sheet.add_child(background)
		for index: int in mini(32, ids.size() - first):
			var id: String = ids[first + index]
			var card := Card.new()
			card.show_unit(
				{"def_id": id, "portrait_id": id, "kind": "unit", "attack": 12, "health": 19},
				Card.Mode.BOARD
			)
			card.set_card_size(Vector2(176, 226))
			card.position = Vector2(50 + (index % 8) * 228, 10 + floori(index / 8.0) * 266)
			sheet.add_child(card)
			var label: Label = UiTheme.label(id, 20, Color.WHITE)
			label.position = card.position + Vector2(-10, 226)
			label.size = Vector2(218, 32)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sheet.add_child(label)
		page += 1
		await _save("portraits-%02d" % page)
		root.remove_child(sheet)
		sheet.queue_free()
	print("hex evidence: all ", ids.size(), " portraits at 176x226")


func _states() -> void:
	var sheet := Control.new()
	sheet.theme = UiTheme.get_theme()
	root.add_child(sheet)
	var samples: Array[Dictionary] = [
		_unit("little_nip", 1),
		_unit("mrs_jay", 2, true),
		_unit("wick", 3),
		{"def_id": "acorn", "kind": "item", "gold_value": 3},
		{"def_id": "horseshoe", "kind": "spell", "cost": 2}
	]
	for index: int in samples.size():
		var card := Card.new()
		var view: Dictionary = samples[index]
		if index < 3:
			view["attack"] = 999
			view["health"] = 888
			view["max_health"] = 888
			view["keywords"] = ["Mire", "Quarry", "Swoop"]
		card.show_unit(view, Card.Mode.BOARD)
		card.set_card_size(Vector2(176, 226))
		card.position = Vector2(230 + index * 250, 300)
		card.selected = index == 0
		sheet.add_child(card)
	await _save("golden-stats-keywords-types")
