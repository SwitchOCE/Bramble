class_name LinePolicies
extends RefCounted
@warning_ignore_start(
	"unsafe_method_access", "unsafe_call_argument", "unsafe_cast", "narrowing_conversion"
)
## Normalize the committed table and the designer's wave-1 line files into playable profiles.

const HISTORICAL_PATH: String = "res://tools/sim/line_profiles.committed.json"
const DEFAULT_PATH: String = "res://tools/sim/lines"
const ALIASES: Dictionary = {
	"line_birds_engine": "line_birds_homecoming",
	"line_fairies_engine": "line_fairies_ring",
	"line_fairies_tempo": "line_fairies_court",
}
const BASES: Dictionary = {
	"birds_homecoming": "birds_passage",
	"birds_tempo": "birds_highway",
	"fairies_ring": "fairies_rings",
	"fairies_court": "fairies_rainbow",
}
static var _profiles: Dictionary = {}


static func profiles() -> Dictionary:
	if _profiles.is_empty():
		load_profiles(DEFAULT_PATH)
	return _profiles


static func load_profiles(path: String) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(HISTORICAL_PATH))
	assert(parsed is Dictionary, "invalid committed line profile table")
	if not DirAccess.dir_exists_absolute(path):
		parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		assert(parsed is Dictionary, "invalid line profile table")
		_profiles = parsed
		for id: String in _profiles:
			var entry: Dictionary = _profiles[id]
			assert(entry.has("tribe") and entry.has("engine") and entry.has("save_threshold"))
			assert(entry["climb_schedule"].size() == UnitLibrary.TIERS - 1)
		return
	_profiles = parsed
	for id: String in _profiles.keys():
		if str(_profiles[id]["tribe"]) in ["Birds", "Fairies"]:
			_profiles.erase(id)
	var files: PackedStringArray = DirAccess.get_files_at(path)
	files.sort()
	for file: String in files:
		if not file.ends_with(".json"):
			continue
		var table: Variant = JSON.parse_string(FileAccess.get_file_as_string(path.path_join(file)))
		var errors: PackedStringArray = validate_wave1(table)
		assert(errors.is_empty(), "%s: %s" % [file, "; ".join(errors)])
		for name: String in table:
			var id: String = "line_" + name
			assert(not _profiles.has(id), "duplicate line: " + id)
			_profiles[id] = normalize_wave1(name, table[name])


## Errors are data so malformed designer input can be tested without an assertion crash.
static func validate_wave1(table: Variant) -> PackedStringArray:
	var errors: PackedStringArray = []
	if not table is Dictionary or table.is_empty():
		return ["expected a nonempty object of named lines"]
	var library := UnitLibrary.load_dir()
	for name: String in table:
		var entry: Variant = table[name]
		if not entry is Dictionary:
			errors.append(name + ": expected an object")
			continue
		if not BASES.has(name):
			errors.append(name + ": no declared base strategy")
		if str(entry.get("tribe", "")) not in ["birds", "fairies"]:
			errors.append(name + ": tribe must be birds or fairies")
		if not entry.get("engine_flag") is bool:
			errors.append(name + ": engine_flag must be a boolean")
		for key: String in ["buy_priority" if entry.has("buy_priority") else "priority"]:
			_validate_cards(entry.get(key), name + "." + key, library, errors)
		for key: String in ["keep", "stayer_keep_rank"]:
			if entry.has(key):
				_validate_cards(entry[key], name + "." + key, library, errors)
		var climb: Variant = entry.get("climb")
		if not climb is Dictionary or climb.size() != UnitLibrary.TIERS - 1:
			errors.append(name + ": climb needs T2 through T6")
			continue
		var previous: int = 0
		for tier: int in range(2, UnitLibrary.TIERS + 1):
			var at: Variant = climb.get("T%d" % tier)
			if not (at is int or at is float) or float(at) != int(at) or int(at) <= previous:
				errors.append(name + ": climb rounds must be positive increasing integers")
				break
			previous = int(at)
		if entry.has("switch_to"):
			var switch: Variant = entry["switch_to"]
			if not switch is Dictionary or not table.has(str(switch.get("line", ""))):
				errors.append(name + ": switch_to must name a line in this file")
			elif CoreUtil.to_int(switch.get("round", 0)) <= 0:
				errors.append(name + ": switch_to.round must be positive")
		if entry.has("fly_policy"):
			var fly: Variant = entry["fly_policy"]
			if not fly is Dictionary or CoreUtil.to_int(fly.get("keep_home_min", 0)) < 1:
				errors.append(name + ": fly_policy needs positive keep_home_min")
	return errors


static func _validate_cards(
	cards: Variant, label: String, library: UnitLibrary, errors: PackedStringArray
) -> void:
	if not cards is Array or cards.is_empty():
		errors.append(label + ": expected a nonempty card list")
		return
	var seen: Dictionary = {}
	for card: Variant in cards:
		if not card is String or library.get_unit(str(card)).is_empty() or seen.has(card):
			errors.append(label + ": unknown or duplicate card " + str(card))
		seen[card] = true


static func normalize_wave1(name: String, source: Dictionary) -> Dictionary:
	var curve: Array = []
	for tier: int in range(2, UnitLibrary.TIERS + 1):
		curve.append(source["climb"]["T%d" % tier])
	var entry: Dictionary = {
		"tribe": "Birds" if source["tribe"] == "birds" else "Fairies",
		"base_strategy": BASES[name],
		"priority": source.get("buy_priority", source.get("priority", [])),
		"engine_pieces": source.get("keep", source.get("stayer_keep_rank", []).slice(0, 3)),
		"climb_schedule": curve,
		"save_threshold": 0,
		"save_until": 0,
		"engine": source["engine_flag"],
		"priority_weight": 14,
		"tribe_weight": 4,
		"policy_version": 2,
		"commit_round": 4,
		"source_line": name,
		"source_policy": source.duplicate(true),
	}
	if source.has("switch_to"):
		entry["switch_to"] = source["switch_to"]
	if source.has("fly_policy"):
		entry["fly_policy"] = source["fly_policy"].duplicate(true)
		if name == "birds_tempo":
			entry["fly_policy"]["allowed"] = ["chiffchaff", "one_swallow"]
	return entry


static func resolve(alias: String, strategy_id: String) -> String:
	if profiles().has(alias):
		return alias
	if profiles().has("line_" + alias):
		return "line_" + alias
	if ALIASES.has(alias) and profiles().has(ALIASES[alias]):
		return ALIASES[alias]
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
	if entry.has("source_line"):
		# Prose is advisory; spending uses only the shared next-climb reservation.
		out["save"] = []
		out["line_court"] = entry["source_line"] == "fairies_court"
	if entry.has("fly_policy"):
		out["line_fly_policy"] = entry["fly_policy"].duplicate(true)
	return out
