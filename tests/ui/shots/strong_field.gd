extends SceneTree
## Evidence only: boot the real main scene with --field-library and click New game/hero/End
## turn/Scout. The seed is pinned using the existing playthrough convention. Hard's legal
## recruit actions automate shopping; no boards, pairings, Health or fight results are staged.
## --probe finds a reachable human-vs-field-ghost game using exactly the same recruit driver.

const App := preload("res://src/ui/app.gd")
const CorePort := preload("res://src/ui/adapter/core_port.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const MainMenu := preload("res://src/ui/screens/main_menu.gd")
const Driver := preload("res://tests/ui/player_driver.gd")
const Settings := preload("res://src/ui/settings.gd")
const Records := preload("res://src/ui/records.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")

var _args: PackedStringArray
var _size: Vector2i
var _out: String
var _seed: int
var _shots: Array[Dictionary] = []
var _captures: Array[Dictionary] = []
var _layout: PackedStringArray = []
var _driver: Driver
var _app: App


func _initialize() -> void:
	_args = OS.get_cmdline_user_args()
	_seed = _option("--seed", "71").to_int()
	_out = _option("--out", "res://docs/ideation/evidence/strong-field")
	if _args.has("--probe"):
		_probe()
		return
	var dims: PackedStringArray = _option("--size", "1688x780").split("x")
	_size = Vector2i(int(dims[0]), int(dims[1]))
	DisplayServer.window_set_size(_size)
	root.size = _size
	Settings.path = "user://strong_field_proof_settings.cfg"
	Records.path = "user://strong_field_proof_records.cfg"
	Settings.reset()
	@warning_ignore("missing_await")
	_run()


func _option(key: String, fallback: String) -> String:
	var index: int = _args.find(key)
	return _args[index + 1] if index >= 0 and index + 1 < _args.size() else fallback


func _probe() -> void:
	var library := UnitLibrary.load_dir()
	for offset: int in 30:
		var config := GameConfig.full_game()
		var problem: String = FieldLibrary.configure(
			config, library, _option("--field-library", FieldLibrary.BUNDLED_PATH)
		)
		assert(problem == "", problem)
		var session := GameSession.create(_seed + offset, library, config)
		assert(session.choose(0) == "")
		var bot: Bot = Bot.create("hard")
		while not session.is_over():
			if session.get_state()["next_opponent_id"] == Matchmaking.GHOST:
				print(
					(
						"field-proof: reachable ghost seed=%d round=%d"
						% [_seed + offset, session._round]
					)
				)
				quit(0)
				return
			bot.play_turn(session._players[0], session.get_rules(), session._round)
			assert(session.end_turn() == "")
		print("field-proof: seed=%d finished without human ghost" % (_seed + offset))
	quit(1)


func _frames(count: int = 8) -> void:
	for frame: int in count:
		await process_frame


func _run() -> void:
	await _frames(2)
	var scene: PackedScene = load("res://src/main/main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)
	_app = main.get("app")
	var port: CorePort = _app.port as CorePort
	_driver = Driver.new(_seed)
	_driver.viewport = root
	Settings.seen_guide = true
	Settings.fight_speed = 4.0
	await _frames()
	var menu: MainMenu = _app.current as MainMenu
	menu.play_requested.disconnect(_app.request_new_game)
	menu.play_requested.connect(func() -> void: _app.start_game(_seed))
	var new_game: Button = menu.get_node("Newgame") as Button
	_driver.press(new_game, "New game")
	await _frames()
	assert(port.session != null and port.config.get_string("opponents") == "field")
	var recruit: RecruitScreen = _app.current as RecruitScreen
	_driver.answer_choices(recruit)
	await _frames()
	assert(port.get_state()["phase"] == "recruit")
	port.session.fight_capture_observer = _capture
	var bot: Bot = Bot.create("hard")
	var ghost_found: bool = false
	while not port.is_over():
		recruit = _app.current as RecruitScreen
		assert(recruit != null)
		var round_number: int = port.session._round
		var opponent: int = CoreUtil.to_int(port.get_state()["next_opponent_id"])
		var ghost: bool = opponent == Matchmaking.GHOST
		bot.play_turn(port.session._players[0], port.session.get_rules(), round_number)
		recruit.render()
		await _frames()
		if round_number == 8:
			await _shoot("lobby", round_number, opponent, recruit)
			_driver.press(_button(recruit, "_scout_token"), "Scout")
			await _frames()
			var scout: Control = recruit.get("_scout")
			assert(scout.visible)
			await _shoot("scout", round_number, opponent, recruit)
			_driver.press(_button(recruit, "_scout_token"), "Close")
			await _frames(2)
		if ghost:
			_driver.press(_button(recruit, "_scout_token"), "Scout")
			await _frames()
			await _shoot("ghost-scout", round_number, opponent, recruit)
			_driver.press(_button(recruit, "_scout_token"), "Close")
			await _frames(2)
		var expected: Dictionary = FieldRivals.side(port.session, opponent)
		_driver.end_turn(recruit)
		var combat: CombatScreen = _app.current as CombatScreen
		assert(combat != null)
		combat.playing = false
		await _frames(2)
		var captured: Dictionary = _captures.back()
		assert(
			(
				FieldLibrary.canonical(captured["boards"][1])
				== FieldLibrary.canonical(expected["board"])
			),
			"fight uses the scouted field input"
		)
		if round_number == 8 or ghost:
			while combat.next_index < combat.events.size():
				var event: Dictionary = combat.events[combat.next_index]
				combat.step_once()
				if event["type"] == "attack":
					break
			await _frames(24)
			await _shoot("ghost-fight" if ghost else "rival-fight", round_number, opponent, combat)
		if ghost:
			ghost_found = true
			break
		_driver.press(_button(combat, "_skip_button"), "Skip")
		await _frames()
		var result: Control = combat.get("_result_plaque")
		_driver.press(result.get_node("Continue") as Button, "Continue")
		await _frames()
	assert(ghost_found, "selected seed must reach an ordinary field ghost pairing")
	assert(_driver.missed_taps.is_empty(), str(_driver.missed_taps))
	var report: Dictionary = {
		"seed": _seed,
		"size": str(_size),
		"screenshots": _shots,
		"game_log": port.session.get_game_log(),
		"human_fight_inputs": _captures,
		"layout_observations": Array(_layout),
		"missed_clicks": Array(_driver.missed_taps),
		"method":
		(
			"real main scene, native launch flag, menu/hero/scout/end/skip/continue clicks; "
			+ "seed pinned; Hard automates legal recruit actions; no staged board or pairing"
		)
	}
	var file := FileAccess.open(
		_out.path_join("ui-%dx%d.json" % [_size.x, _size.y]), FileAccess.WRITE
	)
	file.store_string(JSON.stringify(report, "", true, true))
	file.close()
	print(
		(
			"field-proof: screenshots=%d seed=%d natural_ghost=true missed_clicks=0"
			% [_shots.size(), _seed]
		)
	)
	root.remove_child(main)
	main.queue_free()
	await _frames(2)
	quit(0)


func _button(node: Node, key: String) -> Button:
	var button: Button = node.get(key)
	return button


func _capture(input: Dictionary, _result: Dictionary, _combat: Combat) -> void:
	var ids: Array = input["player_ids"]
	if CoreUtil.to_int(ids[0]) == 0:
		_captures.append(input.duplicate(true))


func _shoot(kind: String, round_number: int, opponent: int, screen: Control) -> void:
	await _frames()
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	assert(picture.get_size() == _size)
	var path: String = _out.path_join("%s_%dx%d.png" % [kind, _size.x, _size.y])
	assert(picture.save_png(path) == OK)
	var observations: PackedStringArray = LayoutCheck.problems(
		screen, kind, not screen is CombatScreen
	)
	_layout.append_array(observations)
	_shots.append(
		{
			"kind": kind,
			"round": round_number,
			"opponent": opponent,
			"file": path.get_file(),
			"layout_observations": Array(observations)
		}
	)
	print("field-proof: saved=%s round=%d opponent=%d" % [path, round_number, opponent])
