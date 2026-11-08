extends BotBrain
## Ranked gap #2, on promoted Hard: price real batches, held payoffs and feeding instead of
## multiplying a strategy's Larder prior by the number of coins needed. No new bank schedule.


func _pay(cost: int, gain: float) -> bool:
	if _player.gold >= cost:
		return super._pay(cost, gain)
	var burn: float = _burn_loss(cost)
	if burn > 0.0 and gain <= burn:
		return false
	var plan: Dictionary = cash_plan(cost - _player.gold)
	if plan.is_empty() or gain <= BotEval._number(plan["loss"]):
		return false
	var chosen: Array[HandItem] = plan["items"]
	return _cash_items(chosen, cost)


func _cash_items(chosen: Array[HandItem], target: int) -> bool:
	# Keep object identities: resolving a Discover can insert/recombine hand items.
	for item: HandItem in chosen:
		if _player.gold >= target:
			break
		var index: int = _player.items.find(item)
		if index < 0 or _rules.play_item(_player, index, -1) != "":
			return false
		_settle()
	return _player.gold >= target


func _hold_value(gold: int) -> float:
	if gold <= 0:
		return 0.0
	var plan: Dictionary = cash_plan(gold)
	return BotEval._number(plan["loss"]) if not plan.is_empty() else INF


func _cash_for_burn() -> void:
	if not _banks_gold():
		return
	var before: float = BotBurner.forecast(_player, _player.gold)
	var most: float = 0.0
	var best: Dictionary = {}
	for plan: Dictionary in _cash_options(1):
		var gain: float = (
			BotBurner.forecast(_player, _player.gold + CoreUtil.to_int(plan["cash"]))
			- before
			- BotEval._number(plan["loss"])
		)
		if gain > most:
			most = gain
			best = plan
	if not best.is_empty():
		var chosen: Array[HandItem] = best["items"]
		_cash_items(chosen, _player.gold + CoreUtil.to_int(best["cash"]))


## A hand holds at most ten cards. Enumerate real item subsets only when liquidating; this
## does not add work to every offer evaluation or simulate fights. Overpayment remains banked.
func cash_plan(needed: int) -> Dictionary:
	var best: Dictionary = {}
	var least: float = INF
	var smallest: int = 0
	for plan: Dictionary in _cash_options(needed):
		var loss: float = BotEval._number(plan["loss"])
		var cash: int = CoreUtil.to_int(plan["cash"])
		if loss < least or (is_equal_approx(loss, least) and cash < smallest):
			least = loss
			smallest = cash
			best = plan
	return best


func _cash_options(needed: int) -> Array[Dictionary]:
	var items: Array[HandItem] = _gold_items(_player.items)
	var before: float = retained_value(items)
	var options: Array[Dictionary] = []
	for mask: int in range(1, 1 << items.size()):
		var kept: Array[HandItem] = []
		var chosen: Array[HandItem] = []
		var cash: int = 0
		for index: int in items.size():
			if mask & (1 << index):
				chosen.append(items[index])
				cash += items[index].gold_value()
			else:
				kept.append(items[index])
		if cash >= needed:
			options.append(
				{"items": chosen, "loss": maxf(0.0, before - retained_value(kept)), "cash": cash}
			)
	return options


## Extra value above the items' cash face value. A feed and keeping that same item are
## alternatives, so use their maximum, not their sum. Re-plan after every legal action.
func retained_value(items: Array[HandItem]) -> float:
	var best: float = _engine_value(items)
	for index: int in items.size():
		var kept: Array[HandItem] = items.duplicate()
		kept.remove_at(index)
		var after: float = _engine_value(kept)
		for unit: RecruitUnit in _player.board:
			if unit != null and unit.eat_rate() > 0:
				best = maxf(
					best,
					(
						after
						+ feed_value(unit, items[index])
						- BotEval.GOLD_POINTS * items[index].gold_value()
					)
				)
	return best


func _engine_value(items: Array[HandItem]) -> float:
	var larder: int = 0
	var counts: Dictionary = {}
	for item: HandItem in items:
		larder += item.gold_value()
		counts[item.def_id()] = CoreUtil.to_int(counts.get(item.def_id(), 0)) + 1
	var total: float = 0.0
	var ammo: Array[HandItem] = items.duplicate()
	ammo.sort_custom(func(a: HandItem, b: HandItem) -> bool: return a.gold_value() < b.gold_value())
	var incoming: int = 0
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = _player.board[slot]
		if unit == null:
			continue
		var params: Dictionary = _params(unit, "larder_stats")
		if not params.is_empty():
			@warning_ignore("integer_division")
			var steps: int = larder / maxi(1, CoreUtil.to_int(params.get("gold_step", 2)))
			steps = mini(steps, CoreUtil.to_int(params.get("max_steps", steps)))
			total += 2 * steps * CoreUtil.to_int(params.get("per", 0))
		if unit.def_id() == "old_mother_mast" and counts.has("great_hoard"):
			# One next-turn buy, plus this turn's first buy if still unused. Never assume a
			# purchase without access to a shop; the longer horizon is deliberately bounded.
			var buys: int = 1 if _player.health > LOW_HEALTH else 0
			buys += 1 if CoreUtil.to_int(unit.limits.get("interest", 0)) == 0 else 0
			if not _player.shop.is_empty():
				total += buys * unit.golden_factor() * BotEval.GOLD_POINTS
		if unit.def_id() == "sleeping_partner" and unit.pays_again():
			var wait: int = 3 - unit.turns_in_slot % 3
			if wait == 1 or (wait == 2 and _player.health > LOW_HEALTH):
				incoming += 2 * unit.golden_factor()
		if unit.has_mechanic_id("sergeant") and not ammo.is_empty():
			var seen: Array = _player.scout.get("specs", [])
			var across: int = BoardGeometry.across(slot)
			if across < seen.size() and seen[across] != null:
				var target: Dictionary = seen[across]
				var gold: int = ammo[0].gold_value()
				ammo.remove_at(0)
				var damage: int = mini(
					CoreUtil.to_int(target.get("health", 0)),
					gold * unit.mechanic_number("sergeant", "damage")
				)
				total += maxf(0.0, damage - gold * BotEval.GOLD_POINTS)
	# A known Partner payout within two turns can finish a batch. Price only the incremental
	# conversion surplus, not its face value a second time. Exhausted/moved Partners pay nothing.
	var acorns: int = CoreUtil.to_int(counts.get("acorn", 0))
	if acorns > 0 and acorns + incoming >= 3:
		total += 2.0 * BotEval.GOLD_POINTS
	var stashes: int = CoreUtil.to_int(counts.get("stash", 0))
	if stashes == 2 and acorns + incoming >= 3:
		total += BotEval.GOLD_POINTS
	var room: int = _rules.config.get_int("hand_limit") - _player.hand.size()
	total -= (
		maxi(0, _player.items.size() - _gold_items(_player.items).size() + items.size() - room + 2)
		* BotEval.GOLD_POINTS
	)
	return total


func feed_value(unit: RecruitUnit, item: HandItem) -> float:
	if not unit.can_gain_permanent() or unit.has_mechanic_id("shy"):
		return 0.0
	var stats: int = unit.acorn_stats(item.gold_value())
	var cap: int = CoreUtil.to_int(unit.def.get("permanent_buff_cap", 0)) * unit.golden_factor()
	var attack: int = mini(stats, maxi(0, cap - unit.perm_attack)) if cap > 0 else stats
	var health: int = mini(stats, maxi(0, cap - unit.perm_health)) if cap > 0 else stats
	var reward: float = attack + health
	# Exact marginal gain of Dozey's forthcoming capped double; don't double its whole board
	# value or assume a second payout after the once-only effect fired.
	if (
		unit.def_id() == "alderman_dozey"
		and unit.turns_in_slot >= 2
		and not unit.counters.has("fired_wakes")
	):
		var most: int = 8 * unit.golden_factor()
		var after_attack: int = attack + mini(unit.attack + attack, most)
		var after_health: int = health + mini(unit.health + health, most)
		var before_attack: int = mini(unit.attack, most)
		var before_health: int = mini(unit.health, most)
		if cap > 0:
			after_attack = mini(after_attack, maxi(0, cap - unit.perm_attack))
			after_health = mini(after_health, maxi(0, cap - unit.perm_health))
			before_attack = mini(before_attack, maxi(0, cap - unit.perm_attack))
			before_health = mini(before_health, maxi(0, cap - unit.perm_health))
		reward = after_attack + after_health - before_attack - before_health
	return reward


func _feed_eaters() -> void:
	for _step: int in _player.items.size():
		var items: Array[HandItem] = _gold_items(_player.items)
		var before: float = _engine_value(items)
		var most: float = 0.0
		var best_item: HandItem
		var best_slot: int = -1
		for index: int in items.size():
			var kept: Array[HandItem] = items.duplicate()
			kept.remove_at(index)
			var loss: float = before - _engine_value(kept)
			for slot: int in BoardGeometry.SLOTS:
				var unit: RecruitUnit = _player.board[slot]
				if unit == null or unit.eat_rate() <= 0:
					continue
				var gain: float = (
					feed_value(unit, items[index])
					- BotEval.GOLD_POINTS * items[index].gold_value()
					- loss
				)
				if gain > most:
					most = gain
					best_item = items[index]
					best_slot = slot
		if best_slot < 0:
			return
		if _rules.play_item(_player, _player.items.find(best_item), best_slot) != "":
			return
		_settle()


static func _gold_items(items: Array[HandItem]) -> Array[HandItem]:
	var out: Array[HandItem] = []
	for item: HandItem in items:
		if item.gold_value() > 0:
			out.append(item)
	return out


static func _params(unit: RecruitUnit, id: String) -> Dictionary:
	for entry: Variant in MechanicRegistry.compiled(unit.def):
		var compiled: CompiledMechanic = entry
		if compiled.id == id:
			return compiled.params_for(unit.golden)
	return {}
