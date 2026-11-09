class_name UnitLibrary
extends RefCounted
## The unit files of content/units/ (SPEC section 3). Bad files are skipped and reported in
## load_errors(); the core reads only the fields, never the rules text.

const DEFAULT_DIR: String = "res://content/units"
const TIERS: int = 6
## Field -> the Variant types it may hold (TYPE_NIL means JSON null is allowed).
const FIELDS: Dictionary = {
	"id": [TYPE_STRING],
	"name": [TYPE_STRING],
	"tier": [TYPE_INT],
	"attack": [TYPE_INT],
	"health": [TYPE_INT],
	"tribes": [TYPE_ARRAY],
	"text": [TYPE_STRING],
	"golden_text": [TYPE_STRING],
	"mechanics": [TYPE_ARRAY],
	"keywords": [TYPE_ARRAY],
	"row_hint": [TYPE_STRING, TYPE_NIL],
	"pool": [TYPE_BOOL],
	"priority": [TYPE_INT, TYPE_NIL],
	"skeleton": [TYPE_BOOL],
}

var _units: Array[Dictionary] = []
var _by_id: Dictionary = {}
var _errors: PackedStringArray = []
## content/spells: spells and hand items. content/heroes: heroes. By id, in id order.
var _cards: Dictionary = {}
var _heroes: Dictionary = {}


static func load_dir(path: String = DEFAULT_DIR) -> UnitLibrary:
	var library := UnitLibrary.new()
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		library._errors.append("%s: can't open the directory" % path)
		return library
	var names: PackedStringArray = dir.get_files()
	names.sort()
	for file_name: String in names:
		if file_name.get_extension() == "json":
			library._load_file(path.path_join(file_name))
	library._finish()
	library._load_extra(path.get_base_dir().path_join("spells"), library._cards)
	library._load_extra(path.get_base_dir().path_join("heroes"), library._heroes)
	return library


## The `keyword_text` of a unit view: [{"keyword", "text"}] (SPEC "Changes after the scope review"),
## from the unit's own source.note.
static func keyword_text_of(unit: Dictionary) -> Array:
	var entries: Array = unit.get("keyword_text", [])
	return entries.duplicate(true)


static func _tier_then_name(a: Dictionary, b: Dictionary) -> bool:
	var tier_a: int = a["tier"]
	var tier_b: int = b["tier"]
	if tier_a != tier_b:
		return tier_a < tier_b
	var name_a: String = a["name"]
	var name_b: String = b["name"]
	return name_a < name_b


func all_units() -> Array[Dictionary]:
	return _units.duplicate()


## The units that can be in a shop, of a card set (GameConfig.card_set): "" is the old library.
func pool_units(card_set: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for unit: Dictionary in _units:
		if unit["pool"] and _in_set(unit, card_set):
			out.append(unit)
	return out


static func _in_set(card: Dictionary, card_set: String) -> bool:
	return str(card.get("set", "")) == card_set


## A spell or hand item by id; {} if unknown.
func get_card(card_id: String) -> Dictionary:
	var card: Dictionary = _cards.get(card_id, {})
	return card


func all_cards() -> Array[Dictionary]:
	return _sorted_values(_cards)


## Spells that can appear in shops, of a card set.
func pool_spells(card_set: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for card: Dictionary in all_cards():
		if CoreUtil.to_bool(card.get("pool", false)) and _in_set(card, card_set):
			out.append(card)
	return out


func get_hero(hero_id: String) -> Dictionary:
	var hero: Dictionary = _heroes.get(hero_id, {})
	return hero


func all_heroes() -> Array[Dictionary]:
	return _sorted_values(_heroes)


## The heroes of a card set.
func heroes_of(card_set: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for hero: Dictionary in all_heroes():
		if _in_set(hero, card_set):
			out.append(hero)
	return out


## The tribes with at least `min_units` pool units, sorted (5.2.4 rotation).
func tribes_in_rotation(min_units: int = 1, card_set: String = "") -> PackedStringArray:
	var counts: Dictionary = {}
	for unit: Dictionary in pool_units(card_set):
		var tribes: Array = unit["tribes"]
		for tribe: Variant in tribes:
			counts[str(tribe)] = CoreUtil.to_int(counts.get(str(tribe), 0)) + 1
	var out: PackedStringArray = []
	for tribe: String in counts:
		if CoreUtil.to_int(counts[tribe]) >= min_units:
			out.append(tribe)
	out.sort()
	return out


## Adds a spell or hand item at run time (tests and the soak's content).
func register_card(raw: Dictionary) -> void:
	var card: Variant = _whole_numbers(raw)
	_cards[str(raw["id"])] = card


## Adds a hero at run time (tests and the soak's content).
func register_hero(raw: Dictionary) -> void:
	var hero: Variant = _whole_numbers(raw)
	_heroes[str(raw["id"])] = hero


func get_unit(def_id: String) -> Dictionary:
	var unit: Dictionary = _by_id.get(def_id, {})
	return unit


func load_errors() -> PackedStringArray:
	return _errors.duplicate()


func unbuilt_units() -> PackedStringArray:
	var out: PackedStringArray = []
	for unit: Dictionary in _units:
		var mechanics: Array = unit["mechanics"]
		for mechanic: Variant in mechanics:
			var entry: Dictionary = mechanic
			if not MechanicRegistry.is_built(str(entry.get("id", ""))):
				out.append(str(unit["id"]))
				break
	return out


## Adds a unit at run time (tests and the soak's content). "" or the problem.
func register_unit(raw: Dictionary) -> String:
	var problem: String = _validate(raw)
	if problem != "":
		return problem
	var unit: Dictionary = _normalised(raw)
	_by_id[unit["id"]] = unit
	var filled: Array[Dictionary] = [unit]
	_fill_keyword_text(filled)
	_units.append(unit)
	_units.sort_custom(_tier_then_name)
	return ""


func _finish() -> void:
	_units.sort_custom(_tier_then_name)
	_fill_keyword_text(_units)


## A card of a set takes its reminders from the schema's keyword list. The old library's reminders
## stay in each unit's source.note.
static func _fill_keyword_text(units: Array[Dictionary]) -> void:
	for unit: Dictionary in units:
		var config: GameConfig = GameConfig.defaults()
		for key: String in unit.get("pass3_rates", {}):
			config.set_value(key, unit["pass3_rates"][key])
		Pass3Text.configure(unit, config)
		var entries: Array = []
		var note: String = _note_of(unit)
		var keywords: Array = unit.get("keywords", [])
		var reminders: Dictionary = EffectSchema.section("keywords")
		var overrides: Dictionary = unit.get("keyword_text_overrides", {})
		for keyword: Variant in keywords:
			if overrides.has(keyword):
				entries.append({"keyword": str(keyword), "text": str(overrides[keyword])})
			elif unit.has("set") and reminders.has(keyword):
				entries.append({"keyword": str(keyword), "text": str(reminders[keyword])})
			elif note != "":
				entries.append({"keyword": str(keyword), "text": note})
		unit["keyword_text"] = entries


static func _note_of(unit: Dictionary) -> String:
	var source: Variant = unit.get("source")
	if typeof(source) != TYPE_DICTIONARY:
		return ""
	var source_dict: Dictionary = source
	var note: Variant = source_dict.get("note")
	return "" if note == null else str(note)


static func _sorted_values(map: Dictionary) -> Array[Dictionary]:
	var keys: Array = map.keys()
	keys.sort()
	var out: Array[Dictionary] = []
	for key: Variant in keys:
		var value: Dictionary = map[key]
		out.append(value)
	return out


## Spell and hero files. Their shape is checked by tools/checks/check_units.py.
func _load_extra(dir_path: String, into: Dictionary) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	var names: PackedStringArray = dir.get_files()
	names.sort()
	for file_name: String in names:
		if file_name.get_extension() != "json":
			continue
		var parsed: Variant = JSON.parse_string(
			FileAccess.get_file_as_string(dir_path.path_join(file_name))
		)
		if typeof(parsed) != TYPE_DICTIONARY:
			_errors.append("%s: not a JSON object" % file_name)
			continue
		var card: Dictionary = _whole_numbers(parsed)
		var filled: Array[Dictionary] = [card]
		_fill_keyword_text(filled)
		into[str(card.get("id", file_name.get_basename()))] = card


func _load_file(file_path: String) -> void:
	var text: String = FileAccess.get_file_as_string(file_path)
	if text.is_empty():
		_errors.append("%s: empty or unreadable" % file_path)
		return
	var json := JSON.new()
	if json.parse(text) != OK:
		_errors.append(
			(
				"%s: JSON error on line %d: %s"
				% [file_path, json.get_error_line(), json.get_error_message()]
			)
		)
		return
	var data: Variant = json.data
	if typeof(data) != TYPE_DICTIONARY:
		_errors.append("%s: not a JSON object" % file_path)
		return
	var unit: Dictionary = data
	if str(unit.get("id", "")) != file_path.get_file().get_basename():
		_errors.append("%s: id doesn't match the file name" % file_path)
		return
	_add(unit, file_path)


func _add(raw: Dictionary, where: String) -> void:
	var problem: String = _validate(raw)
	if problem != "":
		_errors.append("%s: %s" % [where, problem])
		return
	var unit: Dictionary = _normalised(raw)
	var id: String = unit["id"]
	if _by_id.has(id):
		_errors.append("%s: duplicate id %s" % [where, id])
		return
	_by_id[id] = unit
	_units.append(unit)


func _validate(unit: Dictionary) -> String:
	for field: String in FIELDS:
		if not unit.has(field):
			return "missing field %s" % field
		var allowed: Array = FIELDS[field]
		var kind: int = _json_type(unit[field])
		if not allowed.has(kind):
			return "field %s has the wrong type" % field
	return _validate_values(unit)


func _validate_values(unit: Dictionary) -> String:
	var tier: int = _as_int(unit["tier"])
	if tier < 1 or tier > TIERS:
		return "tier must be 1-%d" % TIERS
	if _as_int(unit["attack"]) < 0 or _as_int(unit["health"]) < 1:
		return "needs Attack >= 0 and Health >= 1"
	var mechanics: Array = unit["mechanics"]
	for mechanic: Variant in mechanics:
		var ok: bool = typeof(mechanic) == TYPE_DICTIONARY
		if ok:
			var entry: Dictionary = mechanic
			ok = typeof(entry.get("id")) == TYPE_STRING
		if not ok:
			return "each mechanic must be an object with a string id"
	return ""


## JSON parses every number as a float; whole numbers count as ints.
static func _json_type(value: Variant) -> int:
	var kind: int = typeof(value)
	if kind == TYPE_FLOAT:
		var number: float = value
		if is_equal_approx(number, roundf(number)):
			return TYPE_INT
	return kind


static func _as_int(value: Variant) -> int:
	return CoreUtil.to_int(value)


## Ints stay ints (JSON gives floats), arrays become plain arrays of their values.
static func _normalised(raw: Dictionary) -> Dictionary:
	var unit: Dictionary = raw.duplicate(true)
	for field: String in ["tier", "attack", "health"]:
		unit[field] = _as_int(unit[field])
	if unit["priority"] != null:
		unit["priority"] = _as_int(unit["priority"])
	unit["mechanics"] = _whole_numbers(unit["mechanics"])
	return unit


## JSON gives every number as a float; effect entries nest, so this goes all the way down.
static func _whole_numbers(value: Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT:
			return _as_int(value)
		TYPE_ARRAY:
			var list: Array = value
			var out: Array = []
			for item: Variant in list:
				out.append(_whole_numbers(item))
			return out
		TYPE_DICTIONARY:
			var map: Dictionary = value
			var copy: Dictionary = {}
			for key: Variant in map:
				copy[key] = _whole_numbers(map[key])
			return copy
	return value
