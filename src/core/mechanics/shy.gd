class_name ShyRule
extends Mechanic
## A deliberate thank-you: only the original target of a spell leaves, after its effects finish.


static func thank(rules: RecruitRules, player: PlayerState, unit: RecruitUnit) -> void:
	if unit == null or not unit.has_mechanic_id("shy"):
		return
	var slot: int = player.board.find(unit)
	if slot < 0:
		return
	player.board[slot] = null
	HeldUnits.release(rules, player, unit)
	rules.pool.give_back(unit.def_id(), unit.pool_copies)
	var gold: int = unit.mechanic_number("shy", "gold")
	rules.give_gold(player, gold, "next_turn")
	player.log_event("walk_out", {"name": str(unit.def["name"]), "slot": slot, "gold": gold})
	player.log_event("trigger", {"mechanic": "shy", "source": unit.def_id()})
	rules.events.fire(player, "on_shy_left", {"subject": unit, "amount": slot})
