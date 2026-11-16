class_name Unit
extends RefCounted
## One card a player holds, in hand or on the recruit board: a unit or a Tavern spell.
## Origin (4.3.1) is tracked by copies: `bought_copies` is how many of its copies were paid for
## (sell value, 4.3.3-4.3.4) and `pool_copies` how many came from the shared pool (what returns
## to the pool, 5.3.4-5.3.8). A Bought unit is 1/1, a Discover pick or Triple Reward unit 0/1
## (4.3.2), a token 0/0, a tripled golden the sum of its three copies.

var uid: int = 0
var def: UnitDef
var golden: bool = false
## 7.3.6 made by a triple: playing it gives the Triple Reward.
var from_triple: bool = false
var bought_copies: int = 0
var pool_copies: int = 0
var stats: StatBlock
## Own text first (golden already applied to its numbers), then granted mechanics.
var mechanics: Array[BoundMechanic] = []
## Board slot, or -1 in hand.
var slot: int = -1


static func create(
	card: UnitDef, new_uid: int, is_golden: bool, registry: MechanicRegistry, stat_max: int
) -> Unit:
	var unit := Unit.new()
	unit.uid = new_uid
	unit.def = card
	unit.golden = is_golden
	var factor: int = 2 if is_golden else 1
	unit.stats = StatBlock.of(card.attack * factor, card.health * factor, stat_max)
	for spec: MechanicSpec in card.mechanics:
		unit.mechanics.append(registry.bind(spec, is_golden, false))
	return unit


func is_bought() -> bool:
	return bought_copies > 0


func is_spell() -> bool:
	return def.is_spell()


func attack() -> int:
	return stats.attack()


func health() -> int:
	return stats.max_health()


func has_mechanic(mechanic_id: StringName) -> bool:
	for bound: BoundMechanic in mechanics:
		if bound.id == mechanic_id:
			return true
	return false


## 11.1.1 gain a keyword (no parameters). False if the unit has it already or it is unknown.
func grant(registry: MechanicRegistry, mechanic_id: StringName) -> bool:
	if has_mechanic(mechanic_id) or not registry.has(mechanic_id):
		return false
	mechanics.append(registry.bind(MechanicSpec.new(mechanic_id), golden, true))
	return true


## The keyword mechanics (those with no parameters), for display.
func keyword_ids() -> PackedStringArray:
	var out: PackedStringArray = []
	for bound: BoundMechanic in mechanics:
		if bound.params.to_dict().is_empty() and not out.has(String(bound.id)):
			out.append(String(bound.id))
	return out


## JSON-shaped view for logs and the UI.
func view() -> Dictionary:
	return {
		"uid": uid,
		"id": String(def.id),
		"slot": slot,
		"attack": attack(),
		"health": health(),
		"golden": golden,
		"bought": is_bought(),
		"keywords": Array(keyword_ids()),
	}
