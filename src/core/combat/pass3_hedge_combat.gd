class_name Pass3HedgeCombat
extends RefCounted
## Hedgerow fight effects: live last-unit protection, summoned shares and paid aimed answers.


static func ability(unit: CombatUnit, name: String) -> Dictionary:
	var best: Dictionary = {}
	for index: int in unit.params.size():
		if unit.mechanic_ids[index] != "pass3_hedgerow":
			continue
		var entry: Dictionary = unit.params[index]
		if str(entry.get("ability", "")) == name:
			if factor(unit, entry) > CoreUtil.to_int(best.get("factor", 0)):
				best = entry.duplicate()
				best["factor"] = factor(unit, entry)
	return best


static func factor(unit: CombatUnit, params: Dictionary) -> int:
	return CoreUtil.to_int(params.get("factor", unit.golden_factor()))


## Dispatch receives the stored params instance. Equal-strength copies yield to the first one,
## so every later summon/replayed start can fire again without any lifetime or uid cooldown.
static func _chosen(combat: Combat, unit: CombatUnit, params: Dictionary) -> bool:
	if combat.config.get_value("pass3_loop_guards") == false:
		return true
	var best: Dictionary = {}
	var power: int = -1
	for index: int in unit.params.size():
		var candidate: Dictionary = unit.params[index]
		if (
			unit.mechanic_ids[index] == "pass3_hedgerow"
			and candidate.get("ability", "") == params.get("ability", "")
			and factor(unit, candidate) > power
		):
			best = candidate
			power = factor(unit, candidate)
	return is_same(best, params)


static func start(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	if str(params.get("ability", "")) != "sergeant_at_conkers" or not _chosen(combat, unit, params):
		return
	var throws: int = maxi(0, CoreUtil.to_int(params.get("throws", 1))) * factor(unit, params)
	for _throw: int in throws:
		var enemy: CombatUnit = combat.unit_at(1 - unit.side, BoardGeometry.across(unit.slot))
		if enemy == null or enemy.is_dead():
			return
		var gold: int = CombatMoves.take_ammo(combat, unit.side)
		if gold <= 0:
			return
		var share: float = maxf(0.0, CoreUtil.to_float(params.get("share_per_gold", 0.1))) * gold
		var attack: int = mini(enemy.attack, floori(enemy.attack * share))
		var health: int = mini(maxi(0, enemy.health - 1), floori(enemy.health * share))
		combat.trigger(unit, "pass3_hedgerow:sergeant_at_conkers")
		combat.buff(enemy, -attack, -health, unit, false, "Sergeant-at-Conkers")


static func on_ally_summon(
	combat: Combat, unit: CombatUnit, params: Dictionary, summoned: CombatUnit
) -> void:
	if (
		str(params.get("ability", "")) != "mrs_clover"
		or unit.is_dead()
		or not unit.on_board
		or summoned.side != unit.side
		or not summoned.has_tribe("Hedgerow folk")
		or not _chosen(combat, unit, params)
	):
		return
	# Read the source's displayed stats now, including combat buffs, auras and damage.
	var share: float = maxf(0.0, CoreUtil.to_float(params.get("share", 1.0))) * factor(unit, params)
	var attack: int = floori(unit.attack * share)
	var health: int = floori(unit.health * share)
	combat.trigger(unit, "pass3_hedgerow:mrs_clover")
	combat.buff(summoned, attack, health, unit, false, "Mrs Clover")


## The last OTHER Hedgerow bodies, in reverse Pass order. Gaps and off-tribe bodies do not count.
static func sync_hunker(combat: Combat) -> void:
	var protected: Dictionary = {}
	for side: int in 2:
		for source: CombatUnit in combat.units_of(side):
			var entry: Dictionary = ability(source, "dr_urchin")
			if entry.is_empty() or source.is_dead():
				continue
			var remaining: int = (
				maxi(0, CoreUtil.to_int(entry.get("hunker_targets", 1))) * factor(source, entry)
			)
			for index: int in range(BoardGeometry.ZIGZAG.size() - 1, -1, -1):
				if remaining <= 0:
					break
				var target: CombatUnit = combat.unit_at(side, BoardGeometry.ZIGZAG[index])
				if (
					target == null
					or target == source
					or target.is_dead()
					or not target.has_tribe("Hedgerow folk")
				):
					continue
				protected[target.uid] = {"unit": target, "source": source}
				remaining -= 1
	var previous: Dictionary = combat.notes.get("hedgerow_hunker_targets", {})
	for uid: int in previous:
		if not protected.has(uid):
			var old: Dictionary = previous[uid]
			var old_target: CombatUnit = old["unit"]
			var old_source: CombatUnit = old["source"]
			combat.set_status(old_target, "hunker", false, old_source)
	# Text theft can copy statuses. A borrowed aura stays with its eligible body, not its text.
	for side: int in 2:
		for target: CombatUnit in combat.units_of(side):
			if target.has_status("hunker") and not protected.has(target.uid):
				combat.set_status(target, "hunker", false, null)
	for uid: int in protected:
		var current: Dictionary = protected[uid]
		var target: CombatUnit = current["unit"]
		var source: CombatUnit = current["source"]
		var status: Dictionary = target.statuses.get("hunker", {})
		if not target.has_status("hunker") or status.get("source_uid", 0) != source.uid:
			combat.set_status(target, "hunker", true, source, {"source_uid": source.uid})
	if not protected.is_empty():
		combat._status_text["hunker"] = {
			"keyword": "Hunker", "text": str(EffectSchema.section("keywords")["Hunker"])
		}
	combat.notes["hedgerow_hunker_targets"] = protected


## Intrinsic and lent Hunker share one modifier, and only halve attack damage while defending.
static func reduce_hit(hit: Hit) -> void:
	if (
		hit.target.has_status("hunker")
		and hit.kind == Hit.ATTACK
		and hit.on_defender
		and not hit.modifiers.has("hunker")
	):
		hit.amount = ceili(hit.amount / 2.0)
		hit.modifiers.append("hunker")
