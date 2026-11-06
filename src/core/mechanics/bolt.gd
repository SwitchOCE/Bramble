extends Mechanic
## Warren Lookout (library entry 37): the first time this survives damage in an attack while in the
## front row with a slot behind it empty, it moves there (the left one) and summons `unit` into the
## slot it left. Prototype reading: it checks after attacks, not after effect damage.


func on_survived_attack(
	combat: Combat, unit: CombatUnit, params: Dictionary, _attacker: CombatUnit
) -> void:
	_try_bolt(combat, unit, params)


func on_after_attacking(
	combat: Combat, unit: CombatUnit, params: Dictionary, _defender: CombatUnit
) -> void:
	_try_bolt(combat, unit, params)


static func _try_bolt(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	if unit.has_status("bolted") or not unit.damaged or not BoardGeometry.is_front(unit.slot):
		return
	for slot: int in BoardGeometry.behind(unit.slot):
		if combat.unit_at(unit.side, slot) == null:
			var left: int = unit.slot
			combat.trigger(unit, "bolt")
			combat.set_status(unit, "bolted", true, unit)
			combat.move_unit(unit, slot)
			combat.summon(str(params.get("unit", "")), unit.golden, unit.side, left, unit)
			return
