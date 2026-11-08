class_name BotContent5
extends RefCounted
## Round-five choices use only the public scout and the player's own board.


static func horseshoe_value(player: PlayerState, slot: int) -> float:
	if not BoardGeometry.is_valid(slot) or player.scout.is_empty():
		return 0.0
	for effect: Dictionary in player.slot_effects[slot]:
		if str(effect.get("name", "")) == "Horseshoe":
			return 0.0
	var slots: Array = player.scout.get("slots", [])
	var across: int = BoardGeometry.across(slot)
	if across >= slots.size():
		return 0.0
	var effects: Array = slots[across]
	var ring := Vector2i.ZERO
	for effect: Dictionary in effects:
		if str(effect.get("name", "")) == BoardUpkeep.RING:
			ring += Vector2i(
				CoreUtil.to_int(effect.get("attack", 0)), CoreUtil.to_int(effect.get("health", 0))
			)
	# Keep fractional estimates so rounding ties never prefer a smaller Ring.
	return (ring.x + ring.y) / 2.0


static func spell_value(card: Dictionary, player: PlayerState, rules: RecruitRules = null) -> float:
	match str(card.get("id", "")):
		"horseshoe":
			var best: float = 0.0
			for slot: int in BoardGeometry.SLOTS:
				best = maxf(best, horseshoe_value(player, slot))
			return best
		"market_stall":
			return stall_value(player, rules)
	return -1.0


static func stall_value(player: PlayerState, rules: RecruitRules = null) -> float:
	if player.market_stalls >= 2 or player.health + player.armor <= BotBrain.LOW_HEALTH:
		return 0.0
	# Investment needs time to pay back; a capped ordinary shop buys no additional choice.
	if player.tier == UnitLibrary.TIERS and player.market_stalls >= 1:
		if str(player.hero.get("id", "")) != "pipkin":
			return 0.0
	if rules != null and str(player.hero.get("id", "")) != "pipkin":
		var base: int = rules.config.get_int_at("shop_units_by_tier", player.tier - 1)
		var ordinary: int = (
			rules.ask("shop_size", player, base) - MarketStalls.penalty(rules, player)
		)
		if ordinary + player.market_stalls >= MarketStalls.UNIT_CAP:
			return 0.0
	var turns: float = clampf((player.health + player.armor) / 6.0, 1.0, 5.0)
	return turns * 3.0


static func owl_value(unit: RecruitUnit, player: PlayerState) -> float:
	if player.scout.is_empty():
		return 6.0
	var count: int = 0
	var total: float = 0.0
	for slot: int in BoardGeometry.BACK:
		var enemy: Dictionary = BotLanes._enemy(player, slot)
		if enemy.is_empty():
			continue
		count += 1
		total += 4.0 + 0.5 * mini(12, CoreUtil.to_int(enemy.get("attack", 0)))
		total += 3.0 if unit.attack >= CoreUtil.to_int(enemy.get("health", 0)) else 0.0
	return 1.0 if count == 0 else total / count


static func egg_support_score(player: PlayerState, layout: Array[int]) -> float:
	var recruits: Array[RecruitUnit] = _recruits(player, layout)
	return _support_stats(player, recruits)


static func _support_stats(player: PlayerState, recruits: Array[RecruitUnit]) -> float:
	var total: float = 0.0
	for entry: Dictionary in player.away:
		var slot: int = CoreUtil.to_int(entry.get("nest", -1))
		if not BoardGeometry.is_valid(slot) or recruits[slot] != null:
			continue
		var bird: RecruitUnit = entry["unit"]
		var normal: Dictionary = HeldUnits.egg_spec(bird)
		var supported: Dictionary = HeldUnits.egg_forecast(player, bird, slot, recruits)
		total += CoreUtil.to_int(supported["attack"]) - CoreUtil.to_int(normal["attack"])
		total += CoreUtil.to_int(supported["health"]) - CoreUtil.to_int(normal["health"])
	return total


static func redwing_value(unit: RecruitUnit, player: PlayerState, purchase: bool) -> float:
	var recruits: Array[RecruitUnit] = player.board.duplicate()
	var before: float = _support_stats(player, recruits)
	var best: float = 0.0
	if purchase:
		# Value the best Nest pair it can tend after arranging, rather than its shop position.
		for slot: int in BoardGeometry.SLOTS:
			var previous: RecruitUnit = recruits[slot]
			recruits[slot] = unit
			best = maxf(best, _support_stats(player, recruits) - before)
			recruits[slot] = previous
	elif recruits.has(unit):
		recruits[recruits.find(unit)] = null
		best = before - _support_stats(player, recruits)
	return 2.0 + best


static func redwing_play_slot(player: PlayerState, unit: RecruitUnit) -> int:
	var recruits: Array[RecruitUnit] = player.board.duplicate()
	var before: float = _support_stats(player, recruits)
	var best: int = -1
	var most: float = -0.01
	for slot: int in BoardGeometry.SLOTS:
		if recruits[slot] != null:
			continue
		recruits[slot] = unit
		var gain: float = _support_stats(player, recruits) - before
		var nest: Dictionary = player.nest_at(slot)
		if nest.is_empty():
			var effects: Array = player.slot_effects[slot]
			var ring: Vector2i = BoardUpkeep.ring_stats(effects)
			gain += ring.x + ring.y
		else:
			var bird: RecruitUnit = nest["unit"]
			var egg: Dictionary = HeldUnits.egg_spec(bird)
			gain -= CoreUtil.to_int(egg["attack"]) + CoreUtil.to_int(egg["health"])
		recruits[slot] = null
		if gain > most:
			most = gain
			best = slot
	return best


static func owl_lane_score(
	player: PlayerState, value: BotEval, unit: RecruitUnit, slot: int
) -> float:
	if value.library == null:
		return 0.0
	# Mire still overrides Swoop. Avoid being bound to a dangerous front-row defender.
	for source: int in BoardGeometry.SLOTS:
		var enemy: Dictionary = BotLanes._enemy(player, source)
		var card: Dictionary = value.library.get_unit(str(enemy.get("def_id", "")))
		if card.is_empty():
			continue
		var foe := RecruitUnit.make(card, 0, CoreUtil.to_bool(enemy.get("golden", false)))
		var mire: bool = foe.has_mechanic_id("mire")
		for next: int in BoardGeometry.adjacent(source):
			var lender: Dictionary = BotLanes._enemy(player, next)
			var lender_card: Dictionary = value.library.get_unit(str(lender.get("def_id", "")))
			if lender_card.is_empty():
				continue
			var neighbour := RecruitUnit.make(lender_card, 0)
			mire = (
				mire or CoreUtil.to_bool(BotLanes._params(neighbour, "bog_aura").get("mire", false))
			)
		var targets: Array[int] = [source]
		if CoreUtil.to_bool(BotLanes._params(foe, "mire").get("spread", false)):
			targets.append_array(BoardGeometry.adjacent(source))
		if mire and targets.has(slot):
			var bitter: int = CoreUtil.to_int(BotLanes._params(foe, "bitter").get("n", 0))
			var score: float = -minf(8.0, bitter * 2.0)
			if BoardGeometry.is_front(source):
				score -= 12.0 + mini(24, CoreUtil.to_int(enemy.get("attack", 0)))
			return score + (2.0 if unit.attack >= CoreUtil.to_int(enemy.get("health", 0)) else 0.0)
	return 0.0


static func _recruits(player: PlayerState, layout: Array[int]) -> Array[RecruitUnit]:
	var out: Array[RecruitUnit] = []
	for source: int in layout:
		out.append(player.board[source] if source >= 0 else null)
	return out
