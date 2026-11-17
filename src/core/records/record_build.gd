class_name RecordBuild
extends RefCounted
## Local build identity, available without Git or a network in exported games.
## Windows builds stamp their commit; rules_hash also identifies uncommitted workspace code.

static var _identity: Dictionary = {}


static func identity() -> Dictionary:
	if _identity.is_empty():
		var files: PackedStringArray = []
		_collect("res://src/core", files)
		_collect("res://src/content", files)
		files.append("res://src/game/game_content.gd")
		files.append("res://src/game/data/stand_in_units.json")
		files.sort()
		var parts: PackedStringArray = []
		for path: String in files:
			# Exported scripts can be remapped to compiled resources.
			var actual: String = path
			if FileAccess.file_exists(path + ".remap"):
				var mapping := ConfigFile.new()
				if mapping.load(path + ".remap") == OK:
					actual = str(mapping.get_value("remap", "path", path))
			parts.append(path + ":" + FileAccess.get_sha256(actual))
		_identity = {
			"version": str(ProjectSettings.get_setting("application/config/version", "")),
			"revision": str(ProjectSettings.get_setting("application/config/build", "workspace")),
			"engine": Engine.get_version_info()["string"],
			"rules_hash": "\n".join(parts).sha256_text(),
		}
	return _identity.duplicate()


static func _collect(path: String, files: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	for folder: String in dir.get_directories():
		_collect(path.path_join(folder), files)
	for file: String in dir.get_files():
		var source: String = file.trim_suffix(".remap")
		if source.ends_with(".gd") or source.ends_with(".json"):
			files.append(path.path_join(source))
