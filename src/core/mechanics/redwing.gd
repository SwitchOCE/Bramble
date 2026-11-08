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
	if nest.is_empty():
		# Scouts know only what the supported Egg visibly exposed, never the Bird's text or trip.
		var rules: Dictionary = combat.side_rules[egg.side]
		var public_eggs: Dictionary = rules.get("redwing_eggs", {})
		var public_body: Dictionary = public_eggs.get(egg.slot, {})
		if public_body.is_empty():
			return Vector2i.ZERO
		var public_bonus: int = maxi(0, factor - 1) * 2
		return Vector2i(
			(
				CoreUtil.to_int(public_body["attack"])
				- egg.base_attack_now()
				- egg.perm_attack
				+ public_bonus
			),
			(
				CoreUtil.to_int(public_body["health"])
				- egg.base_health_now()
				- egg.perm_health
				+ public_bonus
			)
		)
	var body: Dictionary = nest["spec"]
	var attack: int = CoreUtil.to_int(body["attack"])
	var health: int = CoreUtil.to_int(body["health"])
	var goose: bool = str(nest["def_id"]) == HeldUnits.GOOSE
	var half_attack: int = 0 if goose else ceili(attack / 2.0)
	var half_health: int = 2 if goose else ceili(health / 2.0)
	var bonus: int = maxi(0, factor - 1) * 2
	return Vector2i(attack - half_attack + bonus, health - half_health + bonus)
