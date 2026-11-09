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
const KEYS: Array[String] = [
	"tribe",
	"base_strategy",
	"engine_flag",
	"engine",
	"buy_priority",
	"priority",
	"keep",
	"engine_pieces",
	"stayer_keep_rank",
	"climb",
	"climb_schedule",
	"switch_to",
	"fly_policy",
	"kind",
	"max_copies",
	"stayer_cap",
	"harvest_supper_rounds",
	"save_rule",
	"great_lump_seat",
	"golden_egg",
	"placement",
	"buy_only_if",
	"place",
	"stander_on_carry_slot",
	"spells",
	"thank",
	"save",
	"knobs",
	"save_threshold",
	"save_until",
	"priority_weight",
	"tribe_weight",
	"commit_round",
	"policy_version",
	"triples",
	"save_rounds",
	"hold",
	"sell_order",
	"sell_first",
	"heir",
	"pelt_target",
	"poach",
]
const FLY_KEYS: Array[String] = [
	"from_round",
	"keep_home_min",
	"max_away",
	"allowed",
	"who",
	"old_tern",
	"omen_turn",
	"elimination_guard",
]
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
	var additions: Dictionary = {}
	var tribes: Dictionary = {}
	var files: PackedStringArray = DirAccess.get_files_at(path)
	files.sort()
	for file: String in files:
		if not file.ends_with(".json"):
			continue
		var table: Variant = JSON.parse_string(FileAccess.get_file_as_string(path.path_join(file)))
		var errors: PackedStringArray = validate_wave1(table)
		assert(errors.is_empty(), "%s: %s" % [file, "; ".join(errors)])
		for name: String in table:
			var id: String = profile_id(name)
			assert(not additions.has(id), "duplicate line: " + id)
			var source: Dictionary = table[name]
			var normalized: Dictionary = normalize_wave1(name, source)
			additions[id] = normalized
			tribes[normalized["tribe"]] = true
	for id: String in _profiles.keys():
		if tribes.has(str(_profiles[id]["tribe"])):
			_profiles.erase(id)
	for id: String in additions:
		assert(not _profiles.has(id), "line collides with another tribe: " + id)
	_profiles.merge(additions)


static func profile_id(line_name: String) -> String:
	return line_name if line_name.begins_with("line_") else "line_" + line_name


static func source_aliases() -> Dictionary:
	var out: Dictionary = {}
	for id: String in profiles():
		var entry: Dictionary = profiles()[id]
		if entry.has("source_line"):
			out[str(entry["source_line"])] = id
	return out


static func _tribe(value: Variant, library: UnitLibrary) -> String:
	if not value is String:
		return ""
	var declared: String = str(value).to_lower()
	for card: Dictionary in library.all_units():
		for tribe: String in card.get("tribes", []):
			if declared == tribe.to_lower() or declared == tribe.to_lower().get_slice(" ", 0):
				return tribe
	return ""


## Errors are data so malformed designer input can be tested without an assertion crash.
static func validate_wave1(table: Variant) -> PackedStringArray:
	var errors: PackedStringArray = []
	if not table is Dictionary or table.is_empty():
		return ["expected a nonempty object of named lines"]
	var library := UnitLibrary.load_dir()
	var names: Dictionary = {}
	for line_name: String in table:
		var canonical: String = profile_id(line_name)
		if line_name.is_empty() or canonical == "line_":
			errors.append("line name must not be empty")
		if names.has(canonical):
			errors.append(line_name + ": duplicate canonical line name")
		names[canonical] = true
		var entry: Variant = table[line_name]
		if not entry is Dictionary:
			errors.append(line_name + ": expected an object")
			continue
		_unknown(entry, KEYS, line_name, errors)
		var tribe: String = _tribe(entry.get("tribe"), library)
		if tribe.is_empty():
			errors.append(line_name + ": unknown tribe")
		var base_entry: Dictionary = BotKnowledge.shared().strategy(
			str(entry.get("base_strategy", ""))
		)
		if base_entry.is_empty():
			errors.append(line_name + ": unknown base_strategy")
		elif (
			not base_entry.get("needs_tribes", []).is_empty()
			and not base_entry["needs_tribes"].has(tribe)
		):
			errors.append(line_name + ": tribe does not match base_strategy")
		if entry.has("engine") == entry.has("engine_flag"):
			errors.append(line_name + ": provide exactly one engine or engine_flag")
		elif not entry.get("engine_flag", entry.get("engine")) is bool:
			errors.append(line_name + ": engine flag must be a boolean")
		if entry.has("buy_priority") and entry.has("priority"):
			errors.append(line_name + ": provide one priority list")
		_validate_cards(
			entry.get("buy_priority", entry.get("priority")),
			line_name + ".priority",
			library,
			errors
		)
		for key: String in [
			"keep", "stayer_keep_rank", "engine_pieces", "triples", "sell_order", "sell_first"
		]:
			if entry.has(key):
				_validate_cards(entry[key], line_name + "." + key, library, errors)
		_validate_curve(entry, line_name, errors)
		if entry.has("switch_to"):
			var change: Variant = entry["switch_to"]
			if not change is Dictionary:
				errors.append(line_name + ": switch_to must be an object")
			else:
				_unknown(change, ["line", "round"], line_name + ".switch_to", errors)
				if not table.has(str(change.get("line", ""))):
					errors.append(line_name + ": switch_to must name a line in this file")
				if not _integer(change.get("round"), 1):
					errors.append(line_name + ": switch_to.round must be a positive integer")
		if entry.has("fly_policy"):
			_validate_fly(entry["fly_policy"], line_name, library, errors)
		_validate_advice(entry, line_name, library, errors)
	return errors


static func _unknown(
	value: Dictionary, allowed: Array, label: String, errors: PackedStringArray
) -> void:
	for key: String in value:
		if not allowed.has(key):
			errors.append(label + ": unknown key " + key)


static func _integer(value: Variant, minimum: int, maximum: int = 2147483647) -> bool:
	return (
		(value is int or value is float)
		and is_finite(float(value))
		and float(value) == int(value)
		and int(value) >= minimum
		and int(value) <= maximum
	)


static func _validate_curve(entry: Dictionary, label: String, errors: PackedStringArray) -> void:
	var curve: Array = []
	if entry.has("climb") == entry.has("climb_schedule"):
		errors.append(label + ": provide exactly one climb or climb_schedule")
		return
	if entry.has("climb"):
		var climb: Variant = entry["climb"]
		if not climb is Dictionary:
			errors.append(label + ": climb must be an object")
			return
		_unknown(climb, ["T2", "T3", "T4", "T5", "T6"], label + ".climb", errors)
		for tier: int in range(2, UnitLibrary.TIERS + 1):
			curve.append(climb.get("T%d" % tier))
	elif entry["climb_schedule"] is Array:
		curve = entry["climb_schedule"]
	if curve.size() != UnitLibrary.TIERS - 1:
		errors.append(label + ": one climb round per tier is required")
		return
	var previous: int = 0
	for at: Variant in curve:
		if not _integer(at, previous + 1):
			errors.append(label + ": climb rounds must be positive increasing integers")
			return
		previous = int(at)


static func _validate_fly(
	value: Variant, label: String, library: UnitLibrary, errors: PackedStringArray
) -> void:
	if not value is Dictionary:
		errors.append(label + ": fly_policy must be an object")
		return
	_unknown(value, FLY_KEYS, label + ".fly_policy", errors)
	for field: String in ["from_round", "keep_home_min"]:
		var maximum: int = BoardGeometry.SLOTS if field == "keep_home_min" else 2147483647
		if not _integer(value.get(field), 1, maximum):
			errors.append(label + ": fly_policy." + field + " must be a positive integer in range")
	if value.has("max_away") and not _integer(value["max_away"], 0, BoardGeometry.SLOTS):
		errors.append(label + ": fly_policy.max_away must be an integer from zero to seven")
	if value.has("allowed"):
		_validate_cards(value["allowed"], label + ".fly_policy.allowed", library, errors)
	for field: String in ["who", "old_tern", "omen_turn", "elimination_guard"]:
		if value.has(field) and not value[field] is String:
			errors.append(label + ": fly_policy." + field + " must be text")


static func _validate_advice(
	entry: Dictionary, label: String, library: UnitLibrary, errors: PackedStringArray
) -> void:
	for key: String in [
		"kind", "save_rule", "great_lump_seat", "golden_egg", "heir", "pelt_target", "poach"
	]:
		if entry.has(key) and not entry[key] is String:
			errors.append(label + "." + key + ": expected text")
	for key: String in ["stander_on_carry_slot", "thank", "save", "knobs"]:
		if entry.has(key):
			_text_list(entry[key], label + "." + key, errors)
	if entry.has("placement") and not entry["placement"] is Dictionary:
		if entry["placement"] is Array:
			_text_list(entry["placement"], label + ".placement", errors)
		elif not entry["placement"] is String:
			errors.append(label + ".placement: expected text, a text list or a placement object")
	for key: String in ["priority_weight", "tribe_weight"]:
		if entry.has(key):
			var weight: Variant = entry[key]
			if (
				not (weight is int or weight is float)
				or not is_finite(float(weight))
				or float(weight) < 0
			):
				errors.append(label + "." + key + ": expected a finite nonnegative number")
	for key: String in ["buy_only_if", "hold", "place", "spells", "max_copies", "stayer_cap"]:
		if not entry.has(key):
			continue
		var value: Variant = entry[key]
		if not value is Dictionary:
			errors.append(label + "." + key + ": expected an object")
			continue
		for sub: String in value:
			var known: bool = not library.get_unit(sub).is_empty()
			if key == "spells":
				known = not library.get_card(sub).is_empty()
			elif key == "place":
				known = known or sub in ["carry_slot", "shy_units"]
			elif key == "max_copies":
				known = known or sub in ["default", "triple"]
			elif key == "stayer_cap":
				known = (
					sub.begins_with("R")
					and sub.substr(1).is_valid_int()
					and int(sub.substr(1)) >= 1
				)
			if not known:
				errors.append(label + "." + key + ": unknown key " + sub)
			if key == "stayer_cap" or (key == "max_copies" and sub != "triple"):
				if not _integer(value[sub], 0, BoardGeometry.SLOTS):
					errors.append(
						label + "." + key + "." + sub + ": expected a count from zero to seven"
					)
			elif not value[sub] is String:
				errors.append(label + "." + key + "." + sub + ": expected text")
	if entry.has("placement") and entry["placement"] is Dictionary:
		var placement: Dictionary = entry["placement"]
		for key: String in placement:
			if key not in ["front", "back", "reading_order"] and library.get_unit(key).is_empty():
				errors.append(label + ".placement: unknown key " + key)
			if not placement[key] is String:
				errors.append(label + ".placement." + key + ": expected text")
	for key: String in ["harvest_supper_rounds", "save_rounds"]:
		if entry.has(key):
			if not entry[key] is Array:
				errors.append(label + "." + key + ": expected a round list")
			else:
				for at: Variant in entry[key]:
					if not _integer(at, 1):
						errors.append(label + "." + key + ": expected positive integer rounds")
	for key: String in ["save_threshold", "save_until", "commit_round", "policy_version"]:
		if entry.has(key) and not _integer(entry[key], 0):
			errors.append(label + "." + key + ": expected a nonnegative integer")


static func _text_list(value: Variant, label: String, errors: PackedStringArray) -> void:
	if not value is Array:
		errors.append(label + ": expected a text list")
		return
	for item: Variant in value:
		if not item is String:
			errors.append(label + ": expected text entries")


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
	var curve: Array = source.get("climb_schedule", []).duplicate()
	if source.has("climb"):
		for tier: int in range(2, UnitLibrary.TIERS + 1):
			curve.append(source["climb"]["T%d" % tier])
	var entry: Dictionary = {
		"tribe": _tribe(source["tribe"], UnitLibrary.load_dir()),
		"base_strategy": source["base_strategy"],
		"priority": source.get("buy_priority", source.get("priority", [])),
		"engine_pieces":
		source.get(
			"engine_pieces", source.get("keep", source.get("stayer_keep_rank", []).slice(0, 3))
		),
		"climb_schedule": curve,
		"save_threshold": source.get("save_threshold", 0),
		"save_until": source.get("save_until", 0),
		"engine": source.get("engine_flag", source.get("engine")),
		"priority_weight": source.get("priority_weight", 14),
		"tribe_weight": source.get("tribe_weight", 4),
		"policy_version": 2,
		"commit_round": source.get("commit_round", 4),
		"source_line": name,
		"source_policy": source.duplicate(true),
	}
	if source.has("switch_to"):
		entry["switch_to"] = source["switch_to"].duplicate(true)
		entry["switch_to"]["line"] = str(entry["switch_to"]["line"]).trim_prefix("line_")
	if source.has("fly_policy"):
		entry["fly_policy"] = source["fly_policy"].duplicate(true)
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
