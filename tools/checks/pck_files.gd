extends SceneTree
## Lists every file inside an exported Godot pack, one res:// path per line.
## Run from an empty project so only the pack's files are visible:
##   godot --headless --path <empty dir> -s <abs path>/pck_files.gd -- <pack>
## <pack> is a .pck, or an executable with an embedded pack. Exit 1 if it cannot be loaded.


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("usage: pck_files.gd -- <pack>")
		quit(2)
		return
	if not ProjectSettings.load_resource_pack(args[0], false):
		printerr("pck_files: cannot load pack %s" % args[0])
		quit(1)
		return
	_list("res://")
	quit(0)


func _list(dir_path: String) -> void:
	for file: String in DirAccess.get_files_at(dir_path):
		print(dir_path.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir_path):
		_list(dir_path.path_join(sub))
