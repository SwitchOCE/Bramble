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
	return unit


func tier() -> int:
	var value: int = def["tier"]
	return value


func is_dead() -> bool:
	return health <= 0


## 9.4.5 step 1 (no effect stops units yet in milestone A).
func can_attack() -> bool:
	return on_board and attack > 0


## 6.3 combat unit view.
func view() -> Dictionary:
	var text_key: String = "golden_text" if golden else "text"
	var tribe_list: Array = def["tribes"]
	var keyword_list: Array = def["keywords"]
	var status_list: Array = []
	for status: String in statuses:
		var data: Dictionary = statuses[status]
		status_list.append({"status": status, "data": data.duplicate()})
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
		"keyword_text": UnitLibrary.keyword_text_of(def),
	}
