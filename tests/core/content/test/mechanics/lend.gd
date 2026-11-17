extends Mechanic
## Lends (the badgers' Armsbearer and Sett Shield-bearer): the units in front of this have extra
## Attack and maximum Health equal to this unit's as they stand (AuraContext.attack_at,
## max_health_at), its slot's buff and permanent buffs included.


func has_aura() -> bool:
	return true


func aura(
	view: AuraContext, source_slot: int, target_slot: int, _params: MechanicParams
) -> Vector2i:
	if source_slot < 0 or not view.geometry.in_front_of(source_slot).has(target_slot):
		return Vector2i.ZERO
	return Vector2i(view.attack_at(source_slot), view.max_health_at(source_slot))
