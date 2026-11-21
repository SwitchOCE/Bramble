class_name GameSettings
extends RefCounted
## The player's settings, kept in user:// so they survive a restart: whether a carried card drops
## where the pointer is (the default) or where the card's middle is (owner, 17 Nov), and the
## sound's volume and mute (owner, 21 Nov). Read where they are used, so a change takes effect
## at once.

const DEFAULT_PATH: String = "user://settings.cfg"
const DEFAULT_VOLUME: float = 0.8

## Where the settings are kept (tests point it elsewhere).
static var path: String = DEFAULT_PATH
static var _loaded: bool = false
static var _drop_by_middle: bool = false
static var _volume: float = DEFAULT_VOLUME
static var _muted: bool = false


## Whether a carried card drops where its middle is, rather than where the pointer is.
static func drop_by_middle() -> bool:
	_load()
	return _drop_by_middle


## Sets it and saves it; save false only sets it for this run (a film).
static func set_drop_by_middle(on: bool, save: bool = true) -> void:
	_load()
	_drop_by_middle = on
	if save:
		_save("drag", "drop_by_middle", on)


## The sound's volume, 0 to 1.
static func volume() -> float:
	_load()
	return _volume


static func set_volume(value: float, save: bool = true) -> void:
	_load()
	_volume = clampf(value, 0.0, 1.0)
	if save:
		_save("sound", "volume", _volume)


static func muted() -> bool:
	_load()
	return _muted


static func set_muted(on: bool, save: bool = true) -> void:
	_load()
	_muted = on
	if save:
		_save("sound", "muted", on)


## Reads the file again on the next use (tests; a changed path).
static func forget() -> void:
	_loaded = false
	_drop_by_middle = false
	_volume = DEFAULT_VOLUME
	_muted = false


static func _save(section: String, key: String, value: Variant) -> void:
	# whatever else the file holds is kept (other builds of the game write it too)
	var file: ConfigFile = ConfigFile.new()
	if file.load(path) != OK:
		file = ConfigFile.new()
	file.set_value(section, key, value)
	var err: Error = file.save(path)
	if err != OK:
		push_warning("settings: could not save %s (%s)" % [path, error_string(err)])


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var file: ConfigFile = ConfigFile.new()
	if file.load(path) == OK:
		# anything but true or false (a hand-edited file): the pointer
		var saved: Variant = file.get_value("drag", "drop_by_middle", false)
		_drop_by_middle = saved is bool and saved == true
		var loud: Variant = file.get_value("sound", "volume", DEFAULT_VOLUME)
		if loud is float:
			var value: float = loud
			_volume = clampf(value, 0.0, 1.0)
		elif loud is int:
			_volume = clampf(float(CoreUtil.to_int(loud)), 0.0, 1.0)
		var mute: Variant = file.get_value("sound", "muted", false)
		_muted = mute is bool and mute == true
