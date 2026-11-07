extends Mechanic
## Granny Stir-Up: Start of Combat, the Oozes in her touching run go inside and she gains their
## Attack (golden: twice). They come back to their own slots when she dies, still holding what they
## hold, with the damage they had.

const OOZES: String = "Oozes"


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	var gain: int = 0
	for slot: int in BoardGeometry.touching(combat._occupied(unit.side), unit.slot):
		var other: CombatUnit = combat.unit_at(unit.side, slot)
		if other == null or other == unit or not other.has_tribe(OOZES):
			continue
		gain += other.attack
		CombatHeld.swallow(combat, unit, other)
	if gain > 0:
		combat.trigger(unit, "granny")
		combat.buff(unit, gain * CoreUtil.to_int(params.get("factor", 1)), 0, unit)
