class_name RecruitKin
extends RefCounted
## Optional paid search. It draws real copies with the normal tier odds.


static func tribes(player: PlayerState) -> PackedStringArray:
	var out: PackedStringArray = []
	for unit: RecruitUnit in player.board:
		if unit != null:
			for tribe: String in unit.tribes():
				if not out.has(tribe):
					out.append(tribe)
	if player.nest_count() > 0 and not out.has("Birds"):
		out.append("Birds")
	return out


static func available(rules: RecruitRules, player: PlayerState) -> bool:
	return (
		rules.config.get_bool("ask_for_kin")
		and not player.is_choosing()
		and not player.asked_for_kin
		and player.gold >= 2
		and not tribes(player).is_empty()
	)


static func ask(rules: RecruitRules, player: PlayerState) -> String:
	if not available(rules, player):
		return "Ask for Kin needs 2 gold, a tribe on your board, and an unused Ask this turn"
	player.asked_for_kin = true
	player.paid_refreshes += 1
	rules.spend(player, 2)
	var poached: Array[RecruitUnit] = HunterRecruit.pull_offers(player)
	rules._return_shop(player)
	player.shop.append_array(poached)
	player.frozen = false
	var kin: PackedStringArray = tribes(player)
	for _index: int in mini(2, rules.shop_size(player.tier, player)):
		var card: String = _draw(rules, player, kin)
		if card == "":
			break
		var unit := RecruitUnit.make(rules.library.get_unit(card), rules.new_iid())
		unit.pool_copies = 1
		player.shop.append(unit)
	rules._fill_shop(player)
	rules.observe_shop(player)
	rules.events.fire(player, "on_refresh", {"paid": true})
	player.log_event("ask_for_kin")
	return ""


static func _draw(rules: RecruitRules, player: PlayerState, kin: PackedStringArray) -> String:
	var by_tier: Dictionary = {}
	var copies: Dictionary = {}
	for card: String in rules.pool.ids():
		var tier: int = rules.pool.tier_of(card)
		var count: int = rules.pool.copies_left(card)
		if tier > player.tier or count <= 0:
			continue
		var matches: bool = false
		for tribe: Variant in rules.pool.tribes_of(card):
			matches = matches or kin.has(str(tribe))
		if not matches:
			continue
		var cards: Array = by_tier.get(tier, [])
		cards.append(card)
		by_tier[tier] = cards
		copies[tier] = CoreUtil.to_int(copies.get(tier, 0)) + count
	var odds: Array = rules._shop_odds(player.tier)
	var total: int = 0
	for tier: int in by_tier:
		total += copies[tier] if odds.is_empty() else CoreUtil.to_int(odds[tier - 1])
	if total <= 0:
		return ""
	var pick: int = player.shop_rng.randi_range(0, total - 1)
	for tier: int in by_tier:
		var weight: int = copies[tier] if odds.is_empty() else CoreUtil.to_int(odds[tier - 1])
		if pick >= weight:
			pick -= weight
			continue
		pick = player.shop_rng.randi_range(0, CoreUtil.to_int(copies[tier]) - 1)
		for card: String in by_tier[tier]:
			var count: int = rules.pool.copies_left(card)
			if pick < count:
				rules.pool.take(card)
				return card
			pick -= count
	return ""
