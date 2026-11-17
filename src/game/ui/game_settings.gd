class_name GameSettings
extends RefCounted
## The player's settings, kept in user:// so they survive a restart. One so far (owner, 17 Nov):
## whether a carried card drops where the pointer is (the default) or where the card's middle is.
## Read where it is used, so a change takes effect at once.

const DEFAULT_PATH: String = "user://settings.cfg"

## Where the settings are kept (tests point it elsewhere).
static var path: String = DEFAULT_PATH
static var _loaded: bool = false
static var _drop_by_middle: bool = false


## Whether a carried card drops where its middle is, rather than where the pointer is.
static func drop_by_middle() -> bool:
	_load()
	return _drop_by_middle


## Sets it and saves it; save false only sets it for this run (a film).
static func set_drop_by_middle(on: bool, save: bool = true) -> void:
	_load()
	_drop_by_middle = on
	if not save:
		return
	# whatever else the file holds is kept (other builds of the game write it too)
	var file: ConfigFile = ConfigFile.new()
	if file.load(path) != OK:
		file = ConfigFile.new()
	file.set_value("drag", "drop_by_middle", on)
	var err: Error = file.save(path)
	if err != OK:
		push_warning("settings: could not save %s (%s)" % [path, error_string(err)])


## Reads the file again on the next use (tests; a changed path).
static func forget() -> void:
	_loaded = false
	_drop_by_middle = false


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var file: ConfigFile = ConfigFile.new()
	if file.load(path) == OK:
		_drop_by_middle = file.get_value("drag", "drop_by_middle", false) == true
