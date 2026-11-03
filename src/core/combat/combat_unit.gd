class_name CombatUnit
extends RefCounted
## One unit in a fight: a copy of a board unit (9.1.1) or a combat-only summon (9.8.4).

var uid: int = 0
var def: Dictionary = {}
var side: int = 0
var slot: int = -1
var golden: bool = false
var attack: int = 0
var health: int = 0
var max_health: int = 0
## 9.4.5 "attacked this cycle".
var flagged: bool = false
## On the board (false once it has died and left its slot).
var on_board: bool = true
## Status name -> data (SPEC 4.1 statuses).
var statuses: Dictionary = {}
## Has taken damage this combat (Ermine Duellist's Quick).
var damaged: bool = false
## The bonus its aura gives it right now (12.2.1), already included in attack/health.
var aura: Vector2i = Vector2i.ZERO
## Built mechanics, with their parameters (golden numbers doubled), in the unit file's order.
var scripts: Array[Mechanic] = []
var params: Array[Dictionary] = []
var mechanic_ids: PackedStringArray = []
var acts_without_attack: bool = false


static func make(
	unit_def: Dictionary, spec: Dictionary, unit_id: int, unit_side: int
) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.uid = unit_id
	unit.def = unit_def
	unit.side = unit_side
	unit.golden = CoreUtil.to_bool(spec.get("golden", false))
	var factor: int = 2 if unit.golden else 1
	var base_attack: int = unit_def["attack"]
	var base_health: int = unit_def["health"]
	unit.attack = CoreUtil.to_int(spec.get("attack", base_attack * factor))
	unit.max_health = CoreUtil.to_int(spec.get("health", base_health * factor))
	unit.health = unit.max_health
	var entries: Array = unit_def["mechanics"]
	for entry_value: Variant in entries:
		var entry: Dictionary = entry_value
		var id: String = str(entry.get("id", ""))
		var mechanic: Mechanic = MechanicRegistry.get_mechanic(id)
		if mechanic == null:
			continue
		var unit_params: Dictionary = MechanicRegistry.params_for(entry, unit.golden)
		unit.scripts.append(mechanic)
		unit.params.append(unit_params)
		unit.mechanic_ids.append(id)
		if mechanic.acts_without_attack(unit_params):
			unit.acts_without_attack = true
		mechanic.setup(unit, unit_params)
	return unit


func tier() -> int:
	var value: int = def["tier"]
	return value


func is_dead() -> bool:
	return health <= 0


## 9.9.1: it can attack. Whistle never attacks, even with Attack (library entry 10).
func can_attack() -> bool:
	return on_board and attack > 0 and not acts_without_attack


## 9.4.5 step 1: it can be chosen in the attack order (it can attack, or it whistles).
func can_act() -> bool:
	return on_board and (attack > 0 or acts_without_attack)


func has_mechanic(mechanic_id: String) -> bool:
	return mechanic_ids.has(mechanic_id)


func has_status(status: String) -> bool:
	return statuses.has(status)


## 6.3 combat unit view. `status_text` maps a status to its {"keyword", "text"} entry.
func view(status_text: Dictionary = {}) -> Dictionary:
	var text_key: String = "golden_text" if golden else "text"
	var tribe_list: Array = def["tribes"]
	var keyword_list: Array = def["keywords"]
	var status_list: Array = []
	var keyword_text: Array = UnitLibrary.keyword_text_of(def)
	for status: String in statuses:
		var data: Dictionary = statuses[status]
		status_list.append({"status": status, "data": data.duplicate()})
		if status_text.has(status):
			var entry: Dictionary = status_text[status]
			if not keyword_text.has(entry):
				keyword_text.append(entry.duplicate())
	return {
		"uid": uid,
		"def_id": str(def["id"]),
		"name": str(def["name"]),
		"tier": tier(),
		"tribes": tribe_list.duplicate(),
		"attack": attack,
		"health": health,
		"max_health": max_health,
		"golden": golden,
		"text": str(def[text_key]),
		"keywords": keyword_list.duplicate(),
		"statuses": status_list,
		"keyword_text": keyword_text,
	}
