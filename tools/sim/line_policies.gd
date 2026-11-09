class_name LinePolicies
extends RefCounted
## Designer-editable policy data; overrides replace the whole table, without changing card files.

const DEFAULT_PATH: String = "res://tools/sim/line_profiles.json"
static var _profiles: Dictionary = {}


static func profiles() -> Dictionary:
	if _profiles.is_empty():
		load_profiles(DEFAULT_PATH)
	return _profiles


static func load_profiles(path: String) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Dictionary, "invalid line profile table")
	_profiles = parsed
	for id: String in _profiles:
		var entry: Dictionary = _profiles[id]
		assert(entry.has("tribe") and entry.has("engine") and entry.has("save_threshold"))
		var curve: Array = entry["climb_schedule"]
		assert(curve.size() == UnitLibrary.TIERS - 1, "one climb round per tier")


static func resolve(alias: String, strategy_id: String) -> String:
	if profiles().has(alias):
		return alias
	var known: Dictionary = BotKnowledge.shared().strategy(strategy_id)
	var tribes: Array = known.get("needs_tribes", [])
	var tribe: String = str(tribes[0]) if not tribes.is_empty() else ""
	var engine: bool = alias == "line_engine"
	for id: String in profiles():
		var entry: Dictionary = profiles()[id]
		if str(entry["tribe"]) == tribe and CoreUtil.to_bool(entry["engine"]) == engine:
			return id
	return "line_fast"


static func strategy(id: String) -> Dictionary:
	var entry: Dictionary = profiles()[id]
	var base: Dictionary = BotKnowledge.shared().strategy(str(entry["base_strategy"]))
	var out: Dictionary = base.duplicate(true)
	out["id"] = id
	out["curve"] = entry["climb_schedule"]
	var priorities: Array = entry["priority"]
	var units: Dictionary = {}
	for index: int in priorities.size():
		units[str(priorities[index])] = (
			BotEval._number(entry["priority_weight"])
			* (priorities.size() - index)
			/ priorities.size()
		)
	out["units"] = units
	var tribe: String = str(entry["tribe"])
	out["tribes"] = {tribe: entry["tribe_weight"]} if tribe != "" else {}
	return out
