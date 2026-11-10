class_name Pass3NeutralCombat
extends RefCounted
## Neutral holders use geometry; Whirligig changes position and loses Health, never damage.


static func has(unit: CombatUnit, name: String) -> bool:
	for index: int in unit.params.size():
		if (
			unit.mechanic_ids[index] == "pass3_neutral"
			and str(unit.params[index].get("ability", "")) == name
		):
			return true
	return false


static func start(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	match str(params.get("ability", "")):
		"shieldbug":
			var targets: Array[CombatUnit] = []
			for slot: int in BoardGeometry.behind(unit.slot):
				var target: CombatUnit = combat.unit_at(unit.side, slot)
				if target != null and not target.is_dead():
					targets.append(target)
			if not targets.is_empty():
				combat.trigger(unit, "shieldbug")
				for target: CombatUnit in targets:
					combat.set_status(target, "shield", true, unit)
		"whirligig_beetle":
			combat.trigger(unit, "whirligig_beetle")
			var moved: Array[CombatUnit] = CombatMoves.swap_rows(combat, 1 - unit.side, true)
			var golden: bool = CoreUtil.to_int(params.get("factor", 1)) > 1
			var share: float = CoreUtil.to_float(
				params.get(
					"golden_health_share" if golden else "health_share", 0.2 if golden else 0.1
				)
			)
			for target: CombatUnit in moved:
				var loss: int = mini(
					maxi(0, target.health - 1), maxi(0, floori(target.health * share))
				)
				if loss > 0:
					CombatMoves.lose_health(combat, target, loss, "Whirligig", unit.side, unit.uid)


## Recalculate the loan after deaths, relocation, summons, swallowing and text theft.
static func sync_swoop(combat: Combat) -> void:
	var chosen: Dictionary = {}
	for side: int in 2:
		for source: CombatUnit in combat.units_of(side):
			if source.is_dead() or not has(source, "ballooning_spider"):
				continue
			for slot: int in BoardGeometry.behind(source.slot):
				var target: CombatUnit = combat.unit_at(side, slot)
				if target != null and not target.is_dead():
					chosen[target.uid] = {"unit": target, "source": source}
	var previous: Dictionary = combat.notes.get("neutral_swoop_targets", {})
	for uid: int in previous:
		if not chosen.has(uid):
			var old: Dictionary = previous[uid]
			var target: CombatUnit = old["unit"]
			var source: CombatUnit = old["source"]
			combat.set_status(target, "lent_swoop", false, source)
	for side: int in 2:
		for target: CombatUnit in combat.units_of(side):
			if target.has_status("lent_swoop") and not chosen.has(target.uid):
				combat.set_status(target, "lent_swoop", false, null)
	for uid: int in chosen:
		var current: Dictionary = chosen[uid]
		var target: CombatUnit = current["unit"]
		var source: CombatUnit = current["source"]
		var status: Dictionary = target.statuses.get("lent_swoop", {})
		if not target.has_status("lent_swoop") or status.get("source_uid", 0) != source.uid:
			combat.set_status(target, "lent_swoop", true, source, {"source_uid": source.uid})
	if not chosen.is_empty():
		combat._status_text["lent_swoop"] = {
			"keyword": "Swoop", "text": str(EffectSchema.section("keywords")["Swoop"])
		}
	combat.notes["neutral_swoop_targets"] = chosen


## Own text, Mire and quarry keep their existing precedence over a newly lent ability.
static func lent_target(combat: Combat, attacker: CombatUnit) -> CombatUnit:
	if not attacker.has_status("lent_swoop"):
		return null
	var mechanic: Mechanic = MechanicRegistry.get_mechanic("swoop")
	return mechanic.attack_target(combat, attacker, {})
