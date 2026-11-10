extends GutTest
## Commitment choices depend on kin and future recruits, rather than the tallest target.
@warning_ignore_start("unsafe_call_argument")

var _library: UnitLibrary = TestLibraries.current()


func _unit(id: String) -> RecruitUnit:
	return RecruitUnit.make(_library.get_unit(id), 0)


func test_kin_aim_beats_an_off_tribe_tall_carry() -> void:
	var player := PlayerState.new()
	player.board[0] = _unit("field_vole")
	player.board[1] = _unit("pixie_scout")
	player.board[4] = _unit("field_vole")
	player.board[5] = _unit("field_vole")
	player.board[5].add_permanent(100, 100)
	var card: Dictionary = _library.get_card("stand_behind_me")
	assert_eq(BotCommitment.aim_value(card, 0, player), 4.0)
	assert_eq(BotCommitment.aim_value(card, 1, player), 4.0)
	player.board[1] = _unit("field_vole")
	assert_eq(BotCommitment.aim_value(card, 1, player), 8.0)


func test_supper_chooses_a_large_uncapped_tribe_and_stops_for_the_turn() -> void:
	var player := PlayerState.new()
	player.round_number = 15
	player.board[0] = _unit("field_vole")
	player.board[1] = _unit("field_vole")
	player.board[2] = _unit("pixie_scout")
	var card: Dictionary = _library.get_card("harvest_supper")
	assert_gt(BotCommitment.aim_value(card, 0, player), BotCommitment.aim_value(card, 2, player))
	player.tribe_bonuses["Hedgerow folk"] = 3
	assert_eq(BotCommitment.aim_value(card, 0, player), 0.0)
	assert_true(BotCommitment.can_cast(card, player), "Fairies still eligible")
	player.harvest_supper_round = 15
	assert_false(BotCommitment.can_cast(card, player))
	assert_eq(BotCommitment.spell_value(card, player), 0.0)


func test_discover_values_future_bonus_without_double_counting_owned_units() -> void:
	var player := PlayerState.new()
	player.tribe_bonuses["Hedgerow folk"] = 3
	var future: RecruitUnit = _unit("field_vole")
	assert_eq(BotCommitment.future_bonus(future, player), 6.0)
	player.hand.append(future)
	assert_eq(BotCommitment.future_bonus(future, player), 0.0)


func test_hiring_fair_premium_requires_five_on_board() -> void:
	var player := PlayerState.new()
	var card: Dictionary = _library.get_card("hiring_fair")
	for slot: int in 4:
		player.board[slot] = _unit("field_vole")
	player.hand.append(_unit("field_vole"))
	var mixed: float = BotCommitment.spell_value(card, player)
	player.board[4] = _unit("field_vole")
	assert_gt(BotCommitment.spell_value(card, player), mixed)


func test_ooze_power_and_all_tribe_weights_have_explicit_scales() -> void:
	var knowledge: BotKnowledge = BotKnowledge.shared()
	for id: String in ["oozes_second_helpings", "birds_passage", "birds_summer_winter"]:
		var strategy: Dictionary = knowledge.strategy(id)
		if id.begins_with("oozes_"):
			assert_eq(strategy["power"], 8.0)
		else:
			assert_gte(strategy["power"], 0.0)
			assert_lte(strategy["power"], 8.0)
		var tribes: Dictionary = strategy["tribes"]
		assert_eq(tribes.values()[0], 5.0)


func test_kin_spell_ignores_shy_recipients_without_a_departure_penalty() -> void:
	var player := PlayerState.new()
	player.board[0] = _unit("pixie_scout")
	player.board[1] = _unit("pixie_scout")
	player.board[4] = _unit("hob_in_the_hearth")
	player.board[5] = _unit("pixie_scout")
	var card: Dictionary = _library.get_card("stand_behind_me")
	assert_eq(BotCommitment.aim_value(card, 0, player), 0.0)
	assert_eq(BotCommitment.aim_value(card, 1, player), 4.0)
	var brain: BotBrain = BotBrain.from_name("hard")
	brain._player = player
	var legal: Array[int] = [0, 1]
	assert_eq(brain._best_aim(legal, card), 1, "the Fairy behind gains stats")
	player.board[2] = _unit("pixie_scout")
	legal.append(2)
	assert_eq(brain._best_aim(legal, card), 1, "another tied column adds no value")
	assert_eq(BotCommitment.spell_value(card, player), 4.0)


func test_supper_skips_ambient_shy_stats_but_prices_a_deliberate_thank() -> void:
	var player := PlayerState.new()
	player.board[0] = _unit("pixie_scout")
	player.board[1] = _unit("hob_in_the_hearth")
	var card: Dictionary = _library.get_card("harvest_supper")
	assert_eq(BotCommitment.aim_value(card, 0, player), 6.0)
	assert_lt(BotCommitment.aim_value(card, 1, player), 6.0)
	assert_eq(BotCommitment.spell_value(card, player), 6.0)


func test_capstone_text_and_build_weights_can_replace_an_early_buffed_body() -> void:
	for pair: Array in [
		["fairies_rings", "fairy_monarch", "pixie_scout"],
		["oozes_second_helpings", "elder_ooze", "wee_wobbly"],
		["hunters_sett", "laird_of_sett", "young_brock"]
	]:
		var brain: BotBrain = BotBrain.from_name("hard:" + str(pair[0]))
		var player := PlayerState.new()
		var early: RecruitUnit = _unit(str(pair[2]))
		early.add_permanent(5, 5)
		player.board[0] = early
		var capstone: RecruitUnit = _unit(str(pair[1]))
		assert_gt(brain.value.text_value(capstone), 9.0, str(pair[1]))
		assert_gt(brain.value.buy_value(capstone, player), brain.value.keep_value(early))
	var ooze: BotBrain = BotBrain.from_name("hard:oozes_second_helpings")
	assert_eq(ooze.value.hint("elder_ooze", "row"), "back")
	assert_eq(ooze.value.text_value(_unit("moss_ooze")), 4.0)
