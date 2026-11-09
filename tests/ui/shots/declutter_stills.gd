extends SceneTree
## Replays the exact before-capture event checkpoint through the current combat presentation.

const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const Capture := preload("res://tests/ui/shots/declutter_capture.gd")
const Settings := preload("res://src/ui/settings.gd")

var _folder: String
var _out: String


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_folder = args[0]
	_out = args[1]
	Settings.path = "user://declutter_stills_settings.cfg"
	Settings.reset()
	@warning_ignore("missing_await")
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out)
	var reports: Array[Dictionary] = []
	for dimensions: String in ["1688x780", "1920x1080"]:
		var dims: PackedStringArray = dimensions.split("x")
		var pixels := Vector2i(dims[0].to_int(), dims[1].to_int())
		DisplayServer.window_set_size(pixels)
		root.size = pixels
		await process_frame
		for scenario: String in [
			"combat_mid", "combat_reminder", "homecoming-following-combat", "rival-fight"
		]:
			var stem: String = "%s_%s" % [scenario, dimensions]
			var fixture: Dictionary = JSON.parse_string(
				FileAccess.get_file_as_string(_folder.path_join(stem + ".json"))
			)
			Settings.field_mode_enabled = scenario == "rival-fight"
			Settings.opponents = "field" if Settings.field_mode_enabled else "bots"
			var names: Array = fixture["names"]
			var combat: Dictionary = fixture["combat"]
			var screen := CombatScreen.new()
			root.add_child(screen)
			Capture.presentation(screen, fixture)
			screen.setup(
				combat,
				PackedStringArray(names),
				CoreUtil.to_int(fixture["bottom_side"]),
				"Last fight",
				CoreUtil.to_int(fixture["opponent_health"])
			)
			screen.playing = false
			for index: int in CoreUtil.to_int(fixture["next_index"]):
				var event: Dictionary = screen.events[index]
				screen._play_event(event, false)
				screen.next_index = index + 1
			for frame: int in 2:
				await process_frame
			await RenderingServer.frame_post_draw
			var image: Image = root.get_texture().get_image()
			assert(image.get_size() == pixels)
			assert(image.save_png(_out.path_join(stem + ".png")) == OK)
			var nodes: Array[Dictionary] = Capture.text_nodes(screen)
			var budgeted: Array[Dictionary] = Capture.budget_nodes(screen)
			var report: Dictionary = {
				"scenario": scenario,
				"pixels": [pixels.x, pixels.y],
				"before_labels": fixture["visible_text_count"],
				"after_labels": nodes.size(),
				"ancillary_labels": budgeted.size(),
				"ancillary_budget": 10,
				"budgeted_text_nodes": budgeted,
				"visible_text_nodes": nodes,
				"next_index": screen.next_index,
				"same_event_checkpoint": true,
				"field_enabled": Settings.field_mode_enabled,
				"file": stem + ".png",
			}
			reports.append(report)
			print(
				(
					"declutter pair: %s labels before=%d after=%d ancillary=%d/10"
					% [
						stem,
						CoreUtil.to_int(fixture["visible_text_count"]),
						nodes.size(),
						budgeted.size()
					]
				)
			)
			assert(budgeted.size() <= 10, "combat ancillary label budget")
			root.remove_child(screen)
			screen.queue_free()
			await process_frame
	var file := FileAccess.open(_out.path_join("pairs.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(reports, "\t", true, true))
	file.close()
	quit(0)
