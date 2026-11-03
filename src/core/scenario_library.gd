class_name ScenarioLibrary
extends RefCounted
## Sandbox scenarios built from the mechanics library's scenes (content/scenarios/*.json), so a
## mechanic can be watched doing what its library entry describes. Load one into a
## CombatSandbox with load_scenario() and fight it with its "seed".
## File format: {"id", "title", "entry", "units", "watch", "note"?, "seed"?, "tiers"?,
## "boards": {"mine": {"F1": unit, ...}, "theirs": {...}}, "expect"?}, where a unit is
## {"def_id", "attack"?, "health"?, "golden"?, "display_name"?} and "expect" lists event
## field subsets the fight at "seed" must contain (checked by the tests).

const DEFAULT_DIR: String = "res://content/scenarios"
const SIDES: PackedStringArray = ["mine", "theirs"]
const UNIT_KEYS: PackedStringArray = ["def_id", "attack", "health", "golden", "display_name"]
const SUMMARY_KEYS: PackedStringArray = ["id", "title", "entry", "units", "watch", "note", "seed"]

var _scenarios: Dictionary = {}
var _order: Array[String] = []
var _errors: PackedStringArray = []
var _units: UnitLibrary


static func load_dir(units: UnitLibrary, path: String = DEFAULT_DIR) -> ScenarioLibrary:
	var library := ScenarioLibrary.new()
	library._units = units
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		library._errors.append("%s: can't open the directory" % path)
		return library
	var names: PackedStringArray = dir.get_files()
	names.sort()
	for file_name: String in names:
		if file_name.get_extension() == "json":
			library._load_file(path.path_join(file_name))
	library._order.sort_custom(library._by_entry)
	return library


## Summaries for a list, by library entry then id: {"id", "title", "entry", "units", "watch",
## "note", "seed"}.
func all_scenarios() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in _order:
		var scenario: Dictionary = _scenarios[id]
		var summary: Dictionary = {}
		for key: String in SUMMARY_KEYS:
			summary[key] = scenario.get(key, "")
		out.append(summary.duplicate(true))
	return out


## The full scenario, or {} if there is none with that id.
func get_scenario(id: String) -> Dictionary:
	var scenario: Dictionary = _scenarios.get(id, {})
	return scenario.duplicate(true)


func load_errors() -> PackedStringArray:
	return _errors.duplicate()


## One side's board (0 = "mine", 1 = "theirs") as 7 CombatSandbox entries in reading order.
static func board_of(scenario: Dictionary, side: int) -> Array:
	var board: Array = []
	board.resize(BoardGeometry.SLOTS)
	var boards: Dictionary = scenario.get("boards", {})
	var units: Dictionary = boards.get(SIDES[side], {})
	for label: Variant in units:
		var slot: int = BoardGeometry.LABELS.find(str(label))
		if slot >= 0:
			var entry: Dictionary = units[label]
			var spec: Dictionary = entry.duplicate()
			for key: String in ["attack", "health"]:
				if spec.has(key):
					spec[key] = CoreUtil.to_int(spec[key])
			board[slot] = spec
	return board


func _load_file(file_path: String) -> void:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file_path)) != OK:
		_errors.append("%s: JSON error on line %d" % [file_path, json.get_error_line()])
		return
	if typeof(json.data) != TYPE_DICTIONARY:
		_errors.append("%s: not a JSON object" % file_path)
		return
	var scenario: Dictionary = json.data
	var problem: String = _check(scenario, file_path.get_file().get_basename())
	if problem != "":
		_errors.append("%s: %s" % [file_path, problem])
		return
	scenario["entry"] = CoreUtil.to_int(scenario["entry"])
	scenario["seed"] = CoreUtil.to_int(scenario.get("seed", 1))
	scenario["note"] = str(scenario.get("note", ""))
	_scenarios[str(scenario["id"])] = scenario
	_order.append(str(scenario["id"]))


func _check(scenario: Dictionary, file_id: String) -> String:
	var problem: String = ""
	if str(scenario.get("id", "")) != file_id:
		problem = "id doesn't match the file name"
	elif (
		typeof(scenario.get("title")) != TYPE_STRING or typeof(scenario.get("watch")) != TYPE_STRING
	):
		problem = "title and watch must be text"
	elif typeof(scenario.get("entry")) != TYPE_FLOAT:
		problem = "entry must be a library entry number"
	elif typeof(scenario.get("units")) != TYPE_ARRAY:
		problem = "units must list the unit ids the scenario shows"
	elif typeof(scenario.get("boards")) != TYPE_DICTIONARY:
		problem = "boards must be {mine, theirs}"
	else:
		var boards: Dictionary = scenario["boards"]
		for side: String in SIDES:
			problem = _check_side(boards.get(side))
			if problem != "":
				return "boards.%s: %s" % [side, problem]
	return problem


func _check_side(value: Variant) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return "must map slots to units"
	var units: Dictionary = value
	if units.is_empty():
		return "must hold at least one unit"
	for label: Variant in units:
		var problem: String = _check_unit(str(label), units[label])
		if problem != "":
			return "%s: %s" % [label, problem]
	return ""


func _check_unit(label: String, value: Variant) -> String:
	if not BoardGeometry.LABELS.has(label):
		return "unknown slot (F1-F4, B1-B3)"
	if typeof(value) != TYPE_DICTIONARY:
		return "must be a unit"
	var unit: Dictionary = value
	for key: Variant in unit:
		if not UNIT_KEYS.has(str(key)):
			return "unknown key %s" % key
	if _units.get_unit(str(unit.get("def_id", ""))).is_empty():
		return "unknown unit %s" % unit.get("def_id", "")
	return ""


func _by_entry(a: String, b: String) -> bool:
	var scenario_a: Dictionary = _scenarios[a]
	var scenario_b: Dictionary = _scenarios[b]
	var entry_a: int = CoreUtil.to_int(scenario_a["entry"])
	var entry_b: int = CoreUtil.to_int(scenario_b["entry"])
	if entry_a != entry_b:
		return entry_a < entry_b
	return a < b
