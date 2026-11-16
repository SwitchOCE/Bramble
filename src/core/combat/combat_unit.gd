class_name CombatUnit
extends RefCounted
## A unit's copy for one combat (9.1.1). Its stat layers are copied from the recruit unit and
## this-combat changes go in the combat layer, so the recruit board never changes (12.1.2).
## Mechanic state for this combat (a shield that is up, a counter) lives in `state`.

var uid: int = 0
var def: UnitDef
var golden: bool = false
var side: int = 0
## Current slot, or its last-known slot once it has left the board (12.2.3).
var slot: int = -1
var stats: StatBlock
var damage: int = 0
var mechanics: Array[BoundMechanic] = []
## Keywords from auras and the slot, recalculated with auras (12.2.1).
var aura_mechanics: Array[BoundMechanic] = []
## This fight's mechanic state (a shield that is up, a counter for this fight only).
var state: Dictionary = {}
## Lasting numbers copied from the recruit unit (Unit.counters); Combat.add_counter changes
## them, and writes back when permanent.
var counters: Dictionary = {}
## 9.4.5 "attacked this cycle".
var flagged: bool = false
## 10.1.2 on its side's board when combat began.
var starting: bool = false
## The recruit unit this copies; -1 for a unit made in combat.
var recruit_uid: int = -1
## 9.10.3 how many times this unit has come back.
var returns: int = 0
## Removed from the board (died). A dead unit never comes back as this object (9.8.2).
var gone: bool = false
## Destroyed outright (Venomous): dies at the next death check whatever its Health.
var destroyed: bool = false
## Bought (4.3.1): the recruit unit came from the shop; false for tokens, copies and units made
## in the fight (Created).
var bought: bool = false


static func from_unit(unit: Unit, new_uid: int, unit_side: int) -> CombatUnit:
	var copy := CombatUnit.new()
	copy.uid = new_uid
	copy.def = unit.def
	copy.golden = unit.golden
	copy.side = unit_side
	copy.slot = unit.slot
	copy.stats = unit.stats.duplicate_block()
	copy.mechanics = unit.mechanics.duplicate()
	copy.counters = unit.counters.duplicate()
	copy.starting = true
	copy.recruit_uid = unit.uid
	copy.bought = unit.bought_copies > 0
	return copy


static func fresh(
	card: UnitDef,
	new_uid: int,
	unit_side: int,
	is_golden: bool,
	registry: MechanicRegistry,
	stat_max: int
) -> CombatUnit:
	var copy := CombatUnit.new()
	var unit: Unit = Unit.create(card, new_uid, is_golden, registry, stat_max)
	copy.uid = new_uid
	copy.def = card
	copy.golden = is_golden
	copy.side = unit_side
	copy.stats = unit.stats
	copy.mechanics = unit.mechanics
	return copy


func attack() -> int:
	return stats.attack()


func max_health() -> int:
	return stats.max_health()


func health() -> int:
	return max_health() - damage


func should_die() -> bool:
	return not gone and (health() <= 0 or destroyed)


func state_int(key: StringName) -> int:
	return CoreUtil.to_int(state.get(key, 0))


func set_state(key: StringName, value: int) -> void:
	state[key] = value


func has_mechanic(mechanic_id: StringName) -> bool:
	for bound: BoundMechanic in hooks():
		if bound.id == mechanic_id:
			return true
	return false


## Every mechanic whose hooks run for this unit: its own, then what auras and its slot give.
func hooks() -> Array[BoundMechanic]:
	if aura_mechanics.is_empty():
		return mechanics
	var out: Array[BoundMechanic] = mechanics.duplicate()
	out.append_array(aura_mechanics)
	return out


## Has a death effect (Mechanic.has_death_effect), its own or given.
func has_death_effect() -> bool:
	return hooks().any(func(b: BoundMechanic) -> bool: return b.mechanic.has_death_effect())


func counter(key: StringName) -> int:
	return CoreUtil.to_int(counters.get(key, 0))


## A combat rule about this unit (Mechanic.Q_*), asked of each of its mechanics in order.
func query(name: StringName, base: int) -> int:
	var value: int = base
	for bound: BoundMechanic in hooks():
		value = bound.mechanic.combat_query(self, name, value, bound.params)
	return value


## Mechanics with parameters that auras or the slot gave this unit ("Root 1"), for pills.
func _grants_view() -> Array:
	var out: Array = []
	for bound: BoundMechanic in aura_mechanics:
		var shown: Dictionary = bound.params.to_dict()
		if not shown.is_empty():
			shown["mechanic"] = String(bound.id)
			out.append(shown)
	return out


func view(geometry: BoardGeometry) -> Dictionary:
	var keywords: Array[String] = []
	for bound: BoundMechanic in hooks():
		if bound.params.to_dict().is_empty() and not keywords.has(String(bound.id)):
			keywords.append(String(bound.id))
	return {
		"uid": uid,
		"recruit_uid": recruit_uid,
		"id": String(def.id),
		"side": side,
		"slot": slot,
		"label": geometry.label(slot),
		"attack": attack(),
		"health": health(),
		"golden": golden,
		"bought": bought,
		"keywords": keywords,
		"grants": _grants_view(),
		"counters": UnitText.counters_view(counters),
		"text": UnitText.fill(def.text, mechanics),
	}
