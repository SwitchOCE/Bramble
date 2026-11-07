extends Mechanic
## The Seven Whistlers: Start of Combat, count your different Birds, on the board or away. At seven,
## every enemy loses a quarter of its Attack and Health (golden: half); below seven only the enemy
## across does. Rounded down, so it never kills. One Whistlers fires per side.

const BIRDS: String = "Birds"
const SEVEN: int = 7


func on_start_of_combat(combat: Combat, unit: CombatUnit, _params: Dictionary) -> void:
	var key: String = "whistlers_%d" % unit.side
	if combat.notes.has(key):
		return
	combat.notes[key] = true
	combat.trigger(unit, "whistlers")
	var part: int = 2 if unit.golden else 4
	for enemy: CombatUnit in _victims(combat, unit):
		@warning_ignore("integer_division")
		combat.buff(enemy, -enemy.attack / part, -enemy.health / part, unit)


func _victims(combat: Combat, unit: CombatUnit) -> Array[CombatUnit]:
	if _different_birds(combat, unit.side) >= SEVEN:
		return combat.units_of(1 - unit.side)
	var out: Array[CombatUnit] = []
	var enemy: CombatUnit = combat.unit_at(1 - unit.side, BoardGeometry.across(unit.slot))
	if enemy != null:
		out.append(enemy)
	return out


static func _different_birds(combat: Combat, side: int) -> int:
	var ids: Dictionary = {}
	for ally: CombatUnit in combat.units_of(side):
		if ally.has_tribe(BIRDS):
			ids[ally.def_id()] = true
	var rules: Dictionary = combat.side_rules[side]
	var away: Array = rules.get("away_birds", [])
	for id: Variant in away:
		ids[str(id)] = true
	return ids.size()
