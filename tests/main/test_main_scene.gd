extends GutTest
## The main scene loads, opens on the start screen and prints the line the export smoke test
## waits for.

const MainScene: PackedScene = preload("res://src/main/main.tscn")
const MainScript := preload("res://src/main/main.gd")


func test_main_never_enables_play_without_a_field_folder() -> void:
	var main: Control = MainScene.instantiate() as Control
	assert_not_null(main, "main.tscn root is a Control")
	var root: String = FlowFixture.new_root()
	main.set(
		"ghost_store", LayeredGhostStore.new(root.path_join("player"), root.path_join("empty"))
	)
	add_child_autofree(main)
	var script: Script = main.get_script()
	assert_same(script, MainScript, "root carries main.gd")
	assert_true(main.get_node_or_null("Start") is StartScreen, "the start screen shows")
	var start: StartScreen = main.get_node("Start")
	assert_false(start.play_enabled)
	var button: Control = start.find_child("Button_Play", true, false) as Control
	assert_eq(button.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	start.play_requested.emit(PackedStringArray())
	assert_null(main.get_node_or_null("Game"), "no fallback opponents")
	assert_push_error("no ghost field folder")


func test_main_shows_error_g1_for_an_empty_or_mismatched_field(
	index: String = use_parameters(["", "wrong-rules"])
) -> void:
	var field: String = FlowFixture.new_root()
	assert_eq(DirAccess.make_dir_recursive_absolute(field), OK)
	var file: FileAccess = FileAccess.open(field.path_join("index.jsonl"), FileAccess.WRITE)
	assert_not_null(file)
	if not index.is_empty():
		(
			file
			. store_line(
				(
					JSON
					. stringify(
						{
							"id": "a".repeat(64),
							"rules_hash": "0".repeat(64),
							"kind": "bot",
							"label": "fixture",
							"placement": 1,
							"last_turn": 1,
							"made": "2026-11-20T00:00:00Z",
							"ended": "won",
						}
					)
				)
			)
		)
	file.close()
	var main: Control = MainScene.instantiate() as Control
	main.set("ghost_store", LayeredGhostStore.new(FlowFixture.new_root(), field))
	add_child_autofree(main)
	var start: StartScreen = main.get_node("Start")
	var message: GlassText = start.find_child("StartMessage", true, false) as GlassText
	assert_eq(message.words, "Error G1: this build has no ghosts to play against.")
	assert_false(start.play_enabled)
	if index.is_empty():
		assert_push_error("need 7 eligible ghost runs, found 0")
	else:
		assert_push_error("differs from the game's")


func test_play_starts_a_game_and_escape_pauses_it() -> void:
	var main: Control = MainScene.instantiate() as Control
	main.set("ghost_store", FlowFixture.test_store())
	add_child_autofree(main)
	var start: StartScreen = main.get_node("Start")
	assert_true(start.play_enabled)
	start.play_requested.emit(PackedStringArray())
	await wait_process_frames(2)
	assert_true(main.get_node_or_null("Game") is GameController, "a game is on screen")
	main.call("toggle_pause")
	assert_true(main.get_node_or_null("PauseLayer/Pause") is PausePanel, "the pause panel opens")
	assert_true(get_tree().paused, "the game is paused")
	main.call("toggle_pause")
	assert_false(get_tree().paused, "resumed")


func test_quitting_to_start_saves_no_ghost_and_keeps_seen_ids() -> void:
	var main: Control = MainScene.instantiate() as Control
	var store: LayeredGhostStore = FlowFixture.test_store()
	main.set("ghost_store", store)
	add_child_autofree(main)
	main.call("start_game")
	var game: GameController = main.get_node("Game")
	var first: Array[String] = game.flow.session.run_ids.slice(1)
	game.request({"type": "end_turn"})
	assert_eq(game.phase, GameController.Phase.FIGHT)
	game.fight.skip()
	game._after_fight()
	assert_eq(game.flow.session.round_number, 2)
	game.request({"type": "freeze"})
	main.call("toggle_pause")
	var panel: PausePanel = _pause_of(main)
	panel.quit_to_start_requested.emit()
	assert_true(main.get_node_or_null("Start") is StartScreen)
	var saved: Array[Dictionary] = GhostStore.new(store.directory).find()
	assert_eq(saved.size(), 0, "quitting after a fight leaves no ghost")
	main.call("start_game")
	game = main.get_node("Game")
	for id: String in game.flow.session.run_ids.slice(1):
		assert_does_not_have(first, id, "no rematch across games")
	main.call("toggle_pause")
	_pause_of(main).quit_to_start_requested.emit()
	assert_eq(GhostStore.new(store.directory).find().size(), 0, "no ghost before the first fight")
	var start: StartScreen = main.get_node("Start")
	assert_false(start.play_enabled, "the app has used all fourteen ghosts")
	assert_eq(start.message, MainScript.GHOSTS_USED)
	await wait_process_frames(2)


## A left click at a stage point as the player makes it: through the viewport, so every node's
## _input and the GUI see it in their own order.
func _real_click(at: Vector2) -> void:
	for down: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = at
		event.global_position = at
		get_viewport().push_input(event, true)


func _cog_middle(cog: SettingsCog) -> Vector2:
	return cog.get_global_transform_with_canvas() * (cog.size / 2.0)


func _main_in_a_game() -> Control:
	var main: Control = MainScene.instantiate() as Control
	main.set("ghost_store", FlowFixture.test_store())
	add_child_autofree(main)
	var start: StartScreen = main.get_node("Start")
	start.play_requested.emit(PackedStringArray())
	await wait_process_frames(2)
	return main


func _pause_of(main: Control) -> PausePanel:
	return main.get_node_or_null("PauseLayer/Pause") as PausePanel


func test_the_cog_shows_in_a_game_and_opens_the_pause_panel() -> void:
	var main: Control = MainScene.instantiate() as Control
	main.set("ghost_store", FlowFixture.test_store())
	add_child_autofree(main)
	var cog: SettingsCog = main.get("cog")
	assert_false(cog.is_visible_in_tree(), "no cog on the start screen")
	var start: StartScreen = main.get_node("Start")
	start.play_requested.emit(PackedStringArray())
	await wait_process_frames(2)
	assert_true(cog.is_visible_in_tree(), "the cog in a game")
	_real_click(_cog_middle(cog) + Vector2(cog.size.x, 0))
	assert_null(_pause_of(main), "a click beside it does nothing")
	_real_click(_cog_middle(cog))
	assert_not_null(_pause_of(main), "the cog opens the panel")
	assert_true(get_tree().paused, "the game is paused")
	# the panel's dim covers the cog: a click there neither closes the panel nor reaches the game
	var game: GameController = main.get_node("Game")
	var shown: int = game.recruit.shown_count()
	_real_click(_cog_middle(cog))
	assert_not_null(_pause_of(main), "a click on the cog while paused does not close the panel")
	assert_true(get_tree().paused, "still paused")
	assert_eq(game.recruit.shown_count(), shown, "and nothing reached the game")
	main.call("toggle_pause")
	assert_false(get_tree().paused, "Escape (or Resume) closes it, as before")


func test_the_cog_is_drawn_under_the_pause_panel() -> void:
	var main: Control = await _main_in_a_game()
	main.call("toggle_pause")
	var cog_layer: CanvasLayer = main.get_node("CogLayer")
	var pause_layer: CanvasLayer = main.get_node("PauseLayer")
	assert_lt(cog_layer.layer, pause_layer.layer, "the panel's dim over the cog")
	main.call("toggle_pause")


func test_a_click_on_the_cog_in_a_fight_opens_the_panel_and_does_not_skip() -> void:
	var main: Control = await _main_in_a_game()
	var game: GameController = main.get_node("Game")
	game.request({"type": "end_turn"})
	assert_eq(game.phase, GameController.Phase.FIGHT)
	# past the fight's first moments, when a click anywhere else skips it
	game._process(GameController.RESULT_GUARD)
	var cog: SettingsCog = main.get("cog")
	_real_click(_cog_middle(cog))
	assert_not_null(_pause_of(main), "the panel opens")
	assert_eq(game.phase, GameController.Phase.FIGHT, "the fight is not skipped")
	main.call("toggle_pause")
	_real_click(Vector2(960, 540))
	assert_eq(game.phase, GameController.Phase.AFTER_FIGHT, "a click elsewhere still skips")


func test_the_cog_does_nothing_while_a_card_is_held() -> void:
	var main: Control = await _main_in_a_game()
	var cog: SettingsCog = main.get("cog")
	var game: GameController = main.get_node("Game")
	var recruit: RecruitScreen = game.recruit
	recruit._input.press(recruit.shop_xy(0) + recruit.card_box() / 2.0)
	assert_true(recruit.is_holding(), "a shop card held")
	_real_click(_cog_middle(cog))
	assert_null(_pause_of(main), "no panel while a card is held")


func test_a_press_on_the_cog_is_forgotten_when_it_hides() -> void:
	var main: Control = await _main_in_a_game()
	var cog: SettingsCog = main.get("cog")
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = _cog_middle(cog)
	get_viewport().push_input(press, true)
	cog.visible = false
	cog.visible = true
	var release: InputEventMouseButton = press.duplicate()
	release.pressed = false
	get_viewport().push_input(release, true)
	assert_null(_pause_of(main), "a release after the cog hid is not a click on it")


func test_the_panel_lights_the_drop_choice_and_saves_it() -> void:
	var panel: PausePanel = PausePanel.new()
	add_child_autofree(panel)
	var pointer: Node = panel.find_child("Button_Pointer", true, false)
	var middle: Node = panel.find_child("Button_Card_middle", true, false)
	assert_not_null(pointer.get_node_or_null("Lit"), "the pointer on at first")
	assert_null(middle.get_node_or_null("Lit"))
	panel.choose_middle(true)
	assert_null(pointer.get_node_or_null("Lit"))
	assert_not_null(middle.get_node_or_null("Lit"), "the card's middle on")
	GameSettings.forget()
	assert_true(GameSettings.drop_by_middle(), "saved")
	# back as the tests' settings file started (tools/checks/gut_settings_hook.gd)
	assert_eq(DirAccess.remove_absolute(GameSettings.path), OK)
	GameSettings.forget()


func test_ready_line_matches_export_smoke() -> void:
	var smoke: String = FileAccess.get_file_as_string("res://scripts/export_smoke.sh")
	assert_string_contains(smoke, MainScript.READY_LINE)
