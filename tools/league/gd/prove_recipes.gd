extends SceneTree
## Initial header oracles: core/game, custom config, subsets, stand-ins and signed seed text.


func _initialize() -> void:
	var all: PackedStringArray = ContentSet.folders_in(ContentSet.ROOT)
	var cases: Array[Dictionary] = [
		{"kind": "core", "paths": Array(all), "seed": "-19", "players": 4},
		{"kind": "game", "paths": ["res://src/content/locust", "res://src/content/shared"],
			"seed": "9223372036854775807", "players": 3, "tribes": ["Locust"]},
		{"kind": "game", "paths": ["res://src/content/shared"], "seed": "0", "players": 2},
		{"kind": "core", "paths": ["res://src/content/shared"], "seed": "-9223372036854775808", "players": 2},
		{"kind": "game", "paths": Array(all), "seed": "42", "players": 8, "tribes": ["Badger"]},
	]
	var output: String = "res://tools/league/gd/recipe_headers.jsonl"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			output = arg.substr(4)
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		printerr("cannot write recipe oracle")
		quit(1)
		return
	for entry: Dictionary in cases:
		var config := GameConfig.new()
		config.players = CoreUtil.to_int(entry["players"])
		config.front_slots = 2
		config.back_slots = 3
		config.starting_armor = 7
		var paths := PackedStringArray(CoreUtil.to_array(entry["paths"]))
		var tribes := PackedStringArray(CoreUtil.to_array(entry.get("tribes", [])))
		var game: GameSession
		if entry["kind"] == "core":
			var content: ContentSet = ContentSet.load_folders(paths)
			if not content.errors.is_empty():
				printerr(content.errors)
				quit(1)
				return
			game = content.session(str(entry["seed"]).to_int(), config, tribes)
		else:
			var content: GameContent = GameContent.load_folders(paths)
			if not content.errors.is_empty():
				printerr(content.errors)
				quit(1)
				return
			game = GameSession.create(str(entry["seed"]).to_int(), content.library, content.registry, config, tribes)
			for mechanic_id: StringName in content.standing_for(tribes):
				game.give_standing(mechanic_id)
		var header: Dictionary = {
			"op": "header", "format": GameRecord.FORMAT, "seed": entry["seed"], "build": RecordBuild.identity(),
			"recipe": {"kind": entry["kind"], "paths": Array(paths), "tribes": Array(tribes)},
			"config": RecordState.fields(config), "initial_hash": RecordState.state_hash(game),
		}
		file.store_line(JSON.stringify(header))
	file.close()
	print("recipe headers: ", cases.size())
	quit(0)
