class_name Pass3BirdCombat
extends RefCounted
## Proportional Birds read permanent sky snapshots; their effects have no size caps.


static func has(unit: CombatUnit, name: String) -> bool:
	for index: int in unit.mechanic_ids.size():
		if (
			unit.mechanic_ids[index] == "pass3_bird"
			and str(unit.params[index].get("ability", "")) == name
		):
			return true
	return false


static func strength(unit: CombatUnit, name: String) -> int:
	var power: int = 0
	for index: int in unit.mechanic_ids.size():
		if (
			unit.mechanic_ids[index] == "pass3_bird"
			and str(unit.params[index].get("ability", "")) == name
		):
			power = maxi(
				power, CoreUtil.to_int(unit.params[index].get("factor", unit.golden_factor()))
			)
	return power


static func start(combat: Combat, unit: CombatUnit, name: String, power: int = 1) -> void:
	match name:
		"jack_daw":
			_steal_stats(combat, unit, power)
		"tom_tit":
			_choose_protected(combat, unit, power)
		"whistlers":
			_whistlers(combat, unit, power)


static func steal_text(combat: Combat, source: CombatUnit, power: int = 1) -> void:
	var birds: Array[CombatUnit] = Pass3Combat.biggest(
		Pass3Combat.tribe(combat, source.side, "Birds")
	)
	if birds.is_empty():
		return
	var across: int = BoardGeometry.across(source.slot)
	var slots: Array[int] = [across]
	if power > 1:
		for neighbour: int in BoardGeometry.neighbours(across):
			if combat.unit_at(1 - source.side, neighbour) != null:
				slots.append(neighbour)
				break
	for slot: int in slots:
		var enemy: CombatUnit = combat.unit_at(1 - source.side, slot)
		if enemy == null:
			continue
		var text: bool = false
		for id: String in enemy.mechanic_ids:
			text = text or id != HeldUnits.BELLY
		if text:
			combat.trigger(source, "mag_pye")
			CombatHeld.steal_text(combat, birds[0], enemy)


static func _steal_stats(combat: Combat, source: CombatUnit, power: int = 1) -> void:
	var enemy: CombatUnit = combat.unit_at(1 - source.side, BoardGeometry.across(source.slot))
	var birds: Array[CombatUnit] = Pass3Combat.biggest(
		Pass3Combat.tribe(combat, source.side, "Birds")
	)
	if enemy == null or birds.is_empty():
		return
	var share: float = Pass3Rates.number(combat.config, "birds_jack_daw_share") * power
	var attack: int = mini(enemy.attack, ceili(enemy.attack * share))
	var health: int = mini(maxi(0, enemy.health - 1), ceili(enemy.health * share))
	combat.trigger(source, "jack_daw")
	combat.buff(enemy, -attack, -health, source)
	combat.buff(
		birds[0],
		attack,
		health,
		source,
		Pass3Rates.enabled(combat.config, "birds_jack_daw_permanent"),
		"jack_daw"
	)


static func lump(combat: Combat, unit: CombatUnit, power: int = 1) -> Vector2i:
	var nest: Dictionary = CombatHeld.nest_at(combat, unit.side, unit.slot)
	if nest.is_empty():
		return Vector2i.ZERO
	var factor: float = Pass3Rates.number(combat.config, "birds_lump_multiplier") * power
	return Vector2i(
		ceili(CoreUtil.to_int(nest["attack"]) * factor),
		ceili(CoreUtil.to_int(nest["health"]) * factor)
	)


static func egg_bonus(combat: Combat, egg: CombatUnit) -> Vector2i:
	var count: int = 0
	for unit: CombatUnit in combat.units_of(egg.side):
		if has(unit, "redwing"):
			count = maxi(
				count,
				(
					Pass3Rates.integer(combat.config, "birds_redwing_targets")
					* strength(unit, "redwing")
				)
			)
	if count <= 0:
		return Vector2i.ZERO
	var rules: Dictionary = combat.side_rules[egg.side]
	var original_nests: Array = rules.get("away_specs", rules.get("nests", []))
	var nests: Array = original_nests.duplicate()
	for index: int in range(1, nests.size()):
		var item: Dictionary = nests[index]
		var at: int = index
		while at > 0:
			var previous: Dictionary = nests[at - 1]
			if _nest_size(item) <= _nest_size(previous):
				break
			nests[at] = nests[at - 1]
			at -= 1
		nests[at] = item
	for index: int in mini(count, nests.size()):
		var nest: Dictionary = nests[index]
		if CoreUtil.to_int(nest["slot"]) != egg.slot:
			continue
		var share: float = Pass3Rates.number(combat.config, "birds_redwing_share")
		return Vector2i(
			(
				ceili(CoreUtil.to_int(nest["attack"]) * share)
				- egg.base_attack_now()
				- egg.perm_attack
			),
			ceili(CoreUtil.to_int(nest["health"]) * share) - egg.base_health_now() - egg.perm_health
		)
	return Vector2i.ZERO


static func _nest_size(nest: Dictionary) -> int:
	return CoreUtil.to_int(nest["attack"]) + CoreUtil.to_int(nest["health"])


static func _choose_protected(combat: Combat, source: CombatUnit, power: int = 1) -> void:
	var count: int = Pass3Rates.integer(combat.config, "birds_tom_tit_targets") * power
	var targets: Array[CombatUnit] = Pass3Combat.biggest(
		Pass3Combat.tribe(combat, source.side, "Birds", source), count
	)
	var ids: Array = []
	for target: CombatUnit in targets:
		ids.append(target.uid)
	combat.notes["tom_tit_%d" % source.uid] = ids
	sync_protection(combat)


static func sync_protection(combat: Combat) -> void:
	for side: int in 2:
		var protected: Dictionary = {}
		for source: CombatUnit in combat.units_of(side):
			if not has(source, "tom_tit") or source.is_dead():
				continue
			for uid: int in combat.notes.get("tom_tit_%d" % source.uid, []):
				protected[uid] = true
		for target: CombatUnit in combat.units_of(side):
			var active: bool = protected.has(target.uid)
			var percent: int = CoreUtil.to_int(target.counters.get("ooze_reduction", 0))
			if active:
				percent = maxi(
					percent, Pass3Rates.integer(combat.config, "birds_tom_tit_reduction")
				)
			var current: Dictionary = target.statuses.get("damage_reduction", {})
			if percent > 0 and CoreUtil.to_int(current.get("percent", 0)) != percent:
				combat.set_status(target, "damage_reduction", true, null, {"percent": percent})
			elif percent <= 0 and target.has_status("damage_reduction"):
				combat.set_status(target, "damage_reduction", false, null)


static func reduce_hit(combat: Combat, hit: Hit) -> void:
	if not hit.target.has_status("damage_reduction") or hit.modifiers.has("damage_reduction"):
		return
	var data: Dictionary = hit.target.statuses["damage_reduction"]
	var percent: int = CoreUtil.to_int(
		data.get("percent", Pass3Rates.integer(combat.config, "birds_tom_tit_reduction"))
	)
	hit.amount -= StatFraction.part(hit.amount, percent)
	hit.modifiers.append("damage_reduction")


static func drop_in(combat: Combat, source: CombatUnit, dead: CombatUnit, power: int = 1) -> void:
	var nest: Dictionary = CombatHeld.nest_at(combat, source.side, dead.slot)
	if nest.is_empty():
		return
	var key: String = "landed_%d_%d" % [source.side, dead.slot]
	if combat.config.get_bool("pass3_loop_guards") and combat.notes.has(key):
		return
	combat.notes[key] = true
	if combat.unit_at(source.side, dead.slot) != null:
		return
	var factor: float = Pass3Rates.number(combat.config, "birds_ratchet_multiplier") * power
	var original: Dictionary = nest["spec"]
	var spec: Dictionary = original.duplicate(true)
	spec["attack"] = ceili(CoreUtil.to_int(spec["attack"]) * factor)
	spec["health"] = ceili(CoreUtil.to_int(spec["health"]) * factor)
	combat.trigger(source, "gabble_ratchet")
	combat.enter_from_spec(spec, source.side, dead.slot, source, {"landed": true})


static func _whistlers(combat: Combat, source: CombatUnit, power: int = 1) -> void:
	var names: Dictionary = {}
	for bird: CombatUnit in Pass3Combat.tribe(combat, source.side, "Birds"):
		names[bird.def_id()] = true
	var targets: Array[CombatUnit] = []
	if names.size() >= Pass3Rates.integer(combat.config, "birds_whistlers_flock_count"):
		targets = combat.units_of(1 - source.side)
	else:
		var across: CombatUnit = combat.unit_at(1 - source.side, BoardGeometry.across(source.slot))
		if across != null:
			targets.append(across)
	if targets.is_empty():
		return
	combat.trigger(source, "whistlers")
	var share: float = Pass3Rates.number(combat.config, "birds_whistlers_loss_share")
	for target: CombatUnit in targets:
		for _time: int in power:
			# Integer minus floor(loss) is ceil(the remainder), without complement-rounding
			# error such as 9 * (1 - 1/3) becoming 6.000000000000001.
			var attack: int = mini(target.attack, maxi(0, floori(target.attack * share)))
			var health: int = mini(
				maxi(0, target.health - 1), maxi(0, floori(target.health * share))
			)
			combat.buff(target, -attack, -health, source)
