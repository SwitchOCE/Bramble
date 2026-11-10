extends SceneTree
## External negative-control helper. Run with --main-pack SOURCE -- LISTING OUTPUT.pck.


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 2:
		printerr("strip-field: expected LISTING OUTPUT.pck")
		quit(2)
		return
	var packer := PCKPacker.new()
	if packer.pck_start(args[1]) != OK:
		quit(1)
		return
	var skipped: int = 0
	for path: String in FileAccess.get_file_as_string(args[0]).split("\n", false):
		var resource: String = "res://" + path
		if resource == FieldLibrary.BUNDLED_PATH:
			skipped += 1
			continue
		if packer.add_file(resource, resource) != OK:
			printerr("strip-field: cannot add %s" % resource)
			quit(1)
			return
	if skipped != 1 or packer.flush() != OK:
		printerr("strip-field: expected exactly one bundled library")
		quit(1)
		return
	print("strip-field: wrote pack without bundled library")
	quit(0)
