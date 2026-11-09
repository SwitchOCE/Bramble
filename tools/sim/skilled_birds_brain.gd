extends CommittedLineBrain
## Tools-only flight experiment. All other line decisions call their native implementation.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

var aggressive_flight: bool = false
var flight_log: Array[Dictionary] = []


## Keep in lockstep with BotBrain._smart_turn; Python validation checks this exact body.
func _smart_turn() -> void:
	_settle()
	_choose_build()
	_open_with_a_plan()
	_cast_spells(false)
	_flight_turn()
	_settle()
	_sell_for_cash()
	_borrow_if_short()
	_climb(false)
	_shop_loop()
	_play_hand()
	_cast_spells(false)
	_maybe_power()
	_shop_loop()
	_climb(true)
	BotPass3.churn(self)
	_feed_eaters()
	_cash_for_burn()
	_cast_spells(true)
	_freeze()
	_settle()
	_arrange()


func _flight_turn() -> void:
	flight_log.clear()
	if not value.level.reads_text:
		return
	# Same bounded action count and phase as BotHeld._profile_fly_turn.
	for step: int in BoardGeometry.SLOTS:
		# Force only the first carry; subsequent flights follow the native policy.
		var force_carry: bool = aggressive_flight and step == 0
		var decision: Dictionary = flight_decision(_player, value, _round_now, force_carry)
		decision["forced_carry"] = force_carry
		decision["step"] = step
		var slot: int = CoreUtil.to_int(decision["chosen_slot"])
		if slot < 0:
			flight_log.append(decision)
			return
		var unit: RecruitUnit = _player.board[slot]
		assert(not _player.is_choosing() and HeldUnits.flies(unit, _player))
		decision["problem"] = _rules.sell(_player, slot)
		var flew: bool = false
		for entry: Dictionary in _player.away:
			flew = flew or entry["unit"] == unit
		decision["flew"] = flew
		flight_log.append(decision)
		assert(decision["problem"] == "" and flew, "legal flight did not become a native trip")


static func flight_decision(
	player: PlayerState, value_now: BotEval, number: int, aggressive: bool
) -> Dictionary:
	var policy: Dictionary = value_now.strategy.get("line_fly_policy", {})
	var largest_bird: RecruitUnit = BotPass3._biggest_bird(player)
	var biggest_legal: int = -1
	var most: int = -1
	var candidates: Array[Dictionary] = []
	var danger: bool = player.health <= maxi(8, 2 * number)
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit == null or not unit.has_mechanic_id(HeldUnits.FLY):
			continue
		var legal: bool = not player.is_choosing() and HeldUnits.flies(unit, player)
		var size: int = unit.attack + unit.health
		if legal and size > most:
			biggest_legal = slot
			most = size
		var denied: Array[String] = []
		if player.is_choosing():
			denied.append("pending_choice")
		if unit.plain_copy:
			denied.append("plain_copy")
		if unit.played_round == player.round_number and player.pass3_loop_guards:
			denied.append("played_or_returned_this_round")
		if number < CoreUtil.to_int(policy.get("from_round", 3)):
			denied.append("policy_from_round")
		if player.board_count() <= CoreUtil.to_int(policy.get("keep_home_min", 3)):
			denied.append("policy_keep_home_min")
		if BotPass3._omen(player):
			denied.append("policy_omen")
		if policy.has("max_away") and player.away.size() >= CoreUtil.to_int(policy["max_away"]):
			denied.append("policy_max_away")
		var allowed: Array = policy.get("allowed", [])
		if not allowed.is_empty() and not allowed.has(unit.def_id()):
			denied.append("policy_allowed")
		if unit.def_id() == "old_tern" and player.away.size() < 2:
			denied.append("policy_tern_two_away")
		if unit == largest_bird and danger:
			denied.append("hard_danger_largest")
		var score: float = BotPass3.trip_score(unit, player, value_now)
		if score <= 0.0:
			denied.append("hard_nonpositive_trip_score")
		(
			candidates
			. append(
				{
					"slot": slot,
					"iid": unit.iid,
					"def_id": unit.def_id(),
					"attack": unit.attack,
					"health": unit.health,
					"stats": size,
					"golden": unit.golden,
					"played_round": unit.played_round,
					"legal": legal,
					"legacy_denials": denied,
					"legacy_trip_score": score,
				}
			)
		)
	var native: int = BotHeld._best_flight(player, value_now, number)
	var chosen: int = biggest_legal if aggressive else native
	if player.is_choosing():
		chosen = -1
	return {
		"round": number,
		"health": player.health,
		"danger": danger,
		"board_count": player.board_count(),
		"away_count": player.away.size(),
		"aggressive": aggressive,
		"candidates": candidates,
		"biggest_legal_slot": biggest_legal,
		"native_chosen_slot": native,
		"chosen_slot": chosen,
		"carry_chosen": chosen >= 0 and chosen == biggest_legal,
	}
