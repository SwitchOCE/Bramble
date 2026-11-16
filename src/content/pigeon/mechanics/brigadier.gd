extends Mechanic
## Brigadier: an aura giving every friendly Decorated Pigeon (3+ Medals), itself included, the
## core's "attacks twice" (windfury, 9.4.11). It follows the Medal count, so a third Medal earned
## mid-fight counts from then. Out-of-turn attacks stay single (the core's attack_now).

const Medals := preload("res://src/content/pigeon/lib/medals.gd")


func has_aura() -> bool:
	return true


func aura_keywords(
	view: AuraContext, source_slot: int, target_slot: int, _params: MechanicParams
) -> Array[StringName]:
	var out: Array[StringName] = []
	if source_slot < 0:
		return out
	if Medals.is_pigeon(view, target_slot) and Medals.decorated(view, target_slot):
		out.append(&"windfury")
	return out
