extends SceneTree
## External editor probe: mount an exported PCK/ZIP with --main-pack, then load its field.


func _initialize() -> void:
	var units := UnitLibrary.load_dir()
	var config := GameConfig.full_game()
	var field := FieldLibrary.prepare(config, units, FieldLibrary.BUNDLED_PATH)
	if field.error != "":
		printerr("export-field: %s" % field.error)
		quit(1)
		return
	var session := GameSession.create(71, units, config, Bot.create, field)
	if session == null or session._field == null:
		printerr("export-field: field session did not start")
		quit(1)
		return
	print("export-field: loaded sha256=%s" % FileAccess.get_sha256(FieldLibrary.BUNDLED_PATH))
	quit(0)
