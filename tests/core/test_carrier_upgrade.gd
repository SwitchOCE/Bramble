extends GutTest
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")
const BRAIN := preload("res://src/core/bots/bot_brain.gd")
const Legacy := preload("res://tests/core/legacy_bog.gd")
var _kit: KIT
var _brain: BRAIN


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game(), true, Legacy.library())
	_kit.player.gold = 10
	_kit.player.health = 40
	_kit.player.tier = 6
	_kit.player.round_number = 12
	_brain = BenchSuites.create_bot("carrier_upgrade") as BRAIN
	_brain._player = _kit.player
	_brain._rules = _kit.rules
	_brain._round_now = 12
	_brain.value.library = _kit.library
	_brain.value.board_owner = _kit.player


func after_each() -> void:
	_brain.value.board_owner = null
	_brain._player = null
	_brain._rules = null


func _full_board(carrier_attack: int = 8, carrier_health: int = 8) -> RecruitUnit:
	var id: String = _kit.card("early_carrier", [], [], carrier_attack, carrier_health)
	var old: RecruitUnit = _kit.put(id, 0)
	_brain.value.strategy = {"id": "test_prior", "units": {id: 40}}
	for slot: int in range(1, BoardGeometry.SLOTS):
		var filler: String = _kit.card("filler_%d" % slot, [], [], 100, 100)
		_kit.put(filler, slot)
	return old


func test_live_committee_text_can_replace_a_prior_favoured_carrier() -> void:
	_full_board()
	var unit: RecruitUnit = _kit.shop("standing_committee")
	var hard: BotBrain = BotBrain.from_name("hard")
	hard._player = _kit.player
	hard._rules = _kit.rules
	hard.value.board_owner = _kit.player
	hard.value.strategy = _brain.value.strategy
	assert_lt(hard._ordinary_unit_gain(unit), 0.0, "incumbent's build prior hides the upgrade")
	var plan: Dictionary = BotCarrier.upgrade_plan(_brain, unit)
	assert_eq(plan.get("slot"), 0)
	assert_gt(_brain._unit_gain(unit), 0.0)
	hard.value.board_owner = null
	hard._player = null
	hard._rules = null


func test_the_purchase_actually_frees_the_scored_slot_and_plays_the_engine() -> void:
	var old: RecruitUnit = _full_board()
	_kit.shop("standing_committee")
	var offer: Dictionary = _brain._best_offer()
	assert_false(offer.is_empty())
	assert_true(_brain._buy_offer(offer))
	assert_eq(_kit.player.board[0].def_id(), "standing_committee")
	assert_false(_kit.player.board.has(old))
	assert_eq(_kit.player.board_count(), 7)


func test_a_large_real_carry_is_not_thrown_away_for_tier_alone() -> void:
	_full_board(80, 80)
	var unit: RecruitUnit = _kit.shop("standing_committee")
	assert_true(BotCarrier.upgrade_plan(_brain, unit).is_empty())
	assert_lte(_brain._unit_gain(unit), 0.0)


func test_committee_counts_touching_not_just_immediate_neighbours() -> void:
	_full_board()
	var committee: RecruitUnit = RecruitUnit.make(_kit.library.get_unit("standing_committee"), 99)
	var board: Array[RecruitUnit] = _kit.player.board.duplicate()
	board[0] = committee
	assert_eq(BotCarrier.engine_text(_brain, committee, board, 0), 21.0)
	board[4] = null
	assert_eq(
		BotCarrier.engine_text(_brain, committee, board, 0), 2.0, "a gap splits the zigzag group"
	)


func test_grizel_growth_requires_a_pack_group_and_time_to_use_it() -> void:
	var grizel: RecruitUnit = _kit.put("grizel", 1)
	assert_eq(BotCarrier.engine_text(_brain, grizel, _kit.player.board, 1), 0.0)
	_kit.put("sable", 0)
	assert_gt(BotCarrier.engine_text(_brain, grizel, _kit.player.board, 1), 0.0)
	_kit.player.health = BotBrain.LOW_HEALTH
	assert_eq(BotCarrier.engine_text(_brain, grizel, _kit.player.board, 1), 0.0)


func test_peat_value_is_bounded_by_mire_marks_vacancies_and_real_token() -> void:
	var king: RecruitUnit = _kit.put("peat_king", 0)
	assert_eq(BotCarrier.engine_text(_brain, king, _kit.player.board, 0), 12.0)
	_kit.put("bridge_toad", 1)
	assert_eq(BotCarrier.engine_text(_brain, king, _kit.player.board, 0), 20.0)
	king.golden = true
	assert_eq(BotCarrier.engine_text(_brain, king, _kit.player.board, 0), 40.0)


func test_scoring_does_not_mutate_board_or_random_streams() -> void:
	var old: RecruitUnit = _full_board()
	var unit: RecruitUnit = _kit.shop("standing_committee")
	var state: int = _kit.player.bot_rng.state
	var plan: Dictionary = BotCarrier.upgrade_plan(_brain, unit)
	assert_false(plan.is_empty())
	assert_eq(_kit.player.bot_rng.state, state)
	assert_same(_kit.player.board[0], old)
	assert_eq(_kit.player.board_count(), 7)


func test_real_buffed_wolf_can_make_room_for_grizels_pack_growth() -> void:
	var wolf: RecruitUnit = _kit.put("brother_wolf", 0)
	wolf.attack = 8
	wolf.health = 4
	for slot: int in range(1, BoardGeometry.SLOTS):
		var id: String = _kit.card(
			"pack_body_%d" % slot, [{"id": "pack", "repeat": false}], [], 30, 30
		)
		var definition: Dictionary = _kit.library.get_unit(id)
		definition["tier"] = 4
		_kit.put(id, slot)
	var grizel: RecruitUnit = _kit.shop("grizel")
	var plan: Dictionary = BotCarrier.upgrade_plan(_brain, grizel)
	assert_eq(plan.get("slot"), 0)
	assert_gt(_brain._unit_gain(grizel), 0.0)


func test_biased_base_score_does_not_make_it_sell_a_better_mid_tier_body() -> void:
	var old: RecruitUnit = _full_board()
	var id: String = _kit.card("mid_tier_body", [], [], 10, 10)
	var definition: Dictionary = _kit.library.get_unit(id)
	definition["tier"] = 4
	var mid: RecruitUnit = _kit.put(id, 1)
	var units: Dictionary = _brain.value.strategy["units"]
	units["standing_committee"] = 40
	_kit.shop("standing_committee")
	assert_true(_brain._buy_offer(_brain._best_offer()))
	assert_false(_kit.player.board.has(old))
	assert_same(_kit.player.board[1], mid)


func test_player_facing_hard_uses_the_promoted_policy() -> void:
	_full_board()
	var unit: RecruitUnit = _kit.shop("standing_committee")
	var hard: BotBrain = Bot.create("hard") as BotBrain
	hard._player = _kit.player
	hard._rules = _kit.rules
	hard.value.board_owner = _kit.player
	hard.value.strategy = _brain.value.strategy
	assert_gt(hard._unit_gain(unit), 0.0)
	assert_eq(hard._unit_gain(unit), _brain._unit_gain(unit))
	hard.value.board_owner = null
	hard._player = null
	hard._rules = null
