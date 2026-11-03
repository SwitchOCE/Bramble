class_name RecruitUnit
extends RefCounted
## One unit a player holds in the Recruit Phase: in the shop, the hand or on the board.
## attack/health include permanent buffs. pool_copies is how many pool copies it holds (5.3.5).

const ORIGIN_BOUGHT: String = "bought"
const ORIGIN_CREATED: String = "created"

var iid: int = 0
var def: Dictionary = {}
var golden: bool = false
var origin: String = ORIGIN_BOUGHT
var attack: int = 0
var health: int = 0
var pool_copies: int = 0
## True for a golden made by a triple (4.3.4 sells for 1).
var from_triple: bool = false
## True until a triple's golden is first played (7.3.6 Triple Reward).
var reward_pending: bool = false
var counters: Dictionary = {}


static func make(unit_def: Dictionary, instance_id: int, is_golden: bool = false) -> RecruitUnit:
	var unit := RecruitUnit.new()
	unit.iid = instance_id
	unit.def = unit_def
	unit.golden = is_golden
	var factor: int = 2 if is_golden else 1
	var base_attack: int = unit_def["attack"]
	var base_health: int = unit_def["health"]
	unit.attack = base_attack * factor
	unit.health = base_health * factor
	return unit


func def_id() -> String:
	var id: String = def["id"]
	return id


func tier() -> int:
	var value: int = def["tier"]
	return value


func tribes() -> Array:
	var value: Array = def["tribes"]
	return value


func row_hint() -> String:
	var hint: Variant = def["row_hint"]
	return "" if hint == null else str(hint)


## 6.2 recruit unit view.
func view() -> Dictionary:
	var text_key: String = "golden_text" if golden else "text"
	var tribe_list: Array = def["tribes"]
	var keyword_list: Array = def["keywords"]
	return {
		"iid": iid,
		"def_id": def_id(),
		"name": str(def["name"]),
		"tier": tier(),
		"tribes": tribe_list.duplicate(),
		"attack": attack,
		"health": health,
		"golden": golden,
		"origin": origin,
		"text": str(def[text_key]),
		"keywords": keyword_list.duplicate(),
		"counters": counters.duplicate(),
		"keyword_text": UnitLibrary.keyword_text_of(def),
	}


## The entry a combat board takes (the same shape as CombatSandbox boards).
func combat_spec() -> Dictionary:
	return {"def_id": def_id(), "golden": golden, "attack": attack, "health": health}
