class_name RecruitExtras
extends RefCounted
## Rarer steps of a recruit turn, apart so RecruitRules stays readable.


## Hob Mumblecrust: what was borrowed comes back first; what's short comes off Health.
static func repay_debt(player: PlayerState) -> void:
	if player.debt <= 0:
		return
	var paid: int = mini(player.gold, player.debt)
	var health_lost: int = player.debt - paid + player.debt_health
	player.gold -= paid
	player.health -= health_lost
	player.log_event("repaid", {"gold": paid, "health": health_lost})
	player.debt = 0
	player.debt_health = 0


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


## Whether the free-move limit is on (free_moves_per_turn >= 0; evidence/placing.md).
static func limits_moves(rules: RecruitRules) -> bool:
	return rules.config.get_int("free_moves_per_turn") >= 0


## Charges a move under the free-move limit before it happens: "" if it may go ahead.
static func pay_for_move(
	rules: RecruitRules, player: PlayerState, from_slot: int, to_slot: int
) -> String:
	if from_slot == to_slot:
		return ""
	var price: int = move_price(rules, player, from_slot, to_slot)
	if price > player.gold:
		return "Not enough gold"
	if move_counts(rules, player, from_slot, to_slot):
		player.counted_moves += 1
	rules.spend(player, price)
	return ""


## A move counts against free_moves_per_turn when it shifts a unit that began the turn on the
## board, the one dragged or the one it swaps with. Units that arrived this turn move freely.
static func move_counts(
	rules: RecruitRules, player: PlayerState, from_slot: int, to_slot: int
) -> bool:
	if not limits_moves(rules):
		return false
	for slot: int in [from_slot, to_slot]:
		var unit: RecruitUnit = player.board[slot]
		if unit != null and player.iids_at_start.has(unit.iid):
			return true
	return false


## Gold a move costs: 0 while free moves are left.
static func move_price(
	rules: RecruitRules, player: PlayerState, from_slot: int, to_slot: int
) -> int:
	if not move_counts(rules, player, from_slot, to_slot):
		return 0
	if player.counted_moves < rules.config.get_int("free_moves_per_turn"):
		return 0
	return rules.config.get_int("move_cost")


## A row-aimed card needs a unit in that row.
static func row_aim_problem(player: PlayerState, aim: String, slot: int) -> String:
	if aim == HandItem.AIM_FRONT_UNIT and not unit_in_row(player, slot, true):
		return "Choose a unit in your front row"
	if aim == HandItem.AIM_BACK_UNIT and not unit_in_row(player, slot, false):
		return "Choose a unit in your back row"
	return ""


static func unit_in_row(player: PlayerState, slot: int, front: bool) -> bool:
	return (
		BoardGeometry.is_valid(slot)
		and player.board[slot] != null
		and BoardGeometry.is_front(slot) == front
	)
