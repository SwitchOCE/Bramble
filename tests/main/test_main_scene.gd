extends GutTest
## The main scene loads, builds its tree and prints the line the export smoke test waits for.

const MainScene: PackedScene = preload("res://src/main/main.tscn")
const MainScript := preload("res://src/main/main.gd")


func test_main_scene_instantiates_as_control() -> void:
	var main: Control = MainScene.instantiate() as Control
	assert_not_null(main, "main.tscn root is a Control")
	add_child_autofree(main)
	var script: Script = main.get_script()
	assert_same(script, MainScript, "root carries main.gd")
	assert_not_null(main.get_node_or_null("Title"), "title label exists")


func test_ready_line_matches_export_smoke() -> void:
	var smoke: String = FileAccess.get_file_as_string("res://scripts/export_smoke.sh")
	assert_string_contains(smoke, MainScript.READY_LINE)
