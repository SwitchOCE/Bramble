class_name Pass3Rates
extends RefCounted
## Authored defaults live in JSON; a harness can override any key in GameConfig.

const PATH: String = "res://content/pass3/rates.json"
const EXACT_RATES: String = "pass3_rates_exact_json"
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
	var authored: Dictionary = defaults()
	var selected: Dictionary = _presets.get(_default_preset, {})
	for key: String in authored:
		if value(config, key) != selected.get(key, authored[key]):
			return true
	return false


## An opaque JSON string preserves float precision through ordinary capture JSON writers.
static func freeze_values(values: Dictionary) -> Dictionary:
	var out: Dictionary = values.duplicate(true)
	var exact: Dictionary = {}
	for key: String in defaults():
		if out.has(key):
			exact[key] = out[key]
	var baseline: Variant = out.get("pass3_text_defaults")
	if baseline is Dictionary:
		exact["pass3_text_defaults"] = baseline
	out[EXACT_RATES] = JSON.stringify(exact, "", true, true)
	return out


static func restore_values(values: Dictionary) -> Dictionary:
	var out: Dictionary = values.duplicate(true)
	var exact: Variant = JSON.parse_string(str(values.get(EXACT_RATES, "null")))
	if exact is Dictionary:
		var exact_map: Dictionary = exact
		_restore_exact(out, exact_map)
	return out


static func _restore_exact(current: Dictionary, exact: Dictionary) -> void:
	for key: String in exact:
		if not current.has(key):
			continue
		var precise: Variant = exact[key]
		var present: Variant = current[key]
		if present is Dictionary and precise is Dictionary:
			var nested_current: Dictionary = present
			var nested_exact: Dictionary = precise
			_restore_exact(nested_current, nested_exact)
		elif present == precise or present == JSON.parse_string(JSON.stringify(precise)):
			# Explicit harness overrides differ from both captured and rounded captured values.
			current[key] = precise
