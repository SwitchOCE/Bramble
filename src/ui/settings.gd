extends RefCounted
## The player's settings, saved to user:// as they change. Static: there is one player, and every
## screen reads them. Tests point `path` elsewhere.

const SPEEDS: Array[float] = [1.0, 2.0, 4.0]
const DEFAULT_MASTER: float = 0.8

static var path: String = "user://settings.cfg"
static var fight_speed: float = 1.0
static var show_dev_panel: bool = false
static var reduce_motion: bool = false
## The how-to-play guide has been offered once.
static var seen_guide: bool = false
## Optional shop experiment, applied when starting a new game.
static var ask_for_kin: bool = false
## The experiment is unavailable in ordinary player exports until a new-pool field is ready.
static var field_mode_enabled: bool = OS.has_feature("strong_field")
static var field_library_path: String = FieldLibrary.BUNDLED_PATH
static var opponents: String = "bots"
## A slider, 0..1 (Sfx hears it).
static var master_volume: float = DEFAULT_MASTER


static func load_saved() -> void:
	var file: ConfigFile = ConfigFile.new()
	if file.load(path) != OK:
		return
	fight_speed = _speed(file.get_value("fights", "speed", 1.0))
	show_dev_panel = file.get_value("testing", "dev_panel", false) == true
	reduce_motion = file.get_value("fights", "reduce_motion", false) == true
	seen_guide = file.get_value("guide", "seen", false) == true
	ask_for_kin = file.get_value("testing", "ask_for_kin", false) == true
	opponents = "field" if file.get_value("game", "opponents", "bots") == "field" else "bots"
	master_volume = _volume(file.get_value("sound", "master", DEFAULT_MASTER), DEFAULT_MASTER)


static func save() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("fights", "speed", fight_speed)
	file.set_value("fights", "reduce_motion", reduce_motion)
	file.set_value("testing", "dev_panel", show_dev_panel)
	file.set_value("guide", "seen", seen_guide)
	file.set_value("testing", "ask_for_kin", ask_for_kin)
	file.set_value("game", "opponents", opponents)
	file.set_value("sound", "master", master_volume)
	file.save(path)


## Back to the defaults, without saving (tests).
static func reset() -> void:
	fight_speed = 1.0
	show_dev_panel = false
	reduce_motion = false
	seen_guide = false
	ask_for_kin = false
	opponents = "bots"
	field_mode_enabled = OS.has_feature("strong_field")
	field_library_path = FieldLibrary.BUNDLED_PATH
	master_volume = DEFAULT_MASTER


static func _volume(value: Variant, fallback: float) -> float:
	if value is float or value is int:
		var volume: float = value
		return clampf(volume, 0.0, 1.0)
	return fallback


static func _speed(value: Variant) -> float:
	if value is float or value is int:
		var speed: float = value
		for known: float in SPEEDS:
			if is_equal_approx(known, speed):
				return known
	return 1.0
