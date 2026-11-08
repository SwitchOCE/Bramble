class_name MarketStalls
extends RefCounted
## Bounded permanent shop space. A capped Pipkin unit slot becomes a spell slot instead.

const CARD: String = "market_stall"
const LIMIT: int = 2
const UNIT_CAP: int = 7


static func limit_reached(player: PlayerState) -> bool:
	var count: int = player.market_stalls
	for item: HandItem in player.items:
		count += 1 if item.def_id() == CARD else 0
	return count >= LIMIT


## Negative shop additions apply after the ceiling, so Hungry Gap still removes one at seven.
static func penalty(rules: RecruitRules, player: PlayerState) -> int:
	var amount: int = 0
	for handler: Dictionary in player.rule_handlers:
		if (
			str(handler["query"]) == "shop_size"
			and str(handler["op"]) == "add"
			and rules._handler_applies(handler, player)
		):
			amount += mini(0, CoreUtil.to_int(handler["value"]))
	return amount


static func unit_capacity(rules: RecruitRules, player: PlayerState) -> int:
	return maxi(0, UNIT_CAP + penalty(rules, player))


static func unit_bonus(rules: RecruitRules, player: PlayerState) -> int:
	var base: int = rules.config.get_int_at("shop_units_by_tier", player.tier - 1)
	var ordinary: int = rules.ask("shop_size", player, base) - penalty(rules, player)
	return mini(player.market_stalls, maxi(0, UNIT_CAP - ordinary))


static func spell_bonus(rules: RecruitRules, player: PlayerState) -> int:
	if str(player.hero.get("id", "")) != "pipkin":
		return 0
	return player.market_stalls - unit_bonus(rules, player)


## Frozen offers keep their identities; only excess ordinary offers return to the pool.
static func trim_units(rules: RecruitRules, player: PlayerState, size: int) -> void:
	var capacity: int = unit_capacity(rules, player)
	while poached_count(player) > capacity:
		for index: int in range(player.shop.size() - 1, -1, -1):
			if player.shop[index].poached_discount > 0:
				player.poached_pending.push_front(player.shop[index])
				player.shop.remove_at(index)
				break
	size = mini(size, capacity - poached_count(player))
	for index: int in range(player.shop.size() - 1, -1, -1):
		if HunterRecruit.normal_shop_count(player) <= size:
			return
		var unit: RecruitUnit = player.shop[index]
		if unit.poached_discount == 0:
			player.shop.remove_at(index)
			rules.pool.give_back(unit.pool_id(), unit.pool_copies)


static func poached_count(player: PlayerState) -> int:
	return player.shop.size() - HunterRecruit.normal_shop_count(player)


static func remove_unavailable(rules: RecruitRules, player: PlayerState) -> void:
	if not limit_reached(player):
		return
	for item: HandItem in player.shop_spells.duplicate():
		if item.def_id() == CARD:
			player.shop_spells.erase(item)
			if rules.spell_pool != null:
				rules.spell_pool.give_back(CARD, item.pool_copies)


static func draw_spell(rules: RecruitRules, player: PlayerState, odds: Array) -> String:
	if not limit_reached(player):
		return rules.spell_pool.draw_by_odds(odds, player.tier, player.spell_rng)
	# Keep the shop's tier-first odds while excluding a card for just this player.
	var weights: Array[int] = []
	var total: int = 0
	for tier: int in range(1, player.tier + 1):
		var copies: int = rules.spell_pool.eligible_copies(tier, tier)
		if tier == rules.spell_pool.tier_of(CARD):
			copies -= rules.spell_pool.copies_left(CARD)
		var weight: int = copies
		if not odds.is_empty():
			weight = CoreUtil.to_int(odds[tier - 1]) if copies > 0 else 0
		weights.append(weight)
		total += weight
	if total <= 0:
		return ""
	var roll: int = player.spell_rng.randi_range(0, total - 1)
	for index: int in weights.size():
		if roll < weights[index]:
			var pick: CardPick = CardPick.spec(1, index + 1, index + 1)
			pick.exclude = PackedStringArray([CARD])
			var cards: PackedStringArray = pick.run(rules.spell_pool, player.spell_rng)
			return "" if cards.is_empty() else cards[0]
		roll -= weights[index]
	return ""
