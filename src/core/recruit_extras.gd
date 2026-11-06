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
