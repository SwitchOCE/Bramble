extends Mechanic
## Wing Commander (with pigeon_sortie): Start of fight (main pass): each friendly Pigeon that has
## Sortie, this one and those a Squadron Leader gives it included, makes `attacks` out-of-turn
## attacks (9.4.12) in reading order. A golden gives two each.

const SORTIE: StringName = &"pigeon_sortie"


func param_kinds() -> Dictionary:
	return {"attacks": MechanicParams.Kind.NUMBER}


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	var flyers: Array[CombatUnit] = []
	for friend: CombatUnit in combat.units(unit.side):
		if friend.def.has_tribe("Pigeon") and friend.has_mechanic(SORTIE):
			flyers.append(friend)
	if flyers.is_empty() or not combat.trigger(unit, &"pigeon_wing_commander"):
		return
	for flyer: CombatUnit in flyers:
		for _attack: int in params.num(&"attacks"):
			if flyer.gone or flyer.should_die() or combat.halted():
				break
			combat.attack_now(flyer)
