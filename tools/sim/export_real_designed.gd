extends SceneTree
## -- RECIPES.json DESIGNED_INPUT.json. Run under the harness simulation lock.


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 2:
		printerr("expected recipes.json designed-input.json")
		quit(2)
		return
	var recipes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var document: Dictionary = RealDesignedBoards.document(recipes, UnitLibrary.load_dir())
	var output := FileAccess.open(args[1], FileAccess.WRITE)
	output.store_string(JSON.stringify(document, "  ") + "\n")
	output.close()
	var boards: Array = document["boards"]
	print("export_real_designed: %d current-library boards" % boards.size())
	quit(0)
