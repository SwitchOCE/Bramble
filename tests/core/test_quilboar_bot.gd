# gdlint:disable=max-public-methods
extends GutTest
## The reference line executes legal actions instead of giving itself scripted engine arrivals.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")

var _kit: Variant
var _player: PlayerState
var _rules: RecruitRules
var _brain: BotBrain


func before_each() -> void:
	_kit = KIT.new()
	var config := GameConfig.full_game()
	config.set_value("reference_quilboar", true)
	_kit.setup(config)
	_player = _kit.player
	_rules = _kit.rules
	_brain = BotBrain.from_name("quilboar_choose_one")
	_brain._player = _player
	_brain._rules = _rules
	_brain._round_now = 8
	_brain.value.library = _rules.library
	_brain.value.recruit_rules = _rules
	_brain.value.board_owner = _player
	_player.round_number = 8
	_player.gold = 10


func _put(id: String, slot: int = -1) -> RecruitUnit:
	var unit := RecruitUnit.make(_rules.library.get_unit(id), _rules.new_iid())
	unit.origin = RecruitUnit.ORIGIN_CREATED
	if slot >= 0:
		_player.board[slot] = unit
	else:
		_player.hand.append(unit)
	return unit


func _mode(id: String) -> int:
	return BotQuilboar.mode(_brain, {"kind": "choose_one", "item_id": id})


func test_raw_name_selects_hard_brain_with_blind_placement() -> void:
	assert_eq(_brain.build_name(), "quilboar_choose_one")
	assert_eq(_brain.level.name, BotLevel.HARD)
	assert_eq(_brain.level.place, BotLevel.PLACE_RULE)
	assert_false(_brain.level.scouts)
	assert_true(BotQuilboar.active(_brain))
	_rules.config.set_value("reference_quilboar", false)
	assert_false(BotQuilboar.active(_brain), "the custom policy is gated as well as the pool")


func test_commit_is_round_six_or_an_early_rat() -> void:
	_brain._round_now = 4
	assert_false(BotQuilboar.committed(_brain))
	_put("qb_gem_rat", 0)
	assert_true(BotQuilboar.committed(_brain))
	_player.board[0] = null
	_brain._round_now = 6
	assert_true(BotQuilboar.committed(_brain))


func test_modes_pivot_from_hand_gems_to_future_size() -> void:
	_brain._round_now = 8
	assert_eq(_mode("qb_crater_miner"), 0)
	assert_eq(_mode("qb_fearless_foodie"), 1)
	_put("qb_turbo_hogrider", 2)
	assert_eq(_mode("qb_crater_miner"), 1)
	assert_eq(_mode("qb_fearless_foodie"), 0)
	assert_eq(_mode("qb_snare_trapper"), 1)
	assert_eq(_mode("qb_veteran_brigand"), 0)


func test_gem_day_balances_the_smaller_axis() -> void:
	_player.gem_attack_halves = 7
	_player.gem_health_halves = 4
	assert_eq(_mode("qb_gem_day"), 1)
	assert_eq(BotQuilboar.mode(_brain, {"card_def": {"id": "qb_gem_day"}}), 1)
	_player.gem_attack_halves = 4
	assert_eq(_mode("qb_gem_day"), 0)


func test_sly_refreshes_only_while_cycling_without_another_choose_one_offer() -> void:
	_player.tier = 4
	_put("qb_bramble_tunneler", 4)
	assert_eq(_mode("qb_sly_infiltrator"), 0)
	_player.shop.append(RecruitUnit.make(_rules.library.get_unit("qb_crater_miner"), 90))
	assert_eq(_mode("qb_sly_infiltrator"), 1)


func test_engine_pieces_are_not_sold_for_the_cycle_slot() -> void:
	_put("qb_turbo_hogrider", 0)
	_put("qb_bramble_tunneler", 1)
	_put("qb_gem_rat", 2)
	_put("qb_sanguine_refiner", 3)
	assert_eq(BotQuilboar._sell_slot(_brain), -1)
	_put("qb_crater_miner", 5)
	assert_eq(BotQuilboar._sell_slot(_brain), 5)


func test_hand_gems_alternate_carry_and_keepers() -> void:
	_put("qb_gem_rat", 0)
	_put("qb_bramble_tunneler", 4)
	assert_eq(BotQuilboar._gem_target(_player), 0)
	assert_eq(BotQuilboar._gem_target(_player), 4)
	assert_eq(BotQuilboar._gem_target(_player), 0)
	assert_eq(BotQuilboar._gem_target(_player), 4)


func test_created_choose_one_is_played_then_sold_for_zero() -> void:
	_put("qb_turbo_hogrider", 2)
	_put("qb_bramble_tunneler", 4)
	_player.tier = 4
	_put("qb_crater_miner")
	var gold: int = _player.gold
	BotQuilboar._play_hand(_brain)
	assert_eq(_player.gold, gold, "a Tunneler-created unit grants no sale gold")
	assert_true(_player.hand.is_empty())
	assert_eq(_player.board_count(), 2)
	assert_false(_player.is_choosing())


func test_last_purchased_cycle_unit_stays_and_fills_the_seventh_slot() -> void:
	_put("qb_turbo_hogrider", 2)
	_put("qb_bramble_tunneler", 4)
	_put("qb_gem_rat", 0)
	_put("qb_sanguine_refiner", 5)
	_put("qb_thorned_trailblazer", 3)
	_put("qb_trench_fighter", 6)
	_player.tier = 4
	var cycle: RecruitUnit = _put("qb_crater_miner")
	cycle.origin = RecruitUnit.ORIGIN_BOUGHT
	BotQuilboar._play_hand(_brain)
	assert_eq(_player.board_count(), 7)
	assert_same(_player.board[1], cycle)
	assert_false(_player.is_choosing())


func test_short_recruit_turn_buys_a_real_offered_engine() -> void:
	_put("qb_gem_rat", 0)
	_player.tier = 4
	_player.shop.append(RecruitUnit.make(_rules.library.get_unit("qb_bramble_tunneler"), 99))
	_brain.play_turn(_player, _rules, 8)
	var found: bool = false
	for unit: RecruitUnit in _player.board:
		if unit != null and unit.def_id() == "qb_bramble_tunneler":
			found = true
	assert_true(found)
	assert_false(_player.is_choosing())
	assert_gte(_player.gold, 0)


func test_ordinary_hard_resolves_a_real_reference_choose_one() -> void:
	var hard: BotBrain = BotBrain.from_name("hard")
	hard._player = _player
	hard._rules = _rules
	hard._round_now = 9
	assert_false(BotQuilboar.active(hard), "the Hard anchor does not become the reference line")
	_put("qb_fearless_foodie")
	assert_eq(_rules.play(_player, 0, 0), "")
	assert_true(_player.is_choosing())
	hard._settle()
	assert_false(_player.is_choosing(), "mode labels are choices, not unit IDs to value")
	assert_eq(_player.gem_attack_halves, 3)
	assert_eq(_player.gem_health_halves, 3)


func test_reference_and_hard_seats_play_three_real_lobby_rounds() -> void:
	var config := GameConfig.full_game()
	config.set_value("reference_quilboar", true)
	config.set_value("tribes_per_lobby", 0)
	config.set_value("hero_choice", false)
	config.set_value("human_bot", "quilboar_choose_one")
	config.set_value("max_rounds", 3)
	var session := GameSession.create(20261110, UnitLibrary.load_dir(), config)
	assert_eq(session._players.size(), 8)
	assert_true(session._pool.has_unit("qb_gem_rat"))
	for _round: int in 3:
		assert_eq(session.end_turn(), "")
	assert_true(session.is_over())
	assert_false(session.get_last_combat().is_empty())
	for player: PlayerState in session._players:
		assert_true(player.reference_quilboar)
		assert_false(player.is_choosing())
