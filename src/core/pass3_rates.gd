class_name Pass3Rates
extends RefCounted
## Authored defaults live in JSON; a harness can override any key in GameConfig.

const PATH: String = "res://content/pass3/rates.json"
static var _defaults: Dictionary = {}


static func defaults() -> Dictionary:
	if _defaults.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			_defaults = parsed
	return _defaults.duplicate()


static func value(config: GameConfig, key: String) -> Variant:
	if _defaults.is_empty():
		defaults()
	var override: Variant = config.get_value(key)
	return _defaults.get(key, 0) if override == null else override


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
		var override: Variant = config.get_value(key)
		if override != null and override != _defaults[key]:
			return true
	return false
