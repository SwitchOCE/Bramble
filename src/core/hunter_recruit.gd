class_name HunterRecruit
extends RefCounted
## Pool-backed next-shop Poach offers and the one-turn Take upgrade reduction.


static func poach(rules: RecruitRules, player: PlayerState, change: Dictionary) -> void:
	var id: String = str(change["card"])
	var card: Dictionary = rules.library.get_unit(id)
	if card.is_empty() or CoreUtil.to_int(card["tier"]) > player.tier or not rules.pool.take(id):
		return
	var unit := RecruitUnit.make(card, rules.new_iid())
	unit.pool_copies = 1
	unit.poached_discount = CoreUtil.to_int(change["discount"])
	player.poached_pending.append(unit)
	player.log_event("poached", {"name": str(card["name"]), "card": id})


static func start_turn(player: PlayerState) -> void:
	player.hunt_discount = player.hunt_discount_next
	player.hunt_discount_next = 0
	player.shop.append_array(player.poached_pending)
	player.poached_pending.clear()


static func normal_shop_count(player: PlayerState) -> int:
	var count: int = 0
	for unit: RecruitUnit in player.shop:
		if unit.poached_discount == 0:
			count += 1
	return count


static func pull_offers(player: PlayerState) -> Array[RecruitUnit]:
	var kept: Array[RecruitUnit] = []
	for unit: RecruitUnit in player.shop.duplicate():
		if unit.poached_discount > 0:
			player.shop.erase(unit)
			kept.append(unit)
	return kept


static func expire(rules: RecruitRules, player: PlayerState) -> void:
	for unit: RecruitUnit in pull_offers(player):
		rules.pool.give_back(unit.pool_id(), unit.pool_copies)
		player.log_event("poach_returned", {"name": str(unit.def["name"])})
	player.hunt_discount = 0
