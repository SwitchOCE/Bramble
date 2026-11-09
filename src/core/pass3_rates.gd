class_name Pass3Rates
extends RefCounted
## Authored defaults live in JSON; a harness can override any key in GameConfig.

const PATH: String = "res://content/pass3/rates.json"
static var _defaults: Dictionary = {}
static var _presets: Dictionary = {}
static var _default_preset: String = "B"


static func defaults() -> Dictionary:
	if _defaults.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			var data: Dictionary = parsed
			_defaults = data.get("rates", data)
			_presets = data.get("presets", {})
			_default_preset = str(data.get("default_preset", "B"))
	return _defaults.duplicate()


static func default_preset() -> String:
	defaults()
	return _default_preset


static func value(config: GameConfig, key: String) -> Variant:
	if _defaults.is_empty():
		defaults()
	var override: Variant = config.get_value(key)
	if override != null:
		return override
	var name: String = config.get_string("pass3_preset")
	var chosen: Dictionary = _presets.get(name if name != "" else _default_preset, {})
	return chosen.get(key, _defaults.get(key, 0))


static func number(config: GameConfig, key: String) -> float:
	return CoreUtil.to_float(value(config, key))


static func integer(config: GameConfig, key: String) -> int:
	return CoreUtil.to_int(value(config, key))


static func enabled(config: GameConfig, key: String) -> bool:
	return CoreUtil.to_bool(value(config, key))


static func resolved(config: GameConfig) -> Dictionary:
	var out: Dictionary = defaults()
	for key: String in out:
		out[key] = value(config, key)
	return out


static func overridden(config: GameConfig) -> bool:
	for key: String in defaults():
		if value(config, key) != _defaults[key]:
			return true
	return false
