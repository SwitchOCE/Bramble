extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access", "unsafe_cast")

const Kit := preload("res://tests/core/recruit_kit.gd")
const Brain := preload("res://tools/sim/skilled_birds_brain.gd")
const ORIGINAL_B := preload("res://tests/core/pass3_original_b.gd")


func _brain(kit: Kit, aggressive: bool) -> Brain:
	var brain: Brain = BotBrain.from_name("hard@blind", Brain) as Brain
	brain.configure_line("line_birds_homecoming")
	brain.aggressive_flight = aggressive
	brain._player = kit.player
	brain._rules = kit.rules
	brain._round_now = kit.player.round_number
	brain.value.library = kit.library
	brain.value.recruit_rules = kit.rules
	brain.value.board_owner = kit.player
	return brain


func _kit(config: GameConfig = null) -> Kit:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game() if config == null else config)
	kit.rules.start_phase(kit.player, 10)
	kit.player.shop.clear()
	return kit


func test_biggest_legal_carry_flies_despite_native_danger_rejection() -> void:
	var kit: Kit = _kit()
	kit.player.health = 1
	var carry: RecruitUnit = kit.put("chiffchaff", 0)
	carry.add_permanent(100, 100)
	carry.played_round = 9
	var smaller: RecruitUnit = kit.put("one_swallow", 1)
	smaller.played_round = 9
	for id: String in ["mr_redbreast", "mrs_dunnock", "tom_tit", "mrs_stork", "great_lump"]:
		kit.put(id, kit.player.board_count())
	kit.rules.board_changed(kit.player)
	var brain: Brain = _brain(kit, true)
	var before: Dictionary = Brain.flight_decision(kit.player, brain.value, 10, true)
	assert_eq(before["biggest_legal_slot"], 0)
	assert_ne(before["native_chosen_slot"], 0)
	assert_true(before["candidates"][0]["legacy_denials"].has("hard_danger_largest"))
	brain._flight_turn()
	assert_eq(brain.flight_log[0]["chosen_slot"], 0)
	assert_true(brain.flight_log[0]["flew"])
	assert_eq(kit.player.away[0]["unit"], carry)
	assert_null(kit.player.board[0])


func test_illegal_same_turn_and_plain_copy_stay_without_sale_or_flight() -> void:
	var kit: Kit = _kit()
	var fresh: RecruitUnit = kit.put("chiffchaff", 0)
	fresh.add_permanent(1000, 1000)
	fresh.played_round = kit.player.round_number
	var copy: RecruitUnit = kit.put("one_swallow", 1)
	copy.plain_copy = true
	copy.played_round = 1
	var brain: Brain = _brain(kit, true)
	var gold: int = kit.player.gold
	brain._flight_turn()
	assert_eq(brain.flight_log.size(), 1)
	assert_eq(brain.flight_log[0]["chosen_slot"], -1)
	assert_eq(kit.player.away.size(), 0)
	assert_eq(kit.player.gold, gold)
	assert_eq(kit.player.board[0], fresh)
	assert_eq(kit.player.board[1], copy)


func test_pending_choice_never_performs_a_flight_action() -> void:
	var kit: Kit = _kit()
	var bird: RecruitUnit = kit.put("mrs_jay", 0)
	bird.played_round = 1
	kit.player.pending.append({"kind": "unit", "options": ["chiffchaff"]})
	var brain: Brain = _brain(kit, true)
	brain._flight_turn()
	assert_eq(kit.player.board[0], bird)
	assert_eq(kit.player.away.size(), 0)
	assert_eq(brain.flight_log[0]["chosen_slot"], -1)


func test_native_homecoming_doubles_body_and_forbids_same_round_redeparture() -> void:
	var kit: Kit = _kit(ORIGINAL_B.apply(GameConfig.full_game()))
	var bird: RecruitUnit = kit.put("one_swallow", 0)
	bird.played_round = 9
	kit.rules.board_changed(kit.player)
	var attack: int = bird.base_attack_now() + bird.perm_attack
	var health: int = bird.base_health_now() + bird.perm_health
	var brain: Brain = _brain(kit, true)
	brain._flight_turn()
	assert_eq(kit.player.away.size(), 1)
	kit.rules.end_phase(kit.player)
	kit.rules.after_fights(kit.player)
	kit.rules.start_phase(kit.player, 11)
	assert_eq(bird.base_attack_now() + bird.perm_attack, 2 * attack)
	assert_eq(bird.base_health_now() + bird.perm_health, 2 * health)
	assert_eq(kit.player.homecomings_this_turn, 1)
	assert_eq(kit.rules.play(kit.player, kit.player.hand.find(bird), 0), "")
	brain._round_now = 11
	brain._flight_turn()
	assert_eq(brain.flight_log[0]["chosen_slot"], -1)
	assert_eq(kit.player.away.size(), 0)
	assert_eq(kit.player.board[0], bird)
	kit.rules.end_phase(kit.player)
	kit.rules.after_fights(kit.player)
	kit.rules.start_phase(kit.player, 12)
	brain._round_now = 12
	brain._flight_turn()
	assert_true(brain.flight_log[0]["flew"])
	assert_eq(kit.player.away[0]["unit"], bird)


func _control_factory(bot_name: String) -> Bot:
	var alias: String = bot_name.get_slice(":", 0).get_slice("@", 0)
	if alias not in ["line_birds_homecoming", "line_birds_tempo"]:
		return BenchSuites.create_bot(bot_name)
	var brain: Brain = BotBrain.from_name("hard@blind", Brain) as Brain
	brain.configure_line(alias)
	return brain


func test_control_instrumentation_preserves_native_lobby_results_and_pool() -> void:
	var config := GameConfig.full_game()
	var seats: PackedStringArray = BenchSuites.seats("wave1_accounting", 1900301)
	config.set_value("tribes_per_lobby", 0)
	config.set_value("human_bot", seats[0])
	config.set_value("bots", Array(seats.slice(1)))
	config.set_value("max_rounds", 4)
	var library := TestLibraries.current()
	var native := GameSession.create(1900301, library, config, BenchSuites.create_bot)
	var observed := GameSession.create(1900301, library, config, _control_factory)
	while not native.is_over():
		assert_eq(native.end_turn(), "")
	while not observed.is_over():
		assert_eq(observed.end_turn(), "")
	assert_eq_deep(observed.get_game_log(), native.get_game_log())
	assert_eq_deep(observed._pool._copies, native._pool._copies)
	for seat: int in 8:
		assert_eq(observed._players[seat].shop_rng.state, native._players[seat].shop_rng.state)
		assert_eq(observed._players[seat].effect_rng.state, native._players[seat].effect_rng.state)


func test_forcing_the_carry_preserves_native_guard_for_other_fliers() -> void:
	var kit: Kit = _kit()
	var carry: RecruitUnit = kit.put("chiffchaff", 0)
	carry.add_permanent(100, 100)
	carry.played_round = 9
	for slot: int in [1, 2]:
		var other: RecruitUnit = kit.put("one_swallow", slot)
		other.played_round = 9
	kit.rules.board_changed(kit.player)
	var brain: Brain = _brain(kit, true)
	brain._flight_turn()
	assert_eq(kit.player.away.size(), 1)
	assert_eq(kit.player.away[0]["unit"], carry)
	assert_eq(kit.player.board_count(), 2)
