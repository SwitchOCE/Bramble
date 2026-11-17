extends Mechanic
## An aura that reads a player number: this has +tide Attack, in both phases.


func has_aura() -> bool:
	return true


func aura(
	view: AuraContext, source_slot: int, target_slot: int, _params: MechanicParams
) -> Vector2i:
	return Vector2i(view.counter(&"test_tide"), 0) if source_slot == target_slot else Vector2i.ZERO
