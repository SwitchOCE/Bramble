# gdlint:disable=max-public-methods
# The port mirrors SPEC section 7 one method per call, which is more than 20.
extends "res://src/ui/adapter/game_port.gd"
## A GamePort that answers from the JSON fixtures in docs/prototype/fixtures/ (SPEC.md formats).
## No rules: recruit actions only report that they aren't wired; End Turn steps through a fixed
## sequence of states and always "fights" combat_nightshade.json. It exists so the screens can be
## built and screenshotted before the rules core is merged.
##
## The fixtures are read straight from docs/ (docs/.gdignore only stops importing, FileAccess
## still reads them in the editor and in tests). An exported build excludes docs/*, so this port
## only works from the project folder; the real port replaces it there.

const Data := preload("res://src/ui/view_data.gd")
const FIXTURE_DIR: String = "res://docs/prototype/fixtures/"
const UNIT_DIR: String = "res://content/units/"
const STATE_SEQUENCE: PackedStringArray = ["recruit_round1", "recruit_round7", "recruit_game_over"]
const COMBAT_FIXTURE: String = "combat_nightshade"
const NOT_WIRED: String = "Fixture mode: %s isn't wired to the rules yet"

var _state: Dictionary = {}
var _step: int = -1
var _last_combat: Dictionary = {}
var _units: Array[Dictionary] = []


## Reads a fixture by name ("recruit_round7"). Integral numbers come back as int, as from the core.
static func load_fixture(fixture_name: String) -> Dictionary:
	return load_json(FIXTURE_DIR + fixture_name + ".json")


static func load_json(path: String) -> Dictionary:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("fixture_port: can't read %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("fixture_port: %s is not a JSON object" % path)
		return {}
	var out: Dictionary = _ints(parsed)
	return out


## JSON numbers parse as float; the core hands out ints. Convert every integral float.
static func _ints(value: Variant) -> Variant:
	if value is float:
		var number: float = value
		if is_equal_approx(number, roundf(number)):
			return int(number)
		return number
	if value is Array:
		var out: Array = []
		for item: Variant in value:
			out.append(_ints(item))
		return out
	if value is Dictionary:
		var source: Dictionary = value
		var out_dict: Dictionary = {}
		for key: Variant in source:
			out_dict[key] = _ints(source[key])
		return out_dict
	return value


## Jumps straight to one fixture state (tests and screenshots).
func use_state(fixture_name: String) -> void:
	_state = load_fixture(fixture_name)
	_step = STATE_SEQUENCE.find(fixture_name)


## Uses a state from any JSON file (tests/ui/data has hero, spell and Discover states).
func use_state_file(path: String) -> void:
	_state = load_json(path)
	_step = -1


func use_combat(fixture_name: String = COMBAT_FIXTURE) -> void:
	_last_combat = load_fixture(fixture_name)


func new_game(_seed: int) -> String:
	_last_combat = {}
	use_state(STATE_SEQUENCE[0])
	return ""


func get_state() -> Dictionary:
	return _state


func get_last_combat() -> Dictionary:
	return _last_combat


func is_over() -> bool:
	return str(_state.get("phase", "")) == "game_over"


func buy(_shop_index: int) -> String:
	return NOT_WIRED % "buying"


func sell(_slot: int) -> String:
	return NOT_WIRED % "selling"


func play(_hand_index: int, _slot: int) -> String:
	return NOT_WIRED % "playing"


func move(_from_slot: int, _to_slot: int) -> String:
	return NOT_WIRED % "moving"


func refresh() -> String:
	return NOT_WIRED % "refresh"


func toggle_freeze() -> String:
	return NOT_WIRED % "freeze"


func tier_up() -> String:
	return NOT_WIRED % "tier up"


func end_turn() -> String:
	if _state.is_empty() or is_over():
		return "No game running"
	use_combat()
	var next_step: int = mini(_step + 1, STATE_SEQUENCE.size() - 1)
	use_state(STATE_SEQUENCE[next_step])
	return ""


func library_units() -> Array[Dictionary]:
	if _units.is_empty():
		_units = _read_units()
	return _units


func sandbox_fight(_boards: Array, _seed: int, _tiers: Array = [1, 1]) -> Dictionary:
	var combat: Dictionary = load_fixture(COMBAT_FIXTURE)
	var events: Array = Data.a(combat, "events")
	var end: Dictionary = Data.entry(events, events.size() - 1)
	return {"events": events, "winner": Data.i(end, "winner", -1), "damage": Data.i(end, "damage")}


func _read_units() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dir: DirAccess = DirAccess.open(UNIT_DIR)
	if dir == null:
		push_error("fixture_port: can't open %s" % UNIT_DIR)
		return out
	for file: String in dir.get_files():
		if file.get_extension() == "json":
			var unit: Dictionary = load_json(UNIT_DIR + file)
			if not unit.is_empty():
				out.append(unit)
	out.sort_custom(_unit_before)
	return out


static func _unit_before(a: Dictionary, b: Dictionary) -> bool:
	var tier_a: int = Data.i(a, "tier", 0)
	var tier_b: int = Data.i(b, "tier", 0)
	if tier_a != tier_b:
		return tier_a < tier_b
	return str(a.get("name", "")) < str(b.get("name", ""))
