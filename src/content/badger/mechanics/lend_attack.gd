extends Mechanic
## Lends its Attack to the units in front of it (an aura, 12.2.1; borrowed stats): extra Attack
## equal to this unit's Attack as it stands (AuraContext.attack_at: permanent buffs, its slot's
## buff and doubling included), recalculated when it changes. A golden lends its own doubled
## Attack.


func has_aura() -> bool:
	return true


func aura(
	view: AuraContext, source_slot: int, target_slot: int, _params: MechanicParams
) -> Vector2i:
	if source_slot < 0 or not view.geometry.in_front_of(source_slot).has(target_slot):
		return Vector2i.ZERO
	return Vector2i(view.attack_at(source_slot), 0)
