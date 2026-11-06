extends RefCounted
## The player's settings, saved to user:// as they change. Static: there is one player, and every
## screen reads them. Tests point `path` elsewhere.

const SPEEDS: Array[float] = [1.0, 2.0, 4.0]

static var path: String = "user://settings.cfg"
static var fight_speed: float = 1.0
## 0 to 100. There is no sound yet; the setting is ready for it.
static var volume: int = 80
static var show_dev_panel: bool = false
static var reduce_motion: bool = false
## The how-to-play guide has been offered once.
static var seen_guide: bool = false


static func load_saved() -> void:
	var file: ConfigFile = ConfigFile.new()
	if file.load(path) != OK:
		return
	fight_speed = _speed(file.get_value("fights", "speed", 1.0))
	var saved_volume: Variant = file.get_value("sound", "volume", 80)
	var loudness: int = saved_volume if saved_volume is int else 80
	volume = clampi(loudness, 0, 100)
	show_dev_panel = file.get_value("testing", "dev_panel", false) == true
	reduce_motion = file.get_value("fights", "reduce_motion", false) == true
	seen_guide = file.get_value("guide", "seen", false) == true


static func save() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("fights", "speed", fight_speed)
	file.set_value("fights", "reduce_motion", reduce_motion)
	file.set_value("sound", "volume", volume)
	file.set_value("testing", "dev_panel", show_dev_panel)
	file.set_value("guide", "seen", seen_guide)
	file.save(path)


## Back to the defaults, without saving (tests).
static func reset() -> void:
	fight_speed = 1.0
	volume = 80
	show_dev_panel = false
	reduce_motion = false
	seen_guide = false


static func _speed(value: Variant) -> float:
	if value is float or value is int:
		var speed: float = value
		for known: float in SPEEDS:
			if is_equal_approx(known, speed):
				return known
	return 1.0
