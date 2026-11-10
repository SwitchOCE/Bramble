extends GutTest
@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/recruit_kit.gd")


func test_default_zero_remains_a_literal_noop_and_default_engine_is_not_in_pool() -> void:
	var library := TestLibraries.current()
	var count: int = library.all_units().size()
	var pool_count: int = library.pool_units("slice").size()
	assert_true(PlantedEngine.install(library, 0).is_empty())
	assert_eq(library.all_units().size(), count)
	var card: Dictionary = PlantedEngine.install(library, 256)
	assert_false(CoreUtil.to_bool(card["pool"]))
	assert_eq(library.pool_units("slice").size(), pool_count)
	assert_eq(library.all_units().size(), count + 1)


func test_explicit_null_and_reference_register_identical_real_inert_bodies() -> void:
	var library := TestLibraries.current()
	var count: int = library.all_units().size()
	var null_card: Dictionary = PlantedEngine.install(library, 0, "null")
	var reference: Dictionary = PlantedEngine.install(library, 0, "reference")
	assert_eq(library.all_units().size(), count + 2)
	assert_eq(null_card["id"], "bench_null")
	assert_eq(reference["id"], "bench_reference")
	assert_eq(null_card["attack"], 1)
	assert_eq(null_card["health"], 1)
	assert_eq(null_card["tier"], 1)
	assert_eq(null_card["set"], "slice")
	assert_eq(null_card["text"], "")
	assert_eq(null_card["golden_text"], "")
	assert_eq(null_card["mechanics"], [])
	assert_false(library.get_unit("bench_null").is_empty())
	var expected: Dictionary = reference.duplicate(true)
	expected["id"] = "bench_null"
	assert_eq(null_card, expected, "only the definition id distinguishes the two controls")


func test_only_explicit_pool_opt_in_adds_test_cards_to_the_real_shop_pool() -> void:
	for mode: String in ["engine", "null", "reference"]:
		for in_pool: bool in [false, true]:
			var library := TestLibraries.current()
			var card: Dictionary = PlantedEngine.install(library, 4, mode, in_pool)
			var pool := UnitPool.create(library, GameConfig.full_game())
			assert_eq(pool.has_unit(str(card["id"])), in_pool, mode)
			if in_pool:
				assert_gt(pool.copies_left(str(card["id"])), 0)


func test_forced_null_is_played_and_pool_cards_are_not_force_played() -> void:
	for in_pool: bool in [false, true]:
		var library := TestLibraries.current()
		var card: Dictionary = PlantedEngine.install(library, 0, "null", in_pool)
		var session := GameSession.create(891, library, GameConfig.full_game())
		var player: PlayerState = session._players[0]
		var before: String = FightCapture.canonical(player.combat_board())
		var hand_size: int = player.hand.size()
		PlantedEngine.spawn(session, card)
		if in_pool:
			assert_eq(FightCapture.canonical(player.combat_board()), before)
			assert_eq(player.hand.size(), hand_size)
		else:
			assert_eq(player.board[0].def_id(), "bench_null")
			assert_eq(player.board[0].attack, 1)
			assert_eq(player.board[0].health, 1)


func test_zero_growth_null_has_no_end_of_turn_effect_or_event() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game())
	var card: Dictionary = PlantedEngine.install(kit.library, 0, "null")
	var unit: RecruitUnit = kit.put(str(card["id"]), 0)
	kit.player.recruit_log.clear()
	kit.rules.end_phase(kit.player)
	assert_eq(unit.attack, 1)
	assert_eq(unit.health, 1)
	assert_eq(kit.rules.events._delivered, 0, "no mechanic receives End of Turn")
	assert_eq(kit.player.recruit_log, [], "no End of Turn effect event is emitted")


func test_real_end_of_turn_effects_grow_permanently_at_every_dose() -> void:
	for growth: int in [1, 4, 16, 64, 128]:
		var kit := Kit.new()
		kit.setup(GameConfig.full_game())
		var card: Dictionary = PlantedEngine.install(kit.library, growth)
		var unit: RecruitUnit = kit.put(str(card["id"]), 0)
		kit.rules.end_phase(kit.player)
		assert_eq(unit.attack, 1 + growth)
		assert_eq(unit.health, 1 + growth)
		kit.rules.start_phase(kit.player, 2)
		kit.rules.end_phase(kit.player)
		assert_eq(unit.attack, 1 + 2 * growth)
		assert_eq(unit.health, 1 + 2 * growth)


func _control_fight(library: UnitLibrary, id: String, fight_seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = fight_seed
	var combat := Combat.create(library, GameConfig.full_game(), rng)
	var ours: Array = []
	var theirs: Array = []
	ours.resize(BoardGeometry.SLOTS)
	theirs.resize(BoardGeometry.SLOTS)
	ours[0] = {"def_id": id, "iid": 101, "golden": false, "attack": 1, "health": 1}
	ours[1] = {"def_id": "field_vole", "iid": 102, "attack": 2, "health": 4}
	theirs[0] = {"def_id": "field_vole", "iid": 201, "attack": 1, "health": 3}
	theirs[1] = {"def_id": "field_vole", "iid": 202, "attack": 2, "health": 2}
	var tiers: Array[int] = [1, 1]
	var ids: Array[int] = [0, 1]
	return combat.run([ours, theirs], tiers, ids, 0)


func test_real_combat_null_and_reference_have_identical_outcomes_and_normalized_events() -> void:
	var library := TestLibraries.current()
	PlantedEngine.install(library, 0, "null")
	PlantedEngine.install(library, 0, "reference")
	for fight_seed: int in [1, 17, 891]:
		var null_result: Dictionary = _control_fight(library, "bench_null", fight_seed)
		var reference: Dictionary = _control_fight(library, "bench_reference", fight_seed)
		var null_events: Array = null_result["events"]
		var reference_events: Array = reference["events"]
		assert_true(FightCapture.canonical(null_events).contains("bench_null"))
		assert_eq(
			FightCapture.canonical(null_events).replace("bench_null", "bench_reference"),
			FightCapture.canonical(reference_events),
			"same iids and RNG produce every event identically after definition id normalization"
		)
		null_result.erase("events")
		reference.erase("events")
		assert_eq(null_result, reference, "winner, damage, carry and all other outcome fields")
