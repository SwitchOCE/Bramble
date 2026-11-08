extends GutTest
@warning_ignore_start("unsafe_method_access", "unsafe_call_argument")

const Kit := preload("res://tests/core/recruit_kit.gd")
const Fight := preload("res://tests/core/combat_kit.gd")


func test_pass_ignores_gaps_and_source_and_sold_slot_replacement() -> void:
	var kit := Kit.new()
	kit.setup()
	var carry: RecruitUnit = kit.put("field_vole", 3)
	var crumb: RecruitUnit = kit.put("mr_crumb")
	assert_eq(kit.rules.play(kit.player, 0, 0), "")
	kit.rules.end_phase(kit.player)
	assert_eq(carry.attack, 3)
	assert_eq(crumb.attack, 1)
	assert_eq(kit.rules.sell(kit.player, 0), "")
	kit.player.board[3] = null
	var replacement: RecruitUnit = kit.put("field_vole", 0)
	kit.rules.end_phase(kit.player)
	assert_eq(replacement.attack, 3, "a sold source does not exclude its old slot")
	assert_eq(BoardGeometry.pass_landing(kit.player.occupied(), 0), -1)


func test_mire_waits_once_without_looping_even_in_a_mirer_duel() -> void:
	var result: Dictionary = Fight.run(
		Fight.board({0: Fight.u("bridge_toad", 1, 8)}),
		Fight.board({0: Fight.u("bridge_toad", 1, 8)})
	)
	var waits: Array[Dictionary] = Fight.of_type(result, "mire_wait")
	assert_eq(waits.size(), 2)
	assert_ne(waits[0]["uid"], waits[1]["uid"])
	assert_eq(result["reason"], Combat.REASON_BOARD_EMPTY)


func test_mire_wait_skips_the_cycle_and_next_friendly_attacks() -> void:
	for fight_seed: int in range(1, 12):
		var result: Dictionary = Fight.run(
			Fight.board({0: Fight.u("bridge_toad", 1, 12), 1: Fight.plain(1, 20)}),
			Fight.board({0: Fight.plain(2, 20), 1: Fight.plain(1, 20)}),
			fight_seed
		)
		var waits: Array[Dictionary] = Fight.of_type(result, "mire_wait")
		assert_lte(waits.size(), 1)
		if not waits.is_empty():
			var wait_at: int = Fight.index_of(result, "mire_wait")
			var events: Array[Dictionary] = Fight.events(result)
			for index: int in range(wait_at + 1, events.size()):
				if events[index]["type"] == "attack":
					assert_ne(events[index]["attacker"], waits[0]["uid"])
					break


func test_four_unit_tier_one_and_kin_off_by_default() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game())
	kit.rules.start_phase(kit.player, 1)
	assert_eq(kit.player.shop.size(), 4)
	assert_false(RecruitKin.available(kit.rules, kit.player))
	assert_false(GameConfig.full_game().get_bool("ask_for_kin"))


func test_kin_paid_refresh_once_per_turn_and_nests_count_as_birds() -> void:
	var kit := Kit.new()
	var config := GameConfig.full_game()
	config.set_value("ask_for_kin", true)
	kit.setup(config)
	kit.rules.start_phase(kit.player, 3)
	var bird: RecruitUnit = kit.put("mrs_jay")
	kit.player.away.append({"unit": bird, "nest": 0, "due": 8})
	kit.player.gold = 8
	assert_true(RecruitKin.available(kit.rules, kit.player))
	assert_eq(RecruitKin.ask(kit.rules, kit.player), "")
	assert_eq(kit.player.gold, 6)
	assert_eq(kit.player.paid_refreshes, 1)
	var birds: int = 0
	for unit: RecruitUnit in kit.player.shop:
		birds += 1 if unit.has_tribe("Birds") else 0
	assert_gte(birds, 2)
	assert_false(RecruitKin.available(kit.rules, kit.player))


func test_kin_depleted_pool_shows_what_it_can_and_preserves_copies() -> void:
	var kit := Kit.new()
	var config := GameConfig.full_game()
	config.set_value("ask_for_kin", true)
	kit.setup(config)
	kit.put("wick", 0)
	kit.player.tier = 1
	kit.player.gold = 4
	for card: String in kit.pool.ids():
		if kit.pool.tribes_of(card).has("Hunters"):
			while kit.pool.take(card):
				pass
	kit.pool.give_back("wick", 1)
	var before: int = kit.pool.total_copies()
	assert_eq(RecruitKin.ask(kit.rules, kit.player), "")
	assert_eq(kit.player.shop.size(), 4)
	assert_eq(kit.pool.total_copies(), before - 4)


func test_early_spoils_queues_one_gold_only_for_early_live_wins() -> void:
	for round_number: int in [1, 4, 5]:
		var config := GameConfig.full_game()
		config.set_value("hero_choice", false)
		var session := GameSession.create(99, UnitLibrary.load_dir(), config)
		session._round = round_number
		var a: PlayerState = session._players[0]
		var b: PlayerState = session._players[1]
		a.board[0] = RecruitUnit.make(session._library.get_unit("wick"), 10001)
		a.board[0].add_permanent(20, 30)
		b.board[0] = RecruitUnit.make(session._library.get_unit("field_vole"), 10002)
		session._fight(0, 1, 0)
		assert_eq(a.early_spoils_next_turn, 1 if round_number <= 4 else 0)
		session._rules.start_phase(a, round_number + 1)
		assert_eq(a.early_spoils_income, 1 if round_number <= 4 else 0)
		assert_eq(a.early_spoils_next_turn, 0)
		session._fight(0, -1, 0)
		assert_eq(a.early_spoils_next_turn, 0, "ghost wins pay no Spoils")
