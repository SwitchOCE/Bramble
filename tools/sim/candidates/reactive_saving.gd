extends BotBrain
## First gap candidate. Gold reserves follow real next-turn interest and current shop/pressure,
## instead of a fixed round schedule. No extra search fights or changes to card/tribe values.

const CASH_OPPORTUNITY: float = 0.25
const MAX_BANK: int = 20
const DANGER_RATIO: float = 0.85
var _price_all_offers: bool = false


func _held_back() -> int:
	if _price_all_offers or _under_pressure():
		return 0
	var effects: Array[Dictionary] = _interest_effects()
	if effects.is_empty():
		return _climb_savings()
	var best: int = 0
	var most: float = 0.0
	# Smallest bank at a useful real threshold; a capped engine never hoards beyond its cap.
	for bank: int in range(1, mini(MAX_BANK, _player.gold) + 1):
		var worth: float = (
			BotEval.GOLD_POINTS * _interest_sum(effects, bank) - CASH_OPPORTUNITY * bank
		)
		if worth > most:
			best = bank
			most = worth
	return maxi(_climb_savings(), best)


func _best_offer() -> Dictionary:
	# Inspect an offer even when the incumbent's scheduled reserve would hide it.
	_price_all_offers = true
	var offer: Dictionary = super._best_offer()
	_price_all_offers = false
	if offer.is_empty():
		return offer
	var cost: int = CoreUtil.to_int(offer["cost"])
	var reserve: int = _held_back()
	if cost <= _player.gold + _player.larder() - reserve:
		return offer
	var next_bank: int = maxi(0, _player.gold - cost)
	var interest_lost: int = interest_at(_player.gold) - interest_at(next_bank)
	var climb_lost: int = maxi(0, _climb_savings() - next_bank)
	var opportunity: float = BotEval.GOLD_POINTS * (interest_lost + climb_lost)
	if _under_pressure() or BotEval._number(offer["gain"]) > opportunity:
		return offer
	# A modest affordable improvement can still be worth buying while the bank stays intact.
	return super._best_offer()


func _refresh_worth_it() -> bool:
	var cost: int = _rules.refresh_cost(_player)
	if cost == 0:
		return _player.gold + _player.larder() >= _rules.unit_cost(_player)
	if not super._refresh_worth_it():
		return false
	if _under_pressure() or cost == 0:
		return true
	# A speculative shop should not break a known next-turn interest payment.
	return interest_at(_player.gold - cost) >= interest_at(_player.gold)


func _under_pressure() -> bool:
	if _player.board_count() == 0 or _player.health <= LOW_HEALTH:
		return true
	if _player.scout.is_empty():
		return false
	var seen: Array = _player.scout["specs"]
	return stat_sum(_player.combat_board()) < DANGER_RATIO * stat_sum(seen)


## Only unconditional carried-gold payments on the actual board/hero. Read the rule parameters,
## including golden effects, rather than maintaining a list of profitable cards or hero names.
func interest_at(bank: int) -> int:
	return _interest_sum(_interest_effects(), bank)


func _interest_effects() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for unit: RecruitUnit in _player.board:
		if unit == null:
			continue
		for entry: Variant in MechanicRegistry.compiled(unit.def):
			var compiled: CompiledMechanic = entry
			if compiled.id == "effect":
				var params: Dictionary = compiled.params_for(unit.golden)
				if str(params.get("trigger", "")) == "start_of_turn":
					out.append(params)
	for effect: Dictionary in HeroRules.effects_of(_player.hero):
		out.append(effect)
	return out


static func _interest_sum(effects: Array[Dictionary], bank: int) -> int:
	var total: int = 0
	for effect: Dictionary in effects:
		total += _interest_effect(effect, bank)
	return total


static func _interest_effect(effect: Dictionary, bank: int) -> int:
	if str(effect.get("trigger", "")) != "start_of_turn" or effect.has("if"):
		return 0
	var total: int = 0
	for step: Dictionary in MechanicRegistry.steps_of(effect):
		if (
			step.has("if")
			or str(step.get("effect", "")) != "gold"
			or str(step.get("per", "")) != "carried"
		):
			continue
		@warning_ignore("integer_division")
		var payments: int = maxi(0, bank) / maxi(1, CoreUtil.to_int(step.get("per_div", 1)))
		payments = mini(payments, CoreUtil.to_int(step.get("per_max", payments)))
		total += payments * CoreUtil.to_int(step.get("amount", 0))
	return total
