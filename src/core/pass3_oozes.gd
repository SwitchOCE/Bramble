class_name Pass3Oozes
extends RefCounted
## Recruit-side eating. The shop layer is live until purchase; meals then use own stats.

const DIGEST: PackedStringArray = ["little_dollop", "bubble_and_squeak", "frumenty"]


static func entries(unit: RecruitUnit) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for compiled: CompiledMechanic in MechanicRegistry.compiled(unit.def):
		if compiled.id == "pass3_ooze":
			out.append(compiled.params_for(unit.golden))
		elif compiled.id == "figgy_duff" and CoreUtil.to_bool(compiled.params.get("pass3", false)):
			out.append({"ability": "figgy_duff", "factor": unit.golden_factor()})
	for grant: Dictionary in unit.grants + unit.borrowed_text():
		var entry: Dictionary = grant["entry"]
		if str(entry.get("id", "")) == "pass3_ooze":
			out.append(
				MechanicRegistry.params_for(entry, CoreUtil.to_bool(grant.get("golden", false)))
			)
		elif (
			str(entry.get("id", "")) == "figgy_duff" and CoreUtil.to_bool(entry.get("pass3", false))
		):
			out.append(
				{
					"ability": "figgy_duff",
					"factor": 2 if CoreUtil.to_bool(grant.get("golden", false)) else 1
				}
			)
	return out


static func has(unit: RecruitUnit, ability: String) -> bool:
	return factor(unit, ability) > 0


static func factor(unit: RecruitUnit, ability: String) -> int:
	var best: int = 0
	for entry: Dictionary in entries(unit):
		if str(entry.get("ability", "")) == ability:
			best = maxi(best, CoreUtil.to_int(entry.get("factor", 1)))
	return best


static func is_digest(unit: RecruitUnit) -> bool:
	for ability: String in DIGEST:
		if has(unit, ability):
			return true
	return false


## Reading order breaks ties. A held unit is never an own-board target.
static func biggest(player: PlayerState, exclude: RecruitUnit = null) -> RecruitUnit:
	var targets: Array[RecruitUnit] = ranked(player, "Oozes", exclude)
	return targets[0] if not targets.is_empty() else null


static func ranked(
	player: PlayerState,
	tribe: String = "Oozes",
	exclude: RecruitUnit = null,
	slots: Array[int] = []
) -> Array[RecruitUnit]:
	var out: Array[RecruitUnit] = []
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit == null or unit == exclude or (tribe != "" and not unit.has_tribe(tribe)):
			continue
		if not slots.is_empty() and not slots.has(slot):
			continue
		out.append(unit)
	out.sort_custom(
		func(a: RecruitUnit, b: RecruitUnit) -> bool:
			if a.attack + a.health == b.attack + b.health:
				return player.board.find(a) < player.board.find(b)
			return a.attack + a.health > b.attack + b.health
	)
	return out


static func own_stats(unit: RecruitUnit) -> Vector2i:
	return Vector2i(
		clampi(unit.base_attack_now() + unit.perm_attack, 0, BoardUnit.STAT_CLAMP),
		clampi(unit.base_health_now() + unit.perm_health, 0, BoardUnit.STAT_CLAMP)
	)


static func soup_bonus(player: PlayerState) -> Vector2i:
	var reads: int = 0
	var sources: Array[int] = []
	for source: RecruitUnit in player.board:
		if source == null:
			continue
		for entry: Dictionary in entries(source):
			if str(entry.get("ability", "")) != "stone_soup":
				continue
			var count: int = 1
			if CoreUtil.to_int(entry.get("factor", 1)) > 1:
				count = CoreUtil.to_int(player.pass3_rates.get("oozes_golden_soup_reads", 2))
			reads = maxi(reads, count)
			sources.append(count)
	if reads <= 0:
		return Vector2i.ZERO
	if player.pass3_loop_guards:
		sources = [reads]
	var targets: Array[RecruitUnit] = ranked(player)
	var share: float = CoreUtil.to_float(player.pass3_rates.get("oozes_soup_share", 0.125))
	var total := Vector2i.ZERO
	for count: int in sources:
		var attack: int = 0
		var health: int = 0
		for target: RecruitUnit in targets.slice(0, count):
			attack += target.attack
			health += target.health
		# Sum in 64-bit scalars: six legal capped bodies exceed Vector2i's range.
		total.x = mini(BoardUnit.STAT_CLAMP, total.x + floori(attack * share))
		total.y = mini(BoardUnit.STAT_CLAMP, total.y + floori(health * share))
	return total


## Called after recruit auras settle and whenever the shop is filled/refreshed.
static func prepare(player: PlayerState) -> void:
	for unit: RecruitUnit in player.owned_units():
		for key: String in ["ooze_ladle", "ooze_nell_eaters", "ooze_digest_preview"]:
			if unit.has_meta(key):
				unit.remove_meta(key)
	var active: bool = false
	for unit: RecruitUnit in player.board:
		if unit != null and unit.has_mechanic_id("pass3_ooze"):
			active = true
	if not active:
		# A sold Soup's live bonus must disappear even when it was the last Ooze.
		for unit: RecruitUnit in player.shop:
			if unit.get_meta("ooze_soup_bonus", Vector2i.ZERO) != Vector2i.ZERO:
				unit.set_aura(0, 0)
				unit.set_meta("ooze_soup_bonus", Vector2i.ZERO)
		return
	var carry: RecruitUnit = biggest(player)
	var bonus: Vector2i = soup_bonus(player)
	for unit: RecruitUnit in player.board:
		if unit == null:
			continue
		unit.set_meta("ooze_ladle", unit == carry)
		unit.set_meta("ooze_digest_preview", digest_preview(player, unit))
		var eaters: Array[int] = []
		if has(unit, "dishwater_nell"):
			var count: int = CoreUtil.to_int(player.pass3_rates.get("oozes_nell_meals", 1))
			count *= factor(unit, "dishwater_nell")
			var targets: Array[RecruitUnit] = ranked(
				player, "Oozes", unit, BoardGeometry.neighbours(player.board.find(unit))
			)
			for target: RecruitUnit in targets.slice(0, count):
				eaters.append(player.board.find(target))
			unit.set_meta("ooze_nell_eaters", eaters)
	for unit: RecruitUnit in player.shop:
		var offer_bonus: Vector2i = Vector2i.ZERO if unit.has_mechanic_id("shy") else bonus
		unit.set_meta("ooze_soup_bonus", offer_bonus)
		unit.set_aura(offer_bonus.x, offer_bonus.y)


## Purchase/eating locks in exactly the currently displayed shop bonus, once.
static func commit_shop(unit: RecruitUnit) -> void:
	var bonus: Vector2i = unit.get_meta("ooze_soup_bonus", Vector2i.ZERO)
	if bonus == Vector2i.ZERO:
		return
	unit.set_meta("ooze_soup_bonus", Vector2i.ZERO)
	unit.set_aura(0, 0)
	if not unit.has_mechanic_id("shy"):
		unit.add_permanent(bonus.x, bonus.y)


## The shop is ready before this dependent sequence; frozen offers are not Nell's food.
static func start_turn(rules: RecruitRules, player: PlayerState, frozen: bool) -> void:
	for eater: RecruitUnit in player.board.duplicate():
		if eater == null or not is_digest(eater):
			continue
		while not eater.held.is_empty():
			var meal: RecruitUnit = eater.held.pop_back()
			eat(rules, player, eater, meal)
	for nell: RecruitUnit in player.board.duplicate():
		if nell == null or factor(nell, "dishwater_nell") <= 0 or frozen:
			continue
		var count: int = CoreUtil.to_int(player.pass3_rates.get("oozes_nell_meals", 1))
		count *= factor(nell, "dishwater_nell")
		var targets: Array[RecruitUnit] = ranked(
			player, "Oozes", nell, BoardGeometry.neighbours(player.board.find(nell))
		)
		for eater: RecruitUnit in targets.slice(0, count):
			var meal: RecruitUnit = lowest_unfrozen(player, frozen)
			if meal == null:
				break
			commit_shop(meal)
			player.shop.erase(meal)
			eat(rules, player, eater, meal)
	for source: RecruitUnit in player.board:
		if source == null or not has(source, "cut_and_come_again"):
			continue
		var carry: RecruitUnit = biggest(player)
		if carry == null:
			continue
		var share: float = CoreUtil.to_float(player.pass3_rates.get("oozes_slice_share", 0.2))
		var stats: Vector2i = _portion(Vector2i(carry.attack, carry.health), share)
		var count: int = CoreUtil.to_int(player.pass3_rates.get("oozes_slice_count", 1))
		for _index: int in count * factor(source, "cut_and_come_again"):
			if not rules.has_hand_space(player):
				break
			var slice: RecruitUnit = RecruitUnit.make(
				rules.library.get_unit("slice"), rules.new_iid()
			)
			slice.origin = RecruitUnit.ORIGIN_CREATED
			slice.add_permanent(
				stats.x - slice.base_attack_now(), maxi(1, stats.y) - slice.base_health_now()
			)
			player.hand.append(slice)
			player.log_event(
				"card", {"card": "slice", "attack": stats.x, "health": maxi(1, stats.y)}
			)


static func lowest_unfrozen(player: PlayerState, frozen: bool = false) -> RecruitUnit:
	if frozen:
		return null
	var best: RecruitUnit = null
	for offer: RecruitUnit in player.shop:
		if best == null or offer.tier() < best.tier():
			best = offer
	return best


## One meal event, shared by Digest and Nell. No sale, buy, or play event is fabricated.
static func eat(
	rules: RecruitRules, player: PlayerState, eater: RecruitUnit, meal: RecruitUnit
) -> void:
	var was_biggest: bool = biggest(player) == eater
	var stats: Vector2i = own_stats(meal)
	var receives_bonuses: bool = not meal.has_tribe("Oozes") or not player.pass3_loop_guards
	var multiplier: float = 1.0 + (aspic_bonus(player, eater) if receives_bonuses else 0.0)
	var gained: Vector2i = _portion(meal_stats(player, meal), multiplier)
	var before_attack: int = eater.perm_attack
	var before_health: int = eater.perm_health
	eater.add_permanent(gained.x, gained.y)
	var accepted: int = eater.perm_attack - before_attack + eater.perm_health - before_health
	if player.has_meta("ooze_probe"):
		eater.set_meta(
			"probe_eat_credit", CoreUtil.to_int(eater.get_meta("probe_eat_credit", 0)) + accepted
		)
	if has(eater, "frumenty"):
		eater.last_meals.append({"def": meal.def, "golden": meal.golden})
		var keep: int = CoreUtil.to_int(player.pass3_rates.get("oozes_frumenty_meals", 1))
		keep *= factor(eater, "frumenty")
		while eater.last_meals.size() > maxi(0, keep):
			eater.last_meals.pop_front()
	rules.pool.give_back(meal.pool_id(), meal.pool_copies)
	player.log_event(
		"eat",
		{
			"source": eater.def_id(),
			"source_iid": eater.iid,
			"meal_iid": meal.iid,
			"recycled_credit": CoreUtil.to_int(meal.get_meta("probe_eat_credit", 0)),
			"accepted": accepted,
			"target": meal.def_id(),
			"attack": gained.x,
			"health": gained.y,
			"meal_attack": stats.x,
			"meal_health": stats.y
		}
	)
	if was_biggest and receives_bonuses:
		_share(rules, player, eater, stats)
	rules.board_changed(player)
	rules.events.fire(player, "on_eat", {"subject": eater, "meal": meal})


## What a meal gives before Aspic: a non-Ooze's printed stats count the eat multiplier's times.
## Elder still reads the meal's own stats; Ooze meals pass whole.
static func meal_stats(player: PlayerState, meal: RecruitUnit) -> Vector2i:
	var stats: Vector2i = own_stats(meal)
	if meal.has_tribe("Oozes"):
		return stats
	var extra: int = eat_multiplier(player) - 1
	return Vector2i(
		stats.x + maxi(0, meal.base_attack_now()) * extra,
		stats.y + maxi(0, meal.base_health_now()) * extra
	)


static func eat_multiplier(player: PlayerState) -> int:
	return maxi(1, CoreUtil.to_int(player.pass3_rates.get("oozes_eat_printed_multiplier", 1)))


static func aspic_bonus(player: PlayerState, eater: RecruitUnit) -> float:
	var best: float = 0.0
	var slot: int = player.board.find(eater)
	for source_slot: int in BoardGeometry.SLOTS:
		var source: RecruitUnit = player.board[source_slot]
		if source == null or not BoardGeometry.in_front_of(source_slot).has(slot):
			continue
		for entry: Dictionary in entries(source):
			if str(entry.get("ability", "")) != "aunt_aspic":
				continue
			var bonus: float = CoreUtil.to_float(player.pass3_rates.get("oozes_aspic_bonus", 0.5))
			if CoreUtil.to_int(entry.get("factor", 1)) > 1:
				bonus = (
					CoreUtil.to_float(player.pass3_rates.get("oozes_golden_aspic_multiplier", 2.0))
					- 1.0
				)
			best = maxf(best, bonus) if player.pass3_loop_guards else best + bonus
	return best


static func digest_preview(player: PlayerState, eater: RecruitUnit) -> Vector2i:
	if not is_digest(eater):
		return Vector2i.ZERO
	var total := Vector2i.ZERO
	for meal: RecruitUnit in eater.held:
		var bonus: float = aspic_bonus(player, eater) if not meal.has_tribe("Oozes") else 0.0
		total += _portion(meal_stats(player, meal), 1.0 + bonus)
	return total


static func _share(
	rules: RecruitRules, player: PlayerState, eater: RecruitUnit, stats: Vector2i
) -> void:
	for elder: RecruitUnit in player.board:
		if elder == null:
			continue
		var count: int = factor(elder, "elder_ooze")
		if count <= 0:
			continue
		var share: float = CoreUtil.to_float(player.pass3_rates.get("oozes_elder_share", 0.5))
		if count > 1:
			share *= CoreUtil.to_float(player.pass3_rates.get("oozes_golden_elder_multiplier", 2.0))
		var bonus: Vector2i = _portion(stats, share)
		for target: RecruitUnit in player.board:
			if target == null or target == eater or not target.has_tribe("Oozes"):
				continue
			var old_attack: int = target.perm_attack
			var old_health: int = target.perm_health
			target.add_permanent(bonus.x, bonus.y)
			var accepted: int = target.perm_attack - old_attack + target.perm_health - old_health
			if player.has_meta("ooze_probe"):
				target.set_meta(
					"probe_eat_credit",
					CoreUtil.to_int(target.get_meta("probe_eat_credit", 0)) + accepted
				)
			target.counters["ooze_share_serial"] = (
				CoreUtil.to_int(target.counters.get("ooze_share_serial", 0)) + 1
			)
			player.log_event(
				"ooze_share",
				{
					"source": elder.def_id(),
					"accepted": accepted,
					"target": target.def_id(),
					"attack": bonus.x,
					"health": bonus.y
				}
			)
		rules.board_changed(player)


## SOT is dispatched once in its dependent sequence, rather than per printed/borrowed entry.
static func recruit_hook(_ctx: RecruitContext) -> void:
	pass


static func _portion(stats: Vector2i, fraction: float) -> Vector2i:
	# Apply the existing game maximum before converting back to a 32-bit vector.
	return Vector2i(
		mini(BoardUnit.STAT_CLAMP, floori(stats.x * fraction)),
		mini(BoardUnit.STAT_CLAMP, floori(stats.y * fraction))
	)


## Probe-only attribution metadata; it never enters combat rules or bot evaluation.
static func probe_merge(golden: RecruitUnit, copy: RecruitUnit) -> void:
	var credit: int = CoreUtil.to_int(copy.get_meta("probe_eat_credit", 0))
	if credit > 0:
		golden.set_meta(
			"probe_eat_credit", CoreUtil.to_int(golden.get_meta("probe_eat_credit", 0)) + credit
		)


static func probe_sale(unit: RecruitUnit) -> Dictionary:
	return {
		"unit": unit.def_id(),
		"eat_credit": CoreUtil.to_int(unit.get_meta("probe_eat_credit", 0)),
		"attack": unit.attack,
		"health": unit.health,
	}
