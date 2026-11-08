class_name RedwingAura
extends Mechanic
## Full Egg size replaces the half-sized body once; several Redwings use the strongest bonus.
## CombatAuras asks once per Egg, so copied or stolen Redwing texts cannot multiply its body.


static func egg_aura(combat: Combat, egg: CombatUnit) -> Vector2i:
	if egg.def_id() != HeldUnits.EGG:
		return Vector2i.ZERO
	var factor: int = 0
	for slot: int in BoardGeometry.adjacent(egg.slot):
		var source: CombatUnit = combat.unit_at(egg.side, slot)
		if source == null:
			continue
		for index: int in source.mechanic_ids.size():
			if source.mechanic_ids[index] == "redwing":
				factor = maxi(factor, CoreUtil.to_int(source.params[index].get("factor", 1)))
	if factor == 0:
		return Vector2i.ZERO
	var nest: Dictionary = CombatHeld.nest_at(combat, egg.side, egg.slot)
	var full := Vector2i.ZERO
	var plain := Vector2i(
		egg.base_attack_now() + egg.perm_attack, egg.base_health_now() + egg.perm_health
	)
	if nest.is_empty():
		if not egg.counters.has("egg_full_attack"):
			return Vector2i.ZERO
		full = Vector2i(
			CoreUtil.to_int(egg.counters["egg_full_attack"]),
			CoreUtil.to_int(egg.counters["egg_full_health"])
		)
	else:
		var body: Dictionary = nest["spec"]
		full = Vector2i(CoreUtil.to_int(body["attack"]), CoreUtil.to_int(body["health"]))
		plain = Vector2i(ceili(full.x / 2.0), ceili(full.y / 2.0))
	return full - plain + Vector2i.ONE * maxi(0, factor - 1) * 2
