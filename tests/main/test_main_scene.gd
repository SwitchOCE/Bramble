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
	assert_true(main.get_node_or_null("Pause") is PausePanel, "the pause panel opens")
	assert_true(get_tree().paused, "the game is paused")
	main.call("toggle_pause")
	assert_false(get_tree().paused, "resumed")


func test_ready_line_matches_export_smoke() -> void:
	var smoke: String = FileAccess.get_file_as_string("res://scripts/export_smoke.sh")
	assert_string_contains(smoke, MainScript.READY_LINE)
