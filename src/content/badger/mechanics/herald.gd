extends Mechanic
## Herald of the Charge: Start of fight (main pass): the chosen front units, any tribe,
## attack immediately, the left one first. Normal attacks: they take damage and their "whenever
## this attacks" effects trigger. A unit that can't attack doesn't.

const Badger := preload("res://src/content/badger/lib/badger_rules.gd")


func param_kinds() -> Dictionary:
	return {"target_set": MechanicParams.Kind.TEXT}


func text_params(params: MechanicParams) -> Dictionary:
	return Badger.front_target_words(params)


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	var charging: Array[CombatUnit] = combat.select(unit, Badger.front_target_set(params))
	if charging.is_empty() or not combat.trigger(unit, &"badger_herald"):
		return
	for front: CombatUnit in charging:
		if not front.gone and not front.should_die():
			combat.attack_now(front)
