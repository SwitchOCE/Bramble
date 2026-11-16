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
var state: Dictionary = {}
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


static func from_unit(unit: Unit, new_uid: int, unit_side: int) -> CombatUnit:
	var copy := CombatUnit.new()
	copy.uid = new_uid
	copy.def = unit.def
	copy.golden = unit.golden
	copy.side = unit_side
	copy.slot = unit.slot
	copy.stats = unit.stats.duplicate_block()
	copy.mechanics = unit.mechanics.duplicate()
	copy.starting = true
	copy.recruit_uid = unit.uid
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
	for bound: BoundMechanic in mechanics:
		if bound.id == mechanic_id:
			return true
	return false


## A combat rule about this unit (Mechanic.Q_*), asked of each of its mechanics in order.
func query(name: StringName, base: int) -> int:
	var value: int = base
	for bound: BoundMechanic in mechanics:
		value = bound.mechanic.combat_query(self, name, value, bound.params)
	return value


func view(geometry: BoardGeometry) -> Dictionary:
	var keywords: Array[String] = []
	for bound: BoundMechanic in mechanics:
		if bound.params.to_dict().is_empty():
			keywords.append(String(bound.id))
	return {
		"uid": uid,
		"id": String(def.id),
		"side": side,
		"slot": slot,
		"label": geometry.label(slot),
		"attack": attack(),
		"health": health(),
		"golden": golden,
		"keywords": keywords,
	}
