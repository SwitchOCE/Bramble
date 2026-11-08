class_name TomTitAura
extends Mechanic
## Full Health, or full stats on golden. Redwing can already supply either axis; never add twice.


static func egg_aura(combat: Combat, egg: CombatUnit) -> Vector2i:
	var factor: int = 0
	for source: CombatUnit in combat.units_of(egg.side):
		for index: int in source.mechanic_ids.size():
			if source.mechanic_ids[index] != "tom_tit":
				continue
			var params: Dictionary = source.params[index]
			factor = maxi(factor, CoreUtil.to_int(params.get("full", 1)))
	if factor <= 0:
		return Vector2i.ZERO
	var nest: Dictionary = CombatHeld.nest_at(combat, egg.side, egg.slot)
	var full := Vector2i.ZERO
	if not nest.is_empty():
		var body: Dictionary = nest["spec"]
		full = Vector2i(CoreUtil.to_int(body["attack"]), CoreUtil.to_int(body["health"]))
	elif egg.counters.has("egg_full_attack"):
		full = Vector2i(
			CoreUtil.to_int(egg.counters["egg_full_attack"]),
			CoreUtil.to_int(egg.counters["egg_full_health"])
		)
	else:
		return Vector2i.ZERO
	var redwing: Vector2i = RedwingAura.egg_aura(combat, egg)
	var attack: int = maxi(0, full.x - ceili(full.x / 2.0) - redwing.x) if factor >= 2 else 0
	return Vector2i(attack, maxi(0, full.y - ceili(full.y / 2.0) - redwing.y))
