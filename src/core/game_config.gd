class_name GameConfig
extends RefCounted
## Every tunable of docs/prototype/SPEC.md section 2, under the keys listed there, so the dev
## panel or a test can change one. Per-turn tables are arrays indexed by turn - 1; the last entry
## repeats for later turns.

var _values: Dictionary = {}


static func defaults() -> GameConfig:
	var config := GameConfig.new()
	config._values = {
		"players": 8,
		"starting_health": 30,
		"max_rounds": 50,
		"income_by_turn": [3, 4, 5, 6, 7, 8, 9, 10],
		"unit_cost": 3,
		"sell_bought": 1,
		"sell_created": 0,
		"refresh_base_cost": 1,
		"refresh_first_step_after": 15,
		"refresh_step_length": 5,
		"freeze_toggles_per_turn": 5,
		"upgrade_costs": [5, 7, 8, 11, 11],
		"upgrade_discount_per_turn": 1,
		"pool_copies_by_tier": [15, 15, 13, 11, 9, 7],
		"shop_units_by_tier": [3, 4, 4, 5, 5, 6],
		"hand_limit": 10,
		"board_front": 4,
		"board_back": 3,
		"damage_cap_by_turn": [5, 5, 5, 10, 10, 10, 10, 15],
		"damage_cap_off_at_alive": 4,
		"attack_limit": 200,
		"trigger_limit_combat": 10000,
		"trigger_limit_action": 1000,
		"return_limit": 5,
		"stat_clamp": 1000000000,
		"pool_filter": "all",
		"peck_max_strikes": 3,
		"bots": ["greedy", "greedy", "wide", "wide", "tribe", "tribe", "balanced"],
		"human_bot": "",
	}
	return config


func get_value(key: String) -> Variant:
	return _values.get(key)


func set_value(key: String, value: Variant) -> void:
	_values[key] = value


## The value as an int (0 if missing).
func get_int(key: String) -> int:
	var value: Variant = _values.get(key, 0)
	return CoreUtil.to_int(value)


## The value as a string ("" if missing).
func get_string(key: String) -> String:
	var value: Variant = _values.get(key, "")
	return str(value)


## Entry `index` of an array value, clamped to its last entry (per-turn tables).
func get_int_at(key: String, index: int) -> int:
	var values: Array = _values.get(key, [])
	if values.is_empty():
		return 0
	var value: Variant = values[clampi(index, 0, values.size() - 1)]
	return CoreUtil.to_int(value)


## An array value as strings.
func get_strings(key: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var values: Array = _values.get(key, [])
	for value: Variant in values:
		out.append(str(value))
	return out
