class_name RecruitUnit
extends BoardUnit
## One unit a player holds in the Recruit Phase: in the shop, the hand or on the board.
## pool_copies is how many pool copies it holds (5.3.5). Its combat layer holds buffs "for the
## next combat" given during the Recruit Phase; it empties when the fight is over.

const ORIGIN_BOUGHT: String = "bought"
const ORIGIN_CREATED: String = "created"

var iid: int = 0
var origin: String = ORIGIN_BOUGHT
var pool_copies: int = 0
## True for a golden made by a triple (4.3.4 sells for 1).
var from_triple: bool = false
## True until a triple's golden is first played (7.3.6 Triple Reward).
var reward_pending: bool = false
## End of Turns ended in this slot; a move resets it (Sleeping Partner, Cold Frame share it).
var turns_in_slot: int = 0
## The slot `turns_in_slot` counts for; -1 until it next ends a turn on the board.
var home_slot: int = -1
## Waiting prizes ("after N turns in its slot"): {"turns", "left", "attack", "health"}.
var timers: Array[Dictionary] = []
## Shy: the stats it last had, to see a rise. x < 0 until first seen on the board.
var shy_seen: Vector2i = Vector2i(-1, -1)


static func make(unit_def: Dictionary, instance_id: int, is_golden: bool = false) -> RecruitUnit:
	var unit := RecruitUnit.new()
	unit.iid = instance_id
	unit.set_base(unit_def, is_golden)
	return unit


func row_hint() -> String:
	var hint: Variant = def["row_hint"]
	return "" if hint == null else str(hint)


## 6.2 recruit unit view. `stat_layers` shows where the numbers come from.
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
		"keywords": _keywords_now(keyword_list),
		"counters": counters.duplicate(),
		"keyword_text": UnitLibrary.keyword_text_of(def),
		"stat_layers":
		{
			"base_attack": base_attack_now(),
			"base_health": base_health_now(),
			"perm_attack": perm_attack,
			"perm_health": perm_health,
			"combat_attack": combat_attack,
			"combat_health": combat_health,
			"aura_attack": aura_attack,
			"aura_health": aura_health,
		},
		"turns_in_slot": _turns_shown(),
		"turns_goal": _turns_goal_left(),
		"timers": timers.duplicate(true),
		"shy": has_mechanic_id("shy"),
		"eats_items": eat_rate() > 0,
	}


## Whether the card itself has this mechanic.
func has_mechanic_id(mechanic_id: String) -> bool:
	for value: Variant in MechanicRegistry.compiled(def):
		var compiled: CompiledMechanic = value
		if compiled.id == mechanic_id:
			return true
	return false


## A number parameter of one of the card's mechanics, doubled if golden; 0 if it has none.
func mechanic_number(mechanic_id: String, key: String) -> int:
	for value: Variant in MechanicRegistry.compiled(def):
		var compiled: CompiledMechanic = value
		if compiled.id == mechanic_id:
			var params: Dictionary = compiled.params_for(golden)
			return CoreUtil.to_int(params.get(key, 0))
	return 0


## Stats per gold when an Acorn item is played on this; 0 if it can't take one.
func eat_rate() -> int:
	return mechanic_number("eats_acorns", "per_gold")


## A move: the slot's count starts over, and waiting prizes with it.
func reset_turns() -> void:
	turns_in_slot = 0
	home_slot = -1
	for timer: Dictionary in timers:
		timer["left"] = timer["turns"]


## The card's keywords plus any it gained.
func _keywords_now(printed: Array) -> Array:
	var out: Array = printed.duplicate()
	for grant: Dictionary in grants:
		var keyword: String = grant.get("keyword", "")
		if keyword != "" and not out.has(keyword):
			out.append(keyword)
	return out


## The entry a combat board takes (the same shape as CombatSandbox boards, plus the layers).
func combat_spec() -> Dictionary:
	var spec: Dictionary = {
		"def_id": def_id(),
		"golden": golden,
		"attack": base_attack_now() + perm_attack,
		"health": base_health_now() + perm_health,
		"iid": iid,
	}
	if counters.has("hex"):
		spec["hex"] = counters["hex"]
	if combat_attack != 0 or combat_health != 0:
		spec["combat_attack"] = combat_attack
		spec["combat_health"] = combat_health
	if not grants.is_empty():
		spec["grants"] = grants.duplicate()
	return spec


## The fight is over: "next combat" buffs end (12.1.1).
func clear_combat_layer() -> void:
	combat_attack = 0
	combat_health = 0
	if grants.is_empty():
		return
	var kept: Array[Dictionary] = []
	for grant: Dictionary in grants:
		if not grant.get("combat_only", false):
			kept.append(grant)
	grants = kept


## A card that pays every N turns shows how far it is into this round of N.
func _turns_shown() -> int:
	var goal: int = CoreUtil.to_int(def.get("turns_goal", 0))
	if goal > 0 and CoreUtil.to_int(def.get("turns_repeat", 0)) > 0:
		return turns_in_slot % goal
	return turns_in_slot


## What the unit's "After N turns" still waits for; 0 once it has fired, so screens stop counting.
func _turns_goal_left() -> int:
	for key: Variant in counters:
		if str(key).begins_with("fired_"):
			return 0
	var goal: int = CoreUtil.to_int(def.get("turns_goal", 0))
	if (
		turns_in_slot >= goal * CoreUtil.to_int(def.get("turns_repeat", 0))
		and def.has("turns_repeat")
	):
		return 0
	return goal
