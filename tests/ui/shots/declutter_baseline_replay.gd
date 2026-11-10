extends SceneTree
## Runs only in the archived project: render old UI from the one-time scripted checkpoints.

const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const Capture := preload("res://tests/ui/shots/declutter_capture.gd")

var _out: String


func _initialize() -> void:
	_out = OS.get_cmdline_user_args()[0]
	@warning_ignore("missing_await")
	_run()


func _run() -> void:
	var fixtures: Dictionary = {}
	for scenario: String in [
		"combat_mid", "combat_reminder", "homecoming-following-combat", "rival-fight"
	]:
		var path: String = _out.path_join(scenario + "_1688x780.json")
		if not FileAccess.file_exists(path) and scenario == "combat_reminder":
			path = _out.path_join("combat_mid_1688x780.json")
		fixtures[scenario] = JSON.parse_string(FileAccess.get_file_as_string(path))
	for dimensions: String in ["1688x780", "1920x1080"]:
		var dims: PackedStringArray = dimensions.split("x")
		var pixels := Vector2i(dims[0].to_int(), dims[1].to_int())
		DisplayServer.window_set_size(pixels)
		root.size = pixels
		await process_frame
		for scenario: String in fixtures:
			var fixture: Dictionary = fixtures[scenario]
			var fight: Dictionary = fixture["combat"]
			var names: Array = fixture["names"]
			var screen := CombatScreen.new()
			root.add_child(screen)
			screen.setup(
				fight,
				PackedStringArray(names),
				CoreUtil.to_int(fixture["bottom_side"]),
				"Round %d" % CoreUtil.to_int(fight.get("round", 8)),
				CoreUtil.to_int(fixture["opponent_health"])
			)
			screen.playing = false
			for index: int in CoreUtil.to_int(fixture["next_index"]):
				var event: Dictionary = screen.events[index]
				screen._play_event(event, false)
				screen.next_index = index + 1
			if scenario == "combat_reminder":
				_open_reminder(screen, CoreUtil.to_int(fixture.get("reader_uid", -1)))
			for frame: int in 2:
				await process_frame
			await RenderingServer.frame_post_draw
			var image_path: String = _out.path_join("%s_%s.png" % [scenario, dimensions])
			Capture.baseline(root, image_path, CoreUtil.to_int(fixture["seed"]))
			assert(root.get_texture().get_image().save_png(image_path) == OK)
			var report_path: String = image_path.get_basename() + ".json"
			var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(report_path))
			for key: String in [
				"combat",
				"state",
				"hero_views",
				"hero_health",
				"hero_health_provenance",
				"fight_input"
			]:
				if fixture.has(key):
					report[key] = fixture[key]
			report["capture_method"] = "old UI, saved exact event checkpoint, synchronous events"
			var file := FileAccess.open(report_path, FileAccess.WRITE)
			file.store_string(JSON.stringify(report, "\t", true, true))
			file.close()
			root.remove_child(screen)
			screen.queue_free()
			await process_frame
	print("declutter: all eight old-UI baseline replays complete")
	quit(0)


func _open_reminder(screen: Control, preferred: int) -> void:
	var cards: Dictionary = screen.get("_cards")
	var ids: Array = [preferred] if cards.has(preferred) else cards.keys()
	var note: RichTextLabel = screen.get("_note_text")
	for uid: int in ids:
		screen.call("_show_detail", uid)
		var found: RegExMatch = RegEx.create_from_string("\\[url=(kw:[^\\]]+)\\]").search(note.text)
		if found != null:
			note.meta_hover_started.emit(found.get_string(1))
			note.meta_clicked.emit(found.get_string(1))
			return
