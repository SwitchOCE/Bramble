class_name RecruitExtras
extends RefCounted
## Rarer steps of a recruit turn, apart so RecruitRules stays readable.


## Hob Mumblecrust: one scheduled instalment comes out of each turn's income.
static func repay_debt(player: PlayerState) -> void:
	if player.debt <= 0:
		return
	var due: int = mini(player.debt, player.debt_payment)
	var paid: int = mini(player.gold, due)
	player.gold -= paid
	player.debt -= paid
	player.log_event("repaid", {"gold": paid, "health": 0})
	if player.debt == 0:
		player.debt_payment = 0


## Rainy Day: last fight's result sets what it pays.
static func rainy_day(player: PlayerState) -> void:
	if player.rainy_win <= 0 and player.rainy_lose <= 0:
		return
	var pays: int = player.rainy_lose if player.last_result == "loss" else player.rainy_win
	player.gold += pays
	player.log_event("gold", {"amount": pays, "when": "now"})
	player.rainy_win = 0
	player.rainy_lose = 0


## Pipistrelle Echo: a spell aimed at this also hits its neighbours in the row. What the first cast
## spent is not spent again.
static func echo(
	rules: RecruitRules, player: PlayerState, item: HandItem, slot: int, first: RecruitContext
) -> void:
	if item.aim() != HandItem.AIM_UNIT or not BoardGeometry.is_valid(slot):
		return
	var aimed: RecruitUnit = player.board[slot]
	if aimed == null or not aimed.has_mechanic_id(RecruitRules.ECHO):
		return
	for other: int in BoardGeometry.adjacent(slot):
		var unit: RecruitUnit = player.board[other]
		if unit == null:
			continue
		var fields: Dictionary = {"chosen_slot": other, "chosen": unit, "card_def": item.def}
		var ctx: RecruitContext = RecruitContext.make(rules, player, "cast", fields)
		ctx.params = item.def
		ctx.amount = first.amount
		for value: Variant in MechanicRegistry.steps_of(item.def):
			var step: Dictionary = value
			if str(step.get("effect", "")) != "spend_all":
				EffectRunner.run_step(step, item.def, ctx)


## The fork of rounds 1-2: the first shop of each shows these spells in place of a drawn one, so
## tempo (a unit), economy (Rainy Day) and a climb (A Leg Up) are all on offer. Not from the pool.
static func show_opening_cards(rules: RecruitRules, player: PlayerState) -> void:
	var cards: Array = rules.config.get_value("opening_spells")
	if player.round_number > rules.config.get_int("opening_rounds"):
		return
	if player.opening_shown >= player.round_number or not player.shop_spells.is_empty():
		return
	player.opening_shown = player.round_number
	for card: Variant in cards:
		player.shop_spells.append(HandItem.make(rules.library.get_card(str(card)), rules.new_iid()))


## An Acorn that makes a Stash takes no room in the end, so it arrives on a full hand.
static func completes_three(player: PlayerState, card_def: Dictionary) -> bool:
	if str(card_def.get("combines_into", "")) == "":
		return false
	return item_count(player, str(card_def["id"])) >= RecruitRules.COMBINE_COUNT - 1


static func item_count(player: PlayerState, card: String) -> int:
	var count: int = 0
	for item: HandItem in player.items:
		if item.def_id() == card:
			count += 1
	return count


## Three of a size combine into the next size at once, and can't be declined.
static func combine_items(rules: RecruitRules, player: PlayerState) -> void:
	var index: int = 0
	while index < player.items.size():
		var item: HandItem = player.items[index]
		var into: String = str(item.def.get("combines_into", ""))
		index += 1
		if into == "" or item_count(player, item.def_id()) < RecruitRules.COMBINE_COUNT:
			continue
		for _gone: int in RecruitRules.COMBINE_COUNT:
			_remove_item(player, item.def_id())
		player.items.append(HandItem.make(rules.library.get_card(into), rules.new_iid()))
		player.log_event("combine", {"into": into})
		index = 0


static func _remove_item(player: PlayerState, card: String) -> void:
	for index: int in player.items.size():
		if player.items[index].def_id() == card:
			player.items.remove_at(index)
			return
