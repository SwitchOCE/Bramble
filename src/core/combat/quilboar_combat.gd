class_name QuilboarCombat
extends RefCounted
## Test-only reference Rally/death rewards. Recruit owns applying their carry-back.


static func fire(combat: Combat, unit: CombatUnit, params: Dictionary, event: String) -> void:
	if not ReferenceQuilboar.allowed(combat.config):
		return
	var kind: String = str(params.get("kind", ""))
	var factor: int = CoreUtil.to_int(params.get("factor", unit.golden_factor()))
	var world := CombatWorld.make(combat, unit, unit.side, params, event)
	var rates: Dictionary = rules(combat, unit.side).get("quilboar_ref", {})
	var step: int = roundi(CoreUtil.to_float(rates.get("gem_size_step", 0.5)) * 2.0)
	if event == "on_attack" and kind == "sanguine_refiner":
		combat.trigger(unit, kind)
		world.gem_size_add(step * factor, step * factor)
	elif event == "on_death" and kind == "sanguine_champion":
		combat.trigger(unit, kind)
		world.gem_size_add(2 * step * factor, step * factor)
	elif event == "on_attack" and kind == "bramble_tunneler":
		_tunnel(combat, unit, rates, factor)


## Fights may reuse a captured rules dictionary: own it before changing future Gem size.
static func rules(combat: Combat, side: int) -> Dictionary:
	var key: String = "quilboar_rules_owned_%d" % side
	if not combat.notes.has(key):
		var current: Dictionary = combat.side_rules[side]
		var owned: Dictionary = current.duplicate(true)
		if not owned.has("quilboar_ref") and ReferenceQuilboar.allowed(combat.config):
			owned["quilboar_ref"] = ReferenceQuilboar.rates(combat.config)
		combat.side_rules[side] = owned
		combat.notes[key] = true
	return combat.side_rules[side]


static func _tunnel(combat: Combat, unit: CombatUnit, rates: Dictionary, count: int) -> void:
	var maximum: Variant = rates.get("tunneler_per_fight", 1)
	var used: int = CoreUtil.to_int(unit.limits.get("qb_tunneler", 0))
	if maximum != null and used >= CoreUtil.to_int(maximum):
		return
	unit.limits["qb_tunneler"] = used + 1
	combat.trigger(unit, "bramble_tunneler")
	var world := CombatWorld.make(combat, unit, unit.side, {}, "on_attack")
	world.add_random_card({"tag": "choose_one", "tier_at_most": "yours"}, count)
