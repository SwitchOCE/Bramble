class_name BotPass3
extends RefCounted
## Small policy adapters for the two new engines; ordinary buying and action execution stay shared.

const FLIERS: Array[String] = ["one_swallow", "chiffchaff", "mrs_jay", "old_tern", "mother_goose"]
const FAIRY_ENGINES: Array[String] = [
	"old_moth_annis",
	"fairy_monarch",
	"cradle_fetch",
	"reel_mistress",
	"queen_of_elfland",
	"lob_lie_by_the_fire",
	"hob_in_the_hearth",
	"cluricaun"
]


static func active(player: PlayerState) -> bool:
	return player.pass3_content


static func fairy_build(value: BotEval) -> bool:
	var tribes: Dictionary = value.strategy.get("tribes", {})
	return CoreUtil.to_int(tribes.get("Fairies", 0)) > 0


static func best_flight(player: PlayerState, value: BotEval, round_number: int) -> int:
	var policy: Dictionary = value.strategy.get("line_fly_policy", {})
	var from_round: int = CoreUtil.to_int(policy.get("from_round", 3))
	var keep_home: int = CoreUtil.to_int(policy.get("keep_home_min", 3))
	if round_number < from_round or player.board_count() <= keep_home or _omen(player):
		return -1
	if policy.has("max_away") and player.away.size() >= CoreUtil.to_int(policy["max_away"]):
		return -1
	var largest: RecruitUnit = _biggest_bird(player)
	var danger: bool = player.health <= maxi(8, 2 * round_number)
	var best: int = -1
	var most: float = 0.0
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit == null or not HeldUnits.flies(unit, player):
			continue
		var allowed: Array = policy.get("allowed", [])
		if not allowed.is_empty() and not allowed.has(unit.def_id()):
			continue
		if unit.def_id() == "old_tern" and player.away.size() < 2:
			continue
		if unit == largest and danger:
			continue
		var score: float = trip_score(unit, player, value)
		if score > most:
			most = score
			best = slot
	return best


static func trip_score(unit: RecruitUnit, player: PlayerState, value: BotEval) -> float:
	var multiplier: float = _rate(value, "birds_homecoming_multiplier", 2.0)
	if unit.golden:
		multiplier = _rate(value, "birds_golden_homecoming_multiplier", 2.0)
	var body: int = (
		unit.base_attack_now() + unit.perm_attack + unit.base_health_now() + unit.perm_health
	)
	var score: float = value.fly_value(unit) + body * (multiplier - 1.0)
	var cost: float = maxf(0.0, unit.attack + unit.health - 1)
	for source: RecruitUnit in player.board:
		if source == null:
			continue
		if source.def_id() == "mr_redbreast":
			score += body * multiplier * _rate(value, "birds_redbreast_share", 0.125)
		elif source.def_id() == "cuckoo":
			score += body * multiplier * _rate(value, "birds_cuckoo_share", 0.1) * 3.0
		elif source.def_id() == "great_lump" or source.def_id() == "gabble_ratchet":
			cost *= 0.5
	# Eggs alone don't pay for the missed fight; the future doubling and homecoming text do.
	return score - cost * 0.7


static func _rate(value: BotEval, key: String, fallback: float) -> float:
	if value.recruit_rules == null:
		return fallback
	return Pass3Rates.number(value.recruit_rules.config, key)


static func _biggest_bird(player: PlayerState) -> RecruitUnit:
	var biggest: RecruitUnit = null
	for unit: RecruitUnit in player.board:
		if unit != null and unit.has_tribe("Birds"):
			if biggest == null or unit.attack + unit.health > biggest.attack + biggest.health:
				biggest = unit
	return biggest


static func _omen(player: PlayerState) -> bool:
	var names: Dictionary = {}
	for unit: RecruitUnit in player.board:
		if unit != null and unit.has_tribe("Birds"):
			names[unit.def_id()] = true
	return names.size() == 7 and names.has("seven_whistlers")


static func ring_count(player: PlayerState) -> int:
	var count: int = 0
	for slot: int in BoardGeometry.SLOTS:
		var effects: Array = player.slot_effects[slot]
		if BoardUpkeep.has_ring(effects):
			count += 1
	return count


static func ring_total(player: PlayerState) -> int:
	var total: int = 0
	for effects: Array in player.slot_effects:
		for effect: Dictionary in effects:
			if str(effect.get("name", "")) == BoardUpkeep.RING:
				total += CoreUtil.to_int(effect.get("count", 1))
	return total


static func ring_aim(player: PlayerState, slot: int) -> float:
	# Finish the rainbow for End of Turn growth; then feed the largest Ring.
	var effects: Array = player.slot_effects[slot]
	if ring_count(player) < 7 and not BoardUpkeep.has_ring(effects):
		return 100000.0 - slot
	var size: Vector2i = BoardUpkeep.ring_value(effects)
	return size.x + size.y + (1.0 if slot == 4 else 0.0)


static func egg_aim(player: PlayerState, slot: int) -> float:
	var unit: RecruitUnit = player.board[slot]
	if unit == null:
		return -1.0
	return unit.base_attack_now() + unit.perm_attack + unit.base_health_now() + unit.perm_health


static func arrange(
	player: PlayerState, value: BotEval, layout: Array[int], pinned: Array[int]
) -> void:
	if not active(player) or not value.level.reads_text:
		return
	_aim_birds(player, value, layout, pinned)
	var lump: int = _find(player, layout, "great_lump")
	if lump >= 0:
		var target: int = _largest_nest(player, pinned)
		if target >= 0:
			_swap(layout, lump, target)
	if not fairy_build(value):
		return
	var court: bool = (
		str(value.strategy.get("id", "")) in ["fairies_rainbow", "fairies_help"]
		or CoreUtil.to_bool(value.strategy.get("line_court", false))
	)
	var annis: int = _find(player, layout, "old_moth_annis")
	var annis_slot: int = 1 if court else 0
	if annis >= 0 and not pinned.has(annis) and not pinned.has(annis_slot):
		_swap(layout, annis, annis_slot)
	var carry: int = _carry_slot(player)
	var stander: int = _stander(player, value, layout, pinned, carry)
	if stander >= 0 and not pinned.has(carry):
		_swap(layout, stander, carry)
	var fetch: int = _find(player, layout, "cradle_fetch")
	var fetch_slot: int = 0 if carry == 4 else (3 if carry == 6 else 1)
	if fetch >= 0 and not pinned.has(fetch) and not pinned.has(fetch_slot):
		if fetch_slot != annis_slot:
			_swap(layout, fetch, fetch_slot)
		elif carry == 4 and not pinned.has(1):
			_swap(layout, fetch, 1)
	_tithe(player, value, layout, pinned)


static func _largest_nest(player: PlayerState, pinned: Array[int]) -> int:
	var best: int = -1
	var most: int = -1
	for entry: Dictionary in player.away:
		var slot: int = CoreUtil.to_int(entry.get("nest", -1))
		var bird: RecruitUnit = entry["unit"]
		if slot >= 0 and not pinned.has(slot) and bird.attack + bird.health > most:
			most = bird.attack + bird.health
			best = slot
	return best


static func _carry_slot(player: PlayerState) -> int:
	var best: int = 4
	var most: int = -1
	for slot: int in BoardGeometry.BACK:
		var effects: Array = player.slot_effects[slot]
		var amount: Vector2i = BoardUpkeep.ring_value(effects)
		if amount.x + amount.y > most:
			most = amount.x + amount.y
			best = slot
	return best


static func _stander(
	player: PlayerState, value: BotEval, layout: Array[int], pinned: Array[int], target: int
) -> int:
	var best: int = -1
	var most: float = -1.0
	for slot: int in BoardGeometry.SLOTS:
		if layout[slot] < 0 or (pinned.has(slot) and slot != target):
			continue
		var unit: RecruitUnit = player.board[layout[slot]]
		if not unit.has_tribe("Fairies") or unit.has_mechanic_id("shy"):
			continue
		if unit.def_id() in FAIRY_ENGINES:
			continue
		var score: float = value.keep_value(unit)
		if unit.def_id() in ["belladonna", "hedge_witch", "changeling"]:
			score += 20.0
		if score > most:
			most = score
			best = slot
	return best


static func _tithe(
	player: PlayerState, value: BotEval, layout: Array[int], pinned: Array[int]
) -> void:
	var queen: int = _find(player, layout, "queen_of_elfland")
	if queen < 0 or pinned.has(queen) or pinned.has(3):
		return
	var source: RecruitUnit = player.board[layout[queen]]
	var period: int = maxi(1, int(_rate(value, "fairies_queen_period", 1.0)))
	var count: int = CoreUtil.to_int(source.counters.get("pass3_teind", 0))
	# This fight still uses the food. Only the next Start of Turn needs it behind the Queen.
	if count + 1 < period:
		return
	_swap(layout, queen, 3)
	var cheapest: int = -1
	var lowest: float = INF
	for slot: int in BoardGeometry.SLOTS:
		if layout[slot] < 0 or pinned.has(slot) or slot == 3 or slot == _carry_slot(player):
			continue
		var unit: RecruitUnit = player.board[layout[slot]]
		if unit.def_id() in FAIRY_ENGINES:
			continue
		var worth: float = value.keep_value(unit)
		if worth < lowest:
			lowest = worth
			cheapest = slot
	if cheapest >= 0 and not pinned.has(6):
		_swap(layout, cheapest, 6)


static func _find(player: PlayerState, layout: Array[int], id: String) -> int:
	for slot: int in BoardGeometry.SLOTS:
		if layout[slot] >= 0 and player.board[layout[slot]].def_id() == id:
			return slot
	return -1


static func _swap(layout: Array[int], a: int, b: int) -> void:
	var keep: int = layout[a]
	layout[a] = layout[b]
	layout[b] = keep


## Scale only engine text whose value is visible on the current board. -1 keeps the normal hint.
static func text_value(unit: RecruitUnit, player: PlayerState, value: BotEval) -> float:
	var ooze_value: float = BotOoze.text_value(unit, player, value)
	if ooze_value >= 0.0:
		return ooze_value
	var hunter_value: float = BotHunt.text_value(unit, player, value)
	if hunter_value >= 0.0:
		return hunter_value
	var bog_value: float = BotBog.text_value(unit, player, value)
	if bog_value >= 0.0:
		return bog_value
	if not active(player):
		return -1.0
	var factor: int = unit.golden_factor()
	match unit.def_id():
		"cluricaun":
			# Fairy routes plan rainbow completion; a splash must already meet the trigger.
			if not fairy_build(value) and ring_count(player) < BoardGeometry.SLOTS:
				return 0.0
			var rings: int = maxi(ring_total(player), 7 if fairy_build(value) else 0)
			return factor * rings * 2.0 * _rate(value, "fairies_ring_growth", 1.0)
		"lob_lie_by_the_fire":
			var turns: int = CoreUtil.to_int(unit.counters.get("pass3_turns_stayed", 0))
			var periods: float = floorf(turns / maxf(1.0, _rate(value, "fairies_lob_turns", 3.0)))
			var rings: int = maxi(ring_total(player), 3 if fairy_build(value) else 0)
			return factor * rings * 2.0 * _rate(value, "fairies_lob_growth", 1.0) * (periods + 1)
		"old_moth_annis":
			return factor * player.ring_size * 6.0 * _rate(value, "fairies_annis_rings", 1.0)
		"fairy_monarch":
			return factor * ring_total(player) * player.ring_size
		"silky":
			return factor * ring_total(player) * 2.0 * _rate(value, "fairies_silky_growth", 1.0)
		"cradle_fetch":
			var most: float = 0.0
			for other: RecruitUnit in player.board:
				if other != null and other != unit and other.has_tribe("Fairies"):
					if not other.has_mechanic_id("shy") and other.def_id() != "cradle_fetch":
						most = maxf(most, other.attack + other.health)
			return most * _rate(value, "fairies_fetch_share", 0.5)
		"great_lump":
			if player.board.has(unit):
				return -1.0
			var biggest: int = 0
			for entry: Dictionary in player.away:
				if CoreUtil.to_int(entry.get("nest", -1)) >= 0:
					var bird: RecruitUnit = entry["unit"]
					biggest = maxi(biggest, bird.attack + bird.health)
			return 8.0 + biggest * factor
		"hob_in_the_hearth", "tom_tit":
			var most: float = 0.0
			var tribe: String = "Fairies" if unit.def_id() == "hob_in_the_hearth" else "Birds"
			for other: RecruitUnit in player.board:
				if other != null and other != unit and other.has_tribe(tribe):
					most = maxf(most, other.health)
			return maxf(4.0, most * 0.5) * factor
	return -1.0


## Preserve one copy of a live investment; extra copies may still make room for an upgrade.
static func keep_engine(player: PlayerState, unit: RecruitUnit, value: BotEval) -> bool:
	if value.level.reads_text and BotOoze.keep_engine(player, unit, value):
		return true
	if value.level.reads_text and BotHunt.keep_engine(player, unit):
		return true
	if value.level.reads_text and BotBog.keep_engine(player, unit, value):
		return true
	if not active(player) or not fairy_build(value):
		return false
	if unit.def_id() not in ["lob_lie_by_the_fire", "hob_in_the_hearth", "cluricaun"]:
		return false
	for other: RecruitUnit in player.board:
		if other != null and other != unit and other.def_id() == unit.def_id():
			if other.golden_factor() >= unit.golden_factor() and other.iid < unit.iid:
				return false
	return true


## Complete affordable missing Rings before a climb spends the gold needed for End of Turn growth.
static func prepare_rainbow(brain: BotBrain) -> void:
	var player: PlayerState = brain._player
	if not active(player) or not fairy_build(brain.value) or not brain.level.reads_text:
		return
	var cluricaun: bool = false
	for unit: RecruitUnit in player.board:
		cluricaun = cluricaun or (unit != null and unit.def_id() == "cluricaun")
	if not cluricaun:
		return
	for _step: int in BoardGeometry.SLOTS:
		if ring_count(player) == BoardGeometry.SLOTS:
			return
		var bought: bool = false
		for index: int in player.shop_spells.size():
			var item: HandItem = player.shop_spells[index]
			if item.ring_add() == Vector2i.ZERO or not brain._can_aim(item.aim()):
				continue
			if brain._rules.spell_cost(player, item) > player.gold:
				continue
			if brain._rules.buy_spell(player, index) == "":
				brain._cast_spells(false)
				bought = true
				break
		if not bought:
			return


## Cash-out value excludes route preference and Lob's bank: the bank is paid by this departure.
static func thank_value(unit: RecruitUnit, player: PlayerState, config: GameConfig) -> float:
	var lost: float = unit.attack + unit.health
	if unit.def_id() == "hob_in_the_hearth":
		var biggest: int = 0
		for other: RecruitUnit in player.board:
			if other != null and other != unit and other.has_tribe("Fairies"):
				biggest = maxi(biggest, other.health)
		lost += biggest * 0.5 * unit.golden_factor()
	return BotContent5.shy_departure_value(unit, player, lost, config)


## Buying an aimed spell can unlock a bank. A missing Ring can also unlock End of Turn growth.
static func spell_bonus(card: Dictionary, player: PlayerState, value: BotEval) -> float:
	if not active(player) or not fairy_build(value) or value.recruit_rules == null:
		return 0.0
	var item: HandItem = HandItem.make(card, 0)
	if not item.is_spell() or item.aim() in [HandItem.AIM_NONE, HandItem.AIM_SHOP_UNIT]:
		return 0.0
	var bonus: float = 0.0
	for slot: int in BoardGeometry.SLOTS:
		if value.recruit_rules.item_aim_problem(player, item, slot) != "":
			continue
		var unit: RecruitUnit = player.board[slot]
		if unit != null and unit.has_mechanic_id("shy"):
			if thank_ready(player, slot, value.recruit_rules.config):
				bonus = maxf(bonus, thank_value(unit, player, value.recruit_rules.config))
	if item.ring_add() != Vector2i.ZERO and ring_count(player) < BoardGeometry.SLOTS:
		for unit: RecruitUnit in player.board:
			if unit != null and unit.def_id() == "cluricaun":
				bonus += (
					2.0
					* ring_total(player)
					* unit.golden_factor()
					* _rate(value, "fairies_ring_growth", 1.0)
					/ maxi(1, BoardGeometry.SLOTS - ring_count(player))
				)
	return bonus


static func thank_aim(
	player: PlayerState, item: HandItem, legal: Array[int], config: GameConfig
) -> int:
	if not active(player) or not item.is_spell():
		return -1
	# An incomplete rainbow gets the Ring spell first; thank a Shy on that slot if possible.
	var ring_missing: bool = item.ring_add() != Vector2i.ZERO and ring_count(player) < 7
	var best: int = -1
	var most: float = 0.0
	for slot: int in legal:
		var unit: RecruitUnit = player.board[slot]
		if unit == null or not unit.has_mechanic_id("shy"):
			continue
		var effects: Array = player.slot_effects[slot]
		if ring_missing and BoardUpkeep.has_ring(effects):
			continue
		var gain: float = thank_value(unit, player, config)
		if gain > most:
			most = gain
			best = slot
	return best


## Spend surplus through Annis in a single flex slot, using the same legal actions as upgrades.
static func churn(brain: BotBrain) -> void:
	var player: PlayerState = brain._player
	if not active(player) or not fairy_build(brain.value) or not brain.level.reads_text:
		return
	var annis: bool = false
	for unit: RecruitUnit in player.board:
		annis = annis or (unit != null and unit.def_id() == "old_moth_annis")
	if not annis or not Pass3Rates.enabled(brain._rules.config, "fairies_annis_sale"):
		return
	for _step: int in 8:
		var offer: int = _fodder_offer(brain)
		if offer < 0:
			return
		var unit: RecruitUnit = player.shop[offer]
		var cost: int = brain._rules.unit_cost(player, unit)
		if player.gold - brain._held_back() < cost:
			return
		var slot: int = _flex_slot(brain)
		if slot < 0:
			return
		if player.board[slot] != null:
			if brain._rules.sell(player, slot) != "":
				return
		if brain._rules.buy(player, offer) != "":
			return
		brain._settle()
		var index: int = player.hand.find(unit)
		if index < 0 or player.board[slot] != null:
			return
		if brain._rules.play(player, index, slot) != "":
			return
		brain._settle()
		if player.board[slot] != unit:
			return
		if brain._rules.sell(player, slot) != "":
			return
		brain._settle()


static func _fodder_offer(brain: BotBrain) -> int:
	if brain._rules.buys_left(brain._player) == 0:
		return -1
	var best: int = -1
	var least: float = INF
	for index: int in brain._player.shop.size():
		var unit: RecruitUnit = brain._player.shop[index]
		if unit.def_id() in FAIRY_ENGINES or unit.has_mechanic_id("shy"):
			continue
		if BotEval.copies_of(brain._player, unit.def_id()) > 0:
			continue
		var cost: int = brain._rules.unit_cost(brain._player, unit)
		var score: float = cost * 100.0 + brain.value.keep_value(unit)
		if score < least:
			least = score
			best = index
	return best


static func _flex_slot(brain: BotBrain) -> int:
	var player: PlayerState = brain._player
	var carry: int = _carry_slot(player)
	var best: int = -1
	var least: float = INF
	for slot: int in BoardGeometry.SLOTS:
		if slot == carry:
			continue
		var unit: RecruitUnit = player.board[slot]
		if unit == null:
			return slot
		if unit.def_id() in FAIRY_ENGINES or unit.has_mechanic_id("shy"):
			continue
		if unit.def_id() in ["belladonna", "changeling"] or unit.golden:
			continue
		var worth: float = brain.value.keep_value(unit)
		if worth < least:
			least = worth
			best = slot
	return best if least < 35.0 else -1


static func play_slot(player: PlayerState, unit: RecruitUnit, value: BotEval) -> int:
	if not active(player) or not value.level.reads_text:
		return -1
	if unit.def_id() == "great_lump":
		var best: int = -1
		var most: int = -1
		for entry: Dictionary in player.away:
			var slot: int = CoreUtil.to_int(entry.get("nest", -1))
			var bird: RecruitUnit = entry["unit"]
			if slot >= 0 and player.board[slot] == null and bird.attack + bird.health > most:
				best = slot
				most = bird.attack + bird.health
		return best
	if not fairy_build(value):
		return -1
	if unit.def_id() == "old_moth_annis":
		var court: bool = (
			str(value.strategy.get("id", "")) in ["fairies_rainbow", "fairies_help"]
			or CoreUtil.to_bool(value.strategy.get("line_court", false))
		)
		var slot: int = 1 if court else 0
		return slot if player.board[slot] == null else -1
	if unit.def_id() == "cradle_fetch":
		var best: int = -1
		var most: int = -1
		for slot: int in BoardGeometry.FRONT:
			if player.board[slot] != null:
				continue
			for behind: int in BoardGeometry.behind(slot):
				var other: RecruitUnit = player.board[behind]
				if (
					other != null
					and other.has_tribe("Fairies")
					and other.attack + other.health > most
				):
					most = other.attack + other.health
					best = slot
		return best
	if unit.def_id() == "nan_toadstool":
		for slot: int in BoardGeometry.SLOTS:
			var effects: Array = player.slot_effects[slot]
			if player.board[slot] == null and not BoardUpkeep.has_ring(effects):
				return slot
	return -1


static func thank_ready(player: PlayerState, slot: int, config: GameConfig) -> bool:
	if not BoardGeometry.is_valid(slot):
		return true
	var unit: RecruitUnit = player.board[slot]
	if unit == null or not unit.has_mechanic_id("shy"):
		return true
	var other_shy: bool = false
	for other: RecruitUnit in player.board:
		if other == null:
			continue
		other_shy = other_shy or (other != unit and other.has_mechanic_id("shy"))
	match unit.def_id():
		"lob_lie_by_the_fire":
			var age: int = CoreUtil.to_int(unit.counters.get("pass3_turns_stayed", 0))
			var period: int = maxi(1, Pass3Rates.integer(config, "fairies_lob_turns"))
			return age >= period and thank_value(unit, player, config) > 0.0
		"silky":
			return not other_shy and thank_value(unit, player, config) > 0.0
	return thank_value(unit, player, config) > 0.0


static func _aim_birds(
	player: PlayerState, value: BotEval, layout: Array[int], pinned: Array[int]
) -> void:
	var seen: Array = player.scout.get("specs", [])
	var enemies: Array[int] = []
	for slot: int in mini(seen.size(), BoardGeometry.SLOTS):
		if seen[slot] != null:
			enemies.append(slot)
	enemies.sort_custom(
		func(a: int, b: int) -> bool:
			var first: Dictionary = seen[a]
			var second: Dictionary = seen[b]
			return (
				CoreUtil.to_int(first.get("attack", 0)) + CoreUtil.to_int(first.get("health", 0))
				> (
					CoreUtil.to_int(second.get("attack", 0))
					+ CoreUtil.to_int(second.get("health", 0))
				)
			)
	)
	if enemies.is_empty():
		return
	var locked: Array[int] = pinned.duplicate()
	for id: String in ["seven_whistlers", "jack_daw", "mag_pye"]:
		var source: int = _find(player, layout, id)
		if source < 0 or locked.has(source):
			continue
		var target: int = enemies[mini(1, enemies.size() - 1)] if id == "jack_daw" else enemies[0]
		if id == "mag_pye":
			var most: float = -1.0
			for enemy: int in enemies:
				var spec: Dictionary = seen[enemy]
				var hint: Dictionary = value.knowledge.card(str(spec.get("def_id", "")))
				var worth: float = BotEval._number(hint.get("keep", 0))
				if not locked.has(enemy) and worth > most:
					most = worth
					target = enemy
		if not locked.has(target):
			_swap(layout, source, target)
			locked.append(target)


static func hold_egg(player: PlayerState) -> bool:
	var home: float = 0.0
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if (
			unit != null
			and unit.has_tribe("Birds")
			and not CoreUtil.to_bool(unit.counters.get("egged", false))
		):
			home = maxf(home, egg_aim(player, slot))
	for entry: Dictionary in player.away:
		var bird: RecruitUnit = entry["unit"]
		if CoreUtil.to_bool(bird.counters.get("egged", false)):
			continue
		var body: int = (
			bird.base_attack_now() + bird.perm_attack + bird.base_health_now() + bird.perm_health
		)
		if body > home and CoreUtil.to_int(entry["due"]) <= player.round_number + 1:
			return true
	return false
