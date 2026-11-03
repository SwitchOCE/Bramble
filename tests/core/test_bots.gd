extends GutTest
## The bot policy of SPEC section 8.
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

var _library: UnitLibrary = UnitLibrary.load_dir()
var _config: GameConfig
var _pool: UnitPool
var _rules: RecruitRules
var _player: PlayerState


func before_each() -> void:
	_config = GameConfig.defaults()
	_pool = UnitPool.create(_library, _config)
	_rules = RecruitRules.create(_library, _config, _pool)
	_player = PlayerState.new()
	_player.shop_rng.seed = 3
	_player.bot_rng.seed = 4
	_rules.setup_player(_player)


func _unit(def_id: String) -> RecruitUnit:
	var unit := RecruitUnit.make(_library.get_unit(def_id), _rules.new_iid())
	unit.pool_copies = 0
	return unit


func _shop(def_ids: Array[String]) -> void:
	_player.shop.clear()
	for def_id: String in def_ids:
		_player.shop.append(_unit(def_id))


func test_buys_the_best_score_and_plays_it() -> void:
	_rules.start_phase(_player, 1)
	_shop(["field_vole", "marsh_frog", "pixie_scout"])
	_player.shop[2].attack = 9
	Bot.create(Bot.WIDE).play_turn(_player, _rules, 1)
	assert_eq(_player.board_count(), 1, "bought one unit and played it")
	assert_eq(_player.owned_units()[0].def_id(), "pixie_scout", "the highest score")


func test_balanced_buys_on_turn_1_then_keeps_a_reserve_of_2() -> void:
	_rules.start_phase(_player, 1)
	var bot: Bot = Bot.create(Bot.BALANCED)
	bot.play_turn(_player, _rules, 1)
	assert_eq(
		[_player.gold, _player.board_count()], [0, 1], "no reserve on turn 1 (prototype pick)"
	)
	_rules.end_phase(_player)
	_rules.start_phase(_player, 2)
	_player.gold = 4
	bot.play_turn(_player, _rules, 2)
	assert_eq(_player.gold, 4, "4 minus a buy would leave 1 < 2")


func test_greedy_tiers_up_from_turn_2() -> void:
	_rules.start_phase(_player, 1)
	_player.gold = 20
	Bot.create(Bot.GREEDY).play_turn(_player, _rules, 1)
	assert_eq(_player.tier, 1, "not on turn 1")
	_rules.end_phase(_player)
	_rules.start_phase(_player, 2)
	_player.gold = 20
	Bot.create(Bot.GREEDY).play_turn(_player, _rules, 2)
	assert_eq(_player.tier, 4, "as often as it can pay: 4, 7 and 8 out of 20")


func test_wide_tiers_up_only_on_its_turns() -> void:
	_rules.start_phase(_player, 3)
	_player.gold = 50
	Bot.create(Bot.WIDE).play_turn(_player, _rules, 3)
	assert_eq(_player.tier, 1, "not on turn 3")
	Bot.create(Bot.WIDE).play_turn(_player, _rules, 4)
	assert_eq(_player.tier, 2, "once on turn 4")


func test_places_rows_by_hint_and_health() -> void:
	_player.board[0] = _unit("still_water_heron")
	_player.board[1] = _unit("field_vole")
	_player.board[2] = _unit("marsh_frog")
	_player.board[3] = _unit("pixie_scout")
	Bot.create(Bot.BALANCED).place(_player)
	assert_eq(_player.board[4].def_id(), "still_water_heron", "back hint goes to the back row")
	assert_eq(_player.board[1].def_id(), "marsh_frog", "the highest Health takes F2")
	assert_eq(_player.board[2].def_id(), "field_vole", "the next takes F3")


func test_both_ends_take_the_row_ends_and_warden_the_centre() -> void:
	_player.board[4] = _unit("hedgehog_twin")
	_player.board[5] = _unit("hedgehog_twin")
	_player.board[6] = _unit("sett_warden")
	_player.board[1] = _unit("hedge_sprite")
	Bot.create(Bot.BALANCED).place(_player)
	assert_eq(_player.board[0].def_id(), "hedgehog_twin", "F1")
	assert_eq(_player.board[3].def_id(), "hedgehog_twin", "F4")
	assert_eq(_player.board[1].def_id(), "sett_warden", "F2")
	assert_eq(_player.board[2].def_id(), "hedge_sprite", "F3")


func test_full_board_swaps_in_a_much_better_unit() -> void:
	for slot: int in BoardGeometry.SLOTS:
		_player.board[slot] = _unit("field_vole")
	_player.hand.append(_unit("elder_ooze"))
	_player.hand.append(_unit("marsh_frog"))
	Bot.create(Bot.BALANCED).play_turn(_player, _rules, 1)
	var ids: Array = []
	for unit: RecruitUnit in _player.board:
		ids.append(unit.def_id())
	assert_true(ids.has("elder_ooze"), "a far better unit replaces the weakest")
	assert_false(ids.has("marsh_frog"), "a unit only a little better stays in hand")


func test_tribe_bot_never_sells_its_tribe() -> void:
	var bot: Bot = Bot.create(Bot.TRIBE)
	for slot: int in BoardGeometry.SLOTS:
		_player.board[slot] = _unit("dewdrop_ooze")
	_player.hand.append(_unit("elder_ooze"))
	bot.play_turn(_player, _rules, 3)
	assert_eq(bot.favoured_tribe, "Oozes", "picks the tribe it has most of")
	assert_eq(_player.hand.size(), 1, "it won't sell an Ooze to make room")


func test_never_freezes() -> void:
	_rules.start_phase(_player, 5)
	_player.gold = 30
	Bot.create(Bot.GREEDY).play_turn(_player, _rules, 5)
	assert_false(_player.frozen, "bots never freeze")
