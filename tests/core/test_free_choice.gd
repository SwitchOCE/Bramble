extends GutTest
## No build route can influence free-choice purchases or the measured final-board label.
@warning_ignore_start("unsafe_call_argument")

var _library: UnitLibrary = UnitLibrary.load_dir()


func test_suite_seats_survive_the_lobby_without_pins() -> void:
	var seats: PackedStringArray = BenchSuites.seats("free_choice", 42)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	assert_eq(seats.size(), 8)
	assert_true(BenchSuites.is_known("free_choice"))
	assert_eq(BotLobby.resolve(seats, ["Birds", "Fairies"], rng), seats)
	for seat: String in seats:
		var brain: BotBrain = BenchSuites.create_bot(seat) as BotBrain
		assert_eq(brain.pinned_strategy, "")
		assert_true(brain.value.strategy.is_empty())
		brain.value.strategy = {"id": "injected", "power": 999}
		brain._choose_build()
		assert_true(brain.value.strategy.is_empty(), "even a stale route cannot steer a turn")


func test_equal_bodies_have_equal_value_for_every_tribe() -> void:
	var brain: BotBrain = BenchSuites.create_bot("free_choice") as BotBrain
	var player := PlayerState.new()
	for tribe: String in ["Birds", "Fairies", "Hunters", "Oozes", "Bog folk", "Hedgerow folk"]:
		var unit := RecruitUnit.make(
			{
				"id": "test_body",
				"tier": 1,
				"attack": 2,
				"health": 3,
				"tribes": [tribe],
				"mechanics": []
			},
			1
		)
		assert_eq(brain.value.build_bonus(unit.def), 0.0)
		assert_eq(brain.value.buy_value(unit, player), 6.5)
		player.tribe_bonuses = {tribe: 2}
		assert_eq(brain.value.buy_value(unit, player), 10.5, "only actual kin investment pays")
		player.tribe_bonuses = {}


func test_shop_purchase_follows_value_not_a_tribe_route() -> void:
	var brain: BotBrain = BenchSuites.create_bot("free_choice") as BotBrain
	var config: GameConfig = GameConfig.full_game()
	var rules: RecruitRules = RecruitRules.create(
		_library, config, UnitPool.create(_library, config)
	)
	var player := PlayerState.new()
	player.gold = 3
	player.shop = [
		RecruitUnit.make(_library.get_unit("mrs_dunnock"), 1),
		RecruitUnit.make(_library.get_unit("wee_wobbly"), 2),
	]
	brain._player = player
	brain._rules = rules
	brain.value.library = _library
	brain.value.board_owner = player
	assert_eq(brain._best_offer().get("index"), 1, "buy the better offered body")
	player.shop.reverse()
	assert_eq(brain._best_offer().get("index"), 0, "shop order cannot pin a route")
	brain._player = null
	brain._rules = null
	brain.value.board_owner = null


func test_final_board_majority_and_mixed_labels() -> void:
	var bird: Dictionary = {"def_id": "mrs_dunnock"}
	var ooze: Dictionary = {"def_id": "wee_wobbly"}
	var neutral: Dictionary = {"def_id": "charcoal_burner"}
	assert_eq(BenchTribes.final_tribe([bird, bird, ooze, neutral, null], _library), "no_tribe")
	assert_eq(BenchTribes.final_tribe([bird, bird, ooze, null], _library), "Birds")
	assert_eq(BenchTribes.final_tribe([ooze, neutral, neutral], _library), "no_tribe")
	assert_eq(BenchTribes.final_tribe([], _library), "no_tribe")


func test_real_lobby_turns_keep_every_seat_free_to_choose() -> void:
	var seats: PackedStringArray = BenchSuites.seats("free_choice", 71)
	var config: GameConfig = GameConfig.full_game()
	config.set_value("human_bot", seats[0])
	config.set_value("bots", Array(seats.slice(1)))
	var session: GameSession = GameSession.create(71, _library, config, BenchSuites.create_bot)
	for _round: int in 3:
		assert_eq(session.end_turn(), "")
		for seat: int in 8:
			assert_eq(session.build_of(seat), "", "no lobby deal or route choice can pin a seat")


func test_final_fight_board_keeps_empty_nest_eggs_in_the_denominator() -> void:
	var player := PlayerState.new()
	for slot: int in 3:
		player.board[slot] = RecruitUnit.make(_library.get_unit("rainbow_chaser"), slot)
	for slot: int in range(3, 7):
		player.away.append(
			{"nest": slot, "unit": RecruitUnit.make(_library.get_unit("chiffchaff"), slot)}
		)
	player.remember_fought_board()
	assert_eq(BenchTribes.final_tribe(player.board_specs(), _library), "Fairies")
	assert_eq(BenchTribes.final_tribe(player.fought_specs, _library), "no_tribe")
	assert_eq(player.fought_specs[6]["def_id"], "nest_egg")
