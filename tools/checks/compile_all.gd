extends SceneTree
## Loads every GDScript, scene and resource under the given res:// roots so parse errors,
## warnings-as-errors and broken scene references surface even where no test looks.
## check.sh also fails on any ERROR/WARNING line in this script's log.
## Usage: godot --headless -s res://tools/checks/compile_all.gd [-- res://src ...]

const SELF_PATH: String = "res://tools/checks/compile_all.gd"
const DEFAULT_ROOTS: PackedStringArray = ["res://src", "res://tests", "res://tools"]
const EXTENSIONS: PackedStringArray = ["gd", "tscn", "tres"]


func _initialize() -> void:
	var roots: PackedStringArray = OS.get_cmdline_user_args()
	if roots.is_empty():
		roots = DEFAULT_ROOTS
	var scripts: PackedStringArray = []
	for root_path: String in roots:
		_collect(root_path, scripts)
	var failed: int = 0
	for path: String in scripts:
		if not _loads(path):
			printerr("compile_all: FAILED %s" % path)
			failed += 1
	print("compile_all: %d files, %d failed" % [scripts.size(), failed])
	quit(1 if failed > 0 else 0)


func _loads(path: String) -> bool:
	var resource: Resource = load(path)
	if resource == null:
		return false
	var script: GDScript = resource as GDScript
	return script == null or script.can_instantiate()


func _collect(dir_path: String, out: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null or dir.file_exists(".gdignore"):
		return
	for sub: String in dir.get_directories():
		if not sub.begins_with("."):
			_collect(dir_path.path_join(sub), out)
	for file: String in dir.get_files():
		var path: String = dir_path.path_join(file)
		if file.get_extension() in EXTENSIONS and path != SELF_PATH:
			out.append(path)
