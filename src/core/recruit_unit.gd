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
		},
	}


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
