extends SceneTree
## Regenerate the Rust field oracle from Godot's real script-variable property lists.
## timeout -k 10 60 godot --headless -s res://tools/league/gd/dump_fields.gd -- out=<file>


func _initialize() -> void:
	var output: String = "res://tools/league/gd/core_fields.json"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			output = arg.substr(4)
	var paths: Array[String] = []
	_collect("res://src/core", paths)
	paths.sort()
	var game := GameSession.new()
	game.config = GameConfig.new()
	game.geometry = BoardGeometry.standard()
	game.registry = MechanicRegistry.with_built_ins()
	game.library = UnitLibrary.with_system_cards(game.registry)
	game.recruit = Recruit.new(game)
	var player: PlayerState = PlayerState.create(0, 7, 30, 0)
	var fields_by_script: Dictionary = {}
	for path: String in paths:
		var script: GDScript = load(path)
		var object: Object = _instance(script, path, game, player)
		var fields: Array[String] = []
		for property: Dictionary in object.get_property_list():
			if CoreUtil.to_int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
				fields.append(str(property["name"]))
		fields_by_script[path.trim_prefix("res://")] = fields
	var file: FileAccess = FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		printerr("cannot write field oracle: ", output)
		quit(1)
		return
	file.store_string(JSON.stringify(fields_by_script, "\t") + "\n")
	file.close()
	print("core field lists: ", fields_by_script.size(), " scripts; wrote ", output)
	quit(0)


func _instance(script: GDScript, path: String, game: GameSession, player: PlayerState) -> Object:
	match path:
		"res://src/core/bots/bot.gd", "res://src/core/bots/random_bot.gd", "res://src/core/bots/simple_bot.gd":
			return script.new(Rng.new(0))
		"res://src/core/rules/rules.gd":
			return script.new(game.config)
		"res://src/core/recruit/recruit.gd":
			return script.new(game)
		"res://src/core/recruit/recruit_context.gd":
			return script.new(game, game.recruit, player)
		"res://src/core/mechanics/bound_mechanic.gd":
			return script.new(&"", Mechanic.new(), MechanicParams.new(), false)
	return script.new()


func _collect(path: String, out: Array[String]) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		return
	for file: String in directory.get_files():
		if file.ends_with(".gd"):
			out.append(path.path_join(file))
	for folder: String in directory.get_directories():
		_collect(path.path_join(folder), out)
