class_name CombatSandbox
extends RefCounted
## Build any two boards and fight them (PLAN item 6). A board is 7 entries in reading order:
## null, or {"def_id": String, "golden": bool, "attack": int, "health": int,
## "display_name": String}; all but "def_id" are optional ("attack"/"health" override the base
## stats, "display_name" replaces the name in the combat view).

var _library: UnitLibrary
var _config: GameConfig
var _boards: Array = [[], []]
var _tiers: Array[int] = [1, 1]


static func create(library: UnitLibrary, config: GameConfig = null) -> CombatSandbox:
	var sandbox := CombatSandbox.new()
	sandbox._library = library
	sandbox._config = config if config != null else GameConfig.defaults()
	for side: int in 2:
		var empty: Array = []
		empty.resize(BoardGeometry.SLOTS)
		sandbox._boards[side] = empty
	return sandbox


func set_board(side: int, board: Array) -> String:
	if side < 0 or side > 1:
		return "Side must be 0 or 1"
	if board.size() != BoardGeometry.SLOTS:
		return "A board has 7 slots"
	var clean: Array = []
	for entry: Variant in board:
		if entry == null:
			clean.append(null)
			continue
		if typeof(entry) != TYPE_DICTIONARY:
			return "Each slot is null or a unit"
		var spec: Dictionary = entry
		var problem: String = _check_spec(spec)
		if problem != "":
			return problem
		clean.append(spec.duplicate())
	_boards[side] = clean
	return ""


func get_board(side: int) -> Array:
	var board: Array = _boards[side]
	return board.duplicate(true)


## Loads a scenario from ScenarioLibrary: both boards and tiers. Fight it with its "seed".
func load_scenario(scenario: Dictionary) -> String:
	if scenario.is_empty():
		return "No such scenario"
	for side: int in 2:
		var problem: String = set_board(side, ScenarioLibrary.board_of(scenario, side))
		if problem != "":
			return problem
		var tiers: Array = scenario.get("tiers", [1, 1])
		set_tier(side, CoreUtil.to_int(tiers[side]))
	return ""


func set_tier(side: int, tier: int) -> void:
	_tiers[side] = clampi(tier, 1, UnitLibrary.TIERS)


## {"events": [...], "winner": int, "damage": int}. The sandbox applies no damage cap.
func fight(fight_seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = fight_seed
	var combat := Combat.create(_library, _config, rng)
	var player_ids: Array[int] = [0, 1]
	var result: Dictionary = combat.run(_boards, _tiers, player_ids, 0)
	return {"events": result["events"], "winner": result["winner"], "damage": result["damage"]}


func _check_spec(spec: Dictionary) -> String:
	var def_id: String = str(spec.get("def_id", ""))
	if _library.get_unit(def_id).is_empty():
		return "Unknown unit: %s" % def_id
	for key: String in ["attack", "health"]:
		if spec.has(key) and typeof(spec[key]) != TYPE_INT and typeof(spec[key]) != TYPE_FLOAT:
			return "%s must be a number" % key
	if spec.has("attack") and CoreUtil.to_int(spec["attack"]) < 0:
		return "Attack can't be below 0"
	if spec.has("health") and CoreUtil.to_int(spec["health"]) < 1:
		return "Health must be at least 1"
	if spec.has("display_name") and typeof(spec["display_name"]) != TYPE_STRING:
		return "display_name must be text"
	return ""
