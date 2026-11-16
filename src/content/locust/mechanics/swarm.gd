extends Mechanic
## Standing, every player (tribe.json): the Tide and the Hopper bonus as an aura from the player.
## Tide +N: every Locust on the board has +N Attack. Hopper bonus +N: every Hopper has +N/+N.
## Both are borrowed (SHARED-RULES 43): auras, never the unit's own stats.

const Locust := preload("res://src/content/locust/lib/locust.gd")


func has_aura() -> bool:
	return true


func aura(
	view: AuraContext, source_slot: int, target_slot: int, _params: MechanicParams
) -> Vector2i:
	if source_slot != -1:
		return Vector2i.ZERO
	var def: UnitDef = view.def_at(target_slot)
	if def == null:
		return Vector2i.ZERO
	var gain := Vector2i.ZERO
	if def.has_tribe(Locust.TRIBE):
		gain.x += view.counter(Locust.TIDE)
	if def.id == Locust.HOPPER:
		var bonus: int = view.counter(Locust.HOPPER_BONUS)
		gain += Vector2i(bonus, bonus)
	return gain
