extends Mechanic
## Lends its Health to the units in front of it: extra maximum Health equal to this unit's
## maximum Health as it stands (AuraContext.max_health_at: permanent buffs and Renown
## included), recalculated when it changes (an aura, 12.2.1; borrowed stats). When this leaves,
## the extra goes but never takes a unit below 1 (the core's rule for aura Health). A golden lends
## its own doubled Health.


func has_aura() -> bool:
	return true


func aura(
	view: AuraContext, source_slot: int, target_slot: int, _params: MechanicParams
) -> Vector2i:
	if source_slot < 0 or not view.geometry.in_front_of(source_slot).has(target_slot):
		return Vector2i.ZERO
	return Vector2i(0, view.max_health_at(source_slot))
