extends RefCounted
## Historical dial settings for mechanism counterexamples with literal pre-measurement answers.
## Current B and its printed faces are pinned separately by test_pass3_path and content tests.

const PATH: String = "res://tests/core/data/a35_original_b.json"


static func apply(config: GameConfig) -> GameConfig:
	var rates: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	for key: String in rates:
		config.set_value(key, rates[key])
	return config


static func path(t: float) -> Dictionary:
	Pass3Rates.defaults()
	var current: Dictionary = Pass3Rates._presets["B"]
	var original: Dictionary = current.duplicate()
	var rates: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	original.merge(rates, true)
	Pass3Rates._presets["B"] = original
	var result: Dictionary = Pass3Path.override(t)
	Pass3Rates._presets["B"] = current
	return result


static func clear(config: GameConfig) -> void:
	var rates: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	for key: String in rates:
		config.set_value(key, null)
