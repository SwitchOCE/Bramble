extends Mechanic
## Belladonna Sprite (library entry 75): Start of Combat, give Nightshade to the `count` enemies
## with the highest Health, ties broken at random. Enemies that already have it are passed over
## (prototype pick), so two Sprites mark two units.


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	var candidates: Array[CombatUnit] = []
	for enemy: CombatUnit in combat.units_of(1 - unit.side):
		if not enemy.has_status("nightshade"):
			candidates.append(enemy)
	if candidates.is_empty():
		return
	var keys: Dictionary = {}
	for enemy: CombatUnit in candidates:
		keys[enemy.uid] = combat.rng.randi()
	candidates.sort_custom(
		func(a: CombatUnit, b: CombatUnit) -> bool:
			if a.health != b.health:
				return a.health > b.health
			return CoreUtil.to_int(keys[a.uid]) < CoreUtil.to_int(keys[b.uid])
	)
	combat.trigger(unit, "nightshade_mark")
	var count: int = mini(CoreUtil.to_int(params.get("count", 1)), candidates.size())
	for index: int in count:
		combat.set_status(candidates[index], "nightshade", true, unit)
