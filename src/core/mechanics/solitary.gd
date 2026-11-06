extends Mechanic
## Solitary (library entry 41): while this has no friendly neighbours (8.2.3), its Attack is
## doubled. Checked whenever the board changes, so it wakes when its neighbours die.


func aura(combat: Combat, unit: CombatUnit, _params: Dictionary) -> Vector2i:
	for slot: int in BoardGeometry.neighbours(unit.slot):
		if combat.unit_at(unit.side, slot) != null:
			return Vector2i.ZERO
	return Vector2i(unit.attack - unit.aura.x, 0)
