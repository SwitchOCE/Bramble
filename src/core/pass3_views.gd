class_name Pass3Views
extends RefCounted
## Predictable combat-start overlays use a copy of the view, never the recruit stat layers.


static func board(player: PlayerState, views: Array, config: GameConfig) -> void:
	var taken: Array[RecruitUnit] = []
	for slot: int in BoardGeometry.SLOTS:
		var fetch: RecruitUnit = player.board[slot]
		if fetch == null or not _fairy(fetch, "fetch"):
			continue
		var target: RecruitUnit = null
		for behind: int in BoardGeometry.behind(slot):
			var candidate: RecruitUnit = player.board[behind]
			if candidate == null or not candidate.has_tribe("Fairies"):
				continue
			if _fairy(candidate, "fetch") or taken.has(candidate):
				continue
			if (
				target == null
				or candidate.attack + candidate.health > target.attack + target.health
			):
				target = candidate
		if target == null:
			continue
		taken.append(target)
		var share: float = Pass3Rates.number(config, "fairies_fetch_share")
		var own: Vector2i = Vector2i.ZERO
		if not target.has_mechanic_id("shy"):
			var effects: Array = player.slot_effects[slot]
			own = BoardUpkeep.ring_stats(effects)
		var view: Dictionary = views[slot]
		view["recruit_attack"] = view["attack"]
		view["recruit_health"] = view["health"]
		view["attack"] = ceili(target.attack * share) + own.x
		view["health"] = maxi(1, ceili(target.health * share)) + own.y
		view["combat_start_overlay"] = true
		view["copied_name"] = target.def["name"]
		view["details"] = (
			"Starts as a copy of %s at %s%% stats, plus this slot's Ring."
			% [str(target.def["name"]), str(share * 100.0)]
		)


static func item(card: HandItem, player: PlayerState) -> Dictionary:
	var view: Dictionary = card.view()
	if player.pass3_fairies and card.ring_add() != Vector2i.ZERO:
		var count: int = card.ring_add().x
		view["text"] = "Ring a slot %d times." % count
		view["ring_count"] = count
		view["ring_size"] = player.ring_size
	return view


static func midsummer_left(player: PlayerState, config: GameConfig) -> int:
	for unit: RecruitUnit in player.board:
		if unit != null and _fairy(unit, "monarch"):
			var period: int = maxi(1, Pass3Rates.integer(config, "fairies_monarch_period"))
			return period - CoreUtil.to_int(player.owner_counters.get("pass3_midsummer", 0))
	return 0


static func _fairy(unit: RecruitUnit, name: String) -> bool:
	for entry: CompiledMechanic in MechanicRegistry.compiled(unit.def):
		if entry.id == "pass3_fairy" and str(entry.params.get("ability", "")) == name:
			return true
	return false
