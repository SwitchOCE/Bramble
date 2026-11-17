extends GutTest
## The main scene loads, opens on the start screen and prints the line the export smoke test
## waits for.

const MainScene: PackedScene = preload("res://src/main/main.tscn")
const MainScript := preload("res://src/main/main.gd")


func test_main_scene_opens_on_the_start_screen() -> void:
	var main: Control = MainScene.instantiate() as Control
	assert_not_null(main, "main.tscn root is a Control")
	add_child_autofree(main)
	var script: Script = main.get_script()
	assert_same(script, MainScript, "root carries main.gd")
	assert_true(main.get_node_or_null("Start") is StartScreen, "the start screen shows")


func test_play_starts_a_game_and_escape_pauses_it() -> void:
	var main: Control = MainScene.instantiate() as Control
	add_child_autofree(main)
	var start: StartScreen = main.get_node("Start")
	start.play_requested.emit(PackedStringArray())
	await wait_process_frames(2)
	assert_true(main.get_node_or_null("Game") is GameController, "a game is on screen")
	main.call("toggle_pause")
	assert_true(main.get_node_or_null("PauseLayer/Pause") is PausePanel, "the pause panel opens")
	assert_true(get_tree().paused, "the game is paused")
	main.call("toggle_pause")
	assert_false(get_tree().paused, "resumed")


func _click(cog: SettingsCog, at: Vector2) -> void:
	for down: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = at
		cog._input(event)


func test_the_cog_shows_in_a_game_and_opens_and_closes_the_pause_panel() -> void:
	var main: Control = MainScene.instantiate() as Control
	add_child_autofree(main)
	var cog: SettingsCog = main.get("cog")
	assert_false(cog.is_visible_in_tree(), "no cog on the start screen")
	var start: StartScreen = main.get_node("Start")
	start.play_requested.emit(PackedStringArray())
	await wait_process_frames(2)
	assert_true(cog.is_visible_in_tree(), "the cog in a game")
	var middle: Vector2 = cog.position + cog.size / 2.0
	_click(cog, middle + Vector2(cog.size.x, 0))
	assert_null(main.get_node_or_null("PauseLayer/Pause"), "a click beside it does nothing")
	_click(cog, middle)
	assert_true(main.get_node_or_null("PauseLayer/Pause") is PausePanel, "the cog opens the panel")
	assert_true(get_tree().paused, "the game is paused")
	_click(cog, middle)
	assert_null(main.get_node_or_null("PauseLayer/Pause"), "and closes it")
	assert_false(get_tree().paused, "resumed")


func test_the_cog_does_nothing_while_a_card_is_held() -> void:
	var main: Control = MainScene.instantiate() as Control
	add_child_autofree(main)
	var start: StartScreen = main.get_node("Start")
	start.play_requested.emit(PackedStringArray())
	await wait_process_frames(2)
	var cog: SettingsCog = main.get("cog")
	var game: GameController = main.get_node("Game")
	var recruit: RecruitScreen = game.recruit
	recruit._input.press(recruit.shop_xy(0) + recruit.card_box() / 2.0)
	assert_true(recruit.is_holding(), "a shop card held")
	_click(cog, cog.position + cog.size / 2.0)
	assert_null(main.get_node_or_null("PauseLayer/Pause"), "no panel while a card is held")


func test_the_panel_lights_the_drop_choice_and_saves_it() -> void:
	GameSettings.path = "user://test_main_scene_settings.cfg"
	GameSettings.forget()
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
	DirAccess.remove_absolute(GameSettings.path)
	GameSettings.path = GameSettings.DEFAULT_PATH
	GameSettings.forget()


func test_ready_line_matches_export_smoke() -> void:
	var smoke: String = FileAccess.get_file_as_string("res://scripts/export_smoke.sh")
	assert_string_contains(smoke, MainScript.READY_LINE)
