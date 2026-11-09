extends GutTest
## No build route can influence free-choice purchases or the measured final-board label.
@warning_ignore_start("unsafe_call_argument")

var _library: UnitLibrary = TestLibraries.current()


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
		RecruitUnit.make(_library.get_unit("field_vole"), 1),
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


func test_tokens_do_not_dilute_tribes_and_pluralities_explain_mixed_boards() -> void:
	var fairy: Dictionary = {"def_id": "rainbow_chaser"}
	var bird: Dictionary = {"def_id": "mrs_dunnock"}
	var egg: Dictionary = {"def_id": "nest_egg"}
	var token: Dictionary = {"def_id": "hoglet"}
	var neutral: Dictionary = {"def_id": "charcoal_burner"}
	assert_eq(BenchTribes.final_tribe([fairy, egg, egg, egg], _library), "Fairies")
	assert_eq(BenchTribes.final_tribe([fairy, token, token], _library), "Fairies")
	var label: Dictionary = BenchTribes.classify([fairy, fairy, bird, neutral], _library)
	assert_eq(label["final_tribe"], "no_tribe")
	assert_eq(label["plurality_tribe"], "Fairies")
	assert_eq(label["plurality_share"], 0.5)
	assert_eq(label["no_tribe_reason"], "mixed")
	label = BenchTribes.classify([fairy, bird], _library)
	assert_eq(label["plurality_tribe"], "Birds+Fairies")
	assert_eq(label["no_tribe_reason"], "tied_plurality")
	assert_eq(BenchTribes.classify([egg], _library)["no_tribe_reason"], "tokens_only")
	assert_eq(BenchTribes.classify([neutral], _library)["no_tribe_reason"], "neutral_only")
	assert_eq(BenchTribes.classify([], _library)["no_tribe_reason"], "empty")


func test_plain_arm_ignores_buy_keep_hints_without_mutating_shared_knowledge() -> void:
	var plain: BotBrain = BenchSuites.create_bot("free_choice_plain") as BotBrain
	var hinted: BotBrain = BenchSuites.create_bot("free_choice") as BotBrain
	var player := PlayerState.new()
	var unit: RecruitUnit = RecruitUnit.make(_library.get_unit("wee_wobbly"), 1)
	plain._choose_build()
	assert_true(BenchSuites.is_known("free_choice_plain"))
	assert_true(plain.value.strategy.is_empty())
	assert_eq(BenchSuites.seats("free_choice_plain", 42).count("free_choice_plain"), 8)
	var buy_before: float = plain.value.buy_value(unit, player)
	var keep_before: float = plain.value.keep_value(unit)
	var text_before: float = plain.value.text_value(unit)
	# Inject extreme hints into isolated knowledge; every hint-based path must ignore them.
	var injected := BotKnowledge.new()
	injected.cards = {unit.def_id(): {"buy": 99999, "keep": 88888}}
	plain.value.knowledge = injected
	assert_eq(plain.value.buy_value(unit, player), buy_before)
	assert_eq(plain.value.keep_value(unit), keep_before)
	assert_eq(plain.value.text_value(unit), text_before)
	assert_eq(text_before, BotEval.TEXT_PER_TIER * unit.tier())
	assert_ne(hinted.value.knowledge.card(unit.def_id()), injected.card(unit.def_id()))
	assert_ne(hinted.value.buy_value(unit, player), buy_before)


func test_plain_arm_real_lobby_keeps_routes_empty() -> void:
	var seats: PackedStringArray = BenchSuites.seats("free_choice_plain", 71)
	var config: GameConfig = GameConfig.full_game()
	config.set_value("human_bot", seats[0])
	config.set_value("bots", Array(seats.slice(1)))
	var session: GameSession = GameSession.create(71, _library, config, BenchSuites.create_bot)
	assert_eq(session.end_turn(), "")
	for seat: int in 8:
		assert_eq(session.build_of(seat), "")
