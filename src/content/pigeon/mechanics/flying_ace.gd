extends Mechanic
## Flying Ace (with pigeon_sortie): after this kills, earn `medals` Medals for each unit its own
## damage killed, on the fight unit and the real one at once, kept if it dies in the same
## exchange. Decorated: Cleave, given to itself as an aura that follows the Medal count.

const Medals := preload("res://src/content/pigeon/lib/medals.gd")


func param_kinds() -> Dictionary:
	return {"medals": MechanicParams.Kind.NUMBER}


func on_kill(combat: Combat, unit: CombatUnit, _victim: CombatUnit, params: MechanicParams) -> void:
	if combat.trigger(unit, &"pigeon_flying_ace"):
		Medals.earn_in_fight(combat, unit, params.num(&"medals"))


func has_aura() -> bool:
	return true


func aura_keywords(
	view: AuraContext, source_slot: int, target_slot: int, _params: MechanicParams
) -> Array[StringName]:
	var out: Array[StringName] = []
	if source_slot >= 0 and source_slot == target_slot and Medals.decorated(view, source_slot):
		out.append(&"cleave")
	return out
